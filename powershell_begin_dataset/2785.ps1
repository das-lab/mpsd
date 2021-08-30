


if (Get-Command logparser.exe) {
    $lpquery = @"
    SELECT
        COUNT(Entry) as ct,
        Entry
    FROM
        *DNSCache.csv
    GROUP BY
        Entry
    ORDER BY
        ct ASC
"@

    & logparser -stats:off -i:csv -dtlines:0 -rtp:-1 "$lpquery"

} else {
    $ScriptName = [System.IO.Path]::GetFileName($MyInvocation.ScriptName)
    "${ScriptName} requires logparser.exe in the path."
}

