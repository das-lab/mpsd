
[CmdletBinding()]
[OutputType('System.DirectoryServices.ActiveDirectorySecurity')]
param (
	[Parameter(Mandatory,
			   ValueFromPipeline,
			   ValueFromPipelineByPropertyName)]
	[string[]]$Hostname,
	
	[Parameter(ValueFromPipeline,
			   ValueFromPipelineByPropertyName)]
	[string]$DomainName = (Get-ADDomain).Forest,
	
	[ValidateSet('Forest', 'Domain')]
	[Parameter(ValueFromPipeline,
			   ValueFromPipelineByPropertyName)]
	[string[]]$AdDnsIntegration = 'Forest'
)

begin
{
	$ErrorActionPreference = 'Stop'
	Set-StrictMode -Version Latest
}

process
{
	try
	{
		$Path = "AD:\DC=$DomainName,CN=MicrosoftDNS,DC=$AdDnsIntegration`DnsZones,DC=$($DomainName.Split('.') -join ',DC=')"
		foreach ($Record in (Get-ChildItem -Path $Path))
		{
			if ($Hostname -contains $Record.Name)
			{
				Get-Acl -Path "ActiveDirectory:://RootDSE/$($Record.DistinguishedName)"
			}
		}
	}
	catch
	{
		Write-Error $_.Exception.Message
	}
}