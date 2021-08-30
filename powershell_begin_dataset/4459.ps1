






Install-PSResource 'TestModule'


Install-PSResource -name 'TestModule'


Install-PSResource 'TestModule1', 'TestModule2', 'TestModule3'


Install-PSResource 'TestModule' -MinimumVersion '1.5.0'


Install-PSResource 'TestModule' -MaximumVersion '1.5.0'


Install-PSResource 'TestModule' -MinimumVersion '1.0.0' -MaximumVersion '2.0.0'


Install-PSResource 'TestModule' -RequiredVersion '1.5.0'


Install-PSResource 'TestModule' -Prerelease


Install-PSResource 'TestModule' -Repository 'Repository1', 'Repository2'


Install-PSResource -RequiredResources @{
    'Configuration' = '[1.3.1,2.0)'
    'Pester'        = @{
        version    = '[4.4.2,4.7.0]'
        repository = 'https://www.powershellgallery.com'
    }
}


Install-PSResource -RequiredResources ConvertTo-Json (
    @{
        'Configuration' = '[1.3.1,2.0)'
        'Pester'        = @{
            version    = '[4.4.2,4.7.0]'
            repository = 'https://www.powershellgallery.com'
        }
    }
)


Install-PSResource -RequiredResourcesFile 'RequiredResource.psd1'


Install-PSResource -RequiredResourcesFile 'RequiredResource.json'


Install-PSResource 'TestModule' -Scope 'CurrentUser'


Install-PSResource 'TestModule' -Scope 'AllUsers'


Install-PSResource 'TestModule' -NoClobber


Install-PSResource 'TestModule' -IgnoreDifferentPublisher


Install-PSResource 'TestModule' -TrustRepository


Install-PSResource 'TestModule' -Force


Install-PSResource 'TestModule' -Reinstall


Install-PSResource 'TestModule' -Quiet


Install-PSResource 'TestModule' -AcceptLicense


Install-PSResource 'TestModule' -PassThru






Install-PSResource 'TestScript'


Install-PSResource -name 'TestScript'


Install-PSResource 'TestScript1', 'TestScript2', 'TestScript3'


Install-PSResource 'TestScript' -MinimumVersion '1.5.0'


Install-PSResource 'TestScript' -MaximumVersion '1.5.0'


Install-PSResource 'TestScript' -MinimumVersion '1.0.0' -MaximumVersion '2.0.0'


Install-PSResource 'TestScript' -RequiredVersion '1.5.0'


Install-PSResource 'TestScript' -Prerelease


Install-PSResource 'TestScript' -Repository 'Repository1', 'Repository2'


Install-PSResource -RequiredResources @{
    'Configuration' = '[1.3.1,2.0)'
    'TestScript'    = @{
        version    = '[4.4.2,4.7.0]'
        repository = 'https://www.powershellgallery.com'
    }
}


Install-PSResource -RequiredResources ConvertTo-Json (
    @{
        'Configuration' = '[1.3.1,2.0)'
        'TestScript'    = @{
            version    = '[4.4.2,4.7.0]'
            repository = 'https://www.powershellgallery.com'
        }
    }
)


Install-PSResource -RequiredResourcesFile 'RequiredResource.psd1'


Install-PSResource -RequiredResourcesFile 'RequiredResource.json'


Install-PSResource 'TestScript' -Scope 'CurrentUser'


Install-PSResource 'TestScript' -Scope 'AllUsers'


Install-PSResource 'TestModule' -NoClobber


Install-PSResource 'TestScript' -IgnoreDifferentPublisher


Install-PSResource 'TestScript' -TrustRepository


Install-PSResource 'TestScript' -Force


Install-PSResource 'TestScript' -Reinstall


Install-PSResource 'TestScript' -Quiet


Install-PSResource 'TestScript' -AcceptLicense


Install-PSResource 'TestScript' -PassThru
