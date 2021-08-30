function Get-ChefConfigItem
{
	
	
	[CmdletBinding()]
	param
	(
		[Parameter()]
		[ValidateNotNullOrEmpty()]
		[string]$Name
	)
	
	$line = Get-Content -Path $ConfigFilePath | where { $_ -match $Name }
	if ($line)
	{
		foreach ($l in $line)
		{
			[pscustomobject]@{
				'Name' = $l.Split(' ')[0].Trim()
				'Value' = ($l.Split(' ')[-1] -replace "'").Trim()
			}
		}
	}
}

function Set-ChefConfigItem
{
	
	
	[CmdletBinding()]
	param
	(
		[Parameter(Mandatory, ValueFromPipelineByPropertyName)]
		[ValidateNotNullOrEmpty()]
		[string]$Name,
		
		[Parameter(Mandatory)]
		[ValidateNotNullOrEmpty()]
		[string]$Value
		
	)
	
	$config = Get-Content -Path $ConfigFilePath | where { $_ -notmatch $Name }
	
	$config += "$Name '$Value'"
	
	$config | Out-File $ConfigFilePath
}