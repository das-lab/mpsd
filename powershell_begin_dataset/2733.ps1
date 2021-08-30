

[CmdletBinding()]
Param (
    [Parameter(Mandatory=$false)]
    [switch]$AllEvents
)

if ($AllEvents) 
{
    Write-Warning "Running this script in 'AllEvents' mode is not recommended as it returns a significant amount of unnecessary data."
    Start-Sleep -Seconds 1
    
    Get-WinEvent -LogName "Microsoft-Windows-TerminalServices-RemoteConnectionManager/Operational" | `
        Select-Object -Property TimeCreated, LogName, Id, Version, ProcessId, ThreadId, MachineName, UserId, Message
}
else 
{
    $RawEvents = Get-WinEvent -LogName "Microsoft-Windows-TerminalServices-RemoteConnectionManager/Operational" | `
        Where-Object { $_.Id -eq 1149 }

    $RawEvents | ForEach-Object `
    {  
        if ($_.Properties.Count -lt 3)
        {
            Write-Warning "Event record missing expected fields. Skipping extended processing."
            $_ | Select-Object -Property TimeCreated, LogName, Id, Version, ProcessId, ThreadId, MachineName, UserId
            continue
        }

        $User = $_.Properties[0].Value
        $Domain = $_.Properties[1].Value
        $SourceIp = $_.Properties[2].Value

        $NormalizedUser = ("{1}\{0}" -f $User, $Domain)

        $Message = $_.Message.Split("`n")[0]

        $PropertyBag = @{
            TimeCreated = $_.TimeCreated;
            LogName = $_.LogName;
            Id = $_.Id;
            Version = $_.Version;
            ProcessId = $_.ProcessId;
            ThreadId = $_.ThreadId;
            MachineNae = $_.MachineName;
            UserId = $_.UserId;
            UserName = $NormalizedUser;
            SourceIp = $SourceIp;
            Message = $Message
        }

        $o = New-Object -TypeName PSCustomObject -Property $PropertyBag
        $o
    }
}