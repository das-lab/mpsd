

function Test-UnblockFile {
    { Get-Content -Path $testfilepath -Stream Zone.Identifier -ErrorAction Stop | Out-Null } |
        Should -Throw -ErrorId "GetContentReaderFileNotFoundError,Microsoft.PowerShell.Commands.GetContentCommand"
}

Describe "Unblock-File" -Tags "CI" {

    BeforeAll {
        if ( ! $IsWindows )
        {
            $origDefaults = $PSDefaultParameterValues.Clone()
            $PSDefaultParameterValues['it:skip'] = $true

        } else {
            $testfilepath = Join-Path -Path $TestDrive -ChildPath testunblockfile.ttt
        }
    }

    AfterAll {
        if ( ! $IsWindows ){
            $global:PSDefaultParameterValues = $origDefaults
        }
    }

    BeforeEach {
        if ( $IsWindows ){
            Set-Content -Value "[ZoneTransfer]`r`nZoneId=4" -Path $testfilepath -Stream Zone.Identifier
        }
    }

    It "With '-Path': no file exist" {
        { Unblock-File -Path nofileexist.ttt -ErrorAction Stop } | Should -Throw -ErrorId "FileNotFound,Microsoft.PowerShell.Commands.UnblockFileCommand"
    }

    It "With '-LiteralPath': no file exist" {
        { Unblock-File -LiteralPath nofileexist.ttt -ErrorAction Stop } | Should -Throw -ErrorId "FileNotFound,Microsoft.PowerShell.Commands.UnblockFileCommand"
    }

    It "With '-Path': file exist" {
        Unblock-File -Path $testfilepath
        Test-UnblockFile

        
        { Unblock-File -Path $testfilepath -ErrorAction Stop } | Should -Not -Throw
    }

    It "With '-LiteralPath': file exist" {
        Unblock-File -LiteralPath $testfilepath
        Test-UnblockFile
    }

    It "Write an error if a file is read only" {
        $TestFile = Join-Path $TestDrive "testfileunlock.ps1"
        Set-Content -Path $TestFile -value 'test'
        $ZoneIdentifier = {
            [ZoneTransfer]
            ZoneId=3
        }
        Set-Content -Path $TestFile -Value $ZoneIdentifier -Stream 'Zone.Identifier'
        Set-ItemProperty -Path $TestFile -Name IsReadOnly -Value $True

        $TestFileCreated = Get-ChildItem $TestFile
        $TestFileCreated.IsReadOnly | Should -BeTrue

        { Unblock-File -LiteralPath $TestFile -ErrorAction Stop } | Should -Throw -ErrorId "RemoveItemUnableToAccessFile,Microsoft.PowerShell.Commands.UnblockFileCommand"
    }
}
