

function Get-RemoteConnection{

	param(
        [parameter(Mandatory=$false)]
        [string[]] 
        $Name
	)
    
    
	
	
	function New-ObjectRemoteConnection{
        param(
            [string]$Name,
            [string]$Server,
            [string]$User,
            [string]$Description,
            [string]$SnapIns,
    		[string]$PrivatKey
        )
        New-Object PSObject -Property @{
            Name = $Name
            Server = $Server
            User = $User
            Description = $Description
            SnapIns = $SnapIns
    		PrivatKey = $PrivatKey
        }
    }
    
	
	
	
        
    
    $ServerConfigs = Get-ChildItem -Path $PSconfigs.Path -Filter $PSconfigs.Server.Filter -Recurse | %{
            [xml]$(get-content $_.FullName)} | %{
                $_.Content.Server}
    
        
    
    if(-not $Name){
    
        $ServerConfigs | Sort Key
        
    }elseif($Name){

        $Matches = $ServerConfigs | 
            %{$Server = $_; $Name | 
                %{if(($Server.Key -contains $_) -or ($Server.Name -contains $_)){$Server}}}
        
        if($Matches -eq $Null){
        
            $Name | %{New-ObjectRemoteConnection -Name $_}
            
        }else{
            
            $Matches
        } 
               
    }else{
    
        throw "Enter values for the following parameters: Name[]"  
    }
}