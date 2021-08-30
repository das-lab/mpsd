

function Add-SPOFieldsToList
{
	
	[CmdletBinding()]
	param
	(
		[Parameter(Mandatory=$true, Position=1)]
		[string[][]]$fields,
		
		[Parameter(Mandatory=$true, Position=2)]
		[string]$listTitle
	)
	
    foreach($field in $fields)
    {
        $fieldName = $field[0]
        $fieldType = $field[1]
        $fieldValue = $field[2]
        
        switch ($fieldType)
        {
            "Text"
            {
                Add-SPOTextFieldtoList $listTitle $fieldName
            }
            "Note"
            {
                Add-SPONoteFieldtoList $listTitle $fieldName
            }
            "DateTime"
            {
                Add-SPODateTimeFieldtoList $listTitle $fieldName
            }
            "Currency"
            {
                Add-SPOCurrencyFieldtoList $listTitle $fieldName
            }
            "Number"
            {
                Add-SPOCurrencyFieldtoList $listTitle $fieldName
            }
            "Choice"
            {
                Add-SPOChoiceFieldtoList $listTitle $fieldName $fieldValue
            }
            "Person or Group"
            {
                Add-SPOUserFieldtoList $listTitle $fieldName
            }
            "Calculated"
            {
                Add-SPOCalculatedFieldtoList $listTitle $fieldName $fieldValue
            }
        }
    }
}
