



[CmdletBinding()]
[OutputType('System.Management.Automation.PSCustomObject')]
param (
	[Parameter(Mandatory)]
	[string]$DnsZone,
	[Parameter()]
	[switch]$CheckValidity,
	[Parameter()]
	[string]$DnsServer = (Get-ADDomain).ReplicaDirectoryServers[0],
	[Parameter()]
	[int]$WarningDays = 1,
	[string]$EmailAddress,
	[Parameter()]
	[string]$NetbiosDomainName = (Get-AdDomain).NetBIOSName,
	[Parameter()]
	[ValidateScript({ Test-Path -Path $_ -PathType Leaf })]
	[string]$NbtScanFilePath = 'C:\nbtscan.exe'
)
begin {
	function Get-DnsHostname ($IPAddress) {
		try {
			
			$Result = nslookup $IPAddress 2> $null
			$Result | where { $_ -match 'name' } | foreach {
				$_.Replace('Name:    ', '')
			}
		} catch {
			Write-Warning "Could not find DNS hostname for IP $IpAddress"
			$false
		}
	}
	Function Test-Ping ($ComputerName) {
		$Result = ping $Computername -n 2
		if ($Result | where { $_ -match 'Reply from ' }) {
			$true
		} else {
			$false
		}
	}
	
	function Get-Computername ($IpAddress) {
		try {
			& $NbtScanFilePath $IpAddress 2> $null | where { $_ -match "$NetbiosDomainName\\(.*) " } | foreach { $matches[1].Trim() }
		} catch {
			Write-Warning -Message "Failed to get computer name for IP $IpAddress"
			$false
		}
	}
}
process {
	try {
		
		$ServerScavenging = Get-DnsServerScavenging -Computername $DnsServer
		$ZoneAging = Get-DnsServerZoneAging -Name $DnsZone -ComputerName $DnsServer
		if (!$ServerScavenging.ScavengingState) {
			Write-Warning "Scavenging not enabled on server '$DnsServer'"
			$NextScavengeTime = 'N/A'
		} else {
			$NextScavengeTime = $ServerScavenging.LastScavengeTime + $ServerScavenging.ScavengingInterval
			Write-Verbose "The next scavenge time is '$NextScavengeTime'"
		}
		if (!$ZoneAging.AgingEnabled) {
			Write-Warning "Aging not enabled on zone '$DnsZone'"
			$NextScavengeTime = 'N/A'
		}
		
		
		
		$StaleThreshold = ($ZoneAging.NoRefreshInterval.Days + $ZoneAging.RefreshInterval.Days) + $WarningDays
		Write-Verbose "The stale threshold is '$StaleThreshold' days"
		
		
		
		
		$StaleRecords = Get-DnsServerResourceRecord -ComputerName $DnsServer -ZoneName $DnsZone -RRType A | where { $_.TimeStamp -and ($_.Timestamp -le (Get-Date).AddDays("-$StaleThreshold")) -and ($_.Hostname -like "*.$DnsZone") }
		Write-Verbose "Found '$($StaleRecords.Count)' stale records in zone '$DnsZone' on server '$DnsServer'"
		$EmailRecords = @()
		foreach ($StaleRecord in $StaleRecords) {
			$Output = @{
				'Server' = $DnsServer
				'Zone' = $DnsZone
				'RecordHostname' = $StaleRecord.Hostname
				'RecordTimestamp' = $StaleRecord.Timestamp
				'ReversePTRRecord' = 'N/A'
				'ReverseNetBIOSHostname' = 'N/A'
				'IsScavengable' = (@{ $true = $false; $false = $true }[$NextScavengeTime -eq 'N/A'])
				'ToBeScavengedOn' = $NextScavengeTime
				'RecordMatchesNetBiosHostname' = 'N/A'
				'HostOnline' = 'N/A'
			}
			if ($CheckValidity.IsPresent) {
				Write-Verbose "Checking stale record '$($StaleRecord.Hostname)'"
				
				$RecordIp = $StaleRecord.RecordData.IPV4Address.IPAddressToString
				$ReverseDnsHostname = Get-DnsHostname -IPAddress $RecordIp
				if ($ReverseDnsHostname) {
					Write-Verbose "DNS PTR record is '$ReverseDnsHostname'"
					$Output.ReversePTRRecord = $ReverseDnsHostname
				} else {
					Write-Verbose "No DNS PTR record exists for record '$($StaleRecord.Hostname)'"
				}
				$ReverseNetbiosHostname = Get-Computername -IpAddress $RecordIp
				if ($ReverseNetbiosHostname) {
					Write-Verbose "Netbios hostname is '$ReverseNetbiosHostname'"
					$Output.ReverseNetBIOSHostname = $ReverseNetbiosHostname
				} else {
					Write-Verbose "No Netbios hostname exists for record '$($StaleRecord.Hostname)'"
				}
				
				if ($ReverseNetbiosHostname -eq $StaleRecord.Hostname.Replace(".$DnsZone", '')) {
					Write-Verbose "Netbios hostname matches DNS record hostname"
					$Output.RecordMatchesNetBiosHostname = $true
					$Output.HostOnline = Test-Ping -Computername $ReverseNetbiosHostname
				}
			}
			if ($EmailAddress) {
				$EmailRecords += [pscustomobject]$Output
			} else {
				[pscustomobject]$Output
			}
		}
		if ($EmailAddress) {
			if ($EmailRecords.Count -eq 0) {
				Write-Verbose "No stale records found to email"
			} else {
				Write-Verbose "Emailing the list of $($EmailRecords.Count) stale records to $EmailAddress"
				$Params = @{
					'From' = 'Union Hospital <abertram@domain.com>';
					'To' = $EmailAddress;
					'Subject' = 'UNH DNS Records To be Scavenged';
					'SmtpServer' = 'smtp.domain.com'
					'Body' = $EmailRecords | Out-String
				}
				
				Send-MailMessage @Params
			}
		}
	} catch {
		Write-Error $_.Exception.Message
	}
}