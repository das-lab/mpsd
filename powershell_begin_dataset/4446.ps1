function Add-PackageSource
{
    [CmdletBinding()]
    param
    (
        [string]
        $Name,

        [string]
        $Location,

        [bool]
        $Trusted
    )

    Write-Debug ($LocalizedData.ProviderApiDebugMessage -f ('Add-PackageSource'))

    if(-not $Name)
    {
        return
    }

    $Credential = $request.Credential

    $IsNewModuleSource = $false
    $Options = $request.Options

    foreach( $o in $Options.Keys )
    {
        Write-Debug ( "OPTION: {0} => {1}" -f ($o, $Options[$o]) )
    }

    $Proxy = $null
    if($Options.ContainsKey($script:Proxy))
    {
        $Proxy = $Options[$script:Proxy]

        if(-not (Test-WebUri -Uri $Proxy))
        {
            $message = $LocalizedData.InvalidWebUri -f ($Proxy, $script:Proxy)
            ThrowError -ExceptionName 'System.ArgumentException' `
                        -ExceptionMessage $message `
                        -ErrorId 'InvalidWebUri' `
                        -CallerPSCmdlet $PSCmdlet `
                        -ErrorCategory InvalidArgument `
                        -ExceptionObject $Proxy
        }
    }

    $ProxyCredential = $null
    if($Options.ContainsKey($script:ProxyCredential))
    {
        $ProxyCredential = $Options[$script:ProxyCredential]
    }

    Set-ModuleSourcesVariable -Force -Proxy $Proxy -ProxyCredential $ProxyCredential

    if($Options.ContainsKey('IsNewModuleSource'))
    {
        $IsNewModuleSource = $Options['IsNewModuleSource']

        if($IsNewModuleSource.GetType().ToString() -eq 'System.String')
        {
            if($IsNewModuleSource -eq 'false')
            {
                $IsNewModuleSource = $false
            }
            elseif($IsNewModuleSource -eq 'true')
            {
                $IsNewModuleSource = $true
            }
        }
    }

    $IsUpdatePackageSource = $false
    if($Options.ContainsKey('IsUpdatePackageSource'))
    {
        $IsUpdatePackageSource = $Options['IsUpdatePackageSource']

        if($IsUpdatePackageSource.GetType().ToString() -eq 'System.String')
        {
            if($IsUpdatePackageSource -eq 'false')
            {
                $IsUpdatePackageSource = $false
            }
            elseif($IsUpdatePackageSource -eq 'true')
            {
                $IsUpdatePackageSource = $true
            }
        }
    }

    $PublishLocation = $null
    if($Options.ContainsKey($script:PublishLocation))
    {
        if($Name -eq $Script:PSGalleryModuleSource)
        {
            $message = $LocalizedData.ParameterIsNotAllowedWithPSGallery -f ('PublishLocation')
            ThrowError -ExceptionName "System.ArgumentException" `
                       -ExceptionMessage $message `
                       -ErrorId 'ParameterIsNotAllowedWithPSGallery' `
                       -CallerPSCmdlet $PSCmdlet `
                       -ErrorCategory InvalidArgument `
                       -ExceptionObject $PublishLocation
        }

        $PublishLocation = $Options[$script:PublishLocation]

        if(-not (Microsoft.PowerShell.Management\Test-Path -LiteralPath $PublishLocation) -and
           -not (Test-WebUri -uri $PublishLocation))
        {
            $PublishLocationUri = [Uri]$PublishLocation
            if($PublishLocationUri.Scheme -eq 'file')
            {
                $message = $LocalizedData.PathNotFound -f ($PublishLocation)
                ThrowError -ExceptionName "System.ArgumentException" `
                           -ExceptionMessage $message `
                           -ErrorId "PathNotFound" `
                           -CallerPSCmdlet $PSCmdlet `
                           -ErrorCategory InvalidArgument `
                           -ExceptionObject $PublishLocation
            }
            else
            {
                $message = $LocalizedData.InvalidWebUri -f ($PublishLocation, "PublishLocation")
                ThrowError -ExceptionName "System.ArgumentException" `
                           -ExceptionMessage $message `
                           -ErrorId "InvalidWebUri" `
                           -CallerPSCmdlet $PSCmdlet `
                           -ErrorCategory InvalidArgument `
                           -ExceptionObject $PublishLocation
            }
        }
    }

    $ScriptSourceLocation = $null
    if($Options.ContainsKey($script:ScriptSourceLocation))
    {
        if($Name -eq $Script:PSGalleryModuleSource)
        {
            $message = $LocalizedData.ParameterIsNotAllowedWithPSGallery -f ('ScriptSourceLocation')
            ThrowError -ExceptionName "System.ArgumentException" `
                       -ExceptionMessage $message `
                       -ErrorId 'ParameterIsNotAllowedWithPSGallery' `
                       -CallerPSCmdlet $PSCmdlet `
                       -ErrorCategory InvalidArgument `
                       -ExceptionObject $ScriptSourceLocation
        }

        $ScriptSourceLocation = $Options[$script:ScriptSourceLocation]

        if(-not (Microsoft.PowerShell.Management\Test-Path -LiteralPath $ScriptSourceLocation) -and
           -not (Test-WebUri -uri $ScriptSourceLocation))
        {
            $ScriptSourceLocationUri = [Uri]$ScriptSourceLocation
            if($ScriptSourceLocationUri.Scheme -eq 'file')
            {
                $message = $LocalizedData.PathNotFound -f ($ScriptSourceLocation)
                ThrowError -ExceptionName "System.ArgumentException" `
                           -ExceptionMessage $message `
                           -ErrorId "PathNotFound" `
                           -CallerPSCmdlet $PSCmdlet `
                           -ErrorCategory InvalidArgument `
                           -ExceptionObject $ScriptSourceLocation
            }
            else
            {
                $message = $LocalizedData.InvalidWebUri -f ($ScriptSourceLocation, "ScriptSourceLocation")
                ThrowError -ExceptionName "System.ArgumentException" `
                           -ExceptionMessage $message `
                           -ErrorId "InvalidWebUri" `
                           -CallerPSCmdlet $PSCmdlet `
                           -ErrorCategory InvalidArgument `
                           -ExceptionObject $ScriptSourceLocation
            }
        }
    }

    $ScriptPublishLocation = $null
    if($Options.ContainsKey($script:ScriptPublishLocation))
    {
        if($Name -eq $Script:PSGalleryModuleSource)
        {
            $message = $LocalizedData.ParameterIsNotAllowedWithPSGallery -f ('ScriptPublishLocation')
            ThrowError -ExceptionName "System.ArgumentException" `
                       -ExceptionMessage $message `
                       -ErrorId 'ParameterIsNotAllowedWithPSGallery' `
                       -CallerPSCmdlet $PSCmdlet `
                       -ErrorCategory InvalidArgument `
                       -ExceptionObject $ScriptPublishLocation
        }

        $ScriptPublishLocation = $Options[$script:ScriptPublishLocation]

        if(-not (Microsoft.PowerShell.Management\Test-Path -LiteralPath $ScriptPublishLocation) -and
           -not (Test-WebUri -uri $ScriptPublishLocation))
        {
            $ScriptPublishLocationUri = [Uri]$ScriptPublishLocation
            if($ScriptPublishLocationUri.Scheme -eq 'file')
            {
                $message = $LocalizedData.PathNotFound -f ($ScriptPublishLocation)
                ThrowError -ExceptionName "System.ArgumentException" `
                           -ExceptionMessage $message `
                           -ErrorId "PathNotFound" `
                           -CallerPSCmdlet $PSCmdlet `
                           -ErrorCategory InvalidArgument `
                           -ExceptionObject $ScriptPublishLocation
            }
            else
            {
                $message = $LocalizedData.InvalidWebUri -f ($ScriptPublishLocation, "ScriptPublishLocation")
                ThrowError -ExceptionName "System.ArgumentException" `
                           -ExceptionMessage $message `
                           -ErrorId "InvalidWebUri" `
                           -CallerPSCmdlet $PSCmdlet `
                           -ErrorCategory InvalidArgument `
                           -ExceptionObject $ScriptPublishLocation
            }
        }
    }

    $currentSourceObject = $null

    
    if($script:PSGetModuleSources.Contains($Name))
    {
        $currentSourceObject = $script:PSGetModuleSources[$Name]
    }

    
    
    
    
    if(($Name -eq $Script:PSGalleryModuleSource) -and
       $Location -and
       ((-not $IsUpdatePackageSource) -or ($currentSourceObject -and $currentSourceObject.SourceLocation -ne $Location)))
    {
        $message = $LocalizedData.ParameterIsNotAllowedWithPSGallery -f ('Location, NewLocation or SourceLocation')
        ThrowError -ExceptionName "System.ArgumentException" `
                   -ExceptionMessage $message `
                   -ErrorId 'ParameterIsNotAllowedWithPSGallery' `
                   -CallerPSCmdlet $PSCmdlet `
                   -ErrorCategory InvalidArgument `
                   -ExceptionObject $Location
    }

    if($Name -eq $Script:PSGalleryModuleSource)
    {
        
        $repository = Set-PSGalleryRepository -Trusted:$Trusted

        if($repository)
        {
            
            Write-Output -InputObject (New-PackageSourceFromModuleSource -ModuleSource $repository)
        }

        return
    }

    if($Location)
    {
        
        $Location = Resolve-Location -Location $Location `
                                     -LocationParameterName 'Location' `
                                     -Credential $Credential `
                                     -Proxy $Proxy `
                                     -ProxyCredential $ProxyCredential `
                                     -CallerPSCmdlet $PSCmdlet
    }

    if(-not $Location)
    {
        
        return
    }

    if(-not (Microsoft.PowerShell.Management\Test-Path -LiteralPath $Location) -and
       -not (Test-WebUri -uri $Location) )
    {
        $LocationUri = [Uri]$Location
        if($LocationUri.Scheme -eq 'file')
        {
            $message = $LocalizedData.PathNotFound -f ($Location)
            ThrowError -ExceptionName "System.ArgumentException" `
                       -ExceptionMessage $message `
                       -ErrorId "PathNotFound" `
                       -CallerPSCmdlet $PSCmdlet `
                       -ErrorCategory InvalidArgument `
                       -ExceptionObject $Location
        }
        else
        {
            $message = $LocalizedData.InvalidWebUri -f ($Location, "Location")
            ThrowError -ExceptionName "System.ArgumentException" `
                       -ExceptionMessage $message `
                       -ErrorId "InvalidWebUri" `
                       -CallerPSCmdlet $PSCmdlet `
                       -ErrorCategory InvalidArgument `
                       -ExceptionObject $Location
        }
    }

    if(Test-WildcardPattern $Name)
    {
        $message = $LocalizedData.RepositoryNameContainsWildCards -f ($Name)
        ThrowError -ExceptionName "System.ArgumentException" `
                    -ExceptionMessage $message `
                    -ErrorId "RepositoryNameContainsWildCards" `
                    -CallerPSCmdlet $PSCmdlet `
                    -ErrorCategory InvalidArgument `
                    -ExceptionObject $Name
    }

    $LocationString = Get-ValidModuleLocation -LocationString $Location -ParameterName "Location" -Proxy $Proxy -ProxyCredential $ProxyCredential -Credential $Credential

    
    $existingSourceName = Get-SourceName -Location $LocationString

    if($existingSourceName -and
       ($Name -ne $existingSourceName) -and
       -not $IsNewModuleSource)
    {
        $message = $LocalizedData.RepositoryAlreadyRegistered -f ($existingSourceName, $Location, $Name)
        ThrowError -ExceptionName "System.ArgumentException" `
                   -ExceptionMessage $message `
                   -ErrorId "RepositoryAlreadyRegistered" `
                   -CallerPSCmdlet $PSCmdlet `
                   -ErrorCategory InvalidArgument
    }

    if(-not $PublishLocation -and $currentSourceObject -and $currentSourceObject.PublishLocation)
    {
        $PublishLocation = $currentSourceObject.PublishLocation
    }

    if((-not $ScriptPublishLocation) -and
       $currentSourceObject -and
       (Get-Member -InputObject $currentSourceObject -Name $script:ScriptPublishLocation) -and
       $currentSourceObject.ScriptPublishLocation)
    {
        $ScriptPublishLocation = $currentSourceObject.ScriptPublishLocation
    }

    if((-not $ScriptSourceLocation) -and
       $currentSourceObject -and
       (Get-Member -InputObject $currentSourceObject -Name $script:ScriptSourceLocation) -and
       $currentSourceObject.ScriptSourceLocation)
    {
        $ScriptSourceLocation = $currentSourceObject.ScriptSourceLocation
    }

    $IsProviderSpecified = $false;
    if ($Options.ContainsKey($script:PackageManagementProviderParam))
    {
        $SpecifiedProviderName = $Options[$script:PackageManagementProviderParam]

        $IsProviderSpecified = $true

        Write-Verbose ($LocalizedData.SpecifiedProviderName -f $SpecifiedProviderName)
        if ($SpecifiedProviderName -eq $script:PSModuleProviderName)
        {
            $message = $LocalizedData.InvalidPackageManagementProviderValue -f ($SpecifiedProviderName, $script:NuGetProviderName, $script:NuGetProviderName)
            ThrowError -ExceptionName "System.ArgumentException" `
                        -ExceptionMessage $message `
                        -ErrorId "InvalidPackageManagementProviderValue" `
                        -CallerPSCmdlet $PSCmdlet `
                        -ErrorCategory InvalidArgument `
                        -ExceptionObject $SpecifiedProviderName
            return
        }
    }
    else
    {
        $SpecifiedProviderName = $script:NuGetProviderName
        Write-Verbose ($LocalizedData.ProviderNameNotSpecified -f $SpecifiedProviderName)
    }

    $packageSource = $null

    $selProviders = $request.SelectProvider($SpecifiedProviderName)

    if(-not $selProviders -and $IsProviderSpecified)
    {
        $message = $LocalizedData.SpecifiedProviderNotAvailable -f $SpecifiedProviderName
        ThrowError -ExceptionName "System.InvalidOperationException" `
                    -ExceptionMessage $message `
                    -ErrorId "SpecifiedProviderNotAvailable" `
                    -CallerPSCmdlet $PSCmdlet `
                    -ErrorCategory InvalidOperation `
                    -ExceptionObject $SpecifiedProviderName
    }

    
    foreach($SelectedProvider in $selProviders)
    {
        if($request.IsCanceled)
        {
            return
        }

        if($SelectedProvider -and $SelectedProvider.Features.ContainsKey($script:SupportsPSModulesFeatureName))
        {
            $NewRequest = $request.CloneRequest( $null, @($LocationString), $request.Credential )
            $packageSource = $SelectedProvider.ResolvePackageSources( $NewRequest )
        }
        else
        {
            $message = $LocalizedData.SpecifiedProviderDoesnotSupportPSModules -f $SelectedProvider.ProviderName
            ThrowError -ExceptionName "System.InvalidOperationException" `
                        -ExceptionMessage $message `
                        -ErrorId "SpecifiedProviderDoesnotSupportPSModules" `
                        -CallerPSCmdlet $PSCmdlet `
                        -ErrorCategory InvalidOperation `
                        -ExceptionObject $SelectedProvider.ProviderName
        }

        if($packageSource)
        {
            break
        }
    }

    
    if(-not $packageSource -and -not $IsProviderSpecified)
    {
        Write-Verbose ($LocalizedData.PollingPackageManagementProvidersForLocation -f $LocationString)

        $moduleProviders = $request.SelectProvidersWithFeature($script:SupportsPSModulesFeatureName)

        foreach($provider in $moduleProviders)
        {
            if($request.IsCanceled)
            {
                return
            }

            
            if($provider.ProviderName -eq $SpecifiedProviderName -or
               $provider.ProviderName -eq $script:PSModuleProviderName)
            {
                continue
            }

            Write-Verbose ($LocalizedData.PollingSingleProviderForLocation -f ($LocationString, $provider.ProviderName))
            $NewRequest = $request.CloneRequest( @{}, @($LocationString), $request.Credential )
            $packageSource = $provider.ResolvePackageSources($NewRequest)

            if($packageSource)
            {
                Write-Verbose ($LocalizedData.FoundProviderForLocation -f ($provider.ProviderName, $Location))
                $SelectedProvider = $provider
                break
            }
        }
    }

    if(-not $packageSource)
    {
        $message = $LocalizedData.SpecifiedLocationCannotBeRegistered -f $Location
        ThrowError -ExceptionName "System.InvalidOperationException" `
                    -ExceptionMessage $message `
                    -ErrorId "SpecifiedLocationCannotBeRegistered" `
                    -CallerPSCmdlet $PSCmdlet `
                    -ErrorCategory InvalidOperation `
                    -ExceptionObject $Location
    }

    $ProviderOptions = @{}

    $SelectedProvider.DynamicOptions | Microsoft.PowerShell.Core\ForEach-Object {
                                            if($options.ContainsKey($_.Name) )
                                            {
                                                $ProviderOptions[$_.Name] = $options[$_.Name]
                                            }
                                       }

    
    if($currentSourceObject)
    {
        $currentSourceObject.ProviderOptions.GetEnumerator() | Microsoft.PowerShell.Core\ForEach-Object {
                                                                   if (-not $ProviderOptions.ContainsKey($_.Key) )
                                                                   {
                                                                       $ProviderOptions[$_.Key] = $_.Value
                                                                   }
                                                               }
    }

    if(-not $PublishLocation)
    {
        $PublishLocation = Get-PublishLocation -Location $LocationString
    }

    
    if(-not $ScriptPublishLocation)
    {
        $ScriptPublishLocation = $PublishLocation

        
        if($Options.ContainsKey($script:ScriptPublishLocation) -and
           (Microsoft.PowerShell.Management\Test-Path -LiteralPath $ScriptPublishLocation))
        {
            if($ScriptPublishLocation -ne $PublishLocation)
            {
                $message = $LocalizedData.PublishLocationPathsForModulesAndScriptsShouldBeEqual -f ($LocationString, $ScriptSourceLocation)
                ThrowError -ExceptionName "System.InvalidOperationException" `
                            -ExceptionMessage $message `
                            -ErrorId "PublishLocationPathsForModulesAndScriptsShouldBeEqual" `
                            -CallerPSCmdlet $PSCmdlet `
                            -ErrorCategory InvalidOperation `
                            -ExceptionObject $Location
            }
        }
    }

    if(-not $ScriptSourceLocation)
    {
        $ScriptSourceLocation = Get-ScriptSourceLocation -Location $LocationString -Proxy $Proxy -ProxyCredential $ProxyCredential -Credential $Credential
    }
    elseif($Options.ContainsKey($script:ScriptSourceLocation))
    {
        
        if(Microsoft.PowerShell.Management\Test-Path -LiteralPath $ScriptSourceLocation)
        {
            if($ScriptSourceLocation -ne $LocationString)
            {
                $message = $LocalizedData.SourceLocationPathsForModulesAndScriptsShouldBeEqual -f ($LocationString, $ScriptSourceLocation)
                ThrowError -ExceptionName "System.InvalidOperationException" `
                            -ExceptionMessage $message `
                            -ErrorId "SourceLocationPathsForModulesAndScriptsShouldBeEqual" `
                            -CallerPSCmdlet $PSCmdlet `
                            -ErrorCategory InvalidOperation `
                            -ExceptionObject $Location
            }
        }
    }

    
    if($script:PSGetModuleSources.Contains($Name))
    {
        $null = $script:PSGetModuleSources.Remove($Name)
    }

    
    $moduleSource = Microsoft.PowerShell.Utility\New-Object PSCustomObject -Property ([ordered]@{
            Name = $Name
            SourceLocation = $LocationString
            PublishLocation = $PublishLocation
            ScriptSourceLocation = $ScriptSourceLocation
            ScriptPublishLocation = $ScriptPublishLocation
            Trusted=$Trusted
            Registered= (-not $IsNewModuleSource)
            InstallationPolicy = if($Trusted) {'Trusted'} else {'Untrusted'}
            PackageManagementProvider = $SelectedProvider.ProviderName
            ProviderOptions = $ProviderOptions
        })

    
    if ($script:TelemetryEnabled)
    {

        Log-NonPSGalleryRegistration -sourceLocation $moduleSource.SourceLocation `
                                     -installationPolicy $moduleSource.InstallationPolicy `
                                     -packageManagementProvider $moduleSource.PackageManagementProvider `
                                     -publishLocation $moduleSource.PublishLocation `
                                     -scriptSourceLocation $moduleSource.ScriptSourceLocation `
                                     -scriptPublishLocation $moduleSource.ScriptPublishLocation `
                                     -operationName PSGET_NONPSGALLERY_REGISTRATION `
                                     -ErrorAction SilentlyContinue `
                                     -WarningAction SilentlyContinue

    }
    

    $moduleSource.PSTypeNames.Insert(0, "Microsoft.PowerShell.Commands.PSRepository")

    
    if(-not $IsNewModuleSource)
    {
        $script:PSGetModuleSources.Add($Name, $moduleSource)

        $message = $LocalizedData.RepositoryRegistered -f ($Name, $LocationString)
        Write-Verbose $message

        
        Save-ModuleSources
    }

    
    Write-Output -InputObject (New-PackageSourceFromModuleSource -ModuleSource $moduleSource)
}
