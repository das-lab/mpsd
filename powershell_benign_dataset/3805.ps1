














function New-WADConfigFromTemplate ($inputPath, $outputPath, $storageAccountName)
{
    (Get-Content $inputPath).replace('[StorageAccountName]', $storageAccountName) | Set-Content $outputPath;
}


function Test-DiagnosticsExtensionBasic
{
    $rgname = Get-ComputeTestResourceName
    $loc = Get-ComputeVMLocation

    try
    {
        
        $vm = Create-VirtualMachine -rgname $rgname -loc $loc
        $vmname = $vm.Name

        
        $storagename = 'stoinconfig' + $rgname
        $storagetype = 'Standard_GRS'
        New-AzStorageAccount -ResourceGroupName $rgname -Name $storagename -Location $loc -Type $storagetype

        
        $extension = Get-AzVMDiagnosticsExtension -ResourceGroupName $rgname -VMName $vmname
        if ($extension) {
            Remove-AzVMDiagnosticsExtension -ResourceGroupName $rgname -VMName $vmname
            $extension = Get-AzVMDiagnosticsExtension -ResourceGroupName $rgname -VMName $vmname
            Assert-Null $extension
        }

        $configTemplate = Join-Path $ConfigFilesPath "DiagnosticsExtensionConfig.xml";
        $configFilePath = Join-Path $ConfigFilesPath "config-$rgname.xml";

        New-WADConfigFromTemplate $configTemplate $configFilePath $storagename;

        
        Set-AzVMDiagnosticsExtension -ResourceGroupName $rgname -VMName $vmname -DiagnosticsConfigurationPath $configFilePath
        $extension = Get-AzVMDiagnosticsExtension -ResourceGroupName $rgname -VMName $vmname

        Assert-NotNull $extension
        Assert-AreEqual $extension.Publisher 'Microsoft.Azure.Diagnostics'
        Assert-AreEqual $extension.ExtensionType 'IaaSDiagnostics'
        Assert-AreEqual $extension.Name 'Microsoft.Insights.VMDiagnosticsSettings'
        $settings = $extension.PublicSettings | ConvertFrom-Json
        Assert-AreEqual $settings.storageAccount $storagename

        
        Remove-AzVMDiagnosticsExtension -ResourceGroupName $rgname -VMName $vmname
        $extension = Get-AzVMDiagnosticsExtension -ResourceGroupName $rgname -VMName $vmname
        Assert-Null $extension
    }
    finally
    {
        
        Clean-ResourceGroup $rgname

        if (Test-Path $configFilePath)
        {
            Remove-Item $configFilePath;
        }
    }
}


function Test-DiagnosticsExtensionSepcifyStorageAccountName
{
    $rgname = Get-ComputeTestResourceName
    $loc = Get-ComputeVMLocation

    try
    {
        
        $vm = Create-VirtualMachine -rgname $rgname -loc $loc
        $vmname = $vm.Name

        
        $storagename = 'stoincmd' + $rgname
        $storagetype = 'Standard_GRS'
        New-AzStorageAccount -ResourceGroupName $rgname -Name $storagename -Location $loc -Type $storagetype

        
        $extension = Get-AzVMDiagnosticsExtension -ResourceGroupName $rgname -VMName $vmname
        if ($extension) {
            Remove-AzVMDiagnosticsExtension -ResourceGroupName $rgname -VMName $vmname
            $extension = Get-AzVMDiagnosticsExtension -ResourceGroupName $rgname -VMName $vmname
            Assert-Null $extension
        }

        Set-AzVMDiagnosticsExtension -ResourceGroupName $rgname -VMName $vmname -DiagnosticsConfigurationPath (Join-Path $ConfigFilesPath "DiagnosticsExtensionConfig.xml") -StorageAccountName $storagename
        $extension = Get-AzVMDiagnosticsExtension -ResourceGroupName $rgname -VMName $vmname

        Assert-NotNull $extension
        Assert-AreEqual $extension.Publisher 'Microsoft.Azure.Diagnostics'
        Assert-AreEqual $extension.ExtensionType 'IaaSDiagnostics'
        Assert-AreEqual $extension.Name 'Microsoft.Insights.VMDiagnosticsSettings'
        $settings = $extension.PublicSettings | ConvertFrom-Json
        Assert-AreEqual $settings.storageAccount $storagename
    }
    finally
    {
        
        Clean-ResourceGroup $rgname
    }
}


