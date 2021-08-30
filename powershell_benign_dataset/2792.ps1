


if (Get-Command logparser.exe) {
    $lpquery = @"
    SELECT
        COUNT(IpAddr, Mac, Type) as ct,
        IpAddr,
        Mac,
        Type
    FROM
        *arp.csv
    GROUP BY
        IpAddr,
        Mac,
        Type
    ORDER BY
        ct ASC
"@

    & logparser -stats:off -i:csv -dtlines:0 -rtp:-1 "$lpquery"

} else {
    $ScriptName = [System.IO.Path]::GetFileName($MyInvocation.ScriptName)
    "${ScriptName} requires logparser.exe in the path."
}

