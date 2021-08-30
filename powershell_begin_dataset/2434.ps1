
 

[CmdletBinding()]
[OutputType('System.Management.Automation.PSCustomObject')]
param (
    [Parameter(Mandatory)]
    [string]$DnsZone,
    [Parameter()]
    [string]$DnsServer = (Get-ADDomain).ReplicaDirectoryServers[0],
    [Parameter()]
    [int]$WarningDays = 1
)
begin {
    function Get-DnsHostname ($IPAddress) {
        
        $Result = nslookup $IPAddress 2> $null
        $Result| where { $_ -match 'name' } | foreach {
            $_.Replace('Name:    ', '')
        }
    }
    Function Test-Ping ($ComputerName) {
        try {
            $oPing = new-object system.net.networkinformation.ping;
            if (($oPing.Send($ComputerName, 200).Status -eq 'TimedOut')) {
                $false;
            } else {
                $true  
            }
        } catch [System.Exception] {
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
        }
        if (!$ZoneAging.AgingEnabled) {
            Write-Warning "Aging not enabled on zone '$DnsZone'"
        }
         
        
        
        $StaleThreshold = ($ZoneAging.NoRefreshInterval.Days + $ZoneAging.RefreshInterval.Days) + $WarningDays
         
        
        
        
        $StaleRecords = Get-DnsServerResourceRecord -ComputerName $DnsServer -ZoneName $DnsZone -RRType A | where { $_.TimeStamp -and ($_.Timestamp -le (Get-Date).AddDays("-$StaleThreshold")) -and ($_.Hostname -like "*.$DnsZone") }
        foreach ($StaleRecord in $StaleREcords) {
            
            $RecordIp = $StaleRecord.RecordData.IPV4Address.IPAddressToString
            
            
            
            
            $ActualHostname = Get-DnsHostname $RecordIp
            if ($ActualHostname) {
                
                
                
                $HostOnline = Test-Ping -Computername $ActualHostname
            } else {
                $HostOnline = 'N/A' 
            }
            [pscustomobject]@{
                'Server' = $DnsServer
                'Zone' = $DnsZone
                'RecordHostname' = $StaleRecord.Hostname
                'RecordTimestamp' = $StaleRecord.Timestamp
                'IsScavengable' = (@{ $true = $false; $false = $true }[$NextScavengeTime -eq 'N/A'])
                'ToBeScavengedOn' = $NextScavengeTime
                'ValidHostname' = $ActualHostname
                'RecordMatchesValidHostname' = $ActualHostname -eq $StaleRecord.Hostname
                'HostOnline' = (@{ $true = $HostOnline; $false = 'N/A' }[$ActualHostname -eq $StaleRecord.Hostname])
            }
        }
    } catch {
        Write-Error $_.Exception.Message
    }
}