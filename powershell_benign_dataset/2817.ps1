

if (Get-Command logparser.exe) {

    $lpquery = @"
    SELECT
        COUNT(To_Lowercase(CmdLine)) as ct, 
        To_Lowercase(CmdLine) as CmdLineLC
    FROM
        *SvcFail.tsv
    GROUP BY
        CmdLineLC
    ORDER BY
        ct ASC
"@

    & logparser -stats:off -i:csv -fixedsep:on -dtlines:0 -rtp:-1 $lpquery

} else {
    $ScriptName = [System.IO.Path]::GetFileName($MyInvocation.ScriptName)
    "${ScriptName} requires logparser.exe in the path."
}
