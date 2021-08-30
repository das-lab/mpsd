
[CmdletBinding(SupportsShouldProcess=$true)]
param(
    [parameter(Mandatory=$true, HelpMessage="Site server name with SMS Provider installed")]
    [string]$SiteServer,
    [parameter(Mandatory=$true, HelpMessage="Path to where the Driver Source root directory is located")]
    [ValidatePattern("^\\\\\w+\\\w+")]
    [ValidateScript({Test-Path -Path $_ -PathType Container})]
    [string]$DriverSourcePath,
    [parameter(Mandatory=$true, HelpMessage="Path to where the Driver Package root directory is located")]
    [ValidatePattern("^\\\\\w+\\\w+")]
    [ValidateScript({Test-Path -Path $_ -PathType Container})]
    [string]$DriverPackagePath,
    [parameter(Mandatory=$true, HelpMessage="Specify the name of the Distribution Point Group that new Driver Packages will be distributed to")]
    [string]$DPGroupName,
    [parameter(Mandatory=$false, HelpMessage="Specify an Operating System folder to be skipped when importing drivers")]
    [string[]]$SkipOS,
    [parameter(Mandatory=$false, HelpMessage="Only validate the driver folder structure")]
    [switch]$Validate,
    [parameter(Mandatory=$false, HelpMessage="Show a progressbar displaying the current operation")]
    [switch]$ShowProgress
)
Begin {
    
    $CurrentLocation = Get-Location
    
    try {
        Write-Verbose "Determining SiteCode for Site Server: '$($SiteServer)'"
        $SiteCodeObjects = Get-WmiObject -Namespace "root\SMS" -Class SMS_ProviderLocation -ComputerName $SiteServer -ErrorAction Stop
        foreach ($SiteCodeObject in $SiteCodeObjects) {
            if ($SiteCodeObject.ProviderForLocalSite -eq $true) {
                $SiteCode = $SiteCodeObject.SiteCode
                Write-Debug "SiteCode: $($SiteCode)"
            }
        }
    }
    catch [Exception] {
        Throw "Unable to determine SiteCode"
    }
    
    try {
        $SiteDrive = $SiteCode + ":"
        Import-Module (Join-Path -Path (($env:SMS_ADMIN_UI_PATH).Substring(0,$env:SMS_ADMIN_UI_PATH.Length-5)) -ChildPath "\ConfigurationManager.psd1") -Force -Verbose:$false
        if ((Get-PSDrive $SiteCode -ErrorAction SilentlyContinue | Measure-Object).Count -ne 1) {
            New-PSDrive -Name $SiteCode -PSProvider "AdminUI.PS.Provider\CMSite" -Root $SiteServer
        }
    }
    catch [Exception] {
        Throw "Unable to determine SiteCode"
    }
    if ($PSBoundParameters["ShowProgress"]) {
        $CurrentDriverCount = 0
    }
}
Process {
    function Validate-FolderItem {
        param(
            [parameter(Mandatory=$true)]
            $FolderItem,
            [parameter(Mandatory=$true)]
            [ValidateSet("OS","Make","Model")]
            [string]$Type
        )
        if (-not((Get-ChildItem -Path $FolderItem.FullName) -eq $null)) {
            foreach ($SubItem in (Get-ChildItem -Path $FolderItem.FullName)) {
                if (($Type -like "OS") -or ($Type -like "Make")) {
                    
                    if (-not((Get-Item -Path $SubItem.FullName).Attributes -like "Directory")) {
                        Write-Warning -Message "Unsupported files found in '$($SubItem.FullName)'"
                        $Script:ValidationResult = $false
                    }
                }
                else {
                    if ((Get-ChildItem -Path $SubItem.FullName -Recurse -Include *.inf, *.exe, *.zip) -eq $null) {
                        Write-Warning -Message "Supported driver files was not found in '$($SubItem.FullName)'"
                        $Script:ValidationResult = $false
                    }
                }
            }
        }
        else {
            switch ($Type) {
                "Model" { Write-Warning -Message "Unable to validate $($Type) folder: $($FolderItem.Parent.Parent.Name)\$($FolderItem.Parent.Name)\$($FolderItem.Name). Folder is empty" }
                "Make" { Write-Warning -Message "Unable to validate $($Type) folder: $($FolderItem.Parent.Name)\$($FolderItem.Name). Folder is empty" }
                "OS" { Write-Warning -Message "Unable to validate $($Type) folder: $($FolderItem.Name). Folder is empty" }
            }
            $Script:ValidationResult = $false
        }
    }
    
    $ValidOSList = New-Object -TypeName System.Collections.ArrayList
    $OSFolders = Get-ChildItem -Path $DriverSourcePath | Select-Object Name, FullName, CreationTime
    Write-Verbose -Message "Starting validation of OS and Make folders"
    foreach ($OSFolder in $OSFolders) {
        $ValidationResult = $true
        $CurrentOSFolder = Get-Item -Path $OSFolder.FullName
        if ($CurrentOSFolder.Attributes -like "Directory") {
            Write-Verbose -Message "OS folder: $($CurrentOSFolder.Name)"
            
            Validate-FolderItem -FolderItem $CurrentOSFolder -Type OS
        }
        foreach ($MakeFolder in (Get-ChildItem -Path $CurrentOSFolder)) {
            $CurrentMakeFolder = Get-Item -Path $MakeFolder.FullName
            if ($CurrentMakeFolder.Attributes -like "Directory") {
                Write-Verbose -Message "Make folder: $($CurrentMakeFolder.Name)"
                
                Validate-FolderItem -FolderItem $MakeFolder -Type Make
            }
            foreach ($ModelFolder in (Get-ChildItem -Path $CurrentMakeFolder)) {
                $CurrentModelFolder = Get-Item -Path $ModelFolder.FullName
                if ($CurrentModelFolder.Attributes -like "Directory") {
                    Write-Verbose -Message "Model folder: $($CurrentModelFolder.Name)"
                    
                    Validate-FolderItem -FolderItem $ModelFolder -Type Model
                }
            }
        }
        if ($ValidationResult -ne $false) {
            if ($PSBoundParameters["SkipOS"]) {
                foreach ($SkipOSItem in $SkipOS) {
                    if ($SkipOSItem -like $CurrentOSFolder.Name) {
                        Write-Verbose -Message "Skipping OS folder: $($CurrentOSFolder.Name)" 
                    }
                    else {
                        $ValidOSList.Add($CurrentOSFolder.FullName) | Out-Null
                    }
                }
            }
            else {
                $ValidOSList.Add($CurrentOSFolder.FullName) | Out-Null
            }
        }
    }
    Write-Verbose -Message "Successfully completed validating OS, Make and Model folders"
    if ($PSBoundParameters["Validate"]) {
        foreach ($ValidOS in $ValidOSList) {
            $PSObject = [PSCustomObject]@{
                OperatingSystem = (Get-Item -Path $ValidOS | Select-Object -ExpandProperty Name)
                Validated = $true
            }
            Write-Output $PSObject
        }
    }
    if (-not($PSBoundParameters["Validate"])) {
        
        Write-Verbose -Message "Starting to process objects"
        
        foreach ($OS in $ValidOSList) {
            $CurrentOSName = Get-Item -Path $OS | Select-Object -ExpandProperty Name
            $CurrentOSPath = $OS
            $MakeObjects = Get-ChildItem -Path $CurrentOSPath | Select-Object -Property Name, FullName
            Write-Verbose -Message "Operating System: $($CurrentOSName)"
            Write-Verbose -Message "Path: $($OS)"
            Set-Location $SiteDrive -Verbose:$false
            
            if ((Get-CMCategory -CategoryType DriverCategories -Name $CurrentOSName -Verbose:$false) -eq $null) {
                Write-Verbose -Message "Creating new Driver Category: $($CurrentOSName)"
                New-CMCategory -CategoryType DriverCategories -Name $CurrentOSName | Out-Null
            }
            Set-Location $CurrentLocation -Verbose:$false
            
            foreach ($Make in $MakeObjects) {
                $CurrentMakeName = $Make.Name
                $CurrentMakePath = $Make.FullName
                $ModelObjects = Get-ChildItem -Path $CurrentMakePath | Select-Object -Property Name, FullName
                Write-Verbose -Message "-- Make: $($CurrentMakeName)"
                Write-Verbose -Message "-- Path: $($CurrentMakePath)"
                Set-Location $SiteDrive -Verbose:$false
                
                if ((Get-CMCategory -CategoryType DriverCategories -Name $CurrentMakeName -Verbose:$false) -eq $null) {
                    Write-Verbose -Message "---- Creating new Driver Category: $($CurrentMakeName)"
                    New-CMCategory -CategoryType DriverCategories -Name $CurrentMakeName -Verbose:$false | Out-Null
                }
                Set-Location $CurrentLocation -Verbose:$false
                
                foreach ($Model in $ModelObjects) {
                    $CurrentModelName = $Model.Name
                    $CurrentModelPath = $Model.FullName
                    Write-Verbose -Message "---- Model: $($CurrentModelName)"
                    Write-Verbose -Message "---- Path: $($CurrentModelPath)"
                    $DriverINFs = Get-ChildItem -Path $CurrentModelPath -Recurse -Include *.inf
                    Write-Verbose -Message "------ Drivers: $(($DriverINFs | Measure-Object).Count)"
                    Set-Location $SiteDrive -Verbose:$false
                    
                    if ((Get-CMCategory -CategoryType DriverCategories -Name $CurrentModelName -Verbose:$false) -eq $null) {
                        Write-Verbose -Message "------ Creating new Driver Category: $($CurrentModelName)"
                        New-CMCategory -CategoryType DriverCategories -Name $CurrentModelName -Verbose:$false | Out-Null
                    }
                    
                    $CurrentDriverPackageName = "$($CurrentMakeName) - $($CurrentModelName) - $($CurrentOSName)"
                    if ((Get-CMDriverPackage -Name $CurrentDriverPackageName -Verbose:$false) -eq $null) {
                        if ($DriverPackagePath.EndsWith("\")) {
                            $NewDriverPackagePath = "$($DriverPackagePath)$($CurrentOSName)\$($CurrentMakeName)\$($CurrentModelName)"
                        }
                        else {
                            $NewDriverPackagePath = "$($DriverPackagePath)\$($CurrentOSName)\$($CurrentMakeName)\$($CurrentModelName)"
                        }
                        Write-Verbose -Message "------ Creating new Driver Package: $($CurrentDriverPackageName)"
                        New-CMDriverPackage -Name $CurrentDriverPackageName -Path $NewDriverPackagePath -Verbose:$false | Out-Null
                        Start-CMContentDistribution -DriverPackageName $CurrentDriverPackageName -DistributionPointGroupName $DPGroupName -Verbose:$false | Out-Null
                    }
                    $CurrentDriverPackage = Get-CMDriverPackage -Name "$($CurrentDriverPackageName)" -Verbose:$false
                    if (($CurrentDriverPackage | Measure-Object).Count -ge 1) {
                        Write-Verbose -Message "------ Current Driver Package: $($CurrentDriverPackage.Name)"
                    }
                    
                    $DriverCategoryArray = @()
                    $DriverCategoryArray += (Get-CMCategory -CategoryType DriverCategories -Name $CurrentOSName -Verbose:$false)
                    $DriverCategoryArray += (Get-CMCategory -CategoryType DriverCategories -Name $CurrentMakeName -Verbose:$false)
                    $DriverCategoryArray += (Get-CMCategory -CategoryType DriverCategories -Name $CurrentModelName -Verbose:$false)
                    foreach ($Category in $DriverCategoryArray) {
                        Write-Verbose -Message "------ Categories: $($Category.LocalizedCategoryInstanceName)"
                    }
                    
                    $DriverCount = ($DriverINFs | Measure-Object).Count
                    foreach ($DriverINF in $DriverINFs) {
                        $CurrentDriverCount++
                        if ($PSBoundParameters["ShowProgress"]) {
                            $ProgressArguments = @{
                                Id = 1
                                Activity = "Importing Drivers"
                                Status = "Processing driver $($CurrentDriverCount) of $($DriverCount)"
                                CurrentOperation = "Current model: $($CurrentModelName)"
                                PercentComplete = (($CurrentDriverCount / $DriverCount) * 100)
                            }
                            Write-Progress $ProgressArguments
                        }
                        try {
                            $DriverArguments = @{
                                UncFileLocation = $DriverINF.FullName
                                DriverPackage = $CurrentDriverPackage
                                EnableAndAllowInstall = $true
                                AdministrativeCategory = $DriverCategoryArray
                                ImportDuplicateDriverOption = "AppendCategory"
                                ErrorAction = "SilentlyContinue"
                                Verbose = $false
                            }
                            Write-Verbose -Message "Attempting to import driver: $($DriverINF.FullName)"
                            Import-CMDriver @DriverArguments | Out-Null
                        }
                        catch {
                            Write-Warning -Message "Failed to import: $($DriverINF.FullName)"
                        }
                    }
                    if ($PSBoundParameters["ShowProgress"]) {
                        Write-Progress -Id 1 -Activity "Importing Drivers" -Completed
                    }
                    Update-CMDistributionPoint -DriverPackageName $CurrentDriverPackageName -Verbose:$false
                    Set-Location $CurrentLocation -Verbose:$false
                }
            }
        }
    }
}