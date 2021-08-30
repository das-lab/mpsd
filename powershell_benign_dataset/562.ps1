

function Add-SPOChoiceFieldtoList
{
	[CmdletBinding()]
	param
	(
		[Parameter(Mandatory=$true, Position=1)]
		[string] $listTitle, 
		
		[Parameter(Mandatory=$true, Position=2)]
		[string] $fieldName,
		
		[Parameter(Mandatory=$true, Position=3)]
		[string] $values
	)
	
    $options = ""
    $valArray = $values.Split(";")
    foreach ($s in $valArray)
    {
        $options = $options + "<CHOICE>$s</CHOICE>"
    }
    
    $newField = "<Field Type='Choice' DisplayName='$fieldName' Name='$fieldName'  required='FALSE'><CHOICES>$options</CHOICES></Field>"
    
    Add-SPOField $listTitle $fieldName $newField  
}
