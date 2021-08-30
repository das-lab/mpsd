

Describe "Scripting.Followup.Tests" -Tags "CI" {
    It "'[void](New-Item) | <Cmdlet>' should work and behave like passing AutomationNull to the pipe" {
        try {
            $testFile = Join-Path $TestDrive (New-Guid)
            [void](New-Item $testFile -ItemType File) | ForEach-Object { "YES" } | Should -BeNullOrEmpty
            
            $testFile | Should -Exist
        } finally {
            Remove-Item $testFile -Force -ErrorAction SilentlyContinue
        }
    }

    
    It "'[void]`$arraylist.Add(1) | <Cmdlet>' should work and behave like passing AutomationNull to the pipe" {
        $arraylist = [System.Collections.ArrayList]::new()
        [void]$arraylist.Add(1) | ForEach-Object { "YES" } | Should -BeNullOrEmpty
        
        $arraylist.Count | Should -Be 1
        $arraylist[0] | Should -Be 1
    }

    
    It "'`$arraylist2.Clear() | <Cmdlet>' should work and behave like passing AutomationNull to the pipe" {
        $arraylist = [System.Collections.ArrayList]::new()
        $arraylist.Add(1) > $null
        $arraylist.Clear() | ForEach-Object { "YES" } | Should -BeNullOrEmpty
        
        $arraylist.Count | Should -Be 0
    }
}
