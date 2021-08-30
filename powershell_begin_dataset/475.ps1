

function Import-PSCredential{



	param(
        [Parameter(Mandatory=$false)]
		[String]
		$Path = "temp.credentials.config.xml"
	)

	
	
	
    
	
	$Import = Import-Clixml $Path 
	
	
	if ( !$Import.UserName -or !$import.EncryptedPassword ) {
		Throw "Input is not a valid ExportedPSCredential object, exiting."
	}

    
	$Username = $Import.Username
	
	
	$SecurePassword = $Import.EncryptedPassword | ConvertTo-SecureString
	
	
	New-Object System.Management.Automation.PSCredential $Username, $SecurePassword
}