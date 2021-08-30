[CmdletBinding()]
param(
	[Parameter(
		Position=0,
		HelpMessage='Credentials to authenticate agains a remote computer')]
	[System.Management.Automation.PSCredential]
	[System.Management.Automation.CredentialAttribute()]
	$Credential
)
