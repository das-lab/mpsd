

param
(
	[string]$WindowsRepository,
	[string]$BIOSPassword,
	[switch]$BIOS,
	[switch]$Drivers,
	[switch]$Applications,
	[string]$WinPERepository
)

function Get-Architecture {

	
	[CmdletBinding()][OutputType([string])]
	param ()
	
	$OSArchitecture = (Get-WmiObject -Class Win32_OperatingSystem | Select-Object OSArchitecture).OSArchitecture
	Return $OSArchitecture
}

function Get-WindowsUpdateReport {

	
	[CmdletBinding()][OutputType([xml])]
	param ()
	
	
	If ((test-path -Path 'REGISTRY::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\WinPE\') -eq $true) {
		$Executable = Get-ChildItem -Path "x:\DCU" -Filter dcu-cli.exe
		$ReportFile = "x:\DCU\DriverReport.xml"
	} else {
		$Architecture = Get-Architecture
		If ($Architecture -eq "32-Bit") {
			$Executable = Get-ChildItem -Path $env:ProgramFiles"\Dell\CommandUpdate" -Filter dcu-cli.exe
		} else {
			$Executable = Get-ChildItem -Path ${env:ProgramFiles(x86)}"\Dell\CommandUpdate" -Filter dcu-cli.exe
		}
		
		If ($WindowsRepository[$WindowsRepository.Length - 1] -ne "\") {
			$ReportFile = $WindowsRepository + "\" + "DriverReport.xml"
		} else {
			$ReportFile = $WindowsRepository + "DriverReport.xml"
		}
	}
	
	If ((Test-Path -Path $ReportFile) -eq $true) {
		Remove-Item -Path $ReportFile -Force -ErrorAction SilentlyContinue
	}
	
	$Switches = "/report" + [char]32 + $ReportFile
	
	$ErrCode = (Start-Process -FilePath $Executable.FullName -ArgumentList $Switches -Wait -Passthru).ExitCode
	
	If ((Test-Path -Path $ReportFile) -eq $true) {
		
		[xml]$DriverList = Get-Content -Path $ReportFile
		Return $DriverList
	} else {
		Return $null
	}
}

function Get-WinPEUpdateReport {

	
	[CmdletBinding()]
	param ()
	
	
	$ReportFile = $env:SystemDrive + "\DCU\DriversReport.xml"
	
	If ((Test-Path $ReportFile) -eq $true) {
		Remove-Item -Path $ReportFile -Force | Out-Null
	}
	
	$Executable = $env:SystemDrive + "\DCU\dcu-cli.exe"
	
	$Switches = "/report" + [char]32 + $ReportFile
	
	$ErrCode = (Start-Process -FilePath $Executable -ArgumentList $Switches -Wait -Passthru).ExitCode
	
	If ((Test-Path -Path $ReportFile) -eq $true) {
		
		[xml]$DriverList = Get-Content -Path $ReportFile
		Return $DriverList
	} else {
		Return $null
	}
}

function Update-Repository {

	
	[CmdletBinding()]
	param
	(
		[ValidateNotNullOrEmpty()]$Updates
	)
	
	
	If ((test-path -Path 'REGISTRY::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\WinPE\') -eq $true) {
		If ($WinPERepository[$WinPERepository.Length - 1] -ne "\") {
			$Repository = $WinPERepository + "\"
		} else {
			$Repository = $WinPERepository
		}
	} elseif ($WindowsRepository[$WindowsRepository.Length - 1] -ne "\") {
		$Repository = $WindowsRepository + "\"
	} else {
		$Repository = $WindowsRepository
	}
	foreach ($Update in $Updates.Updates.Update) {
		
		$UpdateRepository = $Repository + $Update.Release
		
		$DownloadURI = $Update.file
		$DownloadFileName = $UpdateRepository + "\" + ($DownloadURI.split("/")[-1])
		
		If ((Test-Path $UpdateRepository) -eq $false) {
			New-Item -Path $UpdateRepository -ItemType Directory -Force | Out-Null
		}
		
		If ((Test-Path $DownloadFileName) -eq $false) {
			Invoke-WebRequest -Uri $DownloadURI -OutFile $DownloadFileName
		}
	}
}

function Update-Applicatons {

	
	[CmdletBinding()]
	param
	(
		[ValidateNotNullOrEmpty()]$Updates
	)
	
	if ($WindowsRepository[$WindowsRepository.Length - 1] -ne "\") {
		$Repository = $WindowsRepository + "\"
	} else {
		$Repository = $WindowsRepository
	}
	foreach ($Update in $Updates.Updates.Update) {
		
		If ($Update.type -eq "Application") {
			
			$UpdateFile = $Repository + $Update.Release + "\" + (($Update.file).split("/")[-1])
			
			If ((Test-Path $UpdateFile) -eq $true) {
				$Output = "Installing " + $Update.name + "....."
				Write-Host $Output -NoNewline
				
				$Switches = "/s"
				$ErrCode = (Start-Process -FilePath $UpdateFile -ArgumentList $Switches -WindowStyle Minimized -Wait -Passthru).ExitCode
				If (($ErrCode -eq 0) -or ($ErrCode -eq 3010)) {
					Write-Host "Success" -ForegroundColor Yellow
				} else {
					Write-Host "Failed" -ForegroundColor Red
				}
			}
		}
	}
}

function Update-BIOS {

	
	[CmdletBinding()]
	param
	(
		[ValidateNotNullOrEmpty()]$Updates
	)
	
	
	If ((test-path -Path 'REGISTRY::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\WinPE\') -eq $true) {
		If ($WinPERepository[$WinPERepository.Length - 1] -ne "\") {
			$Repository = $WinPERepository + "\"
		} else {
			$Repository = $WinPERepository
		}
	} elseif ($WindowsRepository[$WindowsRepository.Length - 1] -ne "\") {
		$Repository = $WindowsRepository + "\"
	} else {
		$Repository = $WindowsRepository
	}
	foreach ($Update in $Updates.Updates.Update) {
		
		If ($Update.type -eq "BIOS") {
			
			$UpdateFile = $Repository + $Update.Release + "\" + (($Update.file).split("/")[-1])
			
			If ((Test-Path $UpdateFile) -eq $true) {
				$Output = "Installing " + $Update.name + "....."
				Write-Host $Output -NoNewline
				
				$Switches = "/s /p=" + $BIOSPassword
				$ErrCode = (Start-Process -FilePath $UpdateFile -ArgumentList $Switches -WindowStyle Minimized -Wait -Passthru).ExitCode
				If (($ErrCode -eq 0) -or ($ErrCode -eq 2) -or ($ErrCode -eq 3010)) {
					Write-Host "Success" -ForegroundColor Yellow
				} else {
					Write-Host "Failed" -ForegroundColor Red
				}
			}
		}
	}
}

function Update-Drivers {

	
	[CmdletBinding()]
	param
	(
		[ValidateNotNullOrEmpty()]$Updates
	)
	
	if ($WindowsRepository[$WindowsRepository.Length - 1] -ne "\") {
		$Repository = $WindowsRepository + "\"
	} else {
		$Repository = $WindowsRepository
	}
	foreach ($Update in $Updates.Updates.Update) {
		
		If ($Update.type -eq "Driver") {
			
			$UpdateFile = $Repository + $Update.Release + "\" + (($Update.file).split("/")[-1])
			$UpdateFile = Get-ChildItem -Path $UpdateFile
			
			If ((Test-Path $UpdateFile) -eq $true) {
				$Output = "Installing " + $Update.name + "....."
				Write-Host $Output -NoNewline
				
				$Switches = "/s"
				$ErrCode = (Start-Process -FilePath $UpdateFile.Fullname -ArgumentList $Switches -WindowStyle Minimized -Passthru).ExitCode
				$Start = Get-Date
				Do {
					$Process = (Get-Process | Where-Object { $_.ProcessName -eq $UpdateFile.BaseName }).ProcessName
					$Duration = (Get-Date - $Start).TotalMinutes
				} While (($Process -eq $UpdateFile.BaseName) -and ($Duration -lt 10))
				If (($ErrCode -eq 0) -or ($ErrCode -eq 2) -or ($ErrCode -eq 3010)) {
					Write-Host "Success" -ForegroundColor Yellow
				} else {
					Write-Host "Failed with error code $ErrCode" -ForegroundColor Red
				}
			}
		}
	}
}


Clear-Host

If ((test-path -Path 'REGISTRY::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\WinPE\') -eq $true) {
	$Updates = Get-WinPEUpdateReport
} Else {
	
	$Updates = Get-WindowsUpdateReport
}
$Updates.Updates.Update.Name

If ($Updates -ne $null) {
	Update-Repository -Updates $Updates
}

If ((test-path -Path 'REGISTRY::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\WinPE\') -eq $true) {
	
	Update-BIOS -Updates $Updates
} Else {
	
	If (($Applications.IsPresent) -or ((!($Applications.IsPresent)) -and (!($BIOS.IsPresent)) -and (!($Drivers.IsPresent)))) {
		Update-Applicatons -Updates $Updates
	}
	
	If (($BIOS.IsPresent) -or ((!($Applications.IsPresent)) -and (!($BIOS.IsPresent)) -and (!($Drivers.IsPresent)))) {
		Update-BIOS -Updates $Updates
	}
	
	
	If (($Drivers.IsPresent) -or ((!($Applications.IsPresent)) -and (!($BIOS.IsPresent)) -and (!($Drivers.IsPresent)))) {
		Update-Drivers -Updates $Updates
	}
	
	
}