function Test-DiagnosticsExtensionCantListSepcifyStorageAccountKey
{
    $rgname = Get-ComputeTestResourceName
    $loc = Get-ComputeVMLocation

    try
    {
        
        $vm = Create-VirtualMachine -rgname $rgname -loc $loc
        $vmname = $vm.Name

        
        $extension = Get-AzVMDiagnosticsExtension -ResourceGroupName $rgname -VMName $vmname
        if ($extension) {
            Remove-AzVMDiagnosticsExtension -ResourceGroupName $rgname -VMName $vmname
            $extension = Get-AzVMDiagnosticsExtension -ResourceGroupName $rgname -VMName $vmname
            Assert-Null $extension
        }

        
        $storagename = 'notexiststorage'
        Assert-ThrowsContains `
            { Set-AzVMDiagnosticsExtension -ResourceGroupName $rgname -VMName $vmname -DiagnosticsConfigurationPath (Join-Path $ConfigFilesPath "DiagnosticsExtensionConfig.xml") -StorageAccountName $storagename } `
            'Storage account key'
    }
    finally
    {
        
        Clean-ResourceGroup $rgname
    }
}


function Test-DiagnosticsExtensionSupportJsonConfig
{
    $rgname = Get-ComputeTestResourceName
    $loc = Get-ComputeVMLocation

    try
    {
        
        $vm = Create-VirtualMachine -rgname $rgname -loc $loc
        $vmname = $vm.Name
        $storagename = $vmname + "storage"
        $storagetype = 'Standard_GRS'
        New-AzStorageAccount -ResourceGroupName $rgname -Name $storagename -Location $loc -Type $storagetype

        
        $extension = Get-AzVMDiagnosticsExtension -ResourceGroupName $rgname -VMName $vmname
        if ($extension) {
            Remove-AzVMDiagnosticsExtension -ResourceGroupName $rgname -VMName $vmname
            $extension = Get-AzVMDiagnosticsExtension -ResourceGroupName $rgname -VMName $vmname
            Assert-Null $extension
        }

        Set-AzVMDiagnosticsExtension -ResourceGroupName $rgname -VMName $vmname -DiagnosticsConfigurationPath (Join-Path $ConfigFilesPath "DiagnosticsExtensionConfig.json") -StorageAccountName $storagename
        $extension = Get-AzVMDiagnosticsExtension -ResourceGroupName $rgname -VMName $vmname

        Assert-NotNull $extension
        $settings = $extension.PublicSettings | ConvertFrom-Json
        Assert-AreEqual $settings.storageAccount $storagename
    }
    finally
    {
        
        Clean-ResourceGroup $rgname
    }
}


