

[CmdletBinding()]
param ()

function Get-MSIInformation {

	
	[CmdletBinding()]
	param
	(
		[ValidateNotNullOrEmpty()]
		[System.IO.FileInfo]$MSI,
		[ValidateSet('ProductCode', 'ProductVersion', 'ProductName', 'Manufacturer', 'ProductLanguage', 'FullVersion')]
		[string]$Property
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

	
	[CmdletBinding()]
	[OutputType([string])]
	param ()
	
	$Path = (split-path $SCRIPT:MyInvocation.MyCommand.Path -parent) + "\"
	Return $Path
}

function Install-MSI {

	
	[CmdletBinding()]
	param
	(
		[ValidateNotNullOrEmpty()]
		[string]$MSI,
		[ValidateNotNullOrEmpty()]
		[string]$Switches
	)
	
	[string]$DisplayName = Get-MSIInformation -MSI $MSI -Property 'ProductName'
	$Executable = $Env:windir + "\system32\msiexec.exe"
	$Parameters = "/i" + [char]32 + [char]34 + $MSI + [char]34 + [char]32 + $Switches
	Write-Host "Install"$DisplayName.Trim()"....." -NoNewline
	$ErrCode = (Start-Process -FilePath $Executable -ArgumentList $Parameters -Wait -Passthru).ExitCode
	If (($ErrCode -eq 0) -or ($ErrCode -eq 3010)) {
		Write-Host "Success" -ForegroundColor Yellow
	} else {
		Write-Host "Failed with error code "$ErrCode -ForegroundColor Red
		Exit $ErrCode
	}
}

function Stop-Processes {

	
	[CmdletBinding()]
	param
	(
		[ValidateNotNullOrEmpty()]
		[String]$ProcessName
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

function Uninstall-MSIByName {

	
	[CmdletBinding()]
	param
	(
		[ValidateNotNullOrEmpty()]
		[String]$ApplicationName,
		[ValidateNotNullOrEmpty()]
		[String]$Switches
	)
	
	
	$Executable = $Env:windir + "\system32\msiexec.exe"
	Do {
		
		$Uninstall = Get-ChildItem REGISTRY::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall -Recurse -ErrorAction SilentlyContinue -Force
		$Uninstall += Get-ChildItem REGISTRY::HKEY_LOCAL_MACHINE\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall -Recurse -ErrorAction SilentlyContinue
		
		$Key = $uninstall | foreach-object {
			Get-ItemProperty REGISTRY::$_
		} | where-object {
			$_.DisplayName -like "*$ApplicationName*"
		}
		If ($Key -ne $null) {
			Write-Host "Uninstall"$Key[0].DisplayName"....." -NoNewline
			
			$Parameters = "/x " + $Key[0].PSChildName + [char]32 + $Switches
			
			$ErrCode = (Start-Process -FilePath $Executable -ArgumentList $Parameters -Wait -Passthru).ExitCode
			
			If (($ErrCode -eq 0) -or ($ErrCode -eq 3010) -or ($ErrCode -eq 1605)) {
				Write-Host "Success" -ForegroundColor Yellow
			} else {
				Write-Host "Failed with error code "$ErrCode -ForegroundColor Red
			}
		}
	} While ($Key -ne $null)
}


$RelativePath = Get-RelativePath

Stop-Processes -ProcessName 'DesktopApp'
Stop-Processes -ProcessName 'winword'
Stop-Processes -ProcessName 'excel'
Stop-Processes -ProcessName 'outlook'
Stop-Processes -ProcessName 'powerpnt'

Uninstall-MSIByName -ApplicationName 'OutlookAddInInstaller' -Switches '/qb- /norestart'
Uninstall-MSIByName -ApplicationName 'PingDesktopApp' -Switches '/qb- /norestart'

Install-MSI -MSI $RelativePath'DesktopAppInstaller_v2.0.1420.msi' -Switches '/qb- /norestart'
Install-MSI -MSI $RelativePath'OutlookAddInInstaller_v1.5.17.msi' -Switches '/qb- /norestart'
