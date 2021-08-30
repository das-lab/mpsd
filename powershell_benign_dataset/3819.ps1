














function Test-NewAzureRmVhdVMWithValidDiskFile
{

    
    $rgname = Get-ComputeTestResourceName

    try
    {
        
        [string]$loc = Get-ComputeVMLocation;
        $loc = $loc.Replace(' ', '');

        New-AzResourceGroup -Name $rgname -Location $loc -Force;

        
        [string]$file = ".\VhdFiles\tiny.vhd";
        $vmname = $rgname + 'vm';
        [string]$domainNameLabel = "$vmname-$rgname".tolower();
		$vm = New-AzVM -ResourceGroupName $rgname -Name $vmname -Location $loc -DiskFile $file -OpenPorts 1234 -DomainNameLabel $domainNameLabel;
        Assert-AreEqual $vm.Name $vmname;
        Assert-AreEqual $vm.Location $loc;
        Assert-Null $vm.OSProfile $null;
        Assert-Null $vm.StorageProfile.DataDisks;
        Assert-NotNull $vm.StorageProfile.OSDisk.ManagedDisk;
        
        $stoname = $vmname;
        $diskname = $vmname;
        $disk = Get-AzDisk -ResourceGroupName $rgname -DiskName $diskname;
        Assert-AreEqual Windows $disk.OsType;
        Assert-AreEqual Import $disk.CreationData.CreateOption;
        Assert-AreEqual "https://${stoname}.blob.core.windows.net/${rgname}/${diskname}.vhd" $disk.CreationData.SourceUri;
    }
    finally
    {
        
        Clean-ResourceGroup $rgname;
    }
}


function Test-NewAzureRmVhdVMWithInvalidDiskFile
{
    
    $rgname = Get-ComputeTestResourceName;

    try
    {
        
        [string]$file1 = ".\test_invalid_file_1.vhd";
        $st = Set-Content -Path $file1 -Value "test1" -Force;

        
        [string]$loc = Get-ComputeVMLocation;
        $loc = $loc.Replace(' ', '');
      
        New-AzResourceGroup -Name $rgname -Location $loc -Force;

        
        $expectedException = $false;
        $expectedErrorMessage = "*unsupported format*";
        try
        {
			[string]$domainNameLabel = "$rgname-$rgname".tolower();
            $st = New-AzVM -ResourceGroupName $rgname -Name $rgname -Location $loc -Linux -DiskFile $file1 -OpenPorts 1234 -DomainNameLabel $domainNameLabel;
        }
        catch
        {
            if ($_ -like $expectedErrorMessage)
            {
                $expectedException = $true;
            }
        }
        
        if (-not $expectedException)
        {
            throw "Expected exception from calling New-AzVM was not caught: '$expectedErrorMessage'.";
        }
    }
    finally
    {
        
        Clean-ResourceGroup $rgname;
    }
}
