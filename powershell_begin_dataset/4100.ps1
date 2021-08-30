
[CmdletBinding()]
param
(
	[ValidateNotNullOrEmpty()][string]$FilePath
)

function Get-Architecture {

	
	[CmdletBinding()][OutputType([string])]
	param ()
	
	$OSArchitecture = (Get-WmiObject -Class Win32_OperatingSystem | Select-Object OSArchitecture).OSArchitecture
	Return $OSArchitecture
	
}

function Get-RelativePath {

	
	[CmdletBinding()][OutputType([string])]
	param ()
	
	$Path = (split-path $SCRIPT:MyInvocation.MyCommand.Path -parent) + "\"
	Return $Path
}

function Get-CCTK {

	
	[CmdletBinding()]
	param ()
	
	$Architecture = Get-Architecture
	If ($Architecture -eq "64-bit") {
		$Directory = ${env:ProgramFiles(x86)} + "\Dell\"
		$File = Get-ChildItem -Path $Directory -Filter cctk.exe -Recurse | Where-Object { $_.Directory -like "*_64*" }
	} else {
		$Directory = $env:ProgramFiles + "\Dell\"
		$File = Get-ChildItem -Path $Directory -Filter cctk.exe -Recurse | Where-Object { $_.Directory -like "*x86" }
	}
	Return $File
}

function Get-ListOfBIOSSettings {

	
	[CmdletBinding()]
	param
	(
		[ValidateNotNullOrEmpty()]$Executable
	)
	
	
	$RelativePath = Get-RelativePath
	
	$File = $RelativePath + "BIOSExclusions.txt"
	$BIOSExclusions = Get-Content -Path $File | Sort-Object
	
	$BIOSExclusions | Out-File -FilePath $File -Force
	
	$Output = cmd.exe /c $Executable.FullName
	
	$Output = $Output | Where-Object { $_ -like "*--*" } | Where-Object { $_ -notlike "*cctk*" }
	
	$Output = ($Output.split("--") | Where-Object { $_ -notlike "*or*" } | Where-Object{ $_.trim() -ne "" }).Trim() | Where-Object { $_ -notlike "*help*" } | Where-Object { $_ -notlike "*version*" } | Where-Object { $_ -notlike "*infile*" } | Where-Object { $_ -notlike "*logfile*" } | Where-Object { $_ -notlike "*outfile*" } | Where-Object { $_ -notlike "*ovrwrt*" } | Where-Object { $_ -notlike "*setuppwd*" } | Where-Object { $_ -notlike "*sysdefaults*" } | Where-Object { $_ -notlike "*syspwd*" } | ForEach-Object { $_.Split("*")[0] } | Where-Object { $_ -notin $BIOSExclusions }
	
	$Output = $Output + "bootorder" | Sort-Object
	Return $Output
}

function Get-BIOSSettings {

	
	[CmdletBinding()]
	param
	(
		[ValidateNotNullOrEmpty()]$Settings,
		[ValidateNotNullOrEmpty()]$Executable
	)
	
	
	$BIOSArray = @()
	foreach ($Setting in $Settings) {
		switch ($Setting) {
			"advbatterychargecfg" {
				$Arguments = [char]34 + $Executable.FullName + [char]34 + [char]32 + "--" + $Setting
				$Value = (cmd.exe /c $Arguments).split("=")[1]
				$Arguments = [char]34 + $Executable.FullName + [char]34 + [char]32 + "-h" + [char]32 + "--" + $Setting
				$Description = (cmd.exe /c $Arguments | Where-Object { $_.trim() -ne "" }).split(":")[1].Trim()
			}
			"advsm" {
				$Value = ""
				$Arguments = [char]34 + $Executable.FullName + [char]34 + [char]32 + "-h" + [char]32 + $Setting
				$Description = ((cmd.exe /c $Arguments) | where-object {$_.trim() -ne ""}).split(":")[1].Trim().split(".")[0]
			}
			"bootorder" {
				$Arguments = [char]34 + $Executable.FullName + [char]34 + [char]32 + $Setting
				$Output = (((((cmd.exe /c $Arguments | Where-Object { $_ -like "*Enabled*" } | Where-Object { $_ -notlike "*example*" }) -replace 'Enabled', '').Trim()) -replace '^\d+', '').Trim()) | ForEach-Object { ($_ -split ' {2,}')[1] }
				$Output2 = "bootorder="
				foreach ($item in $Output) {
					[string]$Output2 += [string]$item + ","
				}
				$Value = $Output2.Substring(0,$Output2.Length-1)
				$Arguments = [char]34 + $Executable.FullName + [char]34 + [char]32 + "-h" + [char]32 + $Setting
				$Description = ((cmd.exe /c $Arguments) | where-object { $_.trim() -ne "" }).split(":")[1].Trim().split(".")[0]
			}
			"hddinfo" {
				$Value = ""
				$Arguments = [char]34 + $Executable.FullName + [char]34 + [char]32 + "-h" + [char]32 + $Setting
				$Description = ((cmd.exe /c $Arguments) | where-object {$_.trim() -ne ""}).split(":")[1].trim().split(".")[0]
			}
			"hddpwd" {
				$Value = ""
				$Arguments = [char]34 + $Executable.FullName + [char]34 + [char]32 + "-h" + [char]32 + $Setting
				$Description = ((cmd.exe /c $Arguments) | Where-Object {$_.trim() -ne ""}).split(":")[1].split(".")[0].trim()
			}
			"pci" {
				$Value = ""
				$Arguments = [char]34 + $Executable.FullName + [char]34 + [char]32 + "-h" + [char]32 + $Setting
				$Description = ((cmd.exe /c $Arguments) | Where-Object { $_.trim() -ne "" }).split(":")[1].split(".")[0].trim()
			}
			"propowntag" {
				$Arguments = [char]34 + $Executable.FullName + [char]34 + [char]32 + "--" + $Setting
				$Value = ((cmd.exe /c $Arguments).split("=")[1]).trim()
				$Arguments = [char]34 + $Executable.FullName + [char]34 + [char]32 + "-h" + [char]32 + $Setting
				$Description = ((cmd.exe /c $Arguments) | Where-Object { $_.trim() -ne "" }).split(":")[1].trim()
			}
			"secureboot" {
				$Arguments = [char]34 + $Executable.FullName + [char]34 + " --" + $Setting
				$Output = cmd.exe /c $Arguments
				if ($Output -like "*not enabled*") {
					$Value = "disabled"
				} else {
					$Value = "enabled"
				}
				$Arguments = [char]34 + $Executable.FullName + [char]34 + [char]32 + "-h" + [char]32 + $Setting
				$Description = ((cmd.exe /c $Arguments) | where-object { $_.trim() -ne "" }).split(":")[1].Trim().split(".")[0]
			}
			default {
				
				$Output = $null
				$Arguments = [char]34 + $Executable.FullName + [char]34 + [char]32 + "--" + $Setting
				$Output = cmd.exe /c $Arguments
				
				$Arguments = [char]34 + $Executable.FullName + [char]34 + [char]32 + "-h" + [char]32 + "--" + $Setting
				$Description = ((cmd.exe /c $Arguments) | Where-Object { $_.trim() -ne "" }).split(":").Trim()[1]
				$Value = $Output.split("=")[1]
			}
		}
		
		$objBIOS = New-Object System.Object
		$objBIOS | Add-Member -MemberType NoteProperty -Name Setting -Value $Setting
		$objBIOS | Add-Member -MemberType NoteProperty -Name Value -Value $Value
		$objBIOS | Add-Member -MemberType NoteProperty -Name Description -Value $Description
		$BIOSArray += $objBIOS
	}
	Return $BIOSArray
}

$CCTK = Get-CCTK

$BIOSList = Get-ListOfBIOSSettings -Executable $CCTK

$BIOSSettings = Get-BIOSSettings -Executable $CCTK -Settings $BIOSList

$FileName = ((Get-WmiObject -Class win32_computersystem -Namespace root\cimv2).Model).Trim()

$FileName += [char]32 + ((Get-WmiObject -Class win32_bios -Namespace root\cimv2).SMBIOSBIOSVersion).Trim() + ".CSV"

If ($FilePath[$FilePath.Length - 1] -ne "\") {
	$FileName = $FilePath + "\" + $FileName
} else {
	$FileName = $FilePath + $FileName
}

If ((Test-Path $FileName) -eq $true) {
	Remove-Item -Path $FileName -Force
}

$BIOSSettings

$BIOSSettings | Export-Csv -Path $FileName -NoTypeInformation -Force
