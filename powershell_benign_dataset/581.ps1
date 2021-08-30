

function Connect-SSH{



	
	
	
	param (
        [parameter(Mandatory=$true)]
        [string[]]$Name,
        
        [parameter(Mandatory=$false)]
        [string]$User,
        
        [parameter(Mandatory=$false)]
        [int]$Port,
        
        [parameter(Mandatory=$false)]
        [string]$PrivatKey
	)


    
    
    
    if (Get-Command "putty"){ 
    
        
		$Servers = Get-RemoteConnection -Name $Name        
        
        if(!(Get-ChildItem -Path $PSconfigs.Path -Filter $PStemplates.WinSCP.Name -Recurse)){
        
            Write-Host "Copy $($PStemplates.WinSCP.Name) file to the config folder"        
    		Copy-Item -Path $PStemplates.WinSCP.FullName -Destination (Join-Path -Path $PSconfigs.Path -ChildPath $PStemplates.WinSCP.Name)
    	} 
    
        $IniFile = $(Get-ChildItem -Path $PSconfigs.Path -Filter $PStemplates.WinSCP.Name -Recurse).FullName

        $Servers | %{
    		
            
            if(!$Port){
                $_.Protocol | %{if($_.Name -eq "ssh" -and $_.Port -ne ""){$Port = $_.Port}}
            }
            if(!$Port -or $Port -eq 0){
                $Port = 22
            }

            
            $Servername = $_.Name
            
            
            if(!$User){$User = $_.User}
             
            
            if(!$PrivatKey){$PrivatKey = Invoke-Expression ($Command = '"' + $_.PrivatKey + '"')}
                        
            if($PrivatKey -eq ""){
                Invoke-Expression "putty $User@$Servername -P $Port -ssh" 
            }else{
                Invoke-Expression "putty $User@$Servername -P $Port -ssh -i '$PrivatKey'" 
            }
        }
    }
}