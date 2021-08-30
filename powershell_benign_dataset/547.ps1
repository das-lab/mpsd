

function Add-SPOCurrencyFieldtoList
{
	[CmdletBinding()]
	param
	(
		[Parameter(Mandatory=$true, Position=1)]
		[string] $listTitle, 
		
		[Parameter(Mandatory=$true, Position=2)]
		[string] $fieldName
	)
	
    $newField = "<Field Type='Currency' DisplayName='$fieldName' Name='$fieldName' required='FALSE'/>"
    Add-SPOField $listTitle $fieldName $newField  
}
