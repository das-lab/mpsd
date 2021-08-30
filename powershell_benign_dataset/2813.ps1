

if (Get-Command logparser.exe) {

    $lpquery = @"
    SELECT
        COUNT(ServiceName, 
        CmdLine,
        FailAction1,
        FailAction2,
        FailAction3) as ct, 
        ServiceName, 
        CmdLine,
        FailAction1,
        FailAction2,
        FailAction3
    FROM
        *SvcFail.tsv
    WHERE
        CmdLine <> 'customScript.cmd' AND
        CmdLine is not NULL
    GROUP BY
        ServiceName, 
        CmdLine,
        FailAction1,
        FailAction2,
        FailAction3
    ORDER BY
        ct ASC
"@

    & logparser -stats:off -i:csv -fixedsep:on -dtlines:0 -rtp:-1 $lpquery

} else {
    $ScriptName = [System.IO.Path]::GetFileName($MyInvocation.ScriptName)
    "${ScriptName} requires logparser.exe in the path."
}
