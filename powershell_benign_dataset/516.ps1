

function Disable-SPBlobCache{



    [CmdletBinding()]
    param( 
	
		[Parameter(Mandatory=$true)]
		[string]
		$Identity
	)
	
	
	
	
	if(-not (Get-PSSnapin "Microsoft.SharePoint.PowerShell" -ErrorAction SilentlyContinue)){Add-PSSnapin "Microsoft.SharePoint.PowerShell"}
	
    
    
    
	$SPWebApplication = Get-SPWebApplication -Identity $Identity
	$SPWebApp = $SPWebApplication.Read()
	$Mods = @()
	foreach($Mod in $SPWebApp.WebConfigModifications){
		if($Mod.Owner -eq "BlobCacheMod"){
			$Mods += $Mod
		}
	  }

	foreach($Mod in $Mods){
		[void] $SPWebApp.WebConfigModifications.Remove($Mod)
	}

	$SPWebApp.Update()
	$SPWebApp.Parent.ApplyWebConfigModifications()
} 
