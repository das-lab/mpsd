

Function Set-ConsoleTitle {
	Param ([String]$Title)
	$host.ui.RawUI.WindowTitle = $Title
}

Function Get-Architecture {
	
	Set-Variable -Name Architecture -Scope Local -Force
	
	$Architecture = Get-WmiObject -Class Win32_OperatingSystem | Select-Object OSArchitecture
	$Architecture = $Global:Architecture.OSArchitecture
	
	Return $Architecture
	
	
	Remove-Variable -Name Architecture -Scope Local -Force
}

Function Install-Updates {
	Param ([String]$DisplayName,
		[String]$Executable,
		[String]$Switches)
	
	
	Set-Variable -Name ErrCode -Scope Local -Force
	
	Write-Host "Install"$DisplayName"....." -NoNewline
	If ((Test-Path $Executable) -eq $true) {
		$ErrCode = (Start-Process -FilePath $Executable -ArgumentList $Switches -Wait -Passthru).ExitCode
	} else {
		$ErrCode = 1
	}
	If (($ErrCode -eq 0) -or ($ErrCode -eq 1) -or ($ErrCode -eq 3010)) {
		Write-Host "Success" -ForegroundColor Yellow
	} else {
		Write-Host "Failed with error code "$ErrCode -ForegroundColor Red
	}
	
	
	Remove-Variable -Name ErrCode -Scope Local -Force
}


Function CCTKSetting {
	param ($Name,
		$Option,
		$Setting,
		$Drives,
		$Architecture)
	
	
	Set-Variable -Name Argument -Scope Local -Force
	Set-Variable -Name ErrCode -Scope Local -Force
	Set-Variable -Name EXE -Scope Local -Force
	
	If ($Architecture -eq "32-bit") {
		$EXE = $Env:PROGRAMFILES + "\Dell\Command Configure\X86\cctk.exe"
	} else {
		$EXE = ${env:ProgramFiles(x86)} + "\Dell\Command Configure\X86_64\cctk.exe"
	}
	If ($Option -ne "bootorder") {
		$Argument = "--" + $Option + "=" + $Setting
	} else {
		$Argument = "bootorder" + [char]32 + "--" + $Setting + "=" + $Drives
	}
	Write-Host $Name"....." -NoNewline
	If ((Test-Path $EXE) -eq $true) {
		$ErrCode = (Start-Process -FilePath $EXE -ArgumentList $Argument -Wait -Passthru).ExitCode
	} else {
		$ErrCode = 1
	}
	If (($ErrCode -eq 0) -or ($ErrCode -eq 240) -or ($ErrCode -eq 241)) {
		If ($Drives -eq "") {
			Write-Host $Setting -ForegroundColor Yellow
		} else {
			Write-Host $Drives -ForegroundColor Yellow
		}
	} elseIf ($ErrCode -eq 119) {
		Write-Host "Unavailable" -ForegroundColor Green
	} else {
		Write-Host "Failed with error code "$ErrCode -ForegroundColor Red
	}
	
	
	Remove-Variable -Name Argument -Scope Local -Force
	Remove-Variable -Name ErrCode -Scope Local -Force
	Remove-Variable -Name EXE -Scope Local -Force
}


Set-Variable -Name Architecture -Scope Local -Force
Set-Variable -Name EXE -Scope Local -Force

cls
Set-ConsoleTitle -Title "Dell Client Update"
$Architecture = Get-Architecture
CCTKSetting -Name "Disable BIOS Password" -Option "valsetuppwd" -Setting "<BIOS Password> --setuppwd=" -Drives "" -Architecture $Architecture
If ($Architecture -eq "32-bit") {
	$EXE = $Env:PROGRAMFILES + "\Dell\CommandUpdate\dcu-cli.exe"
} else {
	$EXE = ${env:ProgramFiles(x86)} + "\Dell\CommandUpdate\dcu-cli.exe"
}
Install-Updates -DisplayName "Update All Hardware Components" -Executable $EXE -Switches " "


Remove-Variable -Name Architecture -Scope Local -Force
Remove-Variable -Name EXE -Scope Local -Force
