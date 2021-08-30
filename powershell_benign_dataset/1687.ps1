




















function Get-User {
    param (
        [string]$comp = $env:COMPUTERNAME,
        [ValidateSet('computersystem', 'process', 'dir')]
        $method = 'computersystem'
    )
    
    switch ($method) {
        'dir' {
            Get-ChildItem \\$comp\c$\users -Directory -Exclude '*$*' | % {Get-ChildItem $_.FullName ntuser.dat* -Force -ea 0} | sort LastWriteTime -Descending | select @{n='Computer';e={$comp}}, @{n='User';e={Split-Path (Split-Path $_.FullName) -Leaf}}, LastWriteTime | ? user -notmatch '\.net'| group computer, user | % {$_.group | select -f 1}
        }

        'computersystem' {
            try {
                (Get-WmiObject win32_computerSystem -ComputerName $comp).username
            } catch {
                try {
                    [Microsoft.Win32.RegistryKey]::OpenRemoteBaseKey('LocalMachine', $comp).OpenSubKey('SOFTWARE\Microsoft\Windows\CurrentVersion\Authentication\LogonUI').getvalue('LastLoggedOnUser')
                    Get-WmiObject Win32_NetworkLoginProfile -ComputerName $comp
                } catch {
                    'Error'
                }
            }
        }

        'process' {
            $owners = @{}
            Get-WmiObject win32_process -Filter 'name = "explorer.exe"' -ComputerName $comp | % {$owners[$_.handle] = $_.getowner().user}
            Get-Process explorer -ComputerName $comp | % {$owners[$_.id.tostring()]}
        }
    }
}
