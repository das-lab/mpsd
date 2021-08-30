











Set-StrictMode -Version 'Latest'

& (Join-Path -Path $PSScriptRoot -ChildPath 'Initialize-CarbonTest.ps1')

describe Uninstall-Group {

    $groupName = 'TestUninstallGroup'
    $description = 'Used by Uninstall-Group.Tests.ps1'

    BeforeEach {
        Install-Group -Name $groupName -Description $description
        $Global:Error.Clear()
    }

    AfterEach {
        Uninstall-Group -Name $groupName
    }

    BeforeEach {
        $Global:Error.Clear()
    }

    It 'should remove the group' {
        Test-Group -Name $groupName | Should Be $true
        Uninstall-Group -Name $groupName
        Test-Group -Name $groupName | Should Be $false
    }

    It 'should remove nonexistent group without errors' {
        Uninstall-Group -Name 'fubarsnafu'
        $Global:Error.Count | Should Be 0
    }

    It 'should support WhatIf' {
        Uninstall-Group -Name $groupName -WhatIf
        Test-Group -Name $groupName | Should Be $true
    }
}
