function New-PSFSessionContainer
{

	[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseShouldProcessForStateChangingFunctions", "")]
	[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSPossibleIncorrectUsageOfAssignmentOperator", "")]
	[CmdletBinding()]
	param (
		[Parameter(Mandatory = $true)]
		[PSFComputer]
		$ComputerName,
		
		[Parameter(Mandatory = $true, ValueFromPipeline = $true)]
		[object[]]
		$Session,
		
		[switch]
		$EnableException
	)
	
	begin
	{
		$container = New-Object PSFramework.ComputerManagement.SessionContainer
		$container.ComputerName = $ComputerName
	}
	process
	{
		foreach ($sessionItem in $Session)
		{
			if ($null -eq $sessionItem) { continue }
			
			if (-not ($sessionName = [PSFramework.ComputerManagement.ComputerManagementHost]::KnownSessionTypes[$sessionItem.GetType()]))
			{
				Stop-PSFFunction -String 'New-PSFSessionContainer.UnknownSessionType' -StringValues $sessionItem.GetType().Name, $sessionItem -Continue -EnableException $EnableException
			}
			
			$container.Connections[$sessionName] = $sessionItem
		}
	}
	end
	{
		$container
	}
}