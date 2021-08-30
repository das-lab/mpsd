











& (Join-Path -Path $PSScriptRoot -ChildPath 'Initialize-CarbonTest.ps1' -Resolve)

function Init
{
    $Global:Error.Clear()
}

Describe 'Test-ScheduledTask' {
    BeforeEach {
        Init
    }

    It 'should find existing task' {
        $task = Get-ScheduledTask | Select-Object -First 1
        $task | Should -Not -BeNullOrEmpty
        (Test-ScheduledTask -Name $task.FullName) | Should -BeTrue
        $Global:Error.Count | Should -Be 0
    }
    
    It 'should not find non existent task' {
        (Test-ScheduledTask -Name 'fubar') | Should -BeFalse
        $Global:Error.Count | Should -Be 0
    }
}
