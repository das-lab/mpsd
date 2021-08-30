


function Get-OfficeVersion ($computer = $env:COMPUTERNAME) {
    $version = 0
 
    $reg = [Microsoft.Win32.RegistryKey]::OpenRemoteBaseKey('LocalMachine', $computer)

    try {
        $reg.OpenSubKey('SOFTWARE\Microsoft\Office').GetSubKeyNames() | % {
            if ($_ -match '(\d+)\.') {
                if ([int]$matches[1] -gt $version) {
                    $version = $matches[1]
                }
            }
        }
    } catch {}
 
    $version
}
