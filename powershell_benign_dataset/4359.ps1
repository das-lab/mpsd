function Set-InstalledScriptsVariable
{
    
    $script:PSGetInstalledScripts = [ordered]@{}
    $scriptPaths = @($script:ProgramFilesInstalledScriptInfosPath, $script:MyDocumentsInstalledScriptInfosPath)

    foreach ($location in $scriptPaths)
    {
        
        $scriptInfoFiles = Get-ChildItem -Path $location `
                                         -Filter "*$script:InstalledScriptInfoFileName" `
                                         -ErrorAction SilentlyContinue `
                                         -WarningAction SilentlyContinue

        if($scriptInfoFiles)
        {
            foreach ($scriptInfoFile in $scriptInfoFiles)
            {
                $psgetItemInfo = DeSerialize-PSObject -Path $scriptInfoFile.FullName

                $scriptFilePath = Microsoft.PowerShell.Management\Join-Path -Path $psgetItemInfo.InstalledLocation `
                                                                            -ChildPath "$($psgetItemInfo.Name).ps1"

                
                if(-not (Microsoft.PowerShell.Management\Test-Path -Path $scriptFilePath -PathType Leaf))
                {
                    Microsoft.PowerShell.Management\Remove-Item -Path $scriptInfoFile.FullName -Force -ErrorAction SilentlyContinue

                    continue
                }

                $package = New-SoftwareIdentityFromPSGetItemInfo -PSGetItemInfo $psgetItemInfo

                if($package)
                {
                    $script:PSGetInstalledScripts["$($psgetItemInfo.Name)$($psgetItemInfo.Version)"] = @{
                                                                                                            SoftwareIdentity = $package
                                                                                                            PSGetItemInfo = $psgetItemInfo
                                                                                                        }
                }
            }
        }
    }
}