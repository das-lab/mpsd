




Get-PSResource 'TestModule'


Get-PSResource -name 'TestModule'


Get-PSResource 'TestModule' -Type 'Module'


Get-PSResource 'TestModule' -Type 'Module', 'Script', 'Library'


Get-PSResource 'TestModule1', 'TestModule2', 'TestModule3'


Get-PSResource 'TestModule' -MinimumVersion '1.5.0'


Get-PSResource 'TestModule' -MaximumVersion '1.5.0'


Get-PSResource 'TestModule' -MinimumVersion '1.0.0' -MaximumVersion '2.0.0'


Get-PSResource 'TestModule' -RequiredVersion '1.5.0'


Get-PSResource 'TestModule' -AllVersions


Get-PSResource 'TestModule' -Prerelease





Get-PSResource 'TestScript'


Get-PSResource -name 'TestScript'


Get-PSResource 'TestScript' -Type 'Script'


Get-PSResource 'TestScript' -Type 'Module', 'Script', 'Library'


Get-PSResource 'TestScript1', 'TestScript2', 'TestScript3'


Get-PSResource 'TestScript' -MinimumVersion '1.5.0'


Get-PSResource 'TestScript' -MaximumVersion '1.5.0'


Get-PSResource 'TestScript' -MinimumVersion '1.0.0' -MaximumVersion '2.0.0'


Get-PSResource 'TestScript' -RequiredVersion '1.5.0'


Get-PSResource 'TestModule' -AllVersions


Get-PSResource 'TestScript' -Prerelease




Get-PSResource 'TestNupkg'


Get-PSResource 'TestNupkg' -Type 'Library'


Get-PSResource 'TestNupkg' -Type 'Module', 'Script', 'Library'


Get-PSResource 'TestNupkg1', 'TestNupkg2', 'TestNupkg3'


Get-PSResource 'TestNupkg' -MinimumVersion '1.5.0'


Get-PSResource 'TestNupkg' -MaximumVersion '1.5.0'


Get-PSResource 'TestNupkg' -MinimumVersion '1.0.0' -MaximumVersion '2.0.0'


Get-PSResource 'TestNupkg' -RequiredVersion '1.5.0'


Get-PSResource 'TestModule' -AllVersions


Get-PSResource 'TestNupkg' -Prerelease
