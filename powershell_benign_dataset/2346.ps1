


[CmdletBinding()]
[OutputType()]
param
(
	[Parameter(Mandatory)]
	[ValidateNotNullOrEmpty()]
	[ValidatePattern('^OU\=')]
	[string]$OrganizationalUnit,

	[Parameter()]
	[string[]]$EventId = @(4647,4648),

	[Parameter()]
	[ValidateNotNullOrEmpty()]
	[string]$EmailToAddress,

	[Parameter()]
	[ValidateNotNullOrEmpty()]
	[string]$EmailFromAddress = 'IT Administrator',
	
	[Parameter()]
	[ValidateNotNullOrEmpty()]
	[string]$EmailSubject = 'User Activity Report'

)
process {
	try
	{
		
		$Computers = Get-ADComputer -SearchBase $OrganizationalUnit -Filter * | Select-Object Name
		if (-not $Computers)
		{
			throw "No computers found in OU [$($OrganizationalUnit)]"
		}
		
		
		
		$XPathElements = @()
		foreach ($id in $EventId)
		{
			$XPathElements += "Event[System[EventID='$Id']]"
		}
		$EventFilterXPath = $XPathElements -join ' or '
		
		
		
		$LogonId = $EventId[1]
		$LogoffId = $EventId[0]
		
		$SelectOuput = @(
		@{ n = 'ComputerName'; e = { $_.MachineName } },
		@{
			n = 'Event'; e = {
				if ($_.Id -eq $LogonId)
				{
					'Logon'
				}
				else
				{
					'LogOff'
				}
			}
		},
		@{ n = 'Time'; e = { $_.TimeCreated } },
		@{
			n = 'Account'; e = {
				if ($_.Id -eq $LogonId)
				{
					$i = 1
				}
				else
				{
					$i = 3
				}
				[regex]::Matches($_.Message, 'Account Name:\s+(.*)\n').Groups[$i].Value.Trim()
			}
		}
		)
		
		
		
		$TempFile = 'C:\useractivity.txt'
		foreach ($Computer in $Computers) {
	    	Get-WinEvent -ComputerName $Computer -LogName Security -FilterXPath $EventFilterXPath | Select-Object $SelectOuput | Out-File $TempFile
		}
		
		
		$emailParams = @{
			'To' = $EmailToAddress
			'From' = $EmailFromAddress
			'Subject' = $EmailSubject
			'Attachments' = $TempFile
		}
		
		Send-MailMessage @emailParams

	} catch {
		Write-Error $_.Exception.Message
	}
	finally
	{
		
		Remove-Item -Path $TempFile -Force -ErrorAction SilentlyContinue
	}
}