

function Get-PPApp{



	param(
        [Parameter(Mandatory=$false)]
		[String]
		$Name,
        
        [switch]
        $Installed,
        
        [switch]
        $CurrentInstalled
	)
    
    
    $CurrentLocation = (Get-Location).Path
    
    
    
    
    $CurrentAppDataFile = Join-Path $CurrentLocation $PSconfigs.App.DataFile
    
    
    $GlobalAppDataFile = (Get-ChildItem -Path $PSconfigs.Path -Filter $PSconfigs.App.DataFile -Recurse).Fullname
    
    
    $InstalledApps = Get-PPConfiguration -Path $GlobalAppDataFile | %{$_.Content.App}
    
    
    if(Test-Path $CurrentAppDataFile){
        $CurrentInstalledApps = Get-PPConfiguration -Path $CurrentAppDataFile | ForEach-Object{$_.Content.App}
    }    
        
    $(if($Name){
    
        Get-PPConfiguration -Filter $PSconfigs.App.Filter -Path $PSlib.Path | %{$_.Content.App | where{$_.Name -match $Name}}
        
    }else{
    
        Get-PPConfiguration $PSconfigs.App.Filter -Path $PSlib.Path | %{$_.Content.App}
        
    }) | %{
    
        if($Installed){
                
            $Name = $_.Name
            $Version = $_.Version
            
            $InstalledApps | where{($_.Name -eq $Name) -and ($_.Version -eq $Version)}
                  
        
        }elseif($CurrentInstalled){
        
            $Name = $_.Name
            $Version = $_.Version
            
            $CurrentInstalledApps | where{($_.Name -eq $Name) -and ($_.Version -eq $Version)}
        
        }else{
        
            $_
        }
    }
}