

function Backup-AllSPSites{



	[CmdletBinding()]
	param(
		[Parameter(Position=0, Mandatory=$true)]
		[String]
		$Path 
	)
	
	
	
	
	if(-not (Get-PSSnapin "Microsoft.SharePoint.PowerShell" -ErrorAction SilentlyContinue)){Add-PSSnapin "Microsoft.SharePoint.PowerShell"}
	
	
	
	
    $SPSites = $SPWebApp | Get-SPsite -Limit all 

    if(!(Test-Path -path $Path)){New-Item $Path -Type Directory}

    foreach($SPSite in $SPSites){
			
		Write-Progress -Activity "Backup SharePoint sites" -status $SPSite.HostName -percentComplete ([int]([array]::IndexOf($SPSites, $SPSite)/$SPSites.Count*100))
        
        
        [uri]$SPSiteUrl = $SPSite.Url
        
        
        $Name = $SPSiteUrl.Host + $(if($SPSiteUrl.LocalPath -ne "/"){$SPSiteUrl.LocalPath -replace "/","."})
        
        
        $BackupPath = Join-Path -Path $Path -ChildPath $Name

        
        if(!(Test-Path -path $BackupPath)){New-Item $BackupPath -Type Directory}

        
		$FileName = $Name + "
		$FilePath = Join-Path -Path $BackupPath -ChildPath $FileName

		 Write-host "Backup SharePoint Site: "$Name
		Backup-SPSite -Identity $SPSite.Url -Path $FilePath -Force -ErrorAction SilentlyContinue		
    }
}