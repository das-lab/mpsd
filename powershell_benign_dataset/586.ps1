

function Connect-SCP{



	
	
	
	param (
        [parameter(Mandatory=$true)]
        [string[]]
        $Name,
        
        [parameter(Mandatory=$false)]
        [string]$User,
        
        [parameter(Mandatory=$false)]
        [int]$Port,
        
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
    	
        foreach($Server in $Servers){
        
            
            if(!$Port){
                $Server.Protocol | %{if($_.Name -eq "ssh" -and $_.Port -ne ""){$Port = $_.Port}}
            }
            if(!$Port -or $Port -eq 0){
                $Port = 22
            }

            
            $Servername = $Server.Name
            
            
            if(!$User){$User = $Server.User}
             
            
            if(!$PrivatKey){$PrivatKey = Invoke-Expression ($Command = '"' + $Server.PrivatKey + '"')}
                            
    		
            if($PrivatKey -eq ""){
                Invoke-Expression ("WinSCP scp://$User@$Servername" + ":$Port" + " /ini=$IniFile")
            }else{
                Invoke-Expression ("WinSCP scp://$User@$Servername" + ":$Port" + " /privatekey='$PrivatKey'" + " /ini=$IniFile")
            }    
        }
    }    
}