

Describe "Redirection operator now supports encoding changes" -Tags "CI" {
    BeforeAll {
        $asciiString = "abc"

        if ( $IsWindows ) {
             $asciiCR = "`r`n"
        }
        else {
            $asciiCR = [string][char]10
        }

        
        
        $SavedValue = $null
        $oldDefaultParameterValues = $psDefaultParameterValues.Clone()
        $psDefaultParameterValues = @{}
    }
    AfterAll {
        
        $global:psDefaultParameterValues = $oldDefaultParameterValues
    }
    BeforeEach {
        
        $psdefaultParameterValues.Remove("Out-File:Encoding")
    }
    AfterEach {
        
        $psdefaultParameterValues.Remove("Out-File:Encoding")
    }

    It "If encoding is unset, redirection should be UTF8 without bom" {
        $asciiString > TESTDRIVE:\file.txt
        $bytes = Get-Content -AsByteStream TESTDRIVE:\file.txt
        
        $encoding = [Text.UTF8Encoding]::new($false)
        
        $TXT = $encoding.GetBytes($asciiString)
        $CR  = $encoding.GetBytes($asciiCR)
        $expectedBytes = .{ $TXT; $CR }
        $bytes.Count | Should -Be $expectedBytes.count
        for($i = 0; $i -lt $bytes.count; $i++) {
            $bytes[$i] | Should -Be $expectedBytes[$i]
        }
    }

    
    $availableEncodings = (Get-Command Out-File).Parameters["Encoding"].Attributes.ValidValues

    foreach($encoding in $availableEncodings) {
        $skipTest = $false
        if ($encoding -eq "default") {
            
            
            
            
            $skipTest = $true
        }

        
        
        
        
        $enc = [System.Text.Encoding]::$encoding
        if ( $enc )
        {
            $msg = "Overriding encoding for Out-File is respected for $encoding"
            $BOM = $enc.GetPreamble()
            $TXT = $enc.GetBytes($asciiString)
            $CR  = $enc.GetBytes($asciiCR)
            $expectedBytes = .{ $BOM; $TXT; $CR }
            $psdefaultparameterValues["Out-File:Encoding"] = "$encoding"
            $asciiString > TESTDRIVE:/file.txt
            $observedBytes = Get-Content -AsByteStream TESTDRIVE:/file.txt
            
            It $msg -Skip:$skipTest {
                $observedBytes.Count | Should -Be $expectedBytes.Count
                for($i = 0;$i -lt $observedBytes.Count; $i++) {
                    $observedBytes[$i] | Should -Be $expectedBytes[$i]
                }
            }

        }
    }
}

Describe "File redirection mixed with Out-Null" -Tags CI {
    It "File redirection before Out-Null should work" {
        "some text" > $TestDrive\out.txt | Out-Null
        Get-Content $TestDrive\out.txt | Should -BeExactly "some text"

        Write-Output "some more text" > $TestDrive\out.txt | Out-Null
        Get-Content $TestDrive\out.txt | Should -BeExactly "some more text"
    }
}

Describe "File redirection should have 'DoComplete' called on the underlying pipeline processor" -Tags CI {
    BeforeAll {
        $originalErrorView = $ErrorView
        $ErrorView = "NormalView"
    }

    AfterAll {
        $ErrorView = $originalErrorView
    }

    It "File redirection should result in the same file as Out-File" {
        $object = [pscustomobject] @{ one = 1 }
        $redirectFile = Join-Path $TestDrive fileRedirect.txt
        $outFile = Join-Path $TestDrive outFile.txt

        $object > $redirectFile
        $object | Out-File $outFile

        $redirectFileContent = Get-Content $redirectFile -Raw
        $outFileContent = Get-Content $outFile -Raw
        $redirectFileContent | Should -BeExactly $outFileContent
    }

    It "File redirection should not mess up the original pipe" {
        $outputFile = Join-Path $TestDrive output.txt
        $otherStreamFile = Join-Path $TestDrive otherstream.txt

        $result = & { $(Get-Command NonExist; 1234) > $outputFile *> $otherStreamFile; "Hello" }
        $result | Should -BeExactly "Hello"

        $outputContent = Get-Content $outputFile -Raw
        $outputContent.Trim() | Should -BeExactly '1234'

        $errorContent = Get-Content $otherStreamFile | ForEach-Object { $_.Trim() }
        $errorContent = $errorContent -join ""
        $errorContent | Should -Match "CommandNotFoundException,Microsoft.PowerShell.Commands.GetCommandCommand"
    }
}
