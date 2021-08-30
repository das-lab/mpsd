
[CmdletBinding()]
param (
	[Parameter(Mandatory = $True,
			   ValueFromPipeline = $True,
			   ValueFromPipelineByPropertyName = $True)]
	[string]$Computername,
	[Parameter(Mandatory = $False,
			   ValueFromPipeline = $False,
			   ValueFromPipelineByPropertyName = $False)]
	[string]$PsExecPath = 'C:\PsExec.exe'
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
			return $false
		}
		
		
		
		if ($result -ne 1) {
			Write-Verbose "Remoting to $computerName returned an unexpected result."
			return $false
		}
		$true
	}
	
	if (!(Test-Ping $Computername)) {
		throw 'Computer is not reachable'
	} elseif (!(Test-Path $PsExecPath)) {
		throw 'Psexec.exe not found'	
	}
}

process {
	if (Test-PsRemoting $Computername) {
		Write-Warning "Remoting already enabled on $Computername"
	} else {
		Write-Verbose "Attempting to enable remoting on $Computername..."
		& $PsExecPath "\\$Computername" -s c:\windows\system32\winrm.cmd quickconfig -quiet
		if (!(Test-PsRemoting $Computername)) {
			Write-Warning "Remoting was attempted but not enabled on $Computername"
		} else {
			Write-Verbose "Remoting successfully enabled on $Computername"
		}
	}
}

end {
	
}