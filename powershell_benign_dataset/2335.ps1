

function Get-UnlinkedGpo
{
	
	[OutputType([pscustomobject])]
	[CmdletBinding()]
	param()
	begin
	{
		$ErrorActionPreference = 'Stop'
	}
	process
	{
		try
		{
			$gpoReport = [xml](Get-GPOReport -All -ReportType XML)
			@($gpoReport.GPOs.GPO).where({ -not $_.LinksTo }).foreach({
					[pscustomobject]@{ Name = $_.Name }	
				})
		}
		catch
		{
			$PSCmdlet.ThrowTerminatingError($_)
		}
	}
}