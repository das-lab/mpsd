

function Add-SPODateTimeFieldtoList
{
	[CmdletBinding()]
	param
	(
		[Parameter(Mandatory=$true, Position=1)]
		[string] $listTitle, 
		
		[Parameter(Mandatory=$true, Position=2)]
		[string] $fieldName
	)
	
    $newField = "<Field Type='DateTime' DisplayName='$fieldName' Name='$fieldName' required='FALSE'/>"
    Add-SPOField $listTitle $fieldName $newField  
}
