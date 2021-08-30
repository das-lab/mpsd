function Get-Weekday {
		
	[CmdletBinding()]
	param (
		[Parameter(Mandatory)]
		[ValidatePattern('sunday|monday|tuesday|wednesday|thursday|friday|saturday')]
		[string]$Weekday
	)
	process {
		try {
			$Weekday = $Weekday.ToLower()
			
			$DesiredWeekDay = [regex]::Matches($Weekday, 'sunday|monday|tuesday|wednesday|thursday|friday|saturday').Value
			$Today = (Get-Date).Date
			if ($Weekday -match 'next') {
				
				$Range = 1..7
			} elseif ($Weekday -match 'last') {
				
				$Range = -1.. - 7
			} else {
				
				$Range = 1..7
			}
			$Range | foreach {
				$Day = $Today.AddDays($_);
				if ($Day.DayOfWeek -eq $DesiredWeekDay) {
					$Day.Date
				}
			}
		} catch {
			Write-Error $_.Exception.Message
			$false
		}
	}
}
