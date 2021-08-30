function Get-LoggedOnUser
{
	
	[OutputType([pscustomobject])]
	[CmdletBinding()]
	param
	(
		[Parameter()]
		[ValidateNotNullOrEmpty()]
		[string[]]$ComputerName = $env:COMPUTERNAME
	)
	begin
	{
		$ErrorActionPreference = 'Stop'
	}
	process
	{
		try
		{
			foreach ($comp in $ComputerName)
			{
				$output = @{ 
					ComputerName = $comp 
					UserName = 'Unknown'
					ComputerStatus = 'Offline'
				}
				if (Test-Connection -ComputerName $comp -Count 1 -Quiet) {
					$output.UserName = (Get-WmiObject -Class win32_computersystem -ComputerName $comp).UserName
					$output.ComputerStatus = 'Online'
				}
				[pscustomobject]$output
			}
		}
		catch
		{
			$PSCmdlet.ThrowTerminatingError($_)
		}
	}
}
