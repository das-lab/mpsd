

if (Get-Command logparser.exe) {

    $lpquery = @"
    SELECT
        COUNT(Type, Subtype, Data) as ct, 
        ServiceName, 
        Action, 
        Type,
        Subtype, 
        Data 
    FROM
        *svctrigs.tsv 
    GROUP BY
        ServiceName, 
        Action, 
        Type,
        Subtype, 
        Data 
    ORDER BY
        ct ASC
"@

    & logparser  -stats:off -i:csv -fixedsep:on -dtlines:0 -rtp:-1 $lpquery

} else {
    $ScriptName = [System.IO.Path]::GetFileName($MyInvocation.ScriptName)
    "${ScriptName} requires logparser.exe in the path."
}
