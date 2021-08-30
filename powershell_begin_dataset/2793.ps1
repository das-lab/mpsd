


if (Get-Command logparser.exe) {
    $lpquery = @"
    SELECT
        COUNT(ProcessName,
        Owner) as ct,
        ProcessName,
        Owner
    FROM
        *Handle.tsv
    GROUP BY
        ProcessName,
        Owner
    ORDER BY
        ct ASC
"@

    & logparser -stats:off -i:csv -dtlines:0 -fixedsep:on -rtp:-1 "$lpquery"

} else {
    $ScriptName = [System.IO.Path]::GetFileName($MyInvocation.ScriptName)
    "${ScriptName} requires logparser.exe in the path."
}
