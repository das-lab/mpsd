Set-StrictMode -Version Latest





$functionName = '01c1a57716fe4005ac1a7bf216f38ad0'

try {
    Describe 'Mocking Global Functions - Part Two' {
        It 'Restored the global function properly' {
            $globalFunctionExists = Test-Path Function:\global:$functionName
            $globalFunctionExists | Should -Be $true
            & $functionName | Should -Be 'Original Function'
        }
    }
}
finally {
    if (Test-Path Function:\$functionName) {
        Remove-Item Function:\$functionName -Force
    }
}
