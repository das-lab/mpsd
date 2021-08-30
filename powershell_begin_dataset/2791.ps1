

if (Get-Command logparser.exe) {

    $lpquery = @"
    SELECT
        Distinct substr(ForeignAddress, 0, last_index_of(ForeignAddress, '.')) as Local/24
    FROM
        *netstat.csv
    ORDER BY
        Local/24
"@

    & logparser -stats:off -i:csv -dtlines:0 -rtp:-1 $lpquery

} else {
    $ScriptName = [System.IO.Path]::GetFileName($MyInvocation.ScriptName)
    "${ScriptName} requires logparser.exe in the path."
}
