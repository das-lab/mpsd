





Find-PSResource -name 'TestCommand'


Find-PSResource 'TestCommand'


Find-PSResource 'TestCommand' -Type 'Command'


Find-PSResource 'TestCommand' -Type 'Command', 'DscResource', 'RoleCapability', 'Module', 'Script'


Find-PSResource 'TestCommand' -ModuleName 'TestCommandModuleName'


Find-PSResource 'TestCommand' -ModuleName 'TestCommandModuleName' -MinimumVersion '1.5.0'


Find-PSResource 'TestCommand' -ModuleName 'TestCommandModuleName' -MaximumVersion '1.5.0'


Find-PSResource 'TestCommand' -ModuleName 'TestCommandModuleName' -MinimumVersion '1.0.0' -MaximumVersion '2.0.0'


Find-PSResource 'TestCommand' -ModuleName 'TestCommandModuleName' -RequiredVersion '1.5.0'


Find-PSResource 'TestCommand' -ModuleName 'TestCommandModuleName' -AllVersions


Find-PSResource 'TestCommand' -ModuleName 'TestCommandModuleName' -Prerelease


Find-PSResource 'TestCommand' -Tag 'Tag1', 'Tag2', 'Tag3'


Find-PSResource 'TestCommand' -Filter 'Test'


Find-PSResource 'TestCommand' -Repository 'Repository1', 'Repository2'


Find-PSResource 'TestCommand' -Type 'TestDscResource'





Find-PSResource -name 'TestDscResource'


Find-PSResource 'TestDscResource'


Find-PSResource 'TestDscResource' -Type 'DscResource'


Find-PSResource 'TestDscResource' -Type 'Command', 'DscResource', 'RoleCapability', 'Module', 'Script'


Find-PSResource  'TestDscResource' -ModuleName 'TestDscResourceModuleName'


Find-PSResource 'TestDscResource' -ModuleName 'TestDscResourceModuleName' -MinimumVersion '1.5.0'


Find-PSResource 'TestDscResource' -ModuleName 'TestDscResourceModuleName' -MaximumVersion '1.5.0'


Find-PSResource 'TestDscResource' -ModuleName 'TestDscResourceModuleName' -MinimumVersion '1.0.0' -MaximumVersion '2.0.0'


Find-PSResource 'TestDscResource' -ModuleName 'TestDscResourceModuleName' -RequiredVersion '1.5.0'


Find-PSResource 'TestDscResource' -ModuleName 'TestDscResourceModuleName' -AllVersions


Find-PSResource 'TestDscResource' -ModuleName 'TestDscResourceModuleName' -Prerelease


Find-PSResource 'TestDscResource' -Tag 'Tag1', 'Tag2', 'Tag3'


Find-PSResource 'TestDscResource' -Filter 'Test'


Find-PSResource 'TestDscResource' -Repository 'Repository1', 'Repository2'


Find-PSResource 'TestDscResource' -Type 'DscResource'





Find-PSResource -name 'TestRoleCapability'


Find-PSResource 'TestRoleCapability'


Find-PSResource 'TestRoleCapability' -Type 'DscResource'


Find-PSResource 'TestRoleCapability' -Type 'Command', 'DscResource', 'RoleCapability', 'Module', 'Script'


Find-PSResource 'TestRoleCapability' -ModuleName 'TestDscResourceModuleName'


Find-PSResource 'TestRoleCapability' -ModuleName 'TestDscResourceModuleName' -MinimumVersion '1.5.0'


Find-PSResource 'TestRoleCapability' -ModuleName 'TestDscResourceModuleName' -MaximumVersion '1.5.0'


Find-PSResource 'TestRoleCapability' -ModuleName 'TestDscResourceModuleName' -MinimumVersion '1.0.0' -MaximumVersion '2.0.0'


Find-PSResource 'TestRoleCapability' -ModuleName 'TestDscResourceModuleName' -RequiredVersion '1.5.0'


Find-PSResource 'TestRoleCapability' -ModuleName 'TestDscResourceModuleName' -AllVersions


Find-PSResource 'TestRoleCapability' -ModuleName 'TestDscResourceModuleName' -Prerelease


Find-PSResource 'TestRoleCapability' -Tag 'Tag1', 'Tag2', 'Tag3'


Find-PSResource 'TestRoleCapability' -Filter 'Test'


Find-PSResource 'TestRoleCapability' -Repository 'Repository1', 'Repository2'


Find-PSResource 'TestRoleCapability' -Type 'TestDscResource'





