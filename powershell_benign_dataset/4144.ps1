

[CmdletBinding()]
param ()


function Get-Architecture {

	
	[CmdletBinding()][OutputType([string])]
	param ()
	
	$OSArchitecture = Get-WmiObject -Class Win32_OperatingSystem | Select-Object OSArchitecture
	$OSArchitecture = $OSArchitecture.OSArchitecture
	Return $OSArchitecture
	
}

function Get-MSIInformation {

	
	[CmdletBinding()]
	param
	(
		[ValidateNotNullOrEmpty()][System.IO.FileInfo]$MSI,
		[ValidateSet('ProductCode', 'ProductVersion', 'ProductName', 'Manufacturer', 'ProductLanguage', 'FullVersion')][string]$Property
	)
	
	
	$WindowsInstaller = New-Object -ComObject WindowsInstaller.Installer
	$MSIDatabase = $WindowsInstaller.GetType().InvokeMember("OpenDatabase", "InvokeMethod", $null, $WindowsInstaller, @($MSI.FullName, 0))
	$Query = "SELECT Value FROM Property WHERE Property = '$($Property)'"
	$View = $MSIDatabase.GetType().InvokeMember("OpenView", "InvokeMethod", $null, $MSIDatabase, ($Query))
	$View.GetType().InvokeMember("Execute", "InvokeMethod", $null, $View, $null)
	$Record = $View.GetType().InvokeMember("Fetch", "InvokeMethod", $null, $View, $null)
	$Value = $Record.GetType().InvokeMember("StringData", "GetProperty", $null, $Record, 1)
	
	
	$MSIDatabase.GetType().InvokeMember("Commit", "InvokeMethod", $null, $MSIDatabase, $null)
	$View.GetType().InvokeMember("Close", "InvokeMethod", $null, $View, $null)
	$MSIDatabase = $null
	$View = $null
	
	
	return $Value
}

function Get-RelativePath {

	
	[CmdletBinding()][OutputType([string])]
	param ()
	
	$Path = (split-path $SCRIPT:MyInvocation.MyCommand.Path -parent) + "\"
	Return $Path
}

function Install-EXE {

	
	[CmdletBinding()]
	param
	(
		[ValidateNotNullOrEmpty()][string]$DisplayName,
		[ValidateNotNullOrEmpty()][string]$Executable,
		[ValidateNotNullOrEmpty()][string]$Switches
	)
	
	Write-Host "Install"$DisplayName.Trim()"....." -NoNewline
	$ErrCode = (Start-Process -FilePath $Executable -ArgumentList $Switches -Wait -Passthru).ExitCode
	If (($ErrCode -eq 0) -or ($ErrCode -eq 3010)) {
		Write-Host "Success" -ForegroundColor Yellow
	} else {
		Write-Host "Failed with error code "$ErrCode -ForegroundColor Red
		Exit $ErrCode
	}
}

function New-AutoConfigFile {

	
	[CmdletBinding()]
	param
	(
		[ValidateNotNullOrEmpty()][string]$CFGFile
	)
	
	'//The first line must be a comment' | Out-File -FilePath $CFGFile -Encoding UTF8 -NoClobber -Force
	'pref("general.config.filename", "mozilla.cfg");' | Out-File -FilePath $CFGFile -Encoding UTF8 -NoClobber -Append
	'pref("general.config.obscure_value", 0);' | Out-File -FilePath $CFGFile -Encoding UTF8 -NoClobber -Append
}

