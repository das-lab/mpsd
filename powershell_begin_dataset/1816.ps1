

Describe "Simple ItemProperty Tests" -Tag "CI" {
    It "Can retrieve the PropertyValue with Get-ItemPropertyValue" {
        Get-ItemPropertyValue -path $TESTDRIVE -Name Attributes | Should -Be "Directory"
    }
    It "Can clear the PropertyValue with Clear-ItemProperty" {
        setup -f file1.txt
        Set-ItemProperty $TESTDRIVE/file1.txt -Name Attributes -Value ReadOnly
        Get-ItemPropertyValue -path $TESTDRIVE/file1.txt -Name Attributes | Should -Match "ReadOnly"
        Clear-ItemProperty $TESTDRIVE/file1.txt -Name Attributes
        Get-ItemPropertyValue -path $TESTDRIVE/file1.txt -Name Attributes | Should -Not -Match "ReadOnly"
    }
    
    Context "Registry targeted cmdlets" {
        It "Copy ItemProperty" -pending { }
        It "Move ItemProperty" -pending { }
        It "New ItemProperty" -pending { }
        It "Rename ItemProperty" -pending { }
    }
}
