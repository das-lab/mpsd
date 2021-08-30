

Describe "Native Command Arguments" -tags "CI" {
    
    
    
    
    
    
    It "Should handle quoted spaces correctly" {
        $a = 'a"b c"d'
        $lines = testexe -echoargs $a 'a"b c"d' a"b c"d
        $lines.Count | Should -Be 3
        $lines[0] | Should -BeExactly 'Arg 0 is <ab cd>'
        $lines[1] | Should -BeExactly 'Arg 1 is <ab cd>'
        $lines[2] | Should -BeExactly 'Arg 2 is <ab cd>'
    }

    
    
    
    
    
    
    
    
    
    
    
    It "Should handle spaces between escaped quotes" {
        $lines = testexe -echoargs 'a\"b c\"d' "a\`"b c\`"d"
        $lines.Count | Should -Be 2
        $lines[0] | Should -BeExactly 'Arg 0 is <a"b c"d>'
        $lines[1] | Should -BeExactly 'Arg 1 is <a"b c"d>'
    }

    It "Should correctly quote paths with spaces: <arguments>" -TestCases @(
        @{arguments = "'.\test 1\' `".\test 2\`""  ; expected = @(".\test 1\",".\test 2\")},
        @{arguments = "'.\test 1\\\' `".\test 2\\`""; expected = @(".\test 1\\\",".\test 2\\")}
    ) {
        param($arguments, $expected)
        $lines = Invoke-Expression "testexe -echoargs $arguments"
        $lines.Count | Should -Be $expected.Count
        for ($i = 0; $i -lt $lines.Count; $i++) {
            $lines[$i] | Should -BeExactly "Arg $i is <$($expected[$i])>"
        }
    }

    It "Should handle PowerShell arrays with or without spaces correctly: <arguments>" -TestCases @(
        @{arguments = "1,2"; expected = @("1,2")}
        @{arguments = "1,2,3"; expected = @("1,2,3")}
        @{arguments = "1, 2"; expected = "1,", "2"}
        @{arguments = "1 ,2"; expected = "1", ",2"}
        @{arguments = "1 , 2"; expected = "1", ",", "2"}
        @{arguments = "1, 2,3"; expected = "1,", "2,3"}
        @{arguments = "1 ,2,3"; expected = "1", ",2,3"}
        @{arguments = "1 , 2,3"; expected = "1", ",", "2,3"}
    ) {
        param($arguments, $expected)
        $lines = @(Invoke-Expression "testexe -echoargs $arguments")
        $lines.Count | Should -Be $expected.Count
        for ($i = 0; $i -lt $expected.Count; $i++) {
            $lines[$i] | Should -BeExactly "Arg $i is <$($expected[$i])>"
        }
    }
}
