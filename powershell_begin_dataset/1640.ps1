



























function Get-LocalAdmin {
    param (
        $comp = $env:COMPUTERNAME,
        [ValidateSet('AccountManagement', 'ADSI', 'WMI')]
        $method = 'ADSI',
        [ValidateSet('Administrators', 'Remote Desktop Users')]
        $groupname = 'Administrators'
    )

    if ($method -eq 'AccountManagement') {
        Add-Type -AssemblyName System.DirectoryServices.AccountManagement
        $ctype = [System.DirectoryServices.AccountManagement.ContextType]::Machine
        $idtype = [System.DirectoryServices.AccountManagement.IdentityType]::SamAccountName
        $context = New-Object System.DirectoryServices.AccountManagement.PrincipalContext -ArgumentList $ctype, $comp
        try{ $obj = [System.DirectoryServices.AccountManagement.GroupPrincipal]::FindByIdentity($context, $idtype, $groupname) }catch{ continue }
        $obj.Members | % {
            [pscustomobject]@{
                Computer = $comp
                Domain = $_.Context.Name
                User = $_.samaccountname
            }
        }
    } elseif ($method -eq 'ADSI') { 
        $group = [ADSI]"WinNT://$comp/$groupname"
        $group.Invoke('Members') | % {
            $path = ([adsi]$_).path
            [pscustomobject]@{
                Computer = $comp
                Domain = $(Split-Path (Split-Path $path) -Leaf)
                User = $(Split-Path $path -Leaf)
                
                
                
            }
        }
    } elseif ($method -eq 'WMI') { 
        Get-WmiObject -Query 'SELECT GroupComponent, PartComponent FROM Win32_GroupUser' -ComputerName $comp | ? GroupComponent -Like "*`"$groupname`"" | % {
            $_.partcomponent -match '\\(?<computer>[^\\]+)\\.+\.domain="(?<domain>.+)",name="(?<name>.+)"' | Out-Null
            [pscustomobject]@{
                Computer = $matches.computer
                Domain = $matches.domain
                User = $matches.name
            }
        }
    }
}






