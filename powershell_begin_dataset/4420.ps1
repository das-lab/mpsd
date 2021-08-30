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
