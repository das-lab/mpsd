

function Find-SPOFieldName
{
	[CmdletBinding()]
	param
	(
		[Parameter(Mandatory=$true, Position=1)]
		[string] $listTitle, 
		
		[Parameter(Mandatory=$true, Position=2)]
		[string] $displayName
	)

    $web = $clientContext.Web
    $list = $web.Lists.GetByTitle($listTitle)
    $fields = $list.Fields
    $clientContext.Load($fields)
    $clientContext.ExecuteQuery()

    $fieldValues = $fields.GetEnumerator() | select Title, InternalName
    foreach($f in $fieldValues)
    {
        if ($f.Title -eq $displayName)
        {
            return $f.InternalName
        }
    }
    
    return $displayName;
}
