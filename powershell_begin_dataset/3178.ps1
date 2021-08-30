function Import-PSCredential { 
    
    [cmdletbinding()]
	param (
        [Alias("FullName")]
        [validatescript({
            Test-Path -Path $_
        })]
        [string]$Path = "credentials.$env:computername.xml",

        [string]$GlobalVariable
    )

	
	$import = Import-Clixml -Path $Path -ErrorAction Stop

	
	if ( -not $import.UserName -or -not $import.EncryptedPassword ) {
		Throw "Input is not a valid ExportedPSCredential object."
	}

	
	$Credential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $import.Username, $($import.EncryptedPassword | ConvertTo-SecureString)

	if ($OutVariable)
    {
		New-Variable -Name $GlobalVariable -scope Global -value $Credential -Force
	} 
    else
    {
		$Credential
	}
}