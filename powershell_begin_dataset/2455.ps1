
[CmdletBinding()]
param (
	[Parameter(Mandatory = $True,
			   ValueFromPipeline = $True,
			   ValueFromPipelineByPropertyName = $True)]
	[string]$Computername,
	[Parameter(Mandatory = $True,
			   ValueFromPipeline = $False,
			   ValueFromPipelineByPropertyName = $False)]
	[string]$FolderPath,
	[Parameter(Mandatory = $True,
			   ValueFromPipeline = $False,
			   ValueFromPipelineByPropertyName = $False)]
	[string]$ScriptPath,
	[Parameter(Mandatory = $False,
			   ValueFromPipeline = $False,
			   ValueFromPipelineByPropertyName = $False)]
	[string]$RemoteDrive = 'C'
)

begin {
	
	function Test-PsRemoting {
		param (
			[Parameter(Mandatory = $true)]
			$computername
		)
		
		try {
			$errorActionPreference = "Stop"
			$result = Invoke-Command -ComputerName $computername { 1 }
		} catch {
			Write-Verbose $_
			return $false
		}
		
		
		
		if ($result -ne 1) {
			Write-Verbose "Remoting to $computerName returned an unexpected result."
			return $false
		}
		$true
	}
	
	Write-Verbose "Validating prereqs for remote script execution..."
	if (!(Test-Path $FolderPath)) {
		throw 'Folder path does not exist'
	} elseif (!(Test-Path $ScriptPath)) {
		throw 'Script path does not exist'
	} elseif ((Get-ItemProperty -Path $ScriptPath).Extension -ne '.ps1') {
		throw 'Script specified is not a Powershell script'
	} elseif (!(Test-Ping $Computername)) {
		throw 'Computer is not reachable'
	} 
	$ScriptName = $ScriptPath | Split-Path -Leaf
	$RemoteFolderPath = $FolderPath | Split-Path -Leaf
	$RemoteScriptPath = "$RemoteDrive`:\$RemoteFolderPath\$ScriptName"
}

process {
	Write-Verbose "Copying the folder $FolderPath to the remote computer $ComputerName..."
	Copy-Item $FolderPath -Recurse "\\$Computername\$RemoteDrive`$" -Force
	Write-Verbose "Copying the script $ScriptName to the remote computer $ComputerName..."
	Copy-Item $ScriptPath "\\$Computername\$RemoteDrive`$\$RemoteFolderPath" -Force
	Write-Verbose "Executing $RemoteScriptPath on the remote computer $ComputerName..."
	
	([WMICLASS]"\\$Computername\Root\CIMV2:Win32_Process").create("powershell.exe -File $RemoteScriptPath -NonInteractive -NoProfile")
}

end {
	
	
}