












Set-StrictMode -Version 'Latest'

& (Join-Path -Path $PSScriptRoot -ChildPath 'Initialize-CarbonTest.ps1' -Resolve)

Describe 'Test-Service when testing an existing service' {
    $error.Clear()
    Get-Service | ForEach-Object {
        It ('should find the {0} {1} service' -f $_.ServiceName,$_.ServiceType) {
            Test-Service -Name $_.ServiceName | Should Be $true
            $Error.Count | Should Be 0
        }
    }
}

Describe 'Test-Service when testing for a non-existent service' {
    
    $error.Clear()

    It 'should not find missing service' {
        (Test-Service -Name 'ISureHopeIDoNotExist') | Should Be $false
        $error.Count | Should Be 0
    }
    
}

Describe 'Test-Service when testing for a device service' {
    $Error.Clear()
    [ServiceProcess.ServiceController]::GetDevices() | ForEach-Object {
        It ('should find the {0} {1} service' -f $_.ServiceName,$_.ServiceType) {
            Test-Service -Name $_.ServiceName | Should Be $true
            $Error.Count | Should Be 0
        }
    }
}