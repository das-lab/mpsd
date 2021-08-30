

function Backup-AllSPLists{



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

            $SPLists = $SPWeb | foreach{$_.Lists}

            foreach($SPList in $SPLists){
                
                Write-Progress -Activity "Backup SharePoint lists" -status $SPList.title -percentComplete ([int]([array]::IndexOf($SPLists, $SPList)/$SPLists.Count*100))
                
                $RelativePath = $SPSite.HostName + "\" + $SPList.RootFolder.ServerRelativeUrl.Replace("/","\")
                $BackupPath = Join-Path -Path $Path -ChildPath $RelativePath

                if(!(Test-Path -path $BackupPath)){New-Item $BackupPath -Type Directory}

                $FileName = $SPList.Title + "
                $FilePath = Join-Path -Path $BackupPath -ChildPath $FileName
                
                Export-SPWeb -Identity $SPList.ParentWeb.Url -ItemUrl $SPList.RootFolder.ServerRelativeUrl -Path $FilePath  -IncludeVersions All -IncludeUserSecurity -Force -NoLogFile -CompressionSize 1000
                
            }
        }
    }
}