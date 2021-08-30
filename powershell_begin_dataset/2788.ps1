

if (Get-Command logparser.exe) {

    $lpquery = @"
    SELECT
        COUNT(Protocol,
        State,
        Component,
        Process) as Cnt,
        Protocol,
        State,
        Component,
        Process
    FROM
        *netstat.csv
    WHERE
        ConPid not in ('0'; '4') and
        State = 'LISTENING'
    GROUP BY
        Protocol,
        State,
        Component,
        Process

    ORDER BY
        Cnt, Process desc
"@

    & logparser -stats:off -i:csv -dtlines:0 -rtp:-1 $lpquery

} else {
    $ScriptName = [System.IO.Path]::GetFileName($MyInvocation.ScriptName)
    "${ScriptName} requires logparser.exe in the path."
}
