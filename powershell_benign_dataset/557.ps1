

function Add-SPOFolder
{
	[CmdletBinding()]
	param
	(
		[Parameter(Mandatory=$true, Position=1)]
		[string]$folderUrl
	)
	
    
    $folderNameArr = $folderurl.Split('/')
    $folderName = $folderNameArr[$folderNameArr.length-1]
	
    $folderUrl = Join-SPOParts -Separator '/' -Parts $clientContext.Web.ServerRelativeUrl, $folderUrl
	$parentFolderUrl = $folderUrl.Replace('/' + $folderName,'')
    
 	
 
    
    $web = $clientContext.Web
    $folder = $web.GetFolderByServerRelativeUrl($folderUrl)
    $clientContext.Load($folder)
    $alreadyExists = $false
 
    
    try
    {
        $clientContext.ExecuteQuery();
        
        if ($folder.Path)
        {
            $alreadyExists = $true;
        }
    }
    catch { }
 
    if (!$alreadyExists)
    {
        
		Write-Host "Create folder $folderName at $parentFolderUrl" -foregroundcolor black -backgroundcolor yellow
        
        
        $newItemInfo = new-object Microsoft.SharePoint.Client.ListItemCreationInformation
        $newItemInfo.UnderlyingObjectType = [Microsoft.SharePoint.Client.FileSystemObjectType]::Folder
        $newItemInfo.LeafName = $folderName
        $newItemInfo.FolderUrl = $parentFolderUrl
        
        
        $listUrl = Join-SPOParts -Separator '/' -Parts $clientContext.Web.ServerRelativeUrl, $folderNameArr[1]
		
		
		
		
		$method = [Microsoft.SharePoint.Client.ClientContext].GetMethod("Load")
		$loadMethod = $method.MakeGenericMethod([Microsoft.SharePoint.Client.List])

		$parameter = [System.Linq.Expressions.Expression]::Parameter(([Microsoft.SharePoint.Client.List]), "list")
		$expression = [System.Linq.Expressions.Expression]::Lambda(
			[System.Linq.Expressions.Expression]::Convert(
				[System.Linq.Expressions.Expression]::PropertyOrField(
					[System.Linq.Expressions.Expression]::PropertyOrField($parameter, "RootFolder"),
					"ServerRelativeUrl"
				),
				[System.Object]
			),
			$($parameter)
		)
		$expressionArray = [System.Array]::CreateInstance($expression.GetType(), 1)
		$expressionArray.SetValue($expression, 0)
		
		$lists = $web.Lists
		
		$clientContext.Load($lists)
		$clientContext.ExecuteQuery()
		
		$list = $null
		
		foreach	($listfinder in $lists) {
			$loadMethod.Invoke($clientContext, @($listfinder, $expressionArray))
			
			$clientContext.ExecuteQuery()
			
			if ($listfinder.RootFolder.ServerRelativeUrl -eq $listUrl)
			{
				$list = $listfinder
			}
		}
		
        $newListItem = $list.AddItem($newItemInfo)
 
        
        $newListItem.Update()
 
        
        $clientContext.Load($list);
        $clientContext.ExecuteQuery();
    }
}