function New-MozillaConfig {

	
	[CmdletBinding()]
	param
	(
		[ValidateNotNullOrEmpty()][string]$CFGFile
	)
	
	'//The first line must be a comment' | Out-File -FilePath $CFGFile -Encoding UTF8 -NoClobber -Force
	'// This is placed in the %programfiles%\Mozilla Firefox\ folder' | Out-File -FilePath $CFGFile -Encoding UTF8 -Append
	'' | Out-File -FilePath $env:ProgramFiles"\Mozilla Firefox\\mozilla.cfg" -Encoding UTF8 -Append
	'// Enable Automatic Updater' | Out-File -FilePath $CFGFile -Encoding UTF8 -Append
	'lockPref("app.update.enabled", true);' | Out-File -FilePath $CFGFile -Encoding UTF8 -Append
	'lockPref("app.update.auto", true);' | Out-File -FilePath $CFGFile -Encoding UTF8 -Append
	'lockPref("app.update.service.enabled", true);' | Out-File -FilePath $CFGFile -Encoding UTF8 -Append
	'lockPref("app.update.mode", 0);' | Out-File -FilePath $CFGFile -Encoding UTF8 -Append
	'lockPref("app.update.incompatible.mode", 0);' | Out-File -FilePath $CFGFile -Encoding UTF8 -Append
	
	'' | Out-File -FilePath $CFGFile -Encoding UTF8 -Append
	
	'// Do not show "know your rights" on first start' | Out-File -FilePath $CFGFile -Encoding UTF8 -Append
	'pref("browser.rights.3.shown", true);' | Out-File -FilePath $CFGFile -Encoding UTF8 -Append
	
	'' | Out-File -FilePath $CFGFile -Encoding UTF8 -Append
	
	'// Do not show What is New on first run' | Out-File -FilePath $CFGFile -Encoding UTF8 -Append
	'pref("browser.startup.homepage_override.mstone", "ignore");' | Out-File -FilePath $CFGFile -Encoding UTF8 -Append
	
	'' | Out-File -FilePath $CFGFile -Encoding UTF8 -Append
	
	'// Set default homepage' | Out-File -FilePath $CFGFile -Encoding UTF8 -Append
	'defaultPref("browser.startup.homepage","data:text/plain,browser.startup.homepage=http://wallerville.com");' | Out-File -FilePath $CFGFile -Encoding UTF8 -Append
	
	'' | Out-File -FilePath $CFGFile -Encoding UTF8 -Append
	
	'// Do not check if default browser' | Out-File -FilePath $CFGFile -Encoding UTF8 -Append
	'pref("browser.shell.checkDefaultBrowser", false);' | Out-File -FilePath $CFGFile -Encoding UTF8 -Append
	
	'' | Out-File -FilePath $CFGFile -Encoding UTF8 -Append
	
	'// Disable Browser Reset Prompt' | Out-File -FilePath $CFGFile -Encoding UTF8 -Append
	'pref("browser.disableResetPrompt", true);' | Out-File -FilePath $CFGFile -Encoding UTF8 -Append
	
	'' | Out-File -FilePath $CFGFile -Encoding UTF8 -Append
	
	'// Enable extensions update' | Out-File -FilePath $CFGFile -Encoding UTF8 -Append
	'pref("extensions.update.enabled", true);' | Out-File -FilePath $CFGFile -Encoding UTF8 -Append
}

function Remove-Directory {

	
	param
	(
		[String]$Directory,
		[switch]$Recurse
	)
	
	Write-Host "Delete"$Directory"....." -NoNewline
	If (Test-Path $Directory) {
		If ($Recurse.IsPresent) {
			Remove-Item $Directory -Recurse -Force -ErrorAction SilentlyContinue
		} else {
			Remove-Item $Directory -Force -ErrorAction SilentlyContinue
		}
		If ((Test-Path $Directory) -eq $False) {
			Write-Host "Success" -ForegroundColor Yellow
		} else {
			Write-Host "Failed" -ForegroundColor Red
		}
	} else {
		Write-Host "Not Present" -ForegroundColor Green
	}
}

function Stop-Processes {

	
	[CmdletBinding()]
	param
	(
		[ValidateNotNullOrEmpty()][String]$ProcessName
	)
	
	$Processes = Get-Process $ProcessName -ErrorAction SilentlyContinue
	If ($Processes -ne $null) {
		Do {
			foreach ($Process in $Processes) {
				If ($Process.Product -ne $null) {
					Write-Host "Killing"(($Process.Product).ToString()).Trim()"Process ID"(($Process.Id).ToString()).Trim()"....." -NoNewline
					Stop-Process -Id $Process.Id -Force -ErrorAction SilentlyContinue
					Start-Sleep -Milliseconds 250
					$Process = Get-Process -Id $Process.Id -ErrorAction SilentlyContinue
					If ($Process -eq $null) {
						Write-Host "Success" -ForegroundColor Yellow
					} else {
						Write-Host "Failed" -ForegroundColor Red
					}
				}
			}
			$Process = Get-Process $ProcessName -ErrorAction SilentlyContinue
		} While ($Process -ne $null)
	}
}

