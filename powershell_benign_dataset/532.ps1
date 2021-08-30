

function Get-SPORole
{
	[CmdletBinding()]
	param
	(
		[Parameter(Mandatory=$true, Position=1)]
		[Microsoft.SharePoint.Client.RoleType]$rType
	)

	$web = $clientContext.Web
	if ($web -ne $null)
	{
	 $roleDefs = $web.RoleDefinitions
	 $clientContext.Load($roleDefs)
	 $clientContext.ExecuteQuery()
	 $roleDef = $roleDefs | where {$_.RoleTypeKind -eq $rType}
	 return $roleDef
	}
	return $null
}
