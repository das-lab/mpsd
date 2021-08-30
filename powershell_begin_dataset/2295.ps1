
$vCenterServer = "server.contoso.com"
$DataCenterName = "Datacenter"
$DataStoreName = "DCStore"
$VMName = "WINREF01"
$VMPath = "VMStore:\" + $DataCenterName + "\" + $DataStoreName + "\" + $VMName

try {
    
    if(-not (Get-PSSnapin VMware.VimAutomation.Core -ErrorAction SilentlyContinue)) {
        Add-PSSnapin VMware.VimAutomation.Core -ErrorAction Stop
    }

    
    Set-PowerCLIConfiguration -DefaultVIServerMode Single -InvalidCertificateAction Ignore -Confirm:$false -ErrorAction Stop

    
    Connect-VIServer -Server $vCenterServer -ErrorAction Stop

    
    $VirtualMachine = Get-VM -Name $VMName -ErrorAction Stop
    Get-HardDisk -VM $VirtualMachine -ErrorAction Stop | Remove-HardDisk -Confirm:$false -ErrorAction Stop
    Get-ChildItem -Path $VMPath -Recurse -Include *.vmdk | Remove-Item

    
    $VMConfigSpec = New-Object -TypeName VMWare.Vim.VirtualMachineConfigSpec
    $IDEController = $VirtualMachine.ExtensionData.Config.Hardware.Device | Where-Object { $_.GetType().Name -eq "VirtualIDEController" } | Select-Object -First 1
    if ($IDEController -eq $null) {
        
        $IDEKey = -1
        $NewIDEController = New-Object -TypeName VMware.Vim.VirtualDeviceConfigSpec
        $NewIDEController.Operation = "Add"
        $NewIDEController.Device = New-Object -TypeName VMWare.Vim.VirtualIDEController
        $NewIDEController.Device.ControllerKey = $IDEKey
        $VMConfigSpec += $NewIDEController
    }
    else {
        
        $IDEKey = $IDEController.Key

    }

    
    $HDDNumber = 0
    $VirtualMachine.ExtensionData.Config.Hardware.Device | Where-Object { $_.GetType().Name -eq "VirtualDisk" } | Foreach-Object {
        $Number = [int]$_.DeviceInfo.Label.Split(' ')[2]
        if ($HDDNumber -lt $Number) {
            $HDDNumber = $Number
        }
    }
    if ($HDDNumber -eq 0) {
        $HDDString = ""
    }
    else {
        $HDDString = = "_" + $HDDNumber
    }

    
    $DatastoreName = $VirtualMachine.ExtensionData.Config.Files.VmPathName.Split(']')[0].TrimStart('[')

    
    $HDDSize = 60 * 1GB
    $VMDeviceConfigSpec = New-Object -TypeName VMware.Vim.VirtualDeviceConfigSpec 
    $VMDeviceConfigSpec.FileOperation = "Create"
    $VMDeviceConfigSpec.Operation = "Add"
    $VMDeviceConfigSpec.Device = New-Object -TypeName VMware.Vim.VirtualDisk
    $VMDeviceConfigSpec.Device.Backing = New-Object -TypeName VMware.Vim.VirtualDiskFlatVer2BackingInfo
    $VMDeviceConfigSpec.Device.Backing.Datastore = (Get-Datastore -Name $DatastoreName).Extensiondata.MoRef
    $VMDeviceConfigSpec.Device.Backing.DiskMode = "Persistent"
    $VMDeviceConfigSpec.Device.Backing.FileName = "[" + $DatastoreName + "] " + $VMName + "/" + $VMName + $HDDString + ".vmdk"
    $VMDeviceConfigSpec.Device.Backing.ThinProvisioned = $true
    $VMDeviceConfigSpec.Device.CapacityInKb = $HDDSize / 1KB
    $VMDeviceConfigSpec.Device.ControllerKey = $IDEKey
    $VMDeviceConfigSpec.Device.UnitNumber = -1
    $VMConfigSpec.DeviceChange += $VMDeviceConfigSpec
    $VirtualMachine.ExtensionData.ReconfigVM($VMConfigSpec)

    
    Disconnect-VIServer -Server $vCenterServer -Confirm:$false -ErrorAction Stop
	
	
    $Success = "True"
}
catch [System.Exception] {
    $Success = "False"
}