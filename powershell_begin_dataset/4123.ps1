
[CmdletBinding()]
param
(
	[Parameter(Mandatory = $false)][string]$ConsoleTitle = 'Microsoft Office and Windows Activation',
	[Parameter(Mandatory = $false)][string]$OfficeProductKey,
	[Parameter(Mandatory = $false)][string]$WindowsProductKey,
	[switch]$ActivateOffice,
	[switch]$ActivateWindows
)

function Get-OfficeSoftwareProtectionPlatform {

	
	[CmdletBinding()][OutputType([string])]
	param ()
	
	$File = Get-ChildItem $env:ProgramFiles"\Microsoft Office" -Filter "OSPP.VBS" -Recurse
	If (($File -eq $null) -or ($File -eq '')) {
		$File = Get-ChildItem ${env:ProgramFiles(x86)}"\Microsoft Office" -Filter "OSPP.VBS" -Recurse
	}
	$File = $File.FullName
	Return $File
}

function Get-SoftwareLicenseManager {

	
	[CmdletBinding()][OutputType([string])]
	param ()
	
	$File = Get-ChildItem $env:windir"\system32" | Where-Object { $_.Name -eq "slmgr.vbs" }
	$File = $File.FullName
	Return $File
}

function Invoke-OfficeActivation {

	
	[CmdletBinding()][OutputType([boolean])]
	param
	(
		[ValidateNotNullOrEmpty()][string]$OSPP
	)
	
	$Errors = $false
	Write-Host "Activate Microsoft Office....." -NoNewline
	$Executable = $env:windir + "\System32\cscript.exe"
	$Switches = [char]34 + $OSPP + [char]34 + [char]32 + "/act"
	If ((Test-Path $Executable) -eq $true) {
		$ErrCode = (Start-Process -FilePath $Executable -ArgumentList $Switches -Wait -WindowStyle Minimized -Passthru).ExitCode
	}
	If (($ErrCode -eq 0) -or ($ErrCode -eq 3010)) {
		Write-Host "Success" -ForegroundColor Yellow
	} else {
		Write-Host "Failed with error code"$ErrCode -ForegroundColor Red
		$Errors = $true
	}
	Return $Errors
}

function Invoke-WindowsActivation {

	
	[CmdletBinding()]
	param
	(
		[ValidateNotNullOrEmpty()][string]$SLMGR
	)
	
	$Errors = $false
	Write-Host "Activate Microsoft Windows....." -NoNewline
	$Executable = $env:windir + "\System32\cscript.exe"
	$Switches = [char]34 + $SLMGR + [char]34 + [char]32 + "-ato"
	If ((Test-Path $Executable) -eq $true) {
		$ErrCode = (Start-Process -FilePath $Executable -ArgumentList $Switches -Wait -WindowStyle Minimized -Passthru).ExitCode
	}
	If (($ErrCode -eq 0) -or ($ErrCode -eq 3010)) {
		Write-Host "Success" -ForegroundColor Yellow
	} else {
		Write-Host "Failed with error code"$ErrCode -ForegroundColor Red
		$Errors = $true
	}
	Return $Errors
}

function Set-ConsoleTitle {

	
	[CmdletBinding()]
	param
	(
			[Parameter(Mandatory = $true)][String]$ConsoleTitle
	)
	
	$host.ui.RawUI.WindowTitle = $ConsoleTitle
}

function Set-OfficeProductKey {

	
	[CmdletBinding()][OutputType([boolean])]
	param
	(
		[ValidateNotNullOrEmpty()][string]$OSPP
	)
	
	$Errors = $false
	Write-Host "Set Microsoft Office Product Key....." -NoNewline
	$Executable = $env:windir + "\System32\cscript.exe"
	$Switches = [char]34 + $OSPP + [char]34 + [char]32 + "/inpkey:" + $OfficeProductKey
	If ((Test-Path $Executable) -eq $true) {
		$ErrCode = (Start-Process -FilePath $Executable -ArgumentList $Switches -Wait -WindowStyle Minimized -Passthru).ExitCode
	}
	If (($ErrCode -eq 0) -or ($ErrCode -eq 3010)) {
		Write-Host "Success" -ForegroundColor Yellow
	} else {
		Write-Host "Failed with error code"$ErrCode -ForegroundColor Red
		$Errors = $true
	}
	Return $Errors
}

function Set-WindowsProductKey {

	
	[CmdletBinding()][OutputType([boolean])]
	param
	(
		[ValidateNotNullOrEmpty()][string]$SLMGR
	)
	
	$Errors = $false
	Write-Host "Set Microsoft Windows Product Key....." -NoNewline
	$Executable = $env:windir + "\System32\cscript.exe"
	$Switches = [char]34 + $SLMGR + [char]34 + [char]32 + "/ipk" + [char]32 + $WindowsProductKey
	If ((Test-Path $Executable) -eq $true) {
		$ErrCode = (Start-Process -FilePath $Executable -ArgumentList $Switches -Wait -WindowStyle Minimized -Passthru).ExitCode
	}
	If (($ErrCode -eq 0) -or ($ErrCode -eq 3010)) {
		Write-Host "Success" -ForegroundColor Yellow
	} else {
		Write-Host "Failed with error code"$ErrCode -ForegroundColor Red
		$Errors = $true
	}
	Return $Errors
}

Clear-Host
$ErrorReport = $false

Set-ConsoleTitle -ConsoleTitle $ConsoleTitle

$OSPP = Get-OfficeSoftwareProtectionPlatform


If (($OfficeProductKey -ne $null) -and ($OfficeProductKey -ne '')) {
	
	If (($OSPP -ne $null) -and ($OSPP -ne '')) {
		
		$Errors = Set-OfficeProductKey -OSPP $OSPP
		If ($ErrorReport -eq $false) {
			$ErrorReport = $Errors
		}
	} else {
		Write-Host "Office Software Protection Platform not found to set the Microsoft Office Product Key" -ForegroundColor Red
	}
}

If ($ActivateOffice.IsPresent) {
	
	If (($OSPP -ne $null) -and ($OSPP -ne '')) {
		
		$Errors = Invoke-OfficeActivation -OSPP $OSPP
		If ($ErrorReport -eq $false) {
			$ErrorReport = $Errors
		}
	} else {
		Write-Host "Office Software Protection Platform not found to activate Microsoft Office" -ForegroundColor Red
	}
}

If (($WindowsProductKey -ne $null) -and ($WindowsProductKey -ne '')) {
	
	$SLMGR = Get-SoftwareLicenseManager
	
	If (($SLMGR -ne $null) -and ($SLMGR -ne '')) {
		
		$Errors = Set-WindowsProductKey -SLMGR $SLMGR
		If ($ErrorReport -eq $false) {
			$ErrorReport = $Errors
		}
	} else {
		Write-Host "Software licensing management tool not found to set the Microsoft Windows Product Key" -ForegroundColor Red
	}
}

If ($ActivateWindows.IsPresent) {
	
	$SLMGR = Get-SoftwareLicenseManager
	
	If (($SLMGR -ne $null) -and ($SLMGR -ne '')) {
		
		$Errors = Invoke-WindowsActivation -SLMGR $SLMGR
		If ($ErrorReport -eq $false) {
			$ErrorReport = $Errors
		}
	} else {
		Write-Host "Software licensing management tool not found to activate Microsoft Windows" -ForegroundColor Red
	}
}

If ($ErrorReport -eq $true) {
	Exit 1
}
