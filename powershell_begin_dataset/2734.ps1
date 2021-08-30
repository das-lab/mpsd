
[CmdletBinding()]
Param (
    [Parameter(Mandatory=$false)]
    [int32]$BackMins=180
)
$BackTime=(Get-Date) - (New-TimeSpan -Minutes $BackMins)
$RawEvents = Get-WinEvent -LogName "Microsoft-Windows-Sysmon/Operational" | Where-Object {$_.TimeCreated -ge $BackTime} | Where-Object { $_.Id -eq 1}
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
        CommandLine = $_.Properties[4].Value
        CurrentDirectory = $_.Properties[5].Value
        User = $_.Properties[6].Value
        LogonGuid = $_.Properties[7].Value
        LogonId = $_.Properties[8].Value
        TerminalSessionId = $_.Properties[9].Value
        IntegrityLevel = $_.Properties[10].Value
        
        MD5 = ($_.Properties[11].Value.Split(",")[1].split("=")[1]) 
        SHA1 = ($_.Properties[11].Value.Split(",")[0].split("=")[1]) 
        SHA256 = ($_.Properties[11].Value.Split(",")[2].split("=")[1]) 
        ParentProcessGuid = $_.Properties[12].Value
        ParentProcessId = $_.Properties[13].Value
        ParentImage = $_.Properties[14].Value
        ParentCommandLine = $_.Properties[15].Value
    }
    $Output = New-Object -TypeName PSCustomObject -Property $PropertyBag
    
    $Output | Select-Object DateUTC, HostName, Version, EventID, EventType, ProcessGuid, ProcessId, Image, CommandLine, MD5,SHA1, SHA256, CurrentDirectory, User, LogonGuid, LogonId, TerminalSessionId, IntegrityLevel, ParentProcessGuid, ParentProcessId, ParentImage, ParentCommandLine
} 
