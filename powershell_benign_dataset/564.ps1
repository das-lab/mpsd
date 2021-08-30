

function Add-SPOCalculatedFieldtoList
{
	[CmdletBinding()]
	param
	(
		[Parameter(Mandatory=$true, Position=1)]
		[string] $listTitle,
		
		[Parameter(Mandatory=$true, Position=2)]
		[string] $fieldName,
		
		[Parameter(Mandatory=$true, Position=3)]
		[string] $value
	)
	
    $refField = $value.Split(";")[1]
    $formula = $value.Split(";")[0]
    
    $internalName = Find-SPOFieldName $listTitle $refField
    
    $newField = '<Field Type="Calculated" DisplayName="$fieldName" ResultType="DateTime" ReadOnly="TRUE" Name="$fieldName"><Formula>$formula</Formula><FieldRefs><FieldRef Name="$internalName" /></FieldRefs></Field>'
    
    Add-SPOField $listTitle $fieldName $newField          
}
