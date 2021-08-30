

function Connect-RDP{



	param (
        [parameter(Mandatory=$true)]
        [string[]]$Name
	)
    
    
    
    
    if ((Get-Command "cmdkey") -and (Get-Command "mstsc")){ 
    
        
        
        $Servers = Get-RemoteConnection -Name $Name
       
        if(!(Get-ChildItem -Path $PSconfigs.Path -Filter $PStemplates.RDP.Name -Recurse)){
        
            Write-Host "Copy $($PStemplates.RDP.Name) file to the config folder"        
    		Copy-Item -Path $PStemplates.RDP.FullName -Destination (Join-Path -Path $PSconfigs.Path -ChildPath $PStemplates.RDP.Name)
    	} 
		$RDPDefaultFile = $(Get-ChildItem -Path $PSconfigs.Path -Filter $PStemplates.RDP.Name -Recurse).Fullname		

        foreach($Server in $Servers){
		        
            $Servername = $Server.Name
            $Username = $Server.User

            
            $Null = Invoke-Expression "cmdkey /delete:'$Servername'"

            
            $Null = Invoke-Expression "cmdkey /generic:'$Servername' /user:'$Username'"

            
            Invoke-Expression "mstsc '$RDPDefaultFile' /v:$Servername"
	    }
    }
}
