

function Set-SPOWebPermissions
{
	[CmdletBinding()]
	param
	(	
		[Parameter(Mandatory=$true, Position=1)]
		[string]$groupname,

		[Parameter(Mandatory=$true, Position=2)]
		[string]$roleType
	)

	process
	{
		Write-Host "Creating permissions for the web for the group $groupname and role $roleType" -foregroundcolor black -backgroundcolor yellow
		

		

        $web = $clientContext.Web

        
        $roleTypeObject = [Microsoft.SharePoint.Client.RoleType]$roleType
        $role = Get-SPORole $roleTypeObject

        
        $group = Get-SPOGroup $groupname

        
        $rdb = New-Object Microsoft.SharePoint.Client.RoleDefinitionBindingCollection($clientContext)
 
        
        $rdb.Add($role)
 
        
        $ra = $web.RoleAssignments.Add($group, $rdb)
 
        
        $clientContext.ExecuteQuery()	

		Write-Host "Succesfully created permissions" -foregroundcolor black -backgroundcolor green
	}
}
