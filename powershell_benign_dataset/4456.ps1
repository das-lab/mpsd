




Save-PSResource 'TestModule'


Save-PSResource -name 'TestModule'


Save-PSResource 'TestModule' -Type 'Module'


Save-PSResource 'TestModule' -Type 'Module', 'Script', 'Library'


Save-PSResource 'TestModule1', 'TestModule2', 'TestModule3'


Save-PSResource 'TestModule' -MinimumVersion '1.5.0'


Save-PSResource 'TestModule' -MaximumVersion '1.5.0'


Save-PSResource 'TestModule' -MinimumVersion '1.0.0' -MaximumVersion '2.0.0'


Save-PSResource 'TestModule' -RequiredVersion '1.5.0'


Save-PSResource 'TestModule' -Prerelease


Save-PSResource 'TestModule' -Repository 'Repository1', 'Repository2'


Save-PSResource 'TestModule' -Path '.\*\somepath'


Save-PSResource 'TestModule' -LiteralPath '.'


Save-PSResource 'TestModule' -Force


Save-PSResource 'TestModule' -AcceptLicense


Find-PSResource 'TestModule' | Save-PSresource





Save-PSResource 'TestScript'


Save-PSResource -name 'TestScript'


Save-PSResource 'TestScript' -Type 'Script'


Save-PSResource 'TestScript' -Type 'Module', 'Script', 'Library'


Save-PSResource 'TestScript1', 'TestScript2', 'TestScript3'


Save-PSResource 'TestScript' -MinimumVersion '1.5.0'


Save-PSResource 'TestScript' -MaximumVersion '1.5.0'


Save-PSResource 'TestScript' -MinimumVersion '1.0.0' -MaximumVersion '2.0.0'


Save-PSResource 'TestScript' -RequiredVersion '1.5.0'


Save-PSResource 'TestScript' -Prerelease


Save-PSResource 'TestScript' -Repository 'Repository1', 'Repository2'


Save-PSResource 'TestModule' -Path '.\*\somepath'


Save-PSResource 'TestModule' -LiteralPath '.'


Save-PSResource 'TestScript' -Force


Save-PSResource 'TestScript' -AcceptLicense


Find-PSResource 'TestScript' | Save-PSresource




Save-PSResource 'TestNupkg'


Save-PSResource 'TestNupkg' -Type 'Library'


Save-PSResource 'TestNupkg' -Type 'Module', 'Script', 'Library'


Save-PSResource 'TestNupkg1', 'TestNupkg2', 'TestNupkg3'


Save-PSResource 'TestNupkg' -MinimumVersion '1.5.0'


Save-PSResource 'TestNupkg' -MaximumVersion '1.5.0'


Save-PSResource 'TestNupkg' -MinimumVersion '1.0.0' -MaximumVersion '2.0.0'


Save-PSResource 'TestNupkg' -RequiredVersion '1.5.0'


Save-PSResource 'TestNupkg' -Prerelease


Save-PSResource 'TestNupkg' -Repository 'Repository1', 'Repository2'


Save-PSResource 'TestModule' -Path '.\*\somepath'


Save-PSResource 'TestModule' -LiteralPath '.'


Save-PSResource 'TestNupkg' -Force


Save-PSResource 'TestNupkg' -AcceptLicense


Save-PSResource 'TestNupkg' -AsNupkg


Save-PSResource 'TestNupkg' -IncludeAllRuntimes
