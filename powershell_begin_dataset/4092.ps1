
[CmdletBinding()]
param
(
	[switch]
	$Balanced,
	[string]
	$ConsoleTitle = 'PowerScheme',
	[string]
	$Custom,
	[switch]
	$HighPerformance,
	[string]
	$ImportPowerSchemeFile,
	[switch]
	$PowerSaver,
	[string]
	$PowerSchemeName,
	[switch]
	$Report,
	[ValidateSet('MonitorTimeoutAC', 'MonitorTimeoutDC', 'DiskTimeoutAC', 'DiskTimeoutDC', 'StandbyTimeoutAC', 'StandbyTimeoutDC', 'HibernateTimeoutAC', 'HibernateTimeoutDC')][string]
	$SetPowerSchemeSetting,
	[string]
	$SetPowerSchemeSettingValue,
	[switch]
	$SetImportedPowerSchemeDefault
)

function Get-PowerScheme {

	
	[CmdletBinding()][OutputType([object])]
	param ()
	
	
	$Query = powercfg.exe /getactivescheme
	
	$ActiveSchemeName = ($Query.Split("()").Trim())[1]
	
	$ActiveSchemeGUID = ($Query.Split(":(").Trim())[1]
	$Query = powercfg.exe /query $ActiveSchemeGUID
	$GUIDAlias = ($Query | where { $_.Contains("GUID Alias:") }).Split(":")[1].Trim()
	$Scheme = New-Object -TypeName PSObject
	$Scheme | Add-Member -Type NoteProperty -Name PowerScheme -Value $ActiveSchemeName
	$Scheme | Add-Member -Type NoteProperty -Name GUIDAlias -Value $GUIDAlias
	$Scheme | Add-Member -Type NoteProperty -Name GUID -Value $ActiveSchemeGUID
	Return $Scheme
}

function Get-PowerSchemeSubGroupSettings {

	
	[CmdletBinding()]
	param
	(
		[ValidateNotNullOrEmpty()]$Subgroup,
		[ValidateNotNullOrEmpty()][object]
		$ActivePowerScheme
	)
	
	$Query = powercfg.exe /query $ActivePowerScheme.GUID $Subgroup.GUID
	$Query = $Query | where { ((!($_.Contains($ActivePowerScheme.GUID))) -and (!($_.Contains($ActivePowerScheme.GUIDAlias)))) }
	$Settings = @()
	For ($i = 0; $i -lt $Query.Length; $i++) {
		If ($Query[$i] -like "*Power Setting GUID:*") {
			$Setting = New-Object System.Object
			
			$SettingName = $Query[$i].Split("()").Trim()
			$SettingName = $SettingName[1]
			
			If ($Query[$i + 1] -like "*GUID Alias:*") {
				$SettingAlias = $Query[$i + 1].Split(":").Trim()
				$SettingAlias = $SettingAlias[1]
			} else {
				$SettingAlias = $null
			}
			
			$SettingGUID = $Query[$i].Split(":(").Trim()
			$SettingGUID = $SettingGUID[1]
			
			$j = $i
			Do {
				$j++
			}
			while ($Query[$j] -notlike "*Current AC Power Setting*")
			$SettingAC = $Query[$j].Split(":").Trim()
			$SettingAC = [Convert]::ToInt32($SettingAC[1], 16)
			$SettingDC = $Query[$j + 1].Split(":").Trim()
			$SettingDC = [Convert]::ToInt32($SettingDC[1], 16)
			$Setting | Add-Member -Type NoteProperty -Name Subgroup -Value $Subgroup.Subgroup
			$Setting | Add-Member -Type NoteProperty -Name Name -Value $SettingName
			$Setting | Add-Member -Type NoteProperty -Name Alias -Value $SettingAlias
			$Setting | Add-Member -Type NoteProperty -Name GUID -Value $SettingGUID
			$Setting | Add-Member -Type NoteProperty -Name AC -Value $SettingAC
			$Setting | Add-Member -Type NoteProperty -Name DC -Value $SettingDC
			$Settings += $Setting
		}
	}
	Return $Settings
}

function Get-RelativePath {

	
	[CmdletBinding()][OutputType([string])]
	param ()
	
	$Path = (split-path $SCRIPT:MyInvocation.MyCommand.Path -parent) + "\"
	Return $Path
}