function Test-VmssDiagnosticsExtension
{
    $rgname = Get-ComputeTestResourceName
    $loc = Get-ComputeVmssLocation

    try
    {
        
        New-AzResourceGroup -Name $rgname -Location $loc -Force;

        

        
        $stoname = 'sto' + $rgname;
        $stotype = 'Standard_GRS';
        New-AzStorageAccount -ResourceGroupName $rgname -Name $stoname -Location $loc -Type $stotype;
        $stoaccount = Get-AzStorageAccount -ResourceGroupName $rgname -Name $stoname;

        
        $subnet = New-AzVirtualNetworkSubnetConfig -Name ('subnet' + $rgname) -AddressPrefix "10.0.0.0/24";
        $vnet = New-AzVirtualNetwork -Force -Name ('vnet' + $rgname) -ResourceGroupName $rgname -Location $loc -AddressPrefix "10.0.0.0/16" -Subnet $subnet;
        $vnet = Get-AzVirtualNetwork -Name ('vnet' + $rgname) -ResourceGroupName $rgname;
        $subnetId = $vnet.Subnets[0].Id;

        
        $vmssName = 'vmss' + $rgname;
        $vmssType = 'Microsoft.Compute/virtualMachineScaleSets';

        $adminUsername = 'Foo12';
        $adminPassword = Get-PasswordForVM;

        $imgRef = Get-DefaultCRPImage -loc $loc;
        $vhdContainer = "https://" + $stoname + ".blob.core.windows.net/" + $vmssName;

        $extname = 'diagextest';
        $diagExtPublisher = 'Microsoft.Azure.Diagnostics';
        $diagExtType = 'IaaSDiagnostics';

        
        $storagename = 'stoinconfig' + $rgname;
        $storagetype = 'Standard_GRS';
        New-AzStorageAccount -ResourceGroupName $rgname -Name $storagename -Location $loc -Type $storagetype;

        $ipCfg = New-AzVmssIPConfig -Name 'test' -SubnetId $subnetId;
        $vmss = New-AzVmssConfig -Location $loc -SkuCapacity 2 -SkuName 'Standard_A0' -UpgradePolicyMode 'automatic' -NetworkInterfaceConfiguration $netCfg `
            | Add-AzVmssNetworkInterfaceConfiguration -Name 'test' -Primary $true -IPConfiguration $ipCfg `
            | Set-AzVmssOSProfile -ComputerNamePrefix 'test' -AdminUsername $adminUsername -AdminPassword $adminPassword `
            | Set-AzVmssStorageProfile -Name 'test' -OsDiskCreateOption 'FromImage' -OsDiskCaching 'None' `
            -ImageReferenceOffer $imgRef.Offer -ImageReferenceSku $imgRef.Skus -ImageReferenceVersion $imgRef.Version `
            -ImageReferencePublisher $imgRef.PublisherName -VhdContainer $vhdContainer;

        
        $version = '1.5';
        $publicSettingTemplate = Join-Path $ConfigFilesPath "DiagnosticsExtensionPublicConfig.json";
        $privateSettingTemplate = Join-Path $ConfigFilesPath "DiagnosticsExtensionPrivateConfig.json";

        $publicSettingFilePath = Join-Path $ConfigFilesPath "publicconfig-$rgname.json";
        $privateSettingFilePath = Join-Path $ConfigFilesPath "privateconfig-$rgname.json";

        New-WADConfigFromTemplate $publicSettingTemplate $publicSettingFilePath $storagename
        New-WADConfigFromTemplate $privateSettingTemplate $privateSettingFilePath $storagename

        $vmss = Add-AzVmssDiagnosticsExtension -VirtualMachineScaleSet $vmss -Name $extname -SettingFilePath $publicSettingFilePath `
            -ProtectedSettingFilePath $privateSettingFilePath -TypeHandlerVersion $version -AutoUpgradeMinorVersion $false -Force;

        $vmssDiagExtensions = $vmss.VirtualMachineProfile.ExtensionProfile.Extensions | Where-Object {$_.Publisher -eq $diagExtPublisher -and $_.Type -eq $diagExtType};
        Assert-AreEqual 1 $vmssDiagExtensions.Count;
        $vmssDiagExtension = $vmssDiagExtensions | Select-Object -first 1;

        Assert-AreEqual $extname $vmssDiagExtension.Name;
        Assert-AreEqual $version $vmssDiagExtension.TypeHandlerVersion;
        Assert-AreEqual $false $vmssDiagExtension.AutoUpgradeMinorVersion;

        
        $storageAccountKey = $vmssDiagExtension.ProtectedSettings['storageAccountKey'];
        Assert-NotNull $storageAccountKey;
        Assert-AreNotEqual '' $storageAccountKey;

        
        $vmss = Remove-AzVmssDiagnosticsExtension -VirtualMachineScaleSet $vmss;
        $vmssDiagExtensions = $vmss.VirtualMachineProfile.ExtensionProfile.Extensions | Where-Object {$_.Publisher -eq $diagExtPublisher -and $_.Type -eq $diagExtType};

        Assert-Null $vmssDiagExtensions;

        $vmss = $vmss | Add-AzVmssDiagnosticsExtension -Name $extname -SettingFilePath $publicSettingFilePath `
            | New-AzVmss -ResourceGroupName $rgname -Name $vmssName;

        $vmss = Get-AzVmss -ResourceGroupName $rgname -VMScaleSetName $vmssName;

        $vmssDiagExtensions = $vmss.VirtualMachineProfile.ExtensionProfile.Extensions | Where-Object {$_.Publisher -eq $diagExtPublisher -and $_.Type -eq $diagExtType};
        Assert-AreEqual 1 $vmssDiagExtensions.Count;

        $vmssDiagExtension = $vmssDiagExtensions | Select-Object -first 1;
        Assert-AreEqual $extname $vmssDiagExtension.Name;
        
        $settings = $vmssDiagExtension.Settings;
        Assert-AreEqual $storagename $settings.storageAccount.Value;

        $vmss = Remove-AzVmssDiagnosticsExtension -VirtualMachineScaleSet $vmss -Name $extname;
        $vmssDiagExtensions = $vmss.VirtualMachineProfile.ExtensionProfile.Extensions | Where-Object {$_.Publisher -eq $diagExtPublisher -and $_.Type -eq $diagExtType};
        Assert-Null $vmssDiagExtensions;

        Update-AzVmss -ResourceGroupName $rgname -Name $vmssName -VirtualMachineScaleSet $vmss;

        $vmss = Get-AzVmss -ResourceGroupName $rgname -VMScaleSetName $vmssName;
        $vmssDiagExtensions = $vmss.VirtualMachineProfile.ExtensionProfile.Extensions | Where-Object {$_.Publisher -eq $diagExtPublisher -and $_.Type -eq $diagExtType};

        Assert-Null $vmssDiagExtensions;
    }
    finally
    {
        
        Clean-ResourceGroup $rgname

        if (Test-Path $publicSettingFilePath)
        {
            Remove-Item $publicSettingFilePath;
        }

        if (Test-Path $privateSettingFilePath)
        {
            Remove-Item $privateSettingFilePath;
        }
    }
}
