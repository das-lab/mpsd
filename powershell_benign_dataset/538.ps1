

function Add-SPOUserFieldtoList
{
	[CmdletBinding()]
	param
	(
		[Parameter(Mandatory=$true, Position=1)]
		[string] $listTitle, 
		
		[Parameter(Mandatory=$true, Position=2)]
		[string] $fieldName
	)
	
    $newField = "<Field Type='UserMulti' DisplayName='$fieldName' Name='$fieldName' StaticName='$fieldName' UserSelectionScope='0' UserSelectionMode='PeopleAndGroups' Sortable='FALSE' Required='FALSE' Mult='FALSE'/>"
    Add-SPOField $listTitle $fieldName $newField  
}
