

function Set-SPOListPermissions
{
	[CmdletBinding()]
	param
	(	
		[Parameter(Mandatory=$true, Position=1)]
		[string]$groupname,

		[Parameter(Mandatory=$true, Position=2)]
		[string]$listname,

		[Parameter(Mandatory=$true, Position=3)]
		[string]$roleType
	)

	process
	{
		Write-Host "Creating permissions for list $listname for the group $groupname and role $roleType" -foregroundcolor black -backgroundcolor yellow

		

        $web = $clientContext.Web

        
        $roleTypeObject = [Microsoft.SharePoint.Client.RoleType]$roleType
        $role = Get-SPORole $roleTypeObject

        
        $group = Get-SPOGroup $groupname
 
        
        $list = $web.Lists.GetByTitle($listname)


        
        $method = [Microsoft.Sharepoint.Client.ClientContext].GetMethod("Load")
        $loadMethod = $method.MakeGenericMethod([Microsoft.Sharepoint.Client.List])

        $parameter = [System.Linq.Expressions.Expression]::Parameter(([Microsoft.SharePoint.Client.List]), "x")
        $expression = [System.Linq.Expressions.Expression]::Lambda([System.Linq.Expressions.Expression]::Convert([System.Linq.Expressions.Expression]::Property($parameter, ([Microsoft.SharePoint.Client.List]).GetProperty("HasUniqueRoleAssignments")), ([System.Object])), $($parameter))
        $expressionArray = [System.Array]::CreateInstance($expression.GetType(), 1)
        $expressionArray.SetValue($expression, 0)

        $loadMethod.Invoke( $clientContext, @( $list, $expressionArray ) )


        $clientContext.ExecuteQuery()
 
        
        if (-not $list.HasUniqueRoleAssignments)
        {
            $list.BreakRoleInheritance($false, $false) 
        }

        $clientContext.ExecuteQuery()
 
        
        $rdb = New-Object Microsoft.SharePoint.Client.RoleDefinitionBindingCollection($clientContext)
 
        
        $rdb.Add($role)
 
        
        $ra = $list.RoleAssignments.Add($group, $rdb)
 
        
        $clientContext.ExecuteQuery()		

		Write-Host "Succesfully created permissions" -foregroundcolor black -backgroundcolor green
	}
}
