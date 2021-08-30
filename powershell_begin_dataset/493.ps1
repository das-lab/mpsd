

function Mount-NetworkDirectories{


	

    param(
        [parameter(Mandatory=$true)]
        [string[]] 
        $Urls
    )
	
    
    
    
    if (Get-Command "net.exe"){
	
        $DriveLetters = Get-AvailableDriveLetter

        foreach($Url in $Urls){
        
            $Index =  [array]::IndexOf($Urls, $Url)

            $DriveLetter = $DriveLetters[$Index] + ":"

            Write-Host "Mount url:" $Url "to:" $DriveLetter

            & net use $DriveLetter $Url            
        }

        Read-Host "To dismount press Enter"

        foreach($Url in $Urls){

            $Index =  [array]::IndexOf($Urls, $Url)

            $DriveLetter = $DriveLetters[$Index] + ":"

            Write-Host "Dismount drive" $DriveLetter

            & net use $DriveLetter /Delete 
        }        
        
    }else{

        throw "net command is not available"

    }        
}