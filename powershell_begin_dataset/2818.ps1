

if (Get-Command logparser.exe) {

    $lpquery = @"
    SELECT
        COUNT(ImagePath, LaunchString, Publisher) as ct,
        ImagePath,
        LaunchString,
        Publisher
    FROM
        *autorunsc.tsv
    WHERE
        (ImagePath not like 'File not found%')
    GROUP BY
        ImagePath,
        LaunchString,
        Publisher
    ORDER BY
        ct ASC
"@

    & logparser -stats:off -i:csv -dtlines:0 -fixedsep:on -rtp:-1 "$lpquery"

} else {
    $ScriptName = [System.IO.Path]::GetFileName($MyInvocation.ScriptName)
    "${ScriptName} requires logparser.exe in the path."
}

