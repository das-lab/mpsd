

if (Get-Command logparser.exe) {

    $lpquery = @"
    SELECT
        COUNT(ImagePath, LaunchString) as ct,
        ImagePath,
        LaunchString
    FROM
        *autorunsc.tsv
    WHERE
        Publisher not like '(Verified)%' and
        (ImagePath not like 'File not found%')
    GROUP BY
        ImagePath,
        LaunchString
    ORDER BY
        ct ASC
"@

    & logparser -stats:off -i:csv -dtlines:0 -fixedsep:on -rtp:-1 "$lpquery"

} else {
    $ScriptName = [System.IO.Path]::GetFileName($MyInvocation.ScriptName)
    "${ScriptName} requires logparser.exe in the path."
}