function Get-SubGroupsList {

	
	[CmdletBinding()][OutputType([object])]
	param
	(
		[ValidateNotNullOrEmpty()][object]
		$ActivePowerScheme
	)
	
	
	$Query = powercfg.exe /query $ActivePowerScheme.GUID
	
	$Subgroups = @()
	for ($i = 0; $i -lt $Query.Length; $i++) {
		If (($Query[$i] -like "*Subgroup GUID:*") -and ($Query[$i + 1] -notlike "*Subgroup GUID:*")) {
			$Subgroup = New-Object System.Object
			$SubgroupName = $Query[$i].Split("()").Trim()
			$SubgroupName = $SubgroupName[1]
			If ($Query[$i + 1] -like "*GUID Alias:*") {
				$SubgroupAlias = $Query[$i + 1].Split(":").Trim()
				$SubgroupAlias = $SubgroupAlias[1]
			} else {
				$SubgroupAlias = $null
			}
			$SubgroupGUID = $Query[$i].Split(":(").Trim()
			$SubgroupGUID = $SubgroupGUID[1]
			$Subgroup | Add-Member -Type NoteProperty -Name Subgroup -Value $SubgroupName
			$Subgroup | Add-Member -Type NoteProperty -Name Alias -Value $SubgroupAlias
			$Subgroup | Add-Member -Type NoteProperty -Name GUID -Value $SubgroupGUID
			$Subgroups += $Subgroup
		}
	}
	Return $Subgroups
}

function Import-PowerScheme {

	
	[CmdletBinding()][OutputType([boolean])]
	param
	(
		[ValidateNotNullOrEmpty()][string]
		$File,
		[ValidateNotNullOrEmpty()][string]
		$PowerSchemeName,
		[switch]
		$SetActive
	)
	
	$RelativePath = Get-RelativePath
	$File = $RelativePath + $File
	
	$OldPowerSchemes = powercfg.exe /l
	
	$OldPowerSchemes = $OldPowerSchemes | where { $_ -like "*Power Scheme GUID*" } | ForEach-Object { $_ -replace "Power Scheme GUID: ", "" } | ForEach-Object { ($_.split("?("))[0] }
	Write-Host "Importing Power Scheme....." -NoNewline
	
	$Output = powercfg.exe -import $File
	
	$NewPowerSchemes = powercfg.exe /l
	
	$NewScheme = $NewPowerSchemes | where { $_ -like "*Power Scheme GUID*" } | ForEach-Object { $_ -replace "Power Scheme GUID: ", "" } | ForEach-Object { ($_.split("?("))[0] } | where { $OldPowerSchemes -notcontains $_ }
	If ($NewScheme -ne $null) {
		Write-Host "Success" -ForegroundColor Yellow
		$Error = $false
	} else {
		Write-Host "Failed" -ForegroundColor Red
		$Error = $true
	}
	
	Write-Host "Renaming imported power scheme to"$PowerSchemeName"....." -NoNewline
	$Switches = "/changename" + [char]32 + $NewScheme.Trim() + [char]32 + [char]34 + $PowerSchemeName + [char]34
	$ErrCode = (Start-Process -FilePath "powercfg.exe" -ArgumentList $Switches -WindowStyle Minimized -Wait -Passthru).ExitCode
	$NewPowerSchemes = powercfg.exe /l
	If ($ErrCode -eq 0) {
		$Test = $NewPowerSchemes | where { $_ -like ("*" + $PowerSchemeName + "*") }
		If ($Test -ne $null) {
			Write-Host "Success" -ForegroundColor Yellow
			$Error = $false
		} else {
			Write-Host "Failed" -ForegroundColor Red
			$Error = $true
			Return $Error
		}
	}
	Write-Host "Setting"$PowerSchemeName" to default....." -NoNewline
	$Switches = "-setactive " + $NewScheme.Trim()
	$ErrCode = (Start-Process -FilePath "powercfg.exe" -ArgumentList $Switches -WindowStyle Minimized -Wait -Passthru).ExitCode
	$Query = powercfg.exe /getactivescheme
	
	$ActiveSchemeName = (powercfg.exe /getactivescheme).Split("()").Trim()[1]
	If ($ActiveSchemeName -eq $PowerSchemeName) {
		Write-Host "Success" -ForegroundColor Yellow
		$Error = $false
	} else {
		Write-Host "Failed" -ForegroundColor Red
		$Error = $true
	}
	Return $Error
}