Find-PSResource -name 'TestModule'


Find-PSResource 'TestModule'


Find-PSResource 'TestModule' -Type 'Module'


Find-PSResource 'TestModule' -Type 'Command', 'DscResource', 'RoleCapability', 'Module', 'Script'


Find-PSResource 'TestModule' -MinimumVersion '1.5.0'


Find-PSResource 'TestModule' -MaximumVersion '1.5.0'


Find-PSResource 'TestModule' -MinimumVersion '1.0.0' -MaximumVersion '2.0.0'


Find-PSResource 'TestModule' -RequiredVersion '1.5.0'


Find-PSResource 'TestModule' -AllVersions


Find-PSResource 'TestModule' -Prerelease


Find-PSResource 'TestModule' -Tag 'Tag1', 'Tag2', 'Tag3'


Find-PSResource 'TestModule' -Filter 'Test'


Find-PSResource 'TestModule' -Repository 'Repository1', 'Repository2'


Find-PSResource 'TestModule' -IncludeDependencies


Find-PSResource 'TestModule' -Includes 'DscResource'


Find-PSResource 'TestModule' -DSCResource 'TestDscResource'


Find-PSResource 'TestModule' -RoleCapability 'TestRoleCapability'


Find-PSResource 'TestModule' -Command 'Test-Command'





Find-PSResource -name 'TestScript'


Find-PSResource 'TestScript'


Find-PSResource 'TestScript' -Type 'Script'


Find-PSResource 'TestScript' -Type 'Command', 'DscResource', 'RoleCapability', 'Module', 'Script'


Find-PSResource 'TestScript' -MinimumVersion '1.5.0'


Find-PSResource 'TestScript' -MaximumVersion '1.5.0'


Find-PSResource 'TestScript' -MinimumVersion '1.0.0' -MaximumVersion '2.0.0'


Find-PSResource 'TestScript' -RequiredVersion '1.5.0'


Find-PSResource 'TestScript' -AllVersions


Find-PSResource 'TestScript' -AllowPrerelease


Find-PSResource 'TestScript' -Tag 'Tag1', 'Tag2', 'Tag3'


Find-PSResource 'TestScript' -Filter 'Test'


Find-PSResource 'TestScript' -Repository 'Repository1', 'Repository2'


Find-PSResource 'TestScript' -IncludeDependencies


Find-PSResource 'TestScript' -Includes 'TestFunction'


Find-PSResource 'TestScript' -Command 'Test-Command'





Find-PSResource -name 'TestResource1', 'TestResource2', 'TestResource3'


Find-PSResource 'TestResource1', 'TestResource2', 'TestResource3'


Find-PSResource 'TestResource1', 'TestResource2', 'TestResource3' -Type 'Module'


Find-PSResource 'TestResource1', 'TestResource2', 'TestResource3' -Type 'Command', 'DscResource', 'RoleCapability', 'Module', 'Script'


Find-PSResource 'TestResource1', 'TestResource2', 'TestResource3' -MinimumVersion '1.5.0'


Find-PSResource 'TestResource1', 'TestResource2', 'TestResource3' -MaximumVersion '1.5.0'


Find-PSResource 'TestResource1', 'TestResource2', 'TestResource3' -MinimumVersion '1.0.0' -MaximumVersion '2.0.0'


Find-PSResource 'TestResource1', 'TestResource2', 'TestResource3' -RequiredVersion '1.5.0'


Find-PSResource 'TestResource1', 'TestResource2', 'TestResource3' -AllVersions


Find-PSResource 'TestResource1', 'TestResource2', 'TestResource3' -Prerelease


Find-PSResource 'TestResource1', 'TestResource2', 'TestResource3' -Tag 'Tag1', 'Tag2', 'Tag3'


Find-PSResource 'TestResource1', 'TestResource2', 'TestResource3' -Filter 'Test'


Find-PSResource 'TestResource1', 'TestResource2', 'TestResource3' -Repository 'Repository1', 'Repository2'


Find-PSResource 'TestResource1', 'TestResource2', 'TestResource3' -IncludeDependencies


Find-PSResource 'TestResource1', 'TestResource2', 'TestResource3' -Includes 'DscResource'


Find-PSResource 'TestResource1', 'TestResource2', 'TestResource3' -DSCResource 'TestDscResource'


Find-PSResource 'TestResource1', 'TestResource2', 'TestResource3' -RoleCapability 'TestRoleCapability'


Find-PSResource 'TestResource1', 'TestResource2', 'TestResource3' -Command 'Test-Command'












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
