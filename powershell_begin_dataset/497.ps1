

function Get-AvailableDriveLetter {

	param(
		[parameter(Mandatory=$False)]
		[Switch]
		$ReturnFirstLetterOnly,
		[parameter(Mandatory=$False)]
		$FavoriteDriveLetter
	)

	if($ReturnFirstLetterOnly -eq $true -and $FavoriteDriveLetter -ne $null){
		throw "Only one parameter is possible for this function"
		exit
	}	
	
	
    [char[]]$TempDriveLetters = [char[]]'EFGHIJKLMNOPQRSTUVWXYZ' | ? { (Get-PSDrive $_ -ErrorAction 'SilentlyContinue') -eq $null }


	if ($ReturnFirstLetterOnly -eq $true)
	{
		$TempDriveLetters[0]
        
	}elseif($FavoriteDriveLetter -ne $null){
    
        if($TempDriveLetters  -contains $FavoriteDriveLetter){
        
	       $FavoriteDriveLetter
           
        }else{
        
		  $TempDriveLetters[0]
          
        }
    }else{
    
	    $TempDriveLetters
        
    }		
}

