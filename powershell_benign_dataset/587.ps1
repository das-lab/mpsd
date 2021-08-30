

function Connect-FTP{



	param (
        [parameter(Mandatory=$true)]
        [string[]]$Name,
		
        [parameter(Mandatory=$false)]
        [string]$User,
		
        [parameter(Mandatory=$false)]
        [int]$Port,
		
        [switch]$Secure,
				
        [parameter(Mandatory=$false)]
        [string]$PrivatKey
	)


	
	
	
    
	if (Get-Command "winscp"){ 
    
    	
		$Servers = Get-RemoteConnection -Name $Name        
        
        if(!(Get-ChildItem -Path $PSconfigs.Path -Filter $PStemplates.WinSCP.Name -Recurse)){
        
            Write-Host "Copy $($PStemplates.WinSCP.Name) file to the config folder"        
    		Copy-Item -Path $PStemplates.WinSCP.FullName -Destination (Join-Path -Path $PSconfigs.Path -ChildPath $PStemplates.WinSCP.Name)
    	} 
    
        $IniFile = $(Get-ChildItem -Path $PSconfigs.Path -Filter $PStemplates.WinSCP.Name -Recurse).FullName
        
        $SftpPort = 22
        $FtpPort = 21
                
        foreach($Server in $Servers){     
    		
            
            if(!$Port){
                
                
        		$Server.Protocol | %{
                
                    
        			if($_.Name -eq "ftp"){
                                            
        				$Protocol = "ftp"
                        
        				if($_.Port -ne ""){
                        
        					$Port = $_.Port
        				}else{
                            $Port = $FtpPort
                        }
                        
                    
        			}elseif($_.Name -eq "sftp"){
                    
    					$Protocol = "sftp"
                        
    					if($_.Port -ne ""){
    						$Port = $_.Port
                        }else{
                            $Port = $SftpPort
                        }              
                   }
               }        
            }
            
            
            if(!$Port -or $Port -eq 0){
                if($Secure){
                    $Port = $SftpPort
                }else{
                    $Port = $FtpPort
                }
            }
           
            
            if(!$Protocol){
                if($Secure){
                    $Protocol = "sftp"
                }else{
                    $Protocol = "ftp"
                }
            }

    		
    		$Servername = $Server.Name
    				
    		
    		if(!$User){$User = $Server.User}
    		
            
            if(!$PrivatKey){$PrivatKey = Invoke-Expression ($Command = '"' + $Server.PrivatKey + '"')}
            
            if($PrivatKey){
                Invoke-Expression ("WinSCP $Protocol"+"://$User@$Servername"+":$Port"+" /privatekey='$PrivatKey'" + " /ini=$IniFile")
            }else{
                Invoke-Expression ("WinSCP $Protocol"+"://$User@$Servername"+":$Port" + " /ini=$IniFile")
            }
        }
    }
}