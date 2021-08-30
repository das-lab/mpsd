function Export-PSCredential { 
    
    [cmdletbinding()]
	param (
        [parameter(Mandatory=$true)]
        [pscredential]$Credential = (Get-Credential),
        
        [parameter()]
        [Alias("FullName")]
        [validatescript({
            Test-Path -Path (Split-Path -Path $_ -Parent)
        })]
        [string]$Path = "credentials.$env:COMPUTERNAME.xml",

        [switch]$Passthru
    )
	
	
	$export = New-Object -TypeName PSObject -Property @{
        UserName = $Credential.Username
        EncryptedPassword = $Credential.Password | ConvertFrom-SecureString
    }
	
	
	Try
    {
        $export | Export-Clixml -Path $Path -ErrorAction Stop
        Write-Verbose "Saved credentials for $($export.Username) to $Path"

	    if($Passthru)
        {
            
	        Get-Item $Path -ErrorAction Stop
        }
    }
    Catch
    {
	    Write-Error "Error saving credentials to '$Path': $_"
    }
}