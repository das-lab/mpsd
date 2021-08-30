
[CmdletBinding()]
param
(
		[ValidateNotNullOrEmpty()][string]$ReportFile = 'Applications.csv',
		[ValidateNotNullOrEmpty()][string]$ReportFileLocation = 'c:\windows\waller'
)


function Get-AddRemovePrograms {

	
	[CmdletBinding()][OutputType([string])]
	param ()
	
	$Architecture = Get-Architecture
	if ($Architecture -eq "32-bit") {
		$Applications = Get-ChildItem -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\" | ForEach-Object -Process { $_.GetValue("DisplayName") }
	} else {
		$Applicationsx86 = Get-ChildItem -Path "HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\" | ForEach-Object -Process { $_.GetValue("DisplayName") }
		$Applicationsx64 = Get-ChildItem -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\" | ForEach-Object -Process { $_.GetValue("DisplayName") }
		$Applications = $Applicationsx86 + $Applicationsx64
	}
	$Applications = $Applications | Sort-Object
	$Applications = $Applications | Select-Object -Unique
	Return $Applications
}

function Get-Architecture {

	
	[CmdletBinding()][OutputType([string])]
	param ()
	
	$OSArchitecture = Get-WmiObject -Class Win32_OperatingSystem | Select-Object OSArchitecture
	$OSArchitecture = $OSArchitecture.OSArchitecture
	Return $OSArchitecture
}

function Get-RelativePath {

	
	[CmdletBinding()][OutputType([string])]
	param ()
	
	$Path = (split-path $SCRIPT:MyInvocation.MyCommand.Path -parent) + "\"
	Return $Path
}

function New-LogFile {

	
	[CmdletBinding()]
	param ()
	
	If ($ReportFileLocation[$ReportFileLocation.Count - 1] -eq '\') {
		$File = $ReportFileLocation + $ReportFile
	} else {
		$File = $ReportFileLocation + '\' + $ReportFile
	}
	if ((Test-Path $File) -eq $true) {
		Remove-Item -Path $File -Force | Out-Null
	}
	if ((Test-Path $File) -eq $false) {
		New-Item -Path $File -ItemType file -Force | Out-Null
	}
}

function New-Report {

	
	param
	(
			[ValidateNotNullOrEmpty()][object]$Applications
	)
	
	If ($ReportFileLocation[$ReportFileLocation.Count - 1] -eq '\') {
		$File = $ReportFileLocation + $ReportFile
	} else {
		$File = $ReportFileLocation + '\' + $ReportFile
	}
	If ((Test-Path $File) -eq $true) {
		$Applications
		Out-File -FilePath $File -InputObject $Applications -Append -Force -Encoding UTF8
	} else {
		Write-Host "Report File not present to generate report" -ForegroundColor Red
	}
}

function Update-AppList {

	
	[CmdletBinding()][OutputType([object])]
	param
	(
			[ValidateNotNullOrEmpty()][object]$Applications
	)
	
	$RelativePath = Get-RelativePath
	$File = $RelativePath + "ExclusionList.txt"
	If ((Test-Path $File) -eq $true) {
		$Exclusions = Get-Content -Path $File
		$SortedExclusions = $Exclusions | Sort-Object
		$SortedExclusions = $SortedExclusions | Select-Object -Unique
		$Sorted = !(Compare-Object $Exclusions $SortedExclusions -SyncWindow 0)
		If ($Sorted -eq $false) {
			Do {
				Try {
					$Exclusions = Get-Content -Path $File
					$SortedExclusions = $Exclusions | Sort-Object
					$SortedExclusions = $SortedExclusions | Select-Object -Unique
					$Sorted = !(Compare-Object $Exclusions $SortedExclusions -SyncWindow 0)
					If ($Sorted -eq $false) {
						Out-File -FilePath $File -InputObject $SortedExclusions -Force -Encoding UTF8 -ErrorAction SilentlyContinue
					}
					$Success = $true
				} Catch {
					$Success = $false
				}
			}
			while ($Success -eq $false)
		}
		$Applications = $Applications | Where-Object { ($_ -notin $SortedExclusions) -and ($_ -ne "") -and ($_ -ne $null) }
	}
	Return $Applications
}

Clear-Host
New-LogFile
$Apps = Get-AddRemovePrograms
$Apps = Update-AppList -Applications $Apps
New-Report -Applications $Apps
