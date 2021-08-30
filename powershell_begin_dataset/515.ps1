

function Enable-SPBlobCache{



    [CmdletBinding()]
    param( 
	
		[Parameter(Mandatory=$true)]
		[String]
		$Identity,
		
		[Parameter(Mandatory=$false)]
		[String]
		$Path = "E:\Blobcache"
	)
	
	
	
	
	if(-not (Get-PSSnapin "Microsoft.SharePoint.PowerShell" -ErrorAction SilentlyContinue)){Add-PSSnapin "Microsoft.SharePoint.PowerShell"}
	
    
    
    
	$SPWebApplication = Get-SPWebApplication -Identity $Identity	
	$SPWebApp = $SPWebApplication.Read()

	
	$configMod1 = New-Object Microsoft.SharePoint.Administration.SPWebConfigModification
	$configMod1.Path = "configuration/SharePoint/BlobCache" 
	$configMod1.Name = "enabled" 
	$configMod1.Sequence = 0
	$configMod1.Owner = "BlobCacheMod" 
	
	
	
	
	$configMod1.Type = 1
	$configMod1.Value = "true" 

	
	$configMod2 = New-Object Microsoft.SharePoint.Administration.SPWebConfigModification
	$configMod2.Path = "configuration/SharePoint/BlobCache" 
	$configMod2.Name = "max-age" 
	$configMod2.Sequence = 0
	$configMod2.Owner = "BlobCacheMod" 

	
	
	
	$configMod2.Type = 1
	$configMod2.Value = "86400" 
	
	
	$configMod3 = New-Object Microsoft.SharePoint.Administration.SPWebConfigModification
	$configMod3.Path = "configuration/SharePoint/BlobCache" 		
	$configMod3.Name = "location"
	$configMod3.Sequence = 0
	$configMod3.Owner = "BlobCacheMod" 
	$configMod3.Type = 1
	$configMod3.Value = $Path
	
	
	$SPWebApp.WebConfigModifications.Add($configMod1)
	$SPWebApp.WebConfigModifications.Add($configMod2)
	$SPWebApp.WebConfigModifications.Add($configMod3)
	$SPWebApp.Update()
	$SPWebApp.Parent.ApplyWebConfigModifications()
} 