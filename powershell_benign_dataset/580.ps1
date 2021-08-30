

function Add-SPOField
{
	[CmdletBinding()]
	param
	(
		[Parameter(Mandatory=$true, Position=1)]
		[string] $listTitle, 
		
		[Parameter(Mandatory=$true, Position=2)]
		[string] $fieldName, 
		
		[Parameter(Mandatory=$true, Position=3)]
		[string] $fieldXML
	)

    $web = $clientContext.Web
    $list = $web.Lists.GetByTitle($listTitle)
    $fields = $list.Fields
    $clientContext.Load($fields)
    $clientContext.ExecuteQuery()

    if (!(Test-SPOField $list $fields $fieldName))
    {
        $field = $list.Fields.AddFieldAsXml($fieldXML, $true, [Microsoft.SharePoint.Client.AddFieldOptions]::AddToAllContentTypes);
        $list.Update()
        $clientContext.ExecuteQuery()
        
		Write-Host "Field $fieldName added to list $listTitle" -foregroundcolor black -backgroundcolor yellow
    }
    else
    {
		Write-Host "Field $fieldName already exists in list $listTitle" -foregroundcolor black -backgroundcolor yellow
    }
}
