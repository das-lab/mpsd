

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

function Install-MSI {

	
	[CmdletBinding()]
	param
	(
		[ValidateNotNullOrEmpty()][string]$MSI,
		[ValidateNotNullOrEmpty()][string]$Switches
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

function Uninstall-MSIByName {

	
	[CmdletBinding()]
	param
	(
		[ValidateNotNullOrEmpty()][String]$ApplicationName,
		[ValidateNotNullOrEmpty()][String]$Switches
	)
	
	
	$Executable = $Env:windir + "\system32\msiexec.exe"
	
	$Uninstall = Get-ChildItem HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall -Recurse -ErrorAction SilentlyContinue
	If (((Get-WmiObject -Class Win32_OperatingSystem | Select-Object OSArchitecture).OSArchitecture) -eq "64-Bit") {
		$Uninstall += Get-ChildItem HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall -Recurse -ErrorAction SilentlyContinue
	}
	
	$Key = $uninstall | foreach-object { Get-ItemProperty REGISTRY::$_ } | where-object { $_.DisplayName -like "*$ApplicationName*" }
	If ($Key -ne $null) {
		Write-Host "Uninstall"$Key.DisplayName"....." -NoNewline
		
		$Parameters = "/x " + $Key.PSChildName + [char]32 + $Switches
		
		$ErrCode = (Start-Process -FilePath $Executable -ArgumentList $Parameters -Wait -Passthru).ExitCode
		
		If (($ErrCode -eq 0) -or ($ErrCode -eq 3010) -or ($ErrCode -eq 1605)) {
			Write-Host "Success" -ForegroundColor Yellow
		} else {
			Write-Host "Failed with error code "$ErrCode -ForegroundColor Red
			Exit $ErrCode
		}
	}
}

$RelativePath = Get-RelativePath
Uninstall-MSIByName -ApplicationName "Google Chrome" -Switches "/qb- /norestart"
Install-MSI -MSI $RelativePath"GoogleChromeStandaloneEnterprise.msi" -Switches "/qb- /norestart ALLUSERS=1"