function Uninstall-EXE {

	
	[CmdletBinding()]
	param
	(
		[ValidateNotNullOrEmpty()][string]$DisplayName,
		[ValidateNotNullOrEmpty()][string]$Executable,
		[ValidateNotNullOrEmpty()][string]$Switches
	)
	
	Write-Host "Uninstall"$DisplayName.Trim()"....." -NoNewline
	$ErrCode = (Start-Process -FilePath $Executable -ArgumentList $Switches -Wait -Passthru).ExitCode
	If (($ErrCode -eq 0) -or ($ErrCode -eq 3010)) {
		Write-Host "Success" -ForegroundColor Yellow
	} else {
		Write-Host "Failed with error code "$ErrCode -ForegroundColor Red
		Exit $ErrCode
	}
}

function Uninstall-MSI {

	
	param
	(
		[String]$MSI,
		[String]$Switches
	)
	
	$DisplayName = ([string](Get-MSIInformation -MSI $MSI -Property ProductName)).Trim()
	$Executable = $Env:windir + "\system32\msiexec.exe"
	$Parameters = "/x" + [char]32 + [char]34 + $MSI + [char]34 + [char]32 + $Switches
	Write-Host "Uninstall"$DisplayName"....." -NoNewline
	$ErrCode = (Start-Process -FilePath $Executable -ArgumentList $Parameters -Wait -Passthru).ExitCode
	If (($ErrCode -eq 0) -or ($ErrCode -eq 3010)) {
		Write-Host "Success" -ForegroundColor Yellow
	} elseIf ($ErrCode -eq 1605) {
		Write-Host "Not Present" -ForegroundColor Green
	} else {
		Write-Host "Failed with error code "$ErrCode -ForegroundColor Red
	}
}

$Architecture = Get-Architecture
$RelativePath = Get-RelativePath

Stop-Processes -ProcessName Firefox

If (Test-Path $env:ProgramFiles"\Mozilla Firefox\uninstall\helper.exe") {
	Uninstall-EXE -DisplayName "Mozilla Firefox" -Executable $env:ProgramFiles"\Mozilla Firefox\uninstall\helper.exe" -Switches "/S"
	Remove-Directory -Directory $env:ProgramFiles"\Mozilla Firefox" -Recurse
} elseif (Test-Path ${env:ProgramFiles(x86)}"\Mozilla Firefox\uninstall\helper.exe") {
	Uninstall-EXE -DisplayName "Mozilla Firefox" -Executable ${env:ProgramFiles(x86)}"\Mozilla Firefox\uninstall\helper.exe" -Switches "/S"
	Remove-Directory -Directory ${env:ProgramFiles(x86)}"\Mozilla Firefox" -Recurse
}
Uninstall-MSI -MSI $RelativePath"Firefox-35.0.1-en-US.msi" -Switches "/qb- /norestart"

If ((Test-Path $env:ProgramData"\Mozilla") -eq $true) {
	Remove-Directory -Directory $env:ProgramData"\Mozilla" -Recurse
}


$Parameters = "/INI=" + $RelativePath + "Configuration.ini"
If ($Architecture -eq "32-Bit") {
	
	$File = Get-ChildItem -Path ($RelativePath + $Architecture)
	Install-EXE -DisplayName "Mozilla Firefox 32-Bit" -Executable $RelativePath"32-Bit\"$File -Switches $Parameters
	
	New-AutoConfigFile -CFGFile $env:ProgramFiles"\Mozilla Firefox\defaults\pref\autoconfig.js"
	
	New-MozillaConfig -CFGFile $env:ProgramFiles"\Mozilla Firefox\\mozilla.cfg"
} else {
	$File = Get-ChildItem -Path ($RelativePath+$Architecture)
	
	Install-EXE -DisplayName "Mozilla Firefox 64-Bit" -Executable $RelativePath"64-Bit\"$File -Switches $Parameters
	
	New-AutoConfigFile -CFGFile $env:ProgramFiles"\Mozilla Firefox\defaults\pref\autoconfig.js"
	
	New-MozillaConfig -CFGFile $env:ProgramFiles"\Mozilla Firefox\\mozilla.cfg"
}
