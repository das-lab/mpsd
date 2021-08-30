



[CmdletBinding()]
[OutputType('System.Management.Automation.PSCustomObject')]
param (
	[Parameter(Mandatory,
		ValueFromPipeline,
		ValueFromPipelineByPropertyName)]
	[ValidateScript({Test-Connection -ComputerName $_ -Quiet -Count 1})]
	[string]$Computername,
	[Parameter()]
	[int]$RetryInterval = 10
)

begin {
	$ErrorActionPreference = [System.Management.Automation.ActionPreference]::Stop
	Set-StrictMode -Version Latest
	try {
		
		function Test-PsRemoting {
			param (
				[Parameter(Mandatory = $true)]
				$computername
			)
			
			try {
				Write-Verbose "Testing for enabled remoting"
				$result = Invoke-Command -ComputerName $computername { 1 }
			} catch {
				return $false
			}
			
			
			
			if ($result -ne 1) {
				Write-Verbose "Remoting to $computerName returned an unexpected result."
				return $false
			}
			$true
		}
		
		function Get-ClientPrimaryDns ($NicIndex) {
			Write-Verbose "Finding primary DNS server for client '$Computername'"
			$Result = Get-WmiObject -ComputerName $Computername -Class win32_networkadapterconfiguration -Filter "IPenabled = $true AND Index = $NicIndex"
			if ($Result) {
				$PrimaryDnsServer = $Result.DNSServerSearchOrder[0]
				Write-Verbose "Found computer '$Computername' primary DNS server as '$PrimaryDnsServer'"
				$PrimaryDnsServer
			} else {
				$false	
			}
		}
		
		function Get-ClientPrimaryDnsSuffix {
			$Registry = [Microsoft.Win32.RegistryKey]::OpenRemoteBaseKey('LocalMachine', $Computername)
			$RegistryKey = $Registry.OpenSubKey("SYSTEM\CurrentControlSet\Services\Tcpip\Parameters", $true)
			$DnsSuffix = $RegistryKey.GetValue('NV Domain')
			if ($DnsSuffix) {
				Write-Verbose "Computer '$Computername' primary DNS suffix is '$DnsSuffix'"
				$DnsSuffix
			} else {
				Write-Warning "Could not find primary DNS suffix on computer '$Computername'"
				$false
			}
		}
		
		function Get-DynamicDnsEnabledNicIndex {
			$EnabledIndex = Get-WmiObject -Class Win32_NetworkAdapterConfiguration -ComputerName $Computername -Filter { IPEnabled = 'True' } | where { $_.FullDNSRegistrationEnabled }
			if (!$EnabledIndex) {
				Write-Warning 'No NIC detected to have dynamic DNS enabled'
				$false
			} elseif ($EnabledIndex -is [array]) {
				Write-Warning 'Multiple NICs detected having dynamic DNS enabled.  This is not supported'
				$false
			} else {
				Write-Verbose "Found NIC with index '$($EnabledIndex.Index)' as dynamic DNS enabled"
				[int]$EnabledIndex.Index
			}
		}
		
		function Validate-IsInRefreshPeriod($Record) {
			if ($Record.Timestamp.AddDays($ZoneAging.NoRefreshInterval.Days) -lt (Get-Date)) {
				Write-Verbose 'The record is in the refresh period'
				$true
			} else {
				Write-Verbose 'The record is not in the refresh period'
				$false
			}
		}
		
		$ResultHash = @{ 'Computername' = $Computername; }
		
		$EnabledNicIndex = Get-DynamicDnsEnabledNicIndex
		if ($EnabledNicIndex -isnot [int]) {
			throw "Computer '$Computername' does not have dynamic DNS enabled on any interface or on more than 1 interface"
			exit
		}
		
		$PrimaryDnsServer = Get-ClientPrimaryDns $EnabledNicIndex
		if (! $PrimaryDnsServer) {
			throw "Could not find computer '$Computername' primary DNS server."
			exit
		}
		$DnsZone = Get-ClientPrimaryDnsSuffix
		if (! $DnsZone) {
			throw "Could not find computer '$Computername' primary DNS suffix."
			exit
		}
		$script:ZoneAging = Get-DnsServerZoneAging -Name $DnsZone -ComputerName $PrimaryDnsServer
		
		$Record = Get-DnsServerResourceRecord -ComputerName $PrimaryDnsServer -Name $Computername -RRType A -ZoneName $DnsZone -ea silentlycontinue
		if ($Record -and !($Record.TimeStamp)) {
			throw "The '$($Record.Hostname)' record is static and has no timestamp."
		} elseif (!$Record) {
			Write-Verbose "The '$Computername' record does not exist on the DNS server '$($PrimaryDnsServer)'."
		} elseif (!(Validate-IsInRefreshPeriod $Record)) {
			Write-Verbose "The '$($Record.Hostname)' record timestamp is still within the '$DnsZone' zone no-refresh period."
			$ResultHash.Result = $true
			[pscustomobject]$ResultHash
			exit
		}
} catch {
	Write-Error $_.Exception.Message
	break
}
}

process {
	try {
		
		
		$NowRoundHourDown = ((Get-Date).Date).AddHours((Get-Date).Hour)
		if (Test-PsRemoting $Computername) {
			Write-Verbose "Remoting already enabled on $Computername"
			Invoke-Command -ComputerName $Computername -ScriptBlock { ipconfig /registerdns } | Out-Null
		} else {
			Write-Warning "Remoting not enabled on $Computername. Will attempt to use WMI to create remote process"
			if (([WMICLASS]"\\$Computername\Root\CIMV2:Win32_Process").create("ipconfig /registerdns").ReturnValue -ne 0) {
				throw "Unable to successfully start remote process on '$Computername'"	
			}
		}
		Write-Verbose "Initiated DNS record registration on '$Computername'.  Waiting for record to update on DNS server.."
		
		Start-Sleep -Seconds 5
		for ($i = 0; $i -lt $RetryInterval; $i++) {
			$Record = Get-DnsServerResourceRecord -ComputerName $PrimaryDnsServer -Name $Computername -RRType A -ZoneName $DnsZone -ea SilentlyContinue
			if ($Record) {
				$Timestamp = $Record.Timestamp
			}
			if ($Timestamp -eq $NowRoundHourDown) {
				Write-Verbose "Host DNS record for '$Computername' matches current rounded time of $NowRoundHourDown"
				$ResultHash.Result = $true
				[pscustomobject]$ResultHash
				exit
			} else {
				Write-Verbose "Host DNS record timestamp '$Timestamp' for '$Computername' does not match current rounded time of '$NowRoundHourDown'. Trying again..."
			}
			Start-Sleep -Seconds 1
		}
		
		$ResultHash.Result = $false
		[pscustomobject]$ResultHash
	} catch {
		Write-Error $_.Exception.Message
	}
}