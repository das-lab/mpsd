

function Add-SPONumberFieldtoList
{
	[CmdletBinding()]
	param
	(
		[Parameter(Mandatory=$true, Position=1)]
		[string] $listTitle, 
		
		[Parameter(Mandatory=$true, Position=2)]
		[string] $fieldName
	)

    $newField = "<Field Type='Number' DisplayName='$fieldName' Name='$fieldName' required='FALSE'/>"
    Add-SPOField $listTitle $fieldName $newField  
}
