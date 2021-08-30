
[CmdletBinding(SupportsShouldProcess=$true)]
param(
    [parameter(Mandatory=$true, HelpMessage="Site server where the SMS Provider is installed.")]
    [ValidateNotNullOrEmpty()]
    [ValidateScript({Test-Connection -ComputerName $_ -Count 1 -Quiet})]
    [string]$SiteServer,

    [parameter(Mandatory=$true, HelpMessage="Object types that should be assessed for distribution. Supports multiple objects as a string array.")]
    [ValidateNotNullOrEmpty()]
    [ValidateSet("Application","Package","DriverPackage","DeploymentPackage","OSImage","OSUpgradePackage","BootImage")]
    [string[]]$ObjectType,

    [parameter(Mandatory=$true, HelpMessage="Name of a Distribution Point Group where all non-distributed packages will be added to.")]
    [ValidateNotNullOrEmpty()]
    [string]$DPGroupName,

    [parameter(Mandatory=$false, HelpMessage="Amount of seconds the script will wait until processing next object for distribution.")]
    [ValidateNotNullOrEmpty()]
    [int]$DistributionDelaySeconds = 3,

    [parameter(Mandatory=$false, HelpMessage="Show a progressbar displaying the current operation.")]
    [ValidateNotNullOrEmpty()]
    [switch]$ShowProgress
)
Begin {
    
    try {
        Write-Verbose -Message "Determining SiteCode for Site Server: '$($SiteServer)'"
        $SiteCodeObjects = Get-WmiObject -Namespace "root\SMS" -Class SMS_ProviderLocation -ComputerName $SiteServer -ErrorAction Stop
        foreach ($SiteCodeObject in $SiteCodeObjects) {
            if ($SiteCodeObject.ProviderForLocalSite -eq $true) {
                $SiteCode = $SiteCodeObject.SiteCode
                Write-Debug -Message "SiteCode: $($SiteCode)"
            }
        }
    }
    catch [System.UnauthorizedAccessException] {
        Write-Warning -Message "Access denied" ; break
    }
    catch [System.Exception] {
        Write-Warning -Message "Unable to determine SiteCode" ; break
    }

    
    try {
        $SiteDrive = $SiteCode + ":"
        Import-Module -Name ConfigurationManager -ErrorAction Stop -Verbose:$false
    }
    catch [System.UnauthorizedAccessException] {
        Write-Warning -Message "Access denied" ; break
    }
    catch [System.Exception] {
        try {
            Import-Module (Join-Path -Path (($env:SMS_ADMIN_UI_PATH).Substring(0,$env:SMS_ADMIN_UI_PATH.Length-5)) -ChildPath "\ConfigurationManager.psd1") -Force -ErrorAction Stop -Verbose:$false
            if ((Get-PSDrive $SiteCode -ErrorAction SilentlyContinue | Measure-Object).Count -ne 1) {
                New-PSDrive -Name $SiteCode -PSProvider "AdminUI.PS.Provider\CMSite" -Root $SiteServer -ErrorAction Stop -Verbose:$false
            }
        }
        catch [System.UnauthorizedAccessException] {
            Write-Warning -Message "Access denied" ; break
        }
        catch [System.Exception] {
            Write-Warning -Message "$($_.Exception.Message). Line: $($_.InvocationInfo.ScriptLineNumber)" ; break
        }
    }

    
    try {
        Add-Type -Path (Join-Path (Get-Item $env:SMS_ADMIN_UI_PATH).Parent.FullName "Microsoft.ConfigurationManagement.ApplicationManagement.dll") -ErrorAction Stop
        Add-Type -Path (Join-Path (Get-Item $env:SMS_ADMIN_UI_PATH).Parent.FullName "Microsoft.ConfigurationManagement.ApplicationManagement.Extender.dll") -ErrorAction Stop
        Add-Type -Path (Join-Path (Get-Item $env:SMS_ADMIN_UI_PATH).Parent.FullName "Microsoft.ConfigurationManagement.ApplicationManagement.MsiInstaller.dll") -ErrorAction Stop
    }
    catch [System.UnauthorizedAccessException] {
        Write-Warning -Message "Access denied" ; break
    }
    catch [System.Exception] {
        Write-Warning -Message $_.Exception.Message ; break
    }

    
    $CurrentLocation = $PSScriptRoot

    
    $ObjectTypeIDTable = @{
        "Package" = "2"
        "OSUpgradePackage" = "14"
        "OSImage" = "18"
        "BootImage" = "19"
        "DriverPackage" = "23"
        "DeploymentPackage" = "24"
        "Application" = "31"
    }

    
    $SMSClassTable = @{
        "Package" = "SMS_Package"
        "OSUpgradePackage" = "SMS_OperatingSystemInstallPackage"
        "OSImage" = "SMS_ImagePackage"
        "BootImage" = "SMS_BootImagePackage"
        "DriverPackage" = "SMS_DriverPackage"
        "DeploymentPackage" = "SMS_SoftwareUpdatesPackage"
        "Application" = "SMS_ApplicationLatest"
    }
}
Process {
    
    function Invoke-ValidateContentPath {
        param(
            [parameter(Mandatory=$true)]
            [ValidateNotNullOrEmpty()]
            [string]$InputObject,
            [parameter(Mandatory=$true)]
            [ValidateNotNullOrEmpty()]
            [string]$ObjectIdentifier,
            [parameter(Mandatory=$true)]
            [ValidateNotNullOrEmpty()]
            [string]$SMSClass,
            [parameter(Mandatory=$true)]
            [ValidateNotNullOrEmpty()]
            [ValidateSet("Application","Package","DriverPackage","DeploymentPackage","OSImage","OSUpgradePackage","BootImage")]
            [string]$ObjectType
        )
        switch ($ObjectType) {
            "Application" {
                $Application = Get-WmiObject -Namespace "root\SMS\site_$($SiteCode)" -Class $SMSClass -ComputerName $SiteServer -Filter "$ObjectIdentifier like '$($InputObject)'"
                if ($Application.HasContent -eq $true) {
                    $Application.Get()
                    $ApplicationXML = [Microsoft.ConfigurationManagement.ApplicationManagement.Serialization.SccmSerializer]::DeserializeFromString($Application.SDMPackageXML, $true)
                    $DeploymentTypeCount = ($ApplicationXML.DeploymentTypes | Measure-Object).Count
                    $ValidatedDeploymentTypes = 0
                    foreach ($DeploymentType in $ApplicationXML.DeploymentTypes) {
                        if (Test-Path -Path $DeploymentType.Installer.Contents[0].Location) {
                            $ValidatedDeploymentTypes++
                        }
                    }
                    if ($ValidatedDeploymentTypes -eq $DeploymentTypeCount) {
                        return $true
                    }
                    else {
                        return $false
                    }
                }
                else {
                    return $false
                }
            }
            Default {
                $CMObjectContentPath = (Get-WmiObject -Namespace "root\SMS\site_$($SiteCode)" -Class $SMSClass -ComputerName $SiteServer -Filter "$ObjectIdentifier like '$($InputObject)'").PkgSourcePath
                if (($CMObjectContentPath -ne $null) -and ($CMObjectContentPath -notlike "")) {
                    if (Test-Path -Path $CMObjectContentPath -PathType Any) {
                        return $true
                    }
                    else {
                        return $false
                    }
                }
                else {
                    return $false
                }
            }
        }
    }

    
    try {
        $DPGroupID = Get-WmiObject -Namespace "root\SMS\site_$($SiteCode)" -Class SMS_DPGroupInfo -ComputerName $SiteServer -Filter "Name like '$($DPGroupName)'" -ErrorAction Stop | Select-Object -ExpandProperty GroupID
    }
    catch [System.Exception] {
        Write-Warning -Message "Unable to determine DPGroupID from specified DPGroupName" ; break
        Set-Location -Path $CurrentLocation
    }

    foreach ($CurrentObjectType in $ObjectType) {
        
        if ($PSBoundParameters["ShowProgress"]) {
            $ProgressCount = 0
        }

        
        try {
            if ($DPGroupID -ne $null) {            
                $DPGroupDistributedObjectsList = New-Object -TypeName System.Collections.ArrayList
                $DPGroupObjects = Get-WmiObject -Namespace "root\SMS\site_$($SiteCode)" -Class SMS_DPGroupContentInfo -ComputerName $SiteServer -Filter "GroupID like '$($DPGroupID)' AND  ObjectTypeID = $($ObjectTypeIDTable[$CurrentObjectType])" | Select-Object -ExpandProperty ObjectID
                if ($DPGroupObjects -ne $null) {
                    $DPGroupDistributedObjectsList.AddRange(@($DPGroupObjects)) | Out-Null
                }
                else {
                    Write-Verbose -Message "Specified object type '$($CurrentObjectType)' did not return any results when building distributed list of objects"
                }
            }
        }
        catch [System.Exception] {
            Write-Warning -Message "Unable to build required list of $($CurrentObjectType) objects targeted with Distribution Point Group '$($DPGroupName)'" ; break
            Set-Location -Path $CurrentLocation
        }

        
        try {
            $DistributionObjects = Get-WmiObject -Namespace "root\SMS\site_$($SiteCode)" -Class $SMSClassTable[$CurrentObjectType] -ComputerName $SiteServer -ErrorAction Stop
            if ($DistributionObjects -ne $null) {
                $DistributionObjectCount = ($DistributionObjects | Measure-Object).Count
                switch ($CurrentObjectType) {
                    "Application" { $ObjectIdentifier = "ModelName" ; $ObjectNameProperty = "LocalizedDisplayName" }
                    Default { $ObjectIdentifier = "PackageID" ; $ObjectNameProperty = "Name" }
                }
                foreach ($DistributionObject in $DistributionObjects) {
                    if ($PSBoundParameters["ShowProgress"]) {
                        $ProgressCount++
                        Write-Progress -Activity "Assessing content eligible for distribution by object type: $($CurrentObjectType)" -Id 1 -Status "$($ProgressCount) / $($DistributionObjectCount)" -CurrentOperation "Current object: $($DistributionObject.$ObjectNameProperty)" -PercentComplete (($ProgressCount / $DistributionObjectCount) * 100)
                    }
                    if ($DistributionObject.$ObjectIdentifier -notin $DPGroupDistributedObjectsList) {
                        if ($PSCmdlet.ShouldProcess($DistributionObject.$ObjectNameProperty,"Distribute")) {
                            if ((Invoke-ValidateContentPath -InputObject $DistributionObject.$ObjectIdentifier -ObjectIdentifier $ObjectIdentifier -SMSClass $SMSClassTable[$CurrentObjectType] -ObjectType $CurrentObjectType) -eq $true) {
                                $ContentDistributionParams = @{
                                    DistributionPointGroupName = $DPGroupName
                                    ErrorAction = "Stop"
                                    Verbose = $false
                                }
                                switch ($CurrentObjectType) {
                                    "Package" { 
                                        $ContentDistributionParams.Add("PackageId", $DistributionObject.$ObjectIdentifier) 
                                    }
                                    "OSUpgradePackage" { 
                                        $ContentDistributionParams.Add("OperatingSystemInstallerId", $DistributionObject.$ObjectIdentifier) 
                                    }
                                    "OSImage" { 
                                        $ContentDistributionParams.Add("OperatingSystemImageId", $DistributionObject.$ObjectIdentifier) 
                                    }
                                    "BootImage" { 
                                        $ContentDistributionParams.Add("BootImageId", $DistributionObject.$ObjectIdentifier) 
                                    }
                                    "DriverPackage" { 
                                        $ContentDistributionParams.Add("DriverPackageId", $DistributionObject.$ObjectIdentifier) 
                                    }
                                    "DeploymentPackage" { 
                                        $ContentDistributionParams.Add("DeploymentPackageId", $DistributionObject.$ObjectIdentifier) 
                                    }
                                    "Application" { 
                                        $ContentDistributionParams.Add("ApplicationName", $DistributionObject.$ObjectNameProperty) 
                                    }
                                }
                                Set-Location -Path $SiteDrive -ErrorAction Stop -Verbose:$false
                                Start-CMContentDistribution @ContentDistributionParams | Out-Null
                                Write-Verbose -Message "Successfully distributed '$($DistributionObject.$ObjectNameProperty)' to Distribution Point Group '$($DPGroupName)'"
                                Write-Verbose -Message "Allowing $($DistributionDelaySeconds) seconds for the Distribution Manager to process request"
                                Start-Sleep -Seconds $DistributionDelaySeconds
                                Set-Location -Path $CurrentLocation
                            }
                            else {
                                Write-Warning -Message "Content source path could not be validated, skipping '$($DistributionObject.$ObjectNameProperty)'"
                            }
                        }                        
                    }
                }
            }
            else {
                Write-Warning -Message "Empty array of objects returned when querying for objects in SMS Class '$($SMSClassTable[$CurrentObjectType])'"
            }
        }
        catch [System.Exception] {
            Write-Warning -Message "$($_.Exception.Message). Line: $($_.InvocationInfo.ScriptLineNumber)" ; break
            Set-Location -Path $CurrentLocation
        }
        if ($PSBoundParameters["ShowProgress"]) {
            Write-Progress -Activity "Assessing content distribution for object type: $($CurrentObjectType)" -Id 1 -Completed
        }
    }
}
End {
    Set-Location -Path $CurrentLocation
}