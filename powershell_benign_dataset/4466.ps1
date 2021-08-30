





Publish-PSResource -name 'TestModule'


Publish-PSResource 'TestModule'


Publish-PSResource 'TestModule' -Path '.\*\somepath'


Publish-PSResource 'TestModule' -LiteralPath '.'


Publish-PSResource 'TestModule' -RequiredVersion '1.5.0'


Publish-PSResource 'TestModule' -Prerelease


Publish-PSResource 'TestModule' -NuGetApiKey '1234567890'


Publish-PSResource 'TestModule' -Repository 'Repository'


Publish-PSResource 'TestModule' -ReleaseNotes 'Mock release notes.'


Publish-PSResource 'TestModule' -Tags 'Tag1', 'Tag2', 'Tag3'


Publish-PSResource 'TestModule' -LicenseUri 'www.licenseuri.com'


Publish-PSResource 'TestModule' -IconUri 'www.iconuri.com'


Publish-PSResource 'TestModule' -ProjectUri 'www.projecturi.com'


Publish-PSResource 'TestModule' -Exclude 'some\path\file.ps1'


Publish-PSResource 'TestModule' -Force


Publish-PSResource 'TestModule' -SkipDependenciesCheck


Publish-PSResource 'TestModule' -Nuspec '\path\to\file.nuspec'



Publish-PSResource 'TestModule' -DestinationPath '.\TestNupkg.nupkg'





Publish-PSResource 'TestScript' -Path '.\*\TestScript.ps1'


Publish-PSResource 'TestScript' -LiteralPath '.\TestScript.ps1'


Publish-PSResource 'TestScript' -RequiredVersion '1.5.0'


Publish-PSResource 'TestScript' -Prerelease


Publish-PSResource 'TestScript' -NuGetApiKey '1234567890'


Publish-PSResource 'TestScript' -Repository 'Repository'


Publish-PSResource 'TestScript' -ReleaseNotes 'Mock release notes.'


Publish-PSResource 'TestScript' -Tags 'Tag1', 'Tag2', 'Tag3'


Publish-PSResource 'TestScript' -LicenseUri 'www.licenseuri.com'


Publish-PSResource 'TestScript' -IconUri 'www.iconuri.com'


Publish-PSResource 'TestScript' -ProjectUri 'www.projecturi.com'


Publish-PSResource 'TestScript' -Force


Publish-PSResource 'TestScript' -SkipDependenciesCheck


Publish-PSResource 'TestScript' -Nuspec '\path\to\file.nuspec'
