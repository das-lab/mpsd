

function Get-DisabledGpo
{
	
	[OutputType([pscustomobject])]
	[CmdletBinding()]
	param ()
	begin
	{
		$ErrorActionPreference = 'Stop'
	}
	process
	{
		try
		{
			@(Get-GPO -All).where({ $_.GpoStatus -like '*Disabled' }).foreach({
					[pscustomobject]@{
						Name = $_.DisplayName
						DisabledSettingsCategory = ([string]$_.GpoStatus).TrimEnd('Disabled')
					}	
				})
		}
		catch
		{
			$PSCmdlet.ThrowTerminatingError($_)
		}
	}
}