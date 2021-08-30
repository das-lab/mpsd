
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
