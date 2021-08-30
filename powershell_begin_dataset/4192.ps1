

[CmdletBinding()]
param ()

function Close-Process {

	
	[CmdletBinding()][OutputType([boolean])]
	param
	(
		[ValidateNotNullOrEmpty()][string]$ProcessName
	)
	
	$Process = Get-Process -Name $ProcessName -ErrorAction SilentlyContinue
	If ($Process -ne $null) {
		$Output = "Stopping " + $Process.Name + " process....."
		Stop-Process -Name $Process.Name -Force -ErrorAction SilentlyContinue
		Start-Sleep -Seconds 1
		$TestProcess = Get-Process $ProcessName -ErrorAction SilentlyContinue
		If ($TestProcess -eq $null) {
			$Output += "Success"
			Write-Host $Output
			Return $true
		} else {
			$Output += "Failed"
			Write-Host $Output
			Return $false
		}
	} else {
		Return $true
	}
}

function Get-RelativePath {

	
	[CmdletBinding()][OutputType([string])]
	param ()
	
	$Path = (split-path $SCRIPT:MyInvocation.MyCommand.Path -parent) + "\"
	Return $Path
}

function Open-Application {

	
	[CmdletBinding()]
	param
	(
		[string]$Executable,
		[ValidateNotNullOrEmpty()][string]$ApplicationName
	)
	
	$Architecture = Get-Architecture
	$Uninstall = Get-ChildItem -Path REGISTRY::"HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall"
	If ($Architecture -eq "64-bit") {
		$Uninstall += Get-ChildItem -Path REGISTRY::"HKEY_LOCAL_MACHINE\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall"
	}
	$InstallLocation = ($Uninstall | ForEach-Object { Get-ItemProperty $_.PsPath } | Where-Object { $_.DisplayName -eq $ApplicationName }).InstallLocation
	If ($InstallLocation[$InstallLocation.Length - 1] -ne "\") {
		$InstallLocation += "\"
	}
	$Process = ($Executable.Split("."))[0]
	$Output = "Opening $ApplicationName....."
	Start-Process -FilePath $InstallLocation$Executable -ErrorAction SilentlyContinue
	Start-Sleep -Seconds 5
	$NewProcess = Get-Process $Process -ErrorAction SilentlyContinue
	If ($NewProcess -ne $null) {
		$Output += "Success"
	} else {
		$Output += "Failed"
	}
	Write-Output $Output
}

function Remove-ChatFiles {

	
	[CmdletBinding()]
	param ()
	
	
	$ChatHistoryFiles = Get-ChildItem -Path $env:USERPROFILE'\AppData\Local\Cisco\Unified Communications\Jabber\CSF\History' -Filter *.db
	If ($ChatHistoryFiles -ne $null) {
		foreach ($File in $ChatHistoryFiles) {
			$Output = "Deleting " + $File.Name + "....."
			Remove-Item -Path $File.FullName -Force | Out-Null
			If ((Test-Path $File.FullName) -eq $false) {
				$Output += "Success"
			} else {
				$Output += "Failed"
			}
		}
		Write-Output $Output
	} else {
		$Output = "No Chat History Present"
		Write-Output $Output
	}
}

function Remove-MyJabberFilesFolder {

	
	[CmdletBinding()]
	param ()
	
	$MyJabberFilesFolder = Get-Item $env:USERPROFILE'\Documents\MyJabberFiles' -ErrorAction SilentlyContinue
	If ($MyJabberFilesFolder -ne $null) {
		$Output = "Deleting " + $MyJabberFilesFolder.Name + "....."
		Remove-Item -Path $MyJabberFilesFolder -Recurse -Force | Out-Null
		If ((Test-Path $MyJabberFilesFolder.FullName) -eq $false) {
			$Output += "Success"
		} else {
			$Output += "Failed"
		}
		Write-Output $Output
	} else {
		$Output = "No MyJabberFiles folder present"
		Write-Output $Output
	}
}

function Set-DBFilePermissions {

	
	[CmdletBinding()]
	param ()
	
	
	$ChatHistoryFiles = Get-ChildItem -Path $env:USERPROFILE'\AppData\Local\Cisco\Unified Communications\Jabber\CSF\History' -Filter *.db
	foreach ($File in $ChatHistoryFiles) {
		
		$Output = "Setting " + $File.Name + " to Read-Only....."
		$ReadOnly = Get-ItemPropertyValue -Path $File.FullName -Name IsReadOnly
		If (($ReadOnly) -eq $false) {
			Set-ItemProperty -Path $File.FullName -Name IsReadOnly -Value $true
			$ReadOnly = Get-ItemPropertyValue -Path $File.FullName -Name IsReadOnly
			If (($ReadOnly) -eq $true) {
				$Output += "Success"
			} else {
				$Output += "Failed"
			}
		} else {
			$Output += "Success"
		}
		Write-Output $Output
	}
}

Clear-Host

$JabberClosed = Close-Process -ProcessName CiscoJabber

Remove-ChatFiles

Remove-MyJabberFilesFolder

If ($JabberClosed -eq $true) {
	Open-Application -ApplicationName "Cisco Jabber" -Executable CiscoJabber.exe
}
$JabberClosed = Close-Process -ProcessName CiscoJabber

Set-DBFilePermissions

If ($JabberClosed -eq $true) {
	Open-Application -ApplicationName "Cisco Jabber" -Executable CiscoJabber.exe
}
