Set-StrictMode -Version Latest

$here = $MyInvocation.MyCommand.Path | Split-Path
Get-Module Axiom, Format | Remove-Module
Import-Module $here\..\Axiom\Axiom.psm1 -ErrorAction 'stop' -DisableNameChecking
Import-Module $here\Format.psm1 -ErrorAction 'stop' -DisableNameChecking

function New-PSObject ([hashtable]$Property) {
    New-Object -Type PSObject -Property $Property
}

function New-Dictionary ([hashtable]$Hashtable) {
    $d = new-object "Collections.Generic.Dictionary[string,object]"

    $Hashtable.GetEnumerator() | foreach { $d.Add($_.Key, $_.Value) }

    $d
}


Describe "Format-Collection" {
    It "Formats collection of values '<value>' to '<expected>' using comma separator" -TestCases @(
        @{ Value = (1, 2, 3); Expected = "@(1, 2, 3)" }
    ) {
        param ($Value, $Expected)
        Format-Collection -Value $Value | Verify-Equal $Expected
    }
}

Describe "Format-Number" {
    It "Formats number to use . separator (tests anything only on non-english systems --todo)" -TestCases @(
        @{ Value = 1.1; },
        @{ Value = [double] 1.1; },
        @{ Value = [float] 1.1; },
        @{ Value = [single] 1.1; },
        @{ Value = [decimal] 1.1; }
    ) {
        param ($Value)
        Format-Number -Value $Value | Verify-Equal "1.1"
    }
}

























Describe "Format-Boolean" {
    It "Formats boolean '<value>' to '<expected>'" -TestCases @(
        @{ Value = $true; Expected = '$true' },
        @{ Value = $false; Expected = '$false' }
    ) {
        param($Value, $Expected)
        Format-Boolean -Value $Value | Verify-Equal $Expected
    }
}

Describe "Format-Null" {
    It "Formats null to '`$null'" {
        Format-Null | Verify-Equal '$null'
    }
}

Describe "Format-String" {
    It "Formats empty string to '<empty>'" {
        Format-String -Value "" | Verify-Equal '<empty>'
    }

    It "Formats string to be sorrounded by quotes" {
        Format-String -Value "abc" | Verify-Equal "'abc'"
    }
}

Describe "Format-DateTime" {
    It "Formats date to orderable format with ticks" {
        Format-Date -Value ([dateTime]239842659899234234) | Verify-Equal '0761-01-12T16:06:29.9234234'
    }
}

Describe "Format-ScriptBlock" {
    It "Formats scriptblock as string with curly braces" {
        Format-ScriptBlock -Value {abc} | Verify-Equal '{abc}'
    }
}

































Describe "Format-Nicely" {
    It "Formats value '<value>' correctly to '<expected>'" -TestCases @(
        @{ Value = $null; Expected = '$null'}
        @{ Value = $true; Expected = '$true'}
        @{ Value = $false; Expected = '$false'}
        @{ Value = 'a' ; Expected = "'a'"},
        @{ Value = '' ; Expected = '<empty>'},
        @{ Value = ([datetime]636545721418385266) ; Expected = '2018-02-18T17:35:41.8385266'},
        @{ Value = 1; Expected = '1' },
        @{ Value = (1, 2, 3); Expected = '@(1, 2, 3)' },
        @{ Value = 1.1; Expected = '1.1' },
        @{ Value = [int]; Expected = '[int]'}
        
        
        
        
        
    ) {
        param($Value, $Expected)
        Format-Nicely -Value $Value | Verify-Equal $Expected
    }
}












Describe "Format-Type" {
    It "Given '<value>' it returns the correct shortened type name '<expected>'" -TestCases @(
        @{ Value = [int]; Expected = 'int' },
        @{ Value = [double]; Expected = 'double' },
        @{ Value = [string]; Expected = 'string' },
        @{ Value = $null; Expected = '<none>' }
    ) {
        param($Value, $Expected)
        Format-Type -Value $Value | Verify-Equal $Expected
    }
}


Describe "Get-ShortType" {
    It "Given '<value>' it returns the correct shortened type name '<expected>'" -TestCases @(
        @{ Value = 1; Expected = 'int' },
        @{ Value = 1.1; Expected = 'double' },
        @{ Value = 'a' ; Expected = 'string' },
        @{ Value = $null ; Expected = '<none>' },
        @{ Value = New-PSObject @{Name = 'Jakub'} ; Expected = 'PSObject'},
        @{ Value = [Object[]]1, 2, 3 ; Expected = 'collection' }
    ) {
        param($Value, $Expected)
        Get-ShortType -Value $Value | Verify-Equal $Expected
    }
}
