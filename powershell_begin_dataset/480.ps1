

function Export-PSCredential{



	param(
        [Parameter(Mandatory=$true)]
		$Credential = (Get-Credential),

        [Parameter(Mandatory=$false)]
		[String]
		$Path
	)

	
	
	
    
	switch ($Credential.GetType().Name) {

		PSCredential{ 

			continue
		}

		String{

			$Credential = Get-Credential -credential $Credential 
		}

		default{ 

            Throw "You must specify a credential object to export." }
	}	

	$Export = "" | Select-Object Username, EncryptedPassword
	$Export.PSObject.TypeNames.Insert(0,"ExportedPSCredential")	
	$Export.Username = $Credential.Username
	$Export.EncryptedPassword = $Credential.Password | ConvertFrom-SecureString

    if($Path -ne ""){

        if($Path.EndsWith("\")){
            
             $Path = $Path + "temp.credential.config.xml"
        }

        if(!(Test-Path (Split-Path $Path -Parent))){New-Item -ItemType directory -Path (Split-Path $Path -Parent) | Out-Null}
    
    }else{
               
        $Path = "temp.credential.config.xml"
    }

	$Export | Export-Clixml $Path

	Get-Item $Path
}