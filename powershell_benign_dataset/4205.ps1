
[CmdletBinding()]
param
(
	[String]$ComputerName,
	[switch]$Rawdata,
	[ValidateNotNullOrEmpty()][string]$Username
)

function Get-FilteredData {

	
	[CmdletBinding()]
	param
	(
		[ValidateNotNullOrEmpty()]$LogonType,
		[ValidateNotNullOrEmpty()][string]$Message,
		[ValidateNotNullOrEmpty()]$Logons
	)
	
	$Errors = $false
	Write-Host $Message"....." -NoNewline
	Try {
		$Data = $Logons | Where-Object { $_.Message -like "*Logon Type*"+[char]9+[char]9+$LogonType+"*" }
	} catch {
		$Errors = $true
	}
	If ($Errors -eq $false) {
		Write-Host "Success" -ForegroundColor Yellow
	} else {
		Write-Host "Failed" -ForegroundColor Red
	}
	Return $Data
}

function Get-SID {

	
	[CmdletBinding()][OutputType([string])]
	param ()
	
	Write-Host "Retrieving SID for $Username....." -NoNewline
	If ($ComputerName -eq ".") {
		
		$SID = (get-childitem -path REGISTRY::"HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\ProfileList" | Where-Object { $_.Name -like "*S-1-5-21*" } | ForEach-Object { Get-ItemProperty REGISTRY::$_ } | Where-Object { $_.ProfileImagePath -like "*$Username*" }).PSChildName
	} else {
		$HKEY_LOCAL_MACHINE = 2147483650
		$Key = "SOFTWARE\Microsoft\Windows NT\CurrentVersion\ProfileList"
		$RegClass = Get-WMIObject -Namespace "Root\Default" -List -ComputerName $ComputerName | Where-object { $_.Name -eq "StdRegProv" }
		$Value = "ProfileImagePath"
		$SID = ($RegClass.EnumKey($HKEY_LOCAL_MACHINE, $Key)).sNames | Where-Object { $_ -like "*S-1-5-21*" } | ForEach-Object {
			If (($RegClass.GetStringValue($HKEY_LOCAL_MACHINE, $Key + "\" + $_, $Value)).sValue -like "*" + $Username + "*") {
				$_
			}
		}
	}
	If (($SID -ne "") -and ($SID -ne $null)) {
		Write-Host "Success" -ForegroundColor Yellow
	} else {
		Write-Host "Failed" -ForegroundColor Red
	}
	Return $SID
}

function Get-RelativePath {

	
	[CmdletBinding()][OutputType([string])]
	param ()
	
	$Path = (split-path $SCRIPT:MyInvocation.MyCommand.Path -parent) + "\"
	Return $Path
}

function New-Report {

	
	[CmdletBinding()]
	param
	(
		$Keyboard,
		$Unlock,
		$Remote,
		$Cached
	)
	
	$RelativePath = Get-RelativePath
	
	$FileName = $RelativePath + "$Username.csv"
	
	If ((Test-Path $FileName) -eq $true) {
		Write-Host "Deleting $Username.csv....." -NoNewline
		Remove-Item -Path $FileName -Force
		If ((Test-Path $FileName) -eq $false) {
			Write-Host "Success" -ForegroundColor Yellow
		} else {
			Write-Host "Failed" -ForegroundColor Red
		}
	}
	Write-Host "Generating $Username.csv report file....." -NoNewline
	
	"Logon Type,Date/Time" | Out-File -FilePath $FileName -Encoding UTF8 -Force
	$Errors = $false
	
	foreach ($Logon in $Keyboard) {
		$Item = "Keyboard," + [string]$Logon.TimeCreated
		try {
			$Item | Out-File -FilePath $FileName -Encoding UTF8 -Append -Force
		} catch {
			$Errors = $true
		}
	}
	
	foreach ($Logon in $Unlock) {
		$Item = "Unlock," + [string]$Logon.TimeCreated
		Try {
			$Item | Out-File -FilePath $FileName -Encoding UTF8 -Append -Force
		} catch {
			$Errors = $true
		}
	}
	
	foreach ($Logon in $Remote) {
		$Item = "Remote," + [string]$Logon.TimeCreated
		Try {
			$Item | Out-File -FilePath $FileName -Encoding UTF8 -Append -Force
		} catch {
			$Errors = $true
		}
	}
	
	foreach ($Logon in $Cached) {
		$Item = "Cached," + [string]$Logon.TimeCreated
		Try {
			$Item | Out-File -FilePath $FileName -Encoding UTF8 -Append -Force
		} catch {
			$Errors = $true
		}
	}
	If ($Errors -eq $false) {
		Write-Host "Success" -ForegroundColor Yellow
	} else {
		Write-Host "Failed" -ForegroundColor Red
	}
}

function Get-LogonLogs {

	
	[CmdletBinding()]
	param
	(
		[ValidateNotNullOrEmpty()]$SID
	)
	
	If ($ComputerName -ne ".") {
		Write-Host "Retrieving all logon logs for $Username on $ComputerName....." -NoNewline
	} else {
		Write-Host "Retrieving all logon logs for $Username on $env:COMPUTERNAME....." -NoNewline
	}
	$Errors = $false
	Try {
		If ($ComputerName -ne ".") {
			$AllLogons = Get-WinEvent -FilterHashtable @{ logname = 'security'; ID = 4624 } -ComputerName $ComputerName | where-object { ($_.properties.value -like "*$SID*") }
		} else {
			$AllLogons = Get-WinEvent -FilterHashtable @{ logname = 'security'; ID = 4624 } | where-object { ($_.properties.value -like "*$SID*") }
		}
	} catch {
		$Errors = $true
	}
	If ($Errors -eq $false) {
		Write-Host "Success" -ForegroundColor Yellow
	} else {
		Write-Host "Failed" -ForegroundColor Red
	}
	Return $AllLogons
}




Clear-Host
If (($ComputerName -eq "") -or ($ComputerName -eq $null)) {
	$ComputerName = "."
}
$SID = Get-SID

$AllLogons = Get-LogonLogs -SID $SID

$KeyboardLogons = Get-FilteredData -Logons $AllLogons -LogonType "2" -Message "Filtering keyboard logons"

$Unlock = Get-FilteredData -Logons $AllLogons -LogonType "7" -Message "Filtering system unlocks"

$Remote = Get-FilteredData -Logons $AllLogons -LogonType "10" -Message "Filtering remote accesses"

$CachedCredentials = Get-FilteredData -Logons $AllLogons -LogonType "11" -Message "Filtering cached logins"

If ($Rawdata.IsPresent) {
	$RelativePath = Get-RelativePath
	
	$FileName = $RelativePath + "$Username.txt"
	
	If ((Test-Path $FileName) -eq $true) {
		Write-Host "Deleting $Username.txt....." -NoNewline
		Remove-Item -Path $FileName -Force
		If ((Test-Path $FileName) -eq $false) {
			Write-Host "Success" -ForegroundColor Yellow
		} else {
			Write-Host "Failed" -ForegroundColor Red
		}
	}
	Write-Host "Generating raw data file....." -NoNewline
	foreach ($Logon in $AllLogons) {
		[string]$Logon.TimeCreated | Out-File -FilePath $FileName -Encoding UTF8 -Append -Force
		$Logon.Message | Out-File -FilePath $FileName -Encoding UTF8 -Append -Force
		" " | Out-File -FilePath $FileName -Encoding UTF8 -Append -Force
		"----------------------------------------------------------------------------------------------------------------------------------------------------------------" | Out-File -FilePath $FileName -Encoding UTF8 -Append -Force
		"----------------------------------------------------------------------------------------------------------------------------------------------------------------" | Out-File -FilePath $FileName -Encoding UTF8 -Append -Force
		" " | Out-File -FilePath $FileName -Encoding UTF8 -Append -Force
	}
	If ((Test-Path $FileName) -eq $true) {
		Write-Host "Success" -ForegroundColor Yellow
	} else {
		Write-Host "Failed" -ForegroundColor Red
	}
} else {
	New-Report -Keyboard $KeyboardLogons -Unlock $Unlock -Remote $Remote -Cached $CachedCredentials
}
