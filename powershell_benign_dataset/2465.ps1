function New-LogEntry {
	
	[CmdletBinding()]
	param (
		[Parameter(ValueFromRemainingArguments = $true)]
		[string]$Message
	)
	begin {
		$FilePath = 'C:\MyWorkLog.csv'
		
		function Convert-TimeStringToTimeSpan($TimeString) {
			$AllowedLabels = (New-TimeSpan).Psobject.Properties.Name
			
			$AllowedLabels += $AllowedLabels | foreach { $_.TrimEnd('s') }
			
			$Values = $TimeString -split ' and '
			
			$Hours = 0
			foreach ($Value in $Values) {
				$Split = $Value.Split(' ')
				$Value = $Split[0]
				$Label = $Split[1]
				if ($AllowedLabels -notcontains $Label) {
					Write-Error "The label '$Label' is not a valid time label"
					return $false
				} elseif ($Value -notmatch '^\d+$') {
					Write-Error "The time value '$Value' is not a valid time interval"
					return $false
				} else {
					
					if ($Label.Substring($Label.Length - 1, 1) -ne 's') {
						$Label = $Label + 's'
					}
					Write-Verbose "Passing the label $Label and value $Value to New-TimeSpan"
					
					$Params = @{ $Label = $Value }
					$Hours += (New-TimeSpan @Params).TotalHours
				}
			}
			[math]::Round($Hours,2)
		}
	}
	process {
		try {
			
			$Message = $Message -join ' '
			if (!(Test-Path $FilePath)) {
				Write-Verbose "The file '$FilePath' does not exist.  Creating a new file"
			}
			Write-Verbose "Appending a new row to the file at '$FilePath'"
			
			$Split = $Message -split ' for '
			$TimeString = $Split[$Split.Length-1]
			
			
			if ($TimeString -match '\d+(\.\d{1,2})?$') {
				$Hours = $TimeString	
			} else {
				$Hours = Convert-TimeStringToTimeSpan -TimeString $TimeString
			}
			$ObjectParams = @{
				'DateTime' = (Get-Date)
				'Message' = $Message -replace "for $TimeString",''
				'Hours' = $Hours
			}
			[pscustomobject]$ObjectParams | Export-Csv -Path $FilePath -Append -NoTypeInformation -Delimiter "`t"
		} catch {
			Write-Error -Message "Error: $($_.Exception.Message) - Line Number: $($_.InvocationInfo.ScriptLineNumber)"
			$false
		}
	}
}
