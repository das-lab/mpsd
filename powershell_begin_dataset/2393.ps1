

function Get-Uptime
{
	
	[OutputType('System.Management.Automation.PSCustomObject')]
	[CmdletBinding()]
	param
	(
		[Parameter(ValueFromPipeline)]
		[string[]]$ComputerName = $env:COMPUTERNAME
	)
	begin 
	{
		$today = Get-Date 
	}
	process
	{
		foreach ($computer in $ComputerName) 
		{
			try 
			{
				
				$output = [Ordered]@{
					'ComputerName' = $computer
					'StartTime' = $null
					'Uptime (Months)' = $null
					'Uptime (Days)' = $null
					'Status' = $null
					'MightNeedPatched' = $false
				}
				
				
				
				if (-not (Test-Connection -ComputerName $computer -Count 1 -Quiet))
				{
					$output.Status = 'OFFLINE'
					throw "The computer [$($computer)] is offline."
				}
				
				
				$filterHt = @{
					'LogName' = 'System'
					'ID' = 6005
				}
				
				$startEvent = Get-WinEvent -ComputerName $computer -FilterHashtable $filterHt | select -First 1
				
				
				if (-not $startEvent)
				{
					$output.Status = 'ERROR'
					throw "Unable to determine uptime for computer [$($computer)]"
				}
				
				$output.Status = 'OK'
				
				
				$output.StartTime = [dateTime]$startEvent.TimeCreated
				
				
				$daysUp = [math]::Round((New-TimeSpan -Start $startEvent.TimeCreated -End $today).TotalDays, 2)
				$output.'Uptime (Days)' = $daysUp
				
				
				if ($daysUp -gt 30)
				{
					$output.'MightNeedPatched' = $true
				}
			}
			catch
			{
				
				Write-Warning $_.Exception.Message
			}
			finally
			{
				
				[pscustomobject]$output
			}
		}
	}
}