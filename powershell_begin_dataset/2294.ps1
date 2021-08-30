
$vCenterServer = "server.contoso.com"

try {
    
    if(-not (Get-PSSnapin VMware.VimAutomation.Core -ErrorAction SilentlyContinue)) {
        Add-PSSnapin VMware.VimAutomation.Core -ErrorAction Stop
    }

    
    Set-PowerCLIConfiguration -DefaultVIServerMode Single -InvalidCertificateAction Ignore -Confirm:$false -ErrorAction Stop

    
    Connect-VIServer -Server $vCenterServer -ErrorAction Stop

    
    $VirtualMachine = Get-VM -Name "Win7Ref" -ErrorAction Stop
    Get-HardDisk -VM $VirtualMachine -ErrorAction Stop | Remove-HardDisk -Confirm:$false -ErrorAction Stop

    
    $VirtualMachine | New-HardDisk -CapacityGB "60" -Confirm:$false -ErrorAction Stop

    
    Disconnect-VIServer -Server $vCenterServer -Confirm:$false -ErrorAction Stop
    
    
    $Success = "True"
}
catch [System.Exception] {
    $Success = "False"
}