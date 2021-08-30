

function Get-SPOGroup
{
	[CmdletBinding()]
	param
	(
		[Parameter(Mandatory=$true, Position=1)]
		[string]$name
	)

	$web = $clientContext.Web

	if ($web -ne $null)
	{
		$groups = $web.SiteGroups
		$clientContext.Load($groups)
		$clientContext.ExecuteQuery()
		$group = $groups | where {$_.Title -eq $name}

		return $group
	}
	return $null
}
