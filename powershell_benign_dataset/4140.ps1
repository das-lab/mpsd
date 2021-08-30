
[CmdletBinding()]
param
(
	[ValidateNotNullOrEmpty()][string]$Application,
	[ValidateNotNullOrEmpty()][string]$LogFileName,
	[string]$LogFileLocation,
	[switch]$ExactFileName
)

function New-LogFile {

	
	[CmdletBinding()]
	param
	(
		[ValidateNotNullOrEmpty()][string]$Log
	)
	
	
	$LogFile = Get-ChildItem -Path $LogFileLocation -Filter $LogFileName -ErrorAction SilentlyContinue
	Write-Output "Log File Name: $LogFile"
	$Output = "LogFile Creation Date: " + $LogFile.CreationTime
	Write-Output $Output
	If ($LogFile -ne $null) {
		$OSInstallDate = Get-WmiObject Win32_OperatingSystem | ForEach-Object{ $_.ConvertToDateTime($_.InstallDate) -f "MM/dd/yyyy" }
		Write-Output "        OS Build Date: $OSInstallDate"
		If ($LogFile.CreationTime -lt $OSInstallDate) {
			
			Remove-Item -Path $LogFile.FullName -Force | Out-Null
			
			New-Item -Path $Log -ItemType File -Force | Out-Null
			
			Add-Content -Path $Log -Value "Application,Version,TimeStamp,Installation"
		}
	} else {
		
		New-Item -Path $Log -ItemType File -Force | Out-Null
		
		Add-Content -Path $Log -Value "Application,Version,TimeStamp,Installation"
	}
}

Clear-Host

If (($LogFileName -eq $null) -or ($LogFileName -eq "")) {
	If ($LogFileName -notlike "*.csv*") {
		$LogFileName += ".csv"
	} else {
		$LogFileName = "$env:COMPUTERNAME.csv"
	}
} elseIf ($LogFileName -notlike "*.csv*") {
		$LogFileName += ".csv"
}

If ($LogFileLocation[$LogFileLocation.Length - 1] -ne "\") {
	$File = $LogFileLocation + "\" + $LogFileName
} else {
	$File = $LogFileLocation + $LogFileName
}

New-LogFile -Log $File

$Uninstall = Get-ChildItem -Path REGISTRY::"HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall" -Force -ErrorAction SilentlyContinue
$Uninstall += Get-ChildItem -Path REGISTRY::"HKEY_LOCAL_MACHINE\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall" -Force -ErrorAction SilentlyContinue

If ($ExactFileName.IsPresent) {
	$ApplicationInstall = $Uninstall | ForEach-Object { Get-ItemProperty $_.PsPath } | Where-Object { $_.DisplayName -eq $Application }
} else {
	$ApplicationInstall = $Uninstall | ForEach-Object { Get-ItemProperty $_.PsPath } | Where-Object { $_.DisplayName -like "*" + $Application + "*" }
}

If ($ApplicationInstall.length -gt 1) {
	$Size = 0
	for ($i = 0; $i -lt $ApplicationInstall.length; $i++) {
		If (([string]$ApplicationInstall[$i]).length -gt $Size) {
			$Size = ([string]$ApplicationInstall[$i]).length
			$Temp = $ApplicationInstall[$i]
		}
	}
	$ApplicationInstall = $Temp
}

If ($ApplicationInstall -ne $null) {
	$InstallDate = (($ApplicationInstall.InstallDate + "/" + $ApplicationInstall.InstallDate.substring(0, 4)).Substring(4)).Insert(2, "/")
	$Output = $ApplicationInstall.DisplayName + "," + $ApplicationInstall.Version + "," + $InstallDate + "," + "Success"
	Add-Content -Path $File -Value $Output
	Write-Host "Exit Code: 0"
	Exit 0
} else {
	$Output = $Application + "," + "," + "," + "Failed"
	Add-Content -Path $File -Value $Output
	Write-Host "Exit Code: 1"
	Exit 1
}
