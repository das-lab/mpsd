

function Get-SPUrl {



	param(
		[Parameter(Mandatory=$true)]
		$SPobject
	)
    	
	
	
	
    
    if($SPobject.PsObject.TypeNames -contains "System.String"){
    
        [Uri]$Url = $SPobject
      	
    	if($Url -match "(/Forms/).*?\.(aspx$)"){
            
            
            New-Object PSObject -Property @{
                Url = (($Url.Scheme + "://" + $Url.Host + $Url.LocalPath) -replace "(/Forms/).*?\.(aspx)","")
                WebUrl = (($Url.Scheme + "://" + $Url.Host + $Url.LocalPath) -replace "/([^/]*)(/Forms/).*?\.(aspx)","")
            }  
            
        }elseif($Url -match "(/Lists/).*?\.(aspx$)"){
        
            
            New-Object PSObject -Property @{
                Url = (($Url.Scheme + "://" + $Url.Host + $Url.LocalPath) -replace "/([^/]*)\.(aspx)","")
                WebUrl = (($Url.Scheme + "://" + $Url.Host + $Url.LocalPath) -replace "(/Lists/).*?\.(aspx)","")
            } 
            
        }elseif($Url -match "_layouts"){
		
			
            New-Object PSObject -Property @{
                Url = ((($Url.Scheme + "://" + $Url.Host + $Url.LocalPath) -replace "(/_layouts/).+","")  -replace "\\","/")
            }
			
            
        }elseif($Url -match "/SitePages/Homepage.aspx$" -or $Url -match "/default.aspx$"){
        
            
            New-Object PSObject -Property @{
                Url = (($Url.Scheme + "://" + $Url.Host + $Url.LocalPath) -replace "/SitePages/Homepage.aspx", "" -replace "/default.aspx","")
            }
            
    	}elseif($Url -match "_vti_history"){
        
            
            New-Object PSObject -Property @{
                Url = ((($Url.Scheme + "://" + $Url.Host + $Url.LocalPath) -replace "_vti_history/(.*[0-9])/","")  -replace "\\","/")
            }           
        
		}else{ 
        
            
            New-Object PSObject -Property @{
                Url = ($Url.Scheme + "://" + $Url.Host + $Url.LocalPath)
            }
    	}
        
    }elseif($SPobject.PsObject.TypeNames -contains "Microsoft.SharePoint.SPList"){
    
        New-Object PSObject -Property @{
            Url = (([Uri]$SPobject.Parentweb.Url).Scheme + "://" + ([uri]$SPobject.Parentweb.Url).host + $SPobject.RootFolder.ServerRelativeUrl)
        }
        
    }elseif($SPobject.PsObject.TypeNames -contains "Microsoft.SharePoint.SPWeb"){
    
        New-Object PSObject -Property @{
            Url = $SPobject.Url
        }
        
    }elseif($SPobject.PsObject.TypeNames -contains "Microsoft.SharePoint.SPListItem"){
    
        New-Object PSObject -Property @{
            Url = ($SPobject.ParentList.ParentWeb.Url + "/" + $SPobject.Url)
        }
    }        
}