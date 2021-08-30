
[CmdletBinding()]
Param (
    [Parameter(Mandatory=$false)]
    [int32]$BackMins=180
)
$BackTime=(Get-Date) - (New-TimeSpan -Minutes $BackMins)
$RawEvents = Get-WinEvent -LogName "Microsoft-Windows-Sysmon/Operational" | Where-Object {$_.TimeCreated -ge $BackTime} | Where-Object { $_.Id -eq 3}
$RawEvents | ForEach-Object {  
    $PropertyBag = @{
        HostName = $_.MachineName
        Version=$_.Version
        EventType = $_.Message.Split(":")[0]
        EventID = $_.Id
        DateUTC = Get-Date ($_.Properties[0].Value) -format s
        ProcessGuid = $_.Properties[1].Value
        ProcessId = $_.Properties[2].Value
        Image = $_.Properties[3].Value
        User = $_.Properties[4].Value
        Protocol = $_.Properties[5].Value
        Initiated = $_.Properties[6].Value
        SourceIsIpv6 = $_.Properties[7].Value
        SourceIp = $_.Properties[8].Value
        SourceHostname = $_.Properties[9].Value
        SourcePort = $_.Properties[10].Value
        SourcePortName = $_.Properties[11].Value
        DestinationIsIpv6 = $_.Properties[12].Value
        DestinationIp = $_.Properties[13].Value
        DestinationHostname = $_.Properties[14].Value
        DestinationPort = $_.Properties[15].Value
        DestinationPortName = $_.Properties[16].Value
    }
    $Output = New-Object -TypeName PSCustomObject -Property $PropertyBag
    
    $Output | Select-Object HostName, Version, EventType, EventID, DateUTC, ProcessGuid, ProcessId, Image, User, Protocol, Initiated, SourceIsIpv6, SourceIp, SourceHostname, SourcePort, SourcePortName, DestinationIsIpv6, DestinationIp, DestinationHostname, DestinationPort, DestinationPortName
}

        
