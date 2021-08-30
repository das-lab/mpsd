











& (Join-Path -Path $PSScriptRoot -ChildPath 'Initialize-CarbonTest.ps1' -Resolve)

Describe 'System.Diagnostics.Process' {
    It 'processes have ParentProcessID' {
        $parents = @{}
        Get-WmiObject Win32_Process |
            ForEach-Object { $parents[$_.ProcessID] = $_.ParentProcessID }
    
        $foundSome = $false
        Get-Process | 
            Where-Object { $parents.ContainsKey( [UInt32]$_.Id ) -and $_.ParentProcessID } |
            ForEach-Object {
                $foundSome = $true
                $expectedID = $parents[ [UInt32]$_.Id ]  
                $_.ParentProcessID | Should -Be $expectedID
            }
        $foundSome | Should -Be $true
    }
    
}
