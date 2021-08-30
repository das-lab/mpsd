

if (Get-Command logparser.exe) {

    $lpquery = @"
    SELECT
        COUNT(Protocol,
        LocalAddress,
        ForeignAddress,
        State,
        ConPId,
        Component,
        Process) as ct,
        Protocol,
        LocalAddress,
        ForeignAddress,
        State,
        ConPid,
        Component,
        Process
    FROM
        *netstat.csv
    WHERE
        ConPid not in ('0'; '4') and
        ForeignAddress not like '10.%' and
        ForeignAddress not like '169.254%' and
        ForeignAddress not in ('*'; '0.0.0.0'; 
            '127.0.0.1'; '[::]'; '[::1]')
    GROUP BY
        Protocol,
        LocalAddress,
        ForeignAddress,
        State,
        ConPid,
        Component,
        Process
    ORDER BY
        Process,
        ct desc
"@

    & logparser -stats:off -i:csv -dtlines:0 -rtp:-1 $lpquery

} else {
    $ScriptName = [System.IO.Path]::GetFileName($MyInvocation.ScriptName)
    "${ScriptName} requires logparser.exe in the path."
}
