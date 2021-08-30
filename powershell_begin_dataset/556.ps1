

function Add-SPOPrincipalToGroup
{
	
	[CmdletBinding()]
	param
	(	
		[Parameter(Mandatory=$true, Position=1)]
		[string]$username,
		
		[Parameter(Mandatory=$true, Position=1)]
		[string]$groupname
	)

	process
	{
		Write-Host "Adding principal with username $username to group $groupname" -foregroundcolor black -backgroundcolor yellow

        $principal = Get-SPOPrincipal -username $username

		$group = Get-SPOGroup -name $groupname
		
		$userExists = $group.Users.GetById($principal.Id)
		$clientContext.Load($userExists)
		
		try
		{
			$clientContext.ExecuteQuery()
			
			
			
			Write-Host "Principal already added to the group" -foregroundcolor black -backgroundcolor yellow
			
		} 
		catch
		{
			
			
			$addedPrincipal = $group.Users.AddUser($principal)
		
			$clientContext.Load($addedPrincipal)
			$clientContext.ExecuteQuery()
			
			Write-Host "Succesfully added principal to the group" -foregroundcolor black -backgroundcolor green
		}
		
		
	}
}
