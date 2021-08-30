


if (Get-Command logparser.exe) {
    $lpquery = @"
    SELECT
        UserAcct,
        UserPath,
        Subkey,
        KeyLastWriteTime,
        Value,
        Count,
        PSComputerName
    FROM
        *LogUserAssist.tsv
    ORDER BY
        KeyLastWriteTime DESC
"@

    & logparser -stats:off -i:csv -dtlines:0 -fixedsep:on -rtp:-1 "$lpquery"

} else {
    $ScriptName = [System.IO.Path]::GetFileName($MyInvocation.ScriptName)
    "${ScriptName} requires logparser.exe in the path."
}
