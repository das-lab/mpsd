

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
