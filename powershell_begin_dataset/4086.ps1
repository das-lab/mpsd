

function Invoke-MSI {

	
	[CmdletBinding()]
	param
	(
		[string]
		$DisplayName,
		[switch]
		$Install,
		[string]
		$LogDirectory,
		[switch]
		$Logging,
		[ValidateNotNullOrEmpty()][String]
		$MSIFileName,
		[string]
		$MSIFilePath,
		[ValidateNotNullOrEmpty()][String]
		$Switches = '/qb- /norestart',
		[string]
		$GUID,
		[switch]
		$Repair,
		[switch]
		$Uninstall,
		[switch]
		$UninstallByName
	)
	
	function Get-MSIDatabase {
	
		
		[CmdletBinding()][OutputType([string])]
		param
		(
			[ValidateNotNullOrEmpty()][string]
			$Property,
			[ValidateNotNullOrEmpty()][string]
			$MSI,
			[ValidateNotNullOrEmpty()][string]
			$Path
		)
		
		
		$MSIFile = Get-Item $Path$MSI
		
		try {
			
			$WindowsInstaller = New-Object -ComObject WindowsInstaller.Installer
			
			$MSIDatabase = $WindowsInstaller.GetType().InvokeMember("OpenDatabase", "InvokeMethod", $Null, $WindowsInstaller, @($MSIFile.FullName, 0))
			
			$Query = "SELECT Value FROM Property WHERE Property = '$($Property)'"
			
			$View = $MSIDatabase.GetType().InvokeMember("OpenView", "InvokeMethod", $null, $MSIDatabase, ($Query))
			$View.GetType().InvokeMember("Execute", "InvokeMethod", $null, $View, $null)
			$Record = $View.GetType().InvokeMember("Fetch", "InvokeMethod", $null, $View, $null)
			
			$DataField = $Record.GetType().InvokeMember("StringData", "GetProperty", $null, $Record, 1)
			Return $DataField
		} catch {
			Write-Output $_.Exception.Message
			Exit 1
		}
	}
	
	function Get-DisplayNameFromRegistry {
	
		
		[CmdletBinding()][OutputType([string])]
		param
		(
			[ValidateNotNullOrEmpty()][string]
			$GUID
		)
		
		
		$OSArchitecture = Get-WmiObject -Class Win32_OperatingSystem | Select-Object OSArchitecture
		
		$Registry = Get-ChildItem Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall
		If ($OSArchitecture.OSArchitecture -eq "64-bit") {
			$Registry += Get-ChildItem Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall
		}
		
		$Registry = $Registry | Where-Object { $_.PSChildName -eq $GUID }
		
		$Registry = "Registry::" + $Registry.Name
		
		$Registry = Get-ItemProperty $Registry -ErrorAction SilentlyContinue
		
		$DisplayName = $Registry.DisplayName
		Return $DisplayName
	}
	
	
	$OSArchitecture = Get-WmiObject -Class Win32_OperatingSystem | Select-Object OSArchitecture
	
	$Executable = $Env:windir + "\system32\msiexec.exe"
	
	If ($MSIFilePath -eq "") {
		If (($GUID -eq $null) -or ($GUID -eq "")) {
			$MSIFilePath = (split-path $SCRIPT:MyInvocation.MyCommand.Path -parent) + "\"
		}
	} else {
		If ($MSIFilePath[$MSIFilePath.Length - 1] -ne '\') {
			$MSIFilePath += '\'
		}
	}
	If ($Install.IsPresent) {
		$Parameters = "/i" + [char]32 + [char]34 + $MSIFilePath + $MSIFileName + [char]34
		$DisplayName = Get-MSIDatabase -Property "ProductName" -MSI $MSIFileName -Path $MSIFilePath
		Write-Host "Installing"$DisplayName"....." -NoNewline
	} elseif ($Uninstall.IsPresent) {
		If ($GUID -ne "") {
			$Parameters = "/x" + [char]32 + $GUID
			$DisplayName = Get-DisplayNameFromRegistry -GUID $GUID
		} else {
			$Parameters = "/x" + [char]32 + [char]34 + $MSIFilePath + $MSIFileName + [char]34
			$DisplayName = Get-MSIDatabase -Property "ProductName" -MSI $MSIFileName -Path $MSIFilePath
		}
		If ($DisplayName -ne "") {
			Write-Host "Uninstalling"$DisplayName"....." -NoNewline
		} else {
			Write-Host "Uninstalling"$GUID"....." -NoNewline
		}
	} elseif ($UninstallByName.IsPresent) {
		$Uninstaller = Get-ChildItem "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall" -Recurse -ErrorAction SilentlyContinue
		If ($OSArchitecture.OSArchitecture -eq "64-Bit") {
			$Uninstaller += Get-ChildItem "HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall" -Recurse -ErrorAction SilentlyContinue
		}
		$SearchName = "*" + $DisplayName + "*"
		$IdentifyingNumber = get-wmiobject win32_product | where-object { $_.Name -like $SearchName }
		[string]$GUID = $IdentifyingNumber.IdentifyingNumber
		$Parameters = "/x" + [char]32 + $GUID
		$DisplayName = Get-DisplayNameFromRegistry -GUID $GUID
		If ($DisplayName -ne "") {
			Write-Host "Uninstalling"$DisplayName"....." -NoNewline
		} else {
			Write-Host "Uninstalling"$GUID"....." -NoNewline
		}
	} elseif ($Repair.IsPresent) {
		If ($GUID -ne "") {
			$Parameters = "/faumsv" + [char]32 + $GUID
			$DisplayName = Get-DisplayNameFromRegistry -GUID $GUID
		} else {
			$Parameters = "/faumsv" + [char]32 + [char]34 + $MSIFilePath + $MSIFileName + [char]34
			$DisplayName = Get-MSIDatabase -Property "ProductName" -MSI $MSIFileName -Path $MSIFilePath
		}
		Write-Host "Repairing"$DisplayName"....." -NoNewline
	} else {
		Write-Host "Specify to install, repair, or uninstall the MSI" -ForegroundColor Red
		Exit 1
	}
	
	If ($Logging.IsPresent) {
		If ($LogDirectory -eq "") {
			$Parameters += [char]32 + "/lvx " + [char]34 + $env:TEMP + "\" + $DisplayName + ".log" + [char]34
		} else {
			If ($LogDirectory[$LogDirectory.count - 1] -ne "\") {
				$LogDirectory += "\"
			}
			$Parameters += [char]32 + "/lvx " + [char]34 + $LogDirectory + $DisplayName + ".log" + [char]34
		}
	}
	
	$Parameters += [char]32 + $Switches
	$ErrCode = (Start-Process -FilePath $Executable -ArgumentList $Parameters -WindowStyle Minimized -Wait -Passthru).ExitCode
	If (($ErrCode -eq 0) -or ($ErrCode -eq 3010)) {
		If ($GUID -eq "") {
			[string]$ProductCode = Get-MSIDatabase -Property "ProductCode" -MSI $MSIFileName -Path $MSIFilePath
		} else {
			[string]$ProductCode = $GUID
		}
		$ProductCode = $ProductCode.Trim()
		$Registry = Get-ChildItem Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall
		If ($OSArchitecture.OSArchitecture -eq "64-bit") {
			$Registry += Get-ChildItem Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall
		}
		If (($Install.IsPresent) -or ($Repair.IsPresent)) {
			If ($ProductCode -in $Registry.PSChildName) {
				Write-Host "Success" -ForegroundColor Yellow
			} else {
				Write-Host "Failed" -ForegroundColor Red
			}
		} elseif (($Uninstall.IsPresent) -or ($UninstallByName.IsPresent)) {
			If ($ProductCode -in $Registry.PSChildName) {
				Write-Host "Failed" -ForegroundColor Red
			} else {
				Write-Host "Success" -ForegroundColor Yellow
			}
		}
	} elseif ($ErrCode -eq 1605) {
		Write-Host "Application already uninstalled" -ForegroundColor Yellow
	} else {
		Write-Host "Failed with error code "$ErrCode -ForegroundColor Red
	}
}

Invoke-MSI -Install -MSIFileName "ndOfficeSetup.msi" -Switches "ADDLOCAL=Word,Excel,PowerPoint,Outlook,AdobeAcrobatIntegration,AdobeReaderIntegration /qb- /norestart"
Invoke-MSI -Repair -GUID "{A67CA551-ADAE-4C9B-B09D-38D84044FAB8}"
Invoke-MSI -UninstallByName "ndOffice" -Logging
