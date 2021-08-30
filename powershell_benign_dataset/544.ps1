

function Add-SPOListItems
{
	[CmdletBinding()]
	param
	(
		[Parameter(Mandatory=$true, Position=1)]
		[string]$csvPath, 
		
		[Parameter(Mandatory=$true, Position=2)]
		[string]$listName
	)

    $list = $clientContext.Web.Lists.GetByTitle($listName)
    
    $csvPathUnicode = $csvPath -replace ".csv", "_unicode.csv"
    Get-Content $csvPath | Out-File $csvPathUnicode
    $csv = Import-Csv $csvPathUnicode -Delimiter ';'
    foreach ($line in $csv)
    {
        $itemCreateInfo = new-object Microsoft.SharePoint.Client.ListItemCreationInformation
        $listItem = $list.AddItem($itemCreateInfo)
        
        foreach ($prop in $line.psobject.properties)
        {
            $listItem[$prop.Name] = $prop.Value
        }
        
        $listItem.Update()
        
        $clientContext.ExecuteQuery()
    }
}