function Publish-Report {

	
	[CmdletBinding()]
	param ()
	
	
	$RelativePath = Get-RelativePath
	
	$ActivePowerScheme = Get-PowerScheme
	
	$PowerSchemeSubGroups = Get-SubGroupsList -ActivePowerScheme $ActivePowerScheme
	
	$PowerSchemeSettings = @()
	for ($i = 0; $i -lt $PowerSchemeSubGroups.Length; $i++) {
		$PowerSchemeSubGroupSettings = Get-PowerSchemeSubGroupSettings -ActivePowerScheme $ActivePowerScheme -Subgroup $PowerSchemeSubGroups[$i]
		$PowerSchemeSettings += $PowerSchemeSubGroupSettings
	}
	
	$ReportFile = $RelativePath + "PowerSchemeReport.txt"
	
	If ((Test-Path $ReportFile) -eq $true) {
		Remove-Item -Path $ReportFile -Force
	}
	
	$Header = "ACTIVE POWER SCHEME REPORT"
	$Header | Tee-Object -FilePath $ReportFile -Append
	$Header = "--------------------------------------------------------------------------------"
	$Header | Tee-Object -FilePath $ReportFile -Append
	
	$Output = $ActivePowerScheme | Format-Table
	
	$Output | Tee-Object -FilePath $ReportFile -Append
	
	$Header = "POWER SCHEME SUBGROUPS REPORT"
	$Header | Tee-Object -FilePath $ReportFile -Append
	$Header = "--------------------------------------------------------------------------------"
	$Header | Tee-Object -FilePath $ReportFile -Append
	$Output = $PowerSchemeSubgroups | Format-Table
	
	$Output | Tee-Object -FilePath $ReportFile -Append
	
	$Header = "POWER SCHEME SUBGROUP SETTINGS REPORT"
	$Header | Tee-Object -FilePath $ReportFile -Append
	$Header = "--------------------------------------------------------------------------------"
	$Header | Tee-Object -FilePath $ReportFile -Append
	$Output = $PowerSchemeSettings | Format-Table
	
	$Output | Tee-Object -FilePath $ReportFile -Append
}

function Set-ConsoleTitle {

	
	[CmdletBinding()]
	param
	(
		[Parameter(Mandatory = $true)][String]
		$Title
	)
	
	$host.ui.RawUI.WindowTitle = $Title
}

function Set-PowerScheme {

	
	[CmdletBinding()][OutputType([boolean])]
	param
	(
		[ValidateSet('Balanced', 'High Performance', 'Power Saver')][string]
		$PowerScheme,
		[string]
		$CustomPowerScheme
	)
	
	
	$PowerSchemes = powercfg.exe /l
	If ($PowerScheme -ne $null) {
		
		$PowerSchemes = ($PowerSchemes | where { $_ -like "*" + $PowerScheme + "*" }).Split(":(").Trim()[1]
		
		$ActivePowerScheme = Get-PowerScheme
		$ActivePowerScheme.PowerScheme
		Write-Host "Setting Power Scheme from"$ActivePowerScheme.PowerScheme"to"$PowerScheme"....." -NoNewline
		$Output = powercfg.exe -setactive $PowerSchemes
		$ActivePowerScheme = Get-PowerScheme
		If ($PowerScheme -eq $ActivePowerScheme.PowerScheme) {
			Write-Host "Success" -ForegroundColor Yellow
			Return $false
		} else {
			Write-Host "Failed" -ForegroundColor Red
			Return $true
		}
	}
}

function Set-PowerSchemeSettings {

	
	[CmdletBinding()]
	param
	(
		[string]
		$MonitorTimeoutAC,
		[string]
		$MonitorTimeoutDC,
		[string]
		$DiskTimeoutAC,
		[string]
		$DiskTimeoutDC,
		[string]
		$StandbyTimeoutAC,
		[string]
		$StandbyTimeoutDC,
		[string]
		$HibernateTimeoutAC,
		[string]
		$HibernateTimeoutDC
	)
	
	$Scheme = Get-PowerScheme
	If (($MonitorTimeoutAC -ne $null) -and ($MonitorTimeoutAC -ne "")) {
		Write-Host "Setting monitor timeout on AC to"$MonitorTimeoutAC" minutes....." -NoNewline
		$Switches = "/change" + [char]32 + "monitor-timeout-ac" + [char]32 + $MonitorTimeoutAC
		$TestKey = "Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Power\User\PowerSchemes\" + $Scheme.GUID + "\7516b95f-f776-4464-8c53-06167f40cc99\3c0bc021-c8a8-4e07-a973-6b14cbcb2b7e"
		$TestValue = $MonitorTimeoutAC
		$PowerIndex = "ACSettingIndex"
	}
	If (($MonitorTimeoutDC -ne $null) -and ($MonitorTimeoutDC -ne "")) {
		Write-Host "Setting monitor timeout on DC to"$MonitorTimeoutDC" minutes....." -NoNewline
		$Switches = "/change" + [char]32 + "monitor-timeout-dc" + [char]32 + $MonitorTimeoutDC
		$TestKey = "Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Power\User\PowerSchemes\" + $Scheme.GUID + "\7516b95f-f776-4464-8c53-06167f40cc99\3c0bc021-c8a8-4e07-a973-6b14cbcb2b7e"
		$TestValue = $MonitorTimeoutDC
		$PowerIndex = "DCSettingIndex"
	}
	If (($DiskTimeoutAC -ne $null) -and ($DiskTimeoutAC -ne "")) {
		Write-Host "Setting disk timeout on AC to"$DiskTimeoutAC" minutes....." -NoNewline
		$Switches = "/change" + [char]32 + "disk-timeout-ac" + [char]32 + $DiskTimeoutAC
		$TestKey = "Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Power\User\PowerSchemes\" + $Scheme.GUID + "\0012ee47-9041-4b5d-9b77-535fba8b1442\6738e2c4-e8a5-4a42-b16a-e040e769756e"
		$TestValue = $DiskTimeoutAC
		$PowerIndex = "ACSettingIndex"
	}
	If (($DiskTimeoutDC -ne $null) -and ($DiskTimeoutDC -ne "")) {
		Write-Host "Setting disk timeout on DC to"$DiskTimeoutDC" minutes....." -NoNewline
		$Switches = "/change" + [char]32 + "disk-timeout-dc" + [char]32 + $DiskTimeoutDC
		$TestKey = "Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Power\User\PowerSchemes\" + $Scheme.GUID + "\0012ee47-9041-4b5d-9b77-535fba8b1442\6738e2c4-e8a5-4a42-b16a-e040e769756e"
		$TestValue = $DiskTimeoutDC
		$PowerIndex = "DCSettingIndex"
	}
	If (($StandbyTimeoutAC -ne $null) -and ($StandbyTimeoutAC -ne "")) {
		Write-Host "Setting standby timeout on AC to"$StandbyTimeoutAC" minutes....." -NoNewline
		$Switches = "/change" + [char]32 + "standby-timeout-ac" + [char]32 + $StandbyTimeoutAC
		$TestKey = "Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Power\User\PowerSchemes\" + $Scheme.GUID + "\238c9fa8-0aad-41ed-83f4-97be242c8f20\29f6c1db-86da-48c5-9fdb-f2b67b1f44da"
		$TestValue = $StandbyTimeoutAC
		$PowerIndex = "ACSettingIndex"
	}
	If (($StandbyTimeoutDC -ne $null) -and ($StandbyTimeoutDC -ne "")) {
		Write-Host "Setting standby timeout on DC to"$StandbyTimeoutDC" minutes....." -NoNewline
		$Switches = "/change" + [char]32 + "standby-timeout-dc" + [char]32 + $StandbyTimeoutDC
		$TestKey = "Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Power\User\PowerSchemes\" + $Scheme.GUID + "\238c9fa8-0aad-41ed-83f4-97be242c8f20\29f6c1db-86da-48c5-9fdb-f2b67b1f44da"
		$TestValue = $StandbyTimeoutDC
		$PowerIndex = "DCSettingIndex"
	}
	If (($HibernateTimeoutAC -ne $null) -and ($HibernateTimeoutAC -ne "")) {
		Write-Host "Setting hibernate timeout on AC to"$HibernateTimeoutAC" minutes....." -NoNewline
		$Switches = "/change" + [char]32 + "hibernate-timeout-ac" + [char]32 + $HibernateTimeoutAC
		$TestKey = "Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Power\User\PowerSchemes\" + $Scheme.GUID + "\238c9fa8-0aad-41ed-83f4-97be242c8f20\9d7815a6-7ee4-497e-8888-515a05f02364"
		[int]$TestValue = $HibernateTimeoutAC
		$PowerIndex = "ACSettingIndex"
	}
	If (($HibernateTimeoutDC -ne $null) -and ($HibernateTimeoutDC -ne "")) {
		Write-Host "Setting hibernate timeout on DC to"$HibernateTimeoutDC" minutes....." -NoNewline
		$Switches = "/change" + [char]32 + "hibernate-timeout-dc" + [char]32 + $HibernateTimeoutDC
		$TestKey = "Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Power\User\PowerSchemes\" + $Scheme.GUID + "\238c9fa8-0aad-41ed-83f4-97be242c8f20\9d7815a6-7ee4-497e-8888-515a05f02364"
		$TestValue = $HibernateTimeoutDC
		$PowerIndex = "DCSettingIndex"
	}
	$ErrCode = (Start-Process -FilePath "powercfg.exe" -ArgumentList $Switches -WindowStyle Minimized -Wait -Passthru).ExitCode
	$RegValue = (((Get-ItemProperty $TestKey).$PowerIndex) /60)
	
	$RegValue = $RegValue - ($RegValue % 10)
	If (($RegValue -eq $TestValue) -and ($ErrCode -eq 0)) {
		Write-Host "Success" -ForegroundColor Yellow
		$Errors = $false
	} else {
		Write-Host "Failed" -ForegroundColor Red
		$Errors = $true
	}
	Return $Errors
}


