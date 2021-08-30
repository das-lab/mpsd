
[CmdletBinding()]
param
(
	[switch]$Logging,
	[string]$LogLocation
)
function Get-Architecture {

	
	[CmdletBinding()][OutputType([string])]
	param ()
	
	$OSArchitecture = (Get-WmiObject -Class Win32_OperatingSystem | Select-Object OSArchitecture).OSArchitecture
	Return $OSArchitecture
	
}

function Get-DellCommandUpdateLocation {

	
	[CmdletBinding()][OutputType([string])]
	param ()
	
	$Architecture = Get-Architecture
	If ($Architecture -eq "32-bit") {
		$File = Get-ChildItem -Path $env:ProgramFiles -Filter "dcu-cli.exe" -ErrorAction SilentlyContinue -Recurse
	} else {
		$File = Get-ChildItem -Path ${env:ProgramFiles(x86)} -Filter "dcu-cli.exe" -ErrorAction SilentlyContinue -Recurse
	}
	Return $File.FullName
}

function Invoke-DriverUpdate {

	
	[CmdletBinding()]
	param
	(
		[ValidateNotNullOrEmpty()]$Executable
	)
	
	If ($Logging.IsPresent) {
		$Model = (Get-WmiObject -Class Win32_ComputerSystem).Model
		If ($LogLocation[$LogLocation.Length - 1] -ne "\") {
			$Location = $LogLocation + "\" + $Model
		} else {
			$Location = $LogLocation + $Model
		}
		If ((Test-Path $LogLocation) -eq $false) {
			New-Item -Path $LogLocation -ItemType Directory -Force | Out-Null
		}
		If ((Test-Path $Location) -eq $false) {
			New-Item -Path $Location -ItemType Directory -Force | Out-Null
		}
		$Location += "\" + $env:COMPUTERNAME
		If ((Test-Path $Location) -eq $true) {
			Remove-Item -Path $Location -Recurse -Force
		}
		$Arguments = "/log" + [char]32 + [char]34 + $Location + [char]34
	} else {
		$Arguments = [char]32
	}
	Start-Process -FilePath $Executable -ArgumentList $Arguments -Wait -Passthru | Out-Null
}


Clear-Host

$EXE = Get-DellCommandUpdateLocation

Invoke-DriverUpdate -Executable $EXE
