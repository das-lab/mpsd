











& (Join-Path -Path $PSScriptRoot -ChildPath 'Initialize-CarbonTest.ps1' -Resolve)

$manifest = Test-ModuleManifest -Path (Join-Path -Path $PSScriptRoot -ChildPath '..\Carbon\Carbon.psd1' -Resolve)
Describe 'CarbonVersion' {
    $expectedVersion = $null
    
    BeforeEach {
    }
    
    It 'carbon assembly version is correct' {
        $binPath = Join-Path -Path $PSScriptRoot -ChildPath '..\Carbon\bin\*'
        Get-ChildItem -Path $binPath -Include 'Carbon*.dll' | ForEach-Object {
    
            $_.VersionInfo.FileVersion | Should Be $manifest.Version
            $_.VersionInfo.ProductVersion.ToString().StartsWith($manifest.Version.ToString()) | Should Be $true
        }
    }
}
