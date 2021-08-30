
[CmdletBinding(SupportsShouldProcess=$true)]
param(
    [parameter(Mandatory=$true, ParameterSetName="ConfigMgr", HelpMessage="Site server where the SMS Provider is installed")]
    [parameter(ParameterSetName="WIM")]
    [ValidateNotNullOrEmpty()]
    [ValidateScript({Test-Connection -ComputerName $_ -Count 1 -Quiet})]
    [string]$SiteServer,
    [parameter(Mandatory=$true, ParameterSetName="ConfigMgr", HelpMessage="Specify the Boot Image name as a string or an array of strings")]
    [ValidateNotNullOrEmpty()]
    [string[]]$BootImageName,
    [parameter(Mandatory=$true, ParameterSetName="WIM", HelpMessage="Specify the path to a WIM file")]
    [ValidatePattern("^[A-Za-z]{1}:\\\w+\\\w+")]
    [ValidateScript({
        
        if ((Split-Path -Path $_ -Leaf).IndexOfAny([IO.Path]::GetInvalidFileNameChars()) -ge 0) {
            Write-Warning -Message "$(Split-Path -Path $_ -Leaf) contains invalid characters" ; break
        }
        else {
            
            if ([System.IO.Path]::GetExtension((Split-Path -Path $_ -Leaf)) -like ".wim") {
                
                if (-not(Test-Path -Path (Split-Path -Path $_) -PathType Container -ErrorAction SilentlyContinue)) {
                    if ($PSBoundParameters["Force"]) {
                        New-Item -Path (Split-Path -Path $_) -ItemType Directory | Out-Null
                        return $true
                    }
                    else {
                        Write-Warning -Message "Unable to locate part of the specified path" ; break
                    }
                }
                elseif (Test-Path -Path (Split-Path -Path $_) -PathType Container -ErrorAction SilentlyContinue) {
                    return $true
                }
                else {
                    Write-Warning -Message "Unhandled error" ; break
                }
            }
            else {
                Write-Warning -Message "$(Split-Path -Path $_ -Leaf) contains unsupported file extension. Supported extension is '.wim'" ; break
            }
        }
    })]
    [ValidateNotNullOrEmpty()]
    [string]$WimFile,
    [parameter(Mandatory=$true, ParameterSetName="ConfigMgr", HelpMessage="Default path to where the script will temporarly mount the Boot Image")]
    [parameter(ParameterSetName="WIM")]
    [ValidateNotNullOrEmpty()]
    [ValidatePattern("^[A-Za-z]{1}:\\\w+")]
    [string]$MountPath,
    [parameter(Mandatory=$false, ParameterSetName="ConfigMgr", HelpMessage="When specified all drivers will be listed, including default Microsoft drivers")]
    [parameter(ParameterSetName="WIM")]
    [switch]$All,
    [parameter(Mandatory=$false, ParameterSetName="ConfigMgr", HelpMessage="Show a progressbar displaying the current operation")]
    [parameter(ParameterSetName="WIM")]
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
    catch [System.Exception] {
        Write-Warning -Message "Unable to determine SiteCode" ; break
    }
    
    if (-not(Get-Module -Name Dism)) {
        try {
            Import-Module -Name Dism -ErrorAction Stop -Verbose:$false
        }
        catch [System.Exception] {
            Write-Warning -Message "Unable to load the Dism PowerShell module" ; break
        }
    }
    
    if (-not(Test-Path -Path $MountPath -PathType Container -ErrorAction SilentlyContinue -Verbose:$false)) {
        New-Item -Path $MountPath -ItemType Directory -Force -Verbose:$false | Out-Null
    }
}
Process {
    
    function Get-BootImageDrivers {
        [CmdletBinding(SupportsShouldProcess=$true)]
        param(
            [parameter(Mandatory=$true)]
            $BootImage
        )
        
        $WindowsDriverArguments = @{
            Path = $MountPath
            ErrorAction = "Stop"
            Verbose = $false
        }
        if ($Script:PSBoundParameters["All"]) {
            $WindowsDriverArguments.Add("All", $true)
        }
        if ($Script:PSCmdlet.ShouldProcess($MountPath, "ListDrivers")) {
            $Drivers = Get-WindowsDriver @WindowsDriverArguments
            if ($Drivers -ne $null) {
                $DriverCount = ($Drivers | Measure-Object).Count
                foreach ($Driver in $Drivers) {
                    if ($Script:PSBoundParameters["ShowProgress"]) {
                        $ProgressCount++
                        Write-Progress -Activity "Enumerating drivers in '$($BootImage)'" -Id 1 -Status "Processing $($ProgressCount) / $($DriverCount)" -PercentComplete (($ProgressCount / $DriverCount) * 100)
                    }
                    $PSObject = [PSCustomObject]@{
                        Driver = $Driver.Driver
                        Version = $Driver.Version
                        Manufacturer = $Driver.ProviderName
                        ClassName = $Driver.ClassName
                        Date = $Driver.Date
                        BootImageName = $BootImage.Name
                    }
                    Write-Output -InputObject $PSObject
                }
                if ($Script:PSBoundParameters["ShowProgress"]) {
                    Write-Progress -Activity "Enumerating drivers in '$($BootImage)'" -Id 1 -Completed
                }
            }
            else {
                Write-Warning -Message "No drivers was found"
            }
        }
    }
    
    if ($PSBoundParameters["ShowProgress"]) {
        $ProgressCount = 0
    }
    
    if ($PSBoundParameters["BootImageName"]) {
        foreach ($BootImageItem in $BootImageName) {
            try {
                Write-Verbose -Message "Querying for boot image: $($BootImageItem)"
                $BootImage = Get-WmiObject -Namespace "root\SMS\site_$($SiteCode)" -Class SMS_BootImagePackage -ComputerName $SiteServer -Filter "Name like '$($BootImageItem)'" -ErrorAction Stop
                if ($BootImage -ne $null) {
                    $BootImagePath = $BootImage.PkgSourcePath
                    Write-Verbose -Message "Located boot image wim file: $($BootImagePath)"
                    
                    if ($PSCmdlet.ShouldProcess($BootImagePath, "Mount")) {
                        Mount-WindowsImage -ImagePath $BootImagePath -Path $MountPath -Index 1 -ErrorAction Stop -Verbose:$false | Out-Null
                    }
                    
                    Get-BootImageDrivers -BootImage $BootImage.Name
                }
                else {
                    Write-Warning -Message "Unable to locate a boot image called '$($BootImageName)'"
                }
            }
            catch [System.UnauthorizedAccessException] {
                Write-Warning -Message "Access denied" ; break
            }
            catch [System.Exception] {
                Write-Warning -Message $_.Exception.Message ; break
            }
            
            if ($PSCmdlet.ShouldProcess($BootImagePath, "Dismount")) {
                Dismount-WindowsImage -Path $MountPath -Discard -ErrorAction Stop -Verbose:$false | Out-Null
            }
        }
    }
    
    if ($PSBoundParameters["WimFile"]) {
        
        try {
            if ($PSCmdlet.ShouldProcess($WimFile, "Mount")) {
                Mount-WindowsImage -ImagePath $WimFile -Path $MountPath -Index 1 -ErrorAction Stop -Verbose:$false | Out-Null
            }
            
            Get-BootImageDrivers -BootImage (Split-Path -Path $WimFile -Leaf)
        }
        catch [System.UnauthorizedAccessException] {
            Write-Warning -Message "Access denied" ; break
        }
        catch [System.Exception] {
            Write-Warning -Message $_.Exception.Message ; break
        }
        
        if ($PSCmdlet.ShouldProcess($WimFile, "Dismount")) {
            Dismount-WindowsImage -Path $MountPath -Discard -ErrorAction Stop -Verbose:$false | Out-Null
        }
    }
}
End {
    
    try {
        Remove-Item -Path $MountPath -Force -ErrorAction Stop -Verbose:$false
    }
    catch [System.UnauthorizedAccessException] {
        Write-Warning -Message "Access denied"
    }
    catch [System.Exception] {
        Write-Warning -Message $_.Exception.Message
    }
}