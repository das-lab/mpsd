

function Add-SPOList
{
	[CmdletBinding()]
	param
	(
		[Parameter(Mandatory=$true, Position=1)]
		[string]$listTitle,
		
		[Parameter(Mandatory=$false, Position=1)]
		[Microsoft.SharePoint.Client.ListTemplateType]$templateType = "genericList"
	)
	
    $web = $clientContext.Web
    
    
    $lists = $web.Lists
    $clientContext.Load($lists)
    $clientContext.ExecuteQuery()
    
    $listTitles = $lists | select -ExpandProperty Title
    
    if(!($listTitles -contains $listTitle))
    {
        $listCreationInfo = new-object Microsoft.SharePoint.Client.ListCreationInformation
        $listCreationInfo.TemplateType = $templateType
        $listCreationInfo.Title = $listTitle
        $listCreationInfo.QuickLaunchOption = [Microsoft.SharePoint.Client.QuickLaunchOptions]::on

        $list = $web.Lists.Add($listCreationInfo)
        
        $clientContext.ExecuteQuery()
        
		Write-Host "List '$listTitle' is created succesfully" -foregroundcolor black -backgroundcolor green
    }
    else
    {
		Write-Host "List '$listTitle' already exists" -foregroundcolor black -backgroundcolor yellow
    }
}
