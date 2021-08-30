

function Get-CleanSPUrl {



	param(
		[Parameter(Mandatory=$true)]
		[String]
		$Url
	)
    	
	
	
	
    
    
    [Uri]$Url = $Url
  	
    
	if($Url -match "(/Forms/).*?\.(aspx$)"){
    
        
        
        [Uri]$ListUrl =  $Url.AbsoluteUri -replace "(/Forms/).*?\.(aspx)",""
        [Uri]$WebUrl = $Url.AbsoluteUri -replace "/([^/]*)(/Forms/).*?\.(aspx)",""
        
        @{ListUrl=$ListUrl;WebUrl=$Weburl}
        
    }elseif($Url -match "(/Lists/).*?\.(aspx$)"){
    
        
        
        [Uri]$ListUrl =  $Url.AbsoluteUri -replace "/([^/]*)\.(aspx)",""
        [Uri]$WebUrl = $Url.AbsoluteUri -replace "(/Lists/).*?\.(aspx)",""
        
        @{ListUrl=$ListUrl;WebUrl=$Weburl}
        
    }elseif($Url -match "/SitePages/Homepage.aspx$" -or $Url -match "/default.aspx$"){
        
        
        
        [uri]$WebUrl = $Url -replace "/SitePages/Homepage.aspx", "" -replace "/default.aspx",""
        
        @{WebUrl=$Weburl}
         
	}else{        
		 @{WebUrl=$Url}
	}
}