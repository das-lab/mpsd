
function Get-UserCredential
{
	
	
	[CmdletBinding()]
	param
	(
		[Parameter()]
		[ValidateNotNullOrEmpty()]
		[pscredential]$Credential
	)
	try
	{
		if (-not $PSBoundParameters.ContainsKey('Credential')) {
			if ((Get-KeystoreDefaultCertificate) -isnot 'System.Security.Cryptography.X509Certificates.X509Certificate2')
			{
				$Credential = Get-Credential -UserName (whoami) -Message 'Cannot find a suitable credential. Please input your password to use.'
			}
			else
			{
				$Credential = Get-KeyStoreCredential -Name 'svcOrchestrator'
			}
		}
		$Credential
	}
	catch
	{
		$PSCmdlet.ThrowTerminatingError($_)
	}
}
