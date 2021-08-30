function Get-EC2InstanceMetadata
{
	
	[CmdletBinding()]
	[OutputType('System.Management.Automation.PSCustomObject')]
	param
	(
		[Parameter(Mandatory)]
		[ValidateNotNullOrEmpty()]
		[string]$Path,
		
		[Parameter()]
		[ValidateNotNullOrEmpty()]
		[string]$BaseUri = 'http://169.254.169.254/latest/meta-data'
	)
	
	$Uri = "$BaseUri/$Path"
	Write-Verbose -Message "Invoking HTTP request for URI [$($Uri)]"
	$result = Invoke-WebRequest -Uri $Uri
	if ($result.StatusCode -ne 200)
	{
		throw "The HTTP request failed when looking up URI [$Uri]"
	}
	
	$result.Content.Split("`n")
}