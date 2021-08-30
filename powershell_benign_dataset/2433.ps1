


 
[CmdletBinding()]
param
(
	[Parameter(Mandatory)]
	[ValidateNotNullOrEmpty()]
	[string]$Name,
	
	[Parameter(Mandatory)]
	[ValidateNotNullOrEmpty()]
	[string]$Server
)

$resolvParams = @{
	'Server' = $Server
	'DnsOnly' = $true
	'NoHostsFile' = $true
	'ErrorAction' = 'SilentlyContinue'
	'ErrorVariable' = 'err'
	'Name' = $Name
}
try
{
	if (Resolve-DnsName @resolvParams)
	{
		$true
	}
	elseif ($err -and ($err.Exception.Message -match '(DNS name does not exist)|(No such host is known)'))
	{
		$false
	}
	else
	{
		throw $err
	}
}
catch
{
	if ($_.Exception.Message -match 'No such host is known')
	{
		$false
	}
	else
	{
		throw $_	
	}
}