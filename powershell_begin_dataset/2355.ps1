

function Get-EmptyGroup
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
			@(Get-ADGroup -Filter * -Properties isCriticalSystemObject,Members).where({ (-not $_.isCriticalSystemObject) -and ($_.Members.Count -eq 0) })
		}
		catch
		{
			$PSCmdlet.ThrowTerminatingError($_)
		}
	}
}