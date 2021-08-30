

function Backup-AllSPWebs{



	[CmdletBinding()]
	param(
		[Parameter(Position=0, Mandatory=$true)]
		[String]
		$Path
	)
	
	
	
	
	if(-not (Get-PSSnapin "Microsoft.SharePoint.PowerShell" -ErrorAction SilentlyContinue)){Add-PSSnapin "Microsoft.SharePoint.PowerShell"}
	
	
	
	
    $SPSites = $SPWebApp | Get-SPsite -Limit all 

    foreach($SPSite in $SPSites){

        $SPWebs = $SPSite | Get-SPWeb -Limit all
        
        foreach ($SPWeb in $SPWebs){

            Write-Progress -Activity "Backup SharePoint websites" -status $SPWeb.title -percentComplete ([int]([array]::IndexOf($SPWebs, $SPWeb)/$SPWebs.Count*100))
                
            $RelativePath =  $SPSite.HostName + "\" + $SPWeb.RootFolder.ServerRelativeUrl.Replace("/","\").TrimEnd("\")
            $BackupPath = Join-Path -Path $Path -ChildPath $RelativePath

            if(!(Test-Path -path $BackupPath)){New-Item $BackupPath -Type Directory}

            $FileName = $SPWeb.Title + "
            $FilePath = Join-Path $BackupPath -ChildPath $FileName
                
            Export-SPWeb -Identity $SPWeb.Url -Path $FilePath  -IncludeVersions All -IncludeUserSecurity -Force -NoLogFile -CompressionSize 1000
                
        }
    }
}