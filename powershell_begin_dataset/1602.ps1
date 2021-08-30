



function Get-SKU {
    param (
        [object]$comps = $env:COMPUTERNAME
    )
    
    foreach ($computer in $comps) {
        try {
            
            
            [Microsoft.Win32.RegistryKey]::OpenRemoteBaseKey('LocalMachine',$computer).OpenSubKey('HARDWARE\DESCRIPTION\System\BIOS').GetValue('SystemSku')
        } catch {
            try {
                
                (Get-WMIObject -Namespace root\wmi -Class MS_SystemInformation -ComputerName $computer).SystemSKU
            } catch {
                return 'Error'
            }
        }
    }
}