cls

$Errors = $false

Set-ConsoleTitle -Title $ConsoleTitle




If ($Report.IsPresent) {
	Publish-Report
}

If ($Balanced.IsPresent) {
	$Errors = Set-PowerScheme -PowerScheme 'Balanced'
}

If ($PowerSaver.IsPresent) {
	$Errors = Set-PowerScheme -PowerScheme 'Power Saver'
}

If ($HighPerformance.IsPresent) {
	$Errors = Set-PowerScheme -PowerScheme 'High Performance'
}

If (($Custom -ne $null) -and ($Custom -ne "")) {
	$Errors = Set-PowerScheme -PowerScheme $Custom
}

If (($ImportPowerSchemeFile -ne $null) -and ($ImportPowerSchemeFile -ne "")) {
	If ($SetImportedPowerSchemeDefault.IsPresent) {
		$Errors = Import-PowerScheme -File $ImportPowerSchemeFile -PowerSchemeName $PowerSchemeName -SetActive
	} else {
		$Errors = Import-PowerScheme -File $ImportPowerSchemeFile -PowerSchemeName $PowerSchemeName
	}
}

If (($SetPowerSchemeSetting -ne $null) -and ($SetPowerSchemeSetting -ne "")) {
	switch ($SetPowerSchemeSetting) {
		"MonitorTimeoutAC" { $Errors = Set-PowerSchemeSettings -MonitorTimeoutAC $SetPowerSchemeSettingValue }
		"MonitorTimeoutDC" { $Errors = Set-PowerSchemeSettings -MonitorTimeoutDC $SetPowerSchemeSettingValue }
		"DiskTimeOutAC" { $Errors = Set-PowerSchemeSettings -DiskTimeOutAC $SetPowerSchemeSettingValue }
		"DiskTimeOutDC" { $Errors = Set-PowerSchemeSettings -DiskTimeOutDC $SetPowerSchemeSettingValue }
		"StandbyTimeoutAC" { $Errors = Set-PowerSchemeSettings -StandbyTimeoutAC $SetPowerSchemeSettingValue }
		"StandbyTimeoutDC" { $Errors = Set-PowerSchemeSettings -StandbyTimeoutDC $SetPowerSchemeSettingValue }
		"HibernateTimeoutAC" { $Errors = Set-PowerSchemeSettings -HibernateTimeoutAC $SetPowerSchemeSettingValue }
		"HibernateTimeoutDC" { $Errors = Set-PowerSchemeSettings -HibernateTimeoutDC $SetPowerSchemeSettingValue }
	}
}

If ($Errors -eq $true) {
	Exit 5
}
