

if (Get-Command logparser.exe) {

    $lpquery = @"
    SELECT
        Distinct substr(LocalAddress, 0, last_index_of(substr(LocalAddress, 0, last_index_of(LocalAddress, '.')), '.')) as Local/16
    FROM
        *netstat.csv
    ORDER BY
        Local/16
"@

    & logparser -stats:off -i:csv -dtlines:0 -rtp:-1 $lpquery

} else {
    $ScriptName = [System.IO.Path]::GetFileName($MyInvocation.ScriptName)
    "${ScriptName} requires logparser.exe in the path."
}
