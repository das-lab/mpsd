function Set-InstalledModulesVariable
{
    
    $script:PSGetInstalledModules = [ordered]@{}

    $modulePaths = @($script:ProgramFilesModulesPath, $script:MyDocumentsModulesPath)

    foreach ($location in $modulePaths)
    {
        
        $GetChildItemParams = @{
            Path = $location
            Recurse = $true
            Force = $true
            Filter = $script:PSGetItemInfoFileName
            ErrorAction = 'SilentlyContinue'
            WarningAction = 'SilentlyContinue'
        }

        if($script:IsWindows)
        {
            $GetChildItemParams['Attributes'] = 'Hidden'
        }

        $moduleBases = Get-ChildItem @GetChildItemParams | Foreach-Object { $_.Directory }


        foreach ($moduleBase in $moduleBases)
        {
            $PSGetItemInfoPath = Microsoft.PowerShell.Management\Join-Path $moduleBase.FullName $script:PSGetItemInfoFileName

            
            if (Microsoft.PowerShell.Management\Test-Path $PSGetItemInfoPath)
            {
                $psgetItemInfo = DeSerialize-PSObject -Path $PSGetItemInfoPath

                
                if(-not (Get-Member -InputObject $psgetItemInfo -Name $script:InstalledLocation))
                {
                    Microsoft.PowerShell.Utility\Add-Member -InputObject $psgetItemInfo `
                                                            -MemberType NoteProperty `
                                                            -Name $script:InstalledLocation `
                                                            -Value $moduleBase.FullName
                }

                $package = New-SoftwareIdentityFromPSGetItemInfo -PSGetItemInfo $psgetItemInfo

                if($package)
                {
                    $script:PSGetInstalledModules["$($psgetItemInfo.Name)$($psgetItemInfo.Version)"] = @{
                                                                                                            SoftwareIdentity = $package
                                                                                                            PSGetItemInfo = $psgetItemInfo
                                                                                                        }
                }
            }
        }
    }
}