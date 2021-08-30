function Wait-PSFMessage
{

	[CmdletBinding()]
	param (
		[PSFDateTime]
		$Timeout = "5m",
		
		[switch]
		$Terminate
	)
	
	begin
	{
		
		function Test-LogFlushed
		{
			[OutputType([bool])]
			[CmdletBinding()]
			param (
				
			)
			
			
			if ([PSFramework.Message.LogHost]::OutQueueLog.Count -gt 0) { return $false }
			if ([PSFramework.Message.LogHost]::OutQueueError.Count -gt 0) { return $false }
			
			
			if ([PSFramework.Logging.ProviderHost]::LoggingState -like 'Writing') { return $false }
			if ([PSFramework.Logging.ProviderHost]::LoggingState -like 'Initializing') { return $false }
			
			return $true
		}
		
	}
	process
	{
		if (([PSFramework.Message.LogHost]::OutQueueLog.Count -gt 0) -or ([PSFramework.Message.LogHost]::OutQueueError.Count -gt 0))
		{
			if ((Get-PSFRunspace -Name 'psframework.logging').State -notlike 'Running') { Start-PSFRunspace -Name 'psframework.logging' }
		}
		while ($Timeout.Value -gt (Get-Date))
		{
			if (Test-LogFlushed)
			{
				break
			}
			Start-Sleep -Milliseconds 50
		}
		
		if ($Terminate)
		{
			Stop-PSFRunspace -Name 'psframework.logging'
		}
	}
}