

function Add-SPONoteFieldtoList
{
	[CmdletBinding()]
	param
	(
		[Parameter(Mandatory=$true, Position=1)]
		[string] $listTitle, 
		
		[Parameter(Mandatory=$true, Position=2)]
		[string] $fieldName
	)
	
    $newField = "<Field Type='Note' DisplayName='$fieldName' Name='$fieldName' required='FALSE' NumLines='6' RichText='FALSE' Sortable='FALSE' />"
    Add-SPOField $listTitle $fieldName $newField  
}
