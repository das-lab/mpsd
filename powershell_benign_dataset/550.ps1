

function Set-SPODocumentPermissions
{
	[CmdletBinding()]
	param
	(	
		[Parameter(Mandatory=$true, Position=1)]
		[string]$groupname,

		[Parameter(Mandatory=$true, Position=2)]
		[string]$listname,

        [Parameter(Mandatory=$true, Position=3)]
        [string]$listItemName,

		[Parameter(Mandatory=$true, Position=4)]
		[string]$roleType
	)

	process
	{
		Write-Host "Creating permissions for document $listItemName in list $listname for the group $groupname and role $roleType" -foregroundcolor black -backgroundcolor yellow

		

        $web = $clientContext.Web

        
        $roleTypeObject = [Microsoft.SharePoint.Client.RoleType]$roleType
        $role = Get-SPORole $roleTypeObject

        
        $group = Get-SPOGroup $groupname
 
        
        $list = $web.Lists.GetByTitle($listname)


        $camlQuery = new-object Microsoft.SharePoint.Client.CamlQuery
        $camlQuery.ViewXml = "<View><Query><Where><Eq><FieldRef Name='FileLeafRef' /><Value Type='Text'>$listItemName</Value></Eq></Where></Query></View>"

        $listItems = $list.GetItems($camlQuery)


        
        $clientContext.Load($listItems)
        $clientContext.ExecuteQuery()

        if ($listItems.Count -gt 0)
        {
            
            $listItem = $listItems[0]

            $clientContext.Load($listItem)
            $clientContext.ExecuteQuery()


            
            $method = [Microsoft.Sharepoint.Client.ClientContext].GetMethod("Load")
            $loadMethod = $method.MakeGenericMethod([Microsoft.Sharepoint.Client.ListItem])

            $parameter = [System.Linq.Expressions.Expression]::Parameter(([Microsoft.SharePoint.Client.ListItem]), "x")
            $expression = [System.Linq.Expressions.Expression]::Lambda([System.Linq.Expressions.Expression]::Convert([System.Linq.Expressions.Expression]::Property($parameter, ([Microsoft.SharePoint.Client.ListItem]).GetProperty("HasUniqueRoleAssignments")), ([System.Object])), $($parameter))
            $expressionArray = [System.Array]::CreateInstance($expression.GetType(), 1)
            $expressionArray.SetValue($expression, 0)

            $loadMethod.Invoke( $clientContext, @( $listItem, $expressionArray ) )

            $clientContext.ExecuteQuery()


            
            if (-not $listItem.HasUniqueRoleAssignments)
            {
                $listItem.BreakRoleInheritance($false, $false) 
            }

            $clientContext.ExecuteQuery()
 
            
            $rdb = New-Object Microsoft.SharePoint.Client.RoleDefinitionBindingCollection($clientContext)
 
            
            $rdb.Add($role)
 
            
            $ra = $listItem.RoleAssignments.Add($group, $rdb)
 
            
            $clientContext.ExecuteQuery()		

			Write-Host "Succesfully created permissions" -foregroundcolor black -backgroundcolor green

        } else {
			Write-Host "Item $listItemName could not be found" -foregroundcolor black -backgroundcolor red
        }
	}
}
