

function Test-SPOField
{
	[CmdletBinding()]
	param
	(
		[Parameter(Mandatory=$true, Position=1)]
		[Microsoft.SharePoint.Client.List] $list, 
		
		[Parameter(Mandatory=$true, Position=2)]
		[Microsoft.SharePoint.Client.FieldCollection] $fields, 
		
		[Parameter(Mandatory=$true, Position=3)]
		[string] $fieldName
	)
	
    $fieldNames = $fields.GetEnumerator() | select -ExpandProperty Title
    $exists = ($fieldNames -contains $fieldName)
    return $exists
}
