

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
