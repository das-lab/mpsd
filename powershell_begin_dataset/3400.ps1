













$PLACEHOLDER = "PLACEHOLDER1@"


function Get-ComputeTestResourceName
{
    $stack = Get-PSCallStack
    $testName = $null;
    foreach ($frame in $stack)
    {
        if ($frame.Command.StartsWith("Test-", "CurrentCultureIgnoreCase"))
        {
            $testName = $frame.Command;
        }
    }
    
    $oldErrorActionPreferenceValue = $ErrorActionPreference;
    $ErrorActionPreference = "SilentlyContinue";
    
    try
    {
        $assetName = [Microsoft.Azure.Test.HttpRecorder.HttpMockServer]::GetAssetName($testName, "crptestps");
    }
    catch
    {
        if (($Error.Count -gt 0) -and ($Error[0].Exception.Message -like '*Unable to find type*'))
        {
            $assetName = Get-RandomItemName;
        }
        else
        {
            throw;
        }
    }
    finally
    {
        $ErrorActionPreference = $oldErrorActionPreferenceValue;
    }

    return $assetName
}



function Get-ComputeTestMode
{
    $oldErrorActionPreferenceValue = $ErrorActionPreference;
    $ErrorActionPreference = "SilentlyContinue";
    
    try
    {
        $testMode = [Microsoft.Azure.Test.HttpRecorder.HttpMockServer]::Mode;
        $testMode = $testMode.ToString();
    }
    catch
    {
        if (($Error.Count -gt 0) -and ($Error[0].Exception.Message -like '*Unable to find type*'))
        {
            $testMode = 'Record';
        }
        else
        {
            throw;
        }
    }
    finally
    {
        $ErrorActionPreference = $oldErrorActionPreferenceValue;
    }

    return $testMode;
}


function Get-ComputeTestLocation
{
    return $env:AZURE_COMPUTE_TEST_LOCATION;
}


function Get-ComputeDefaultLocation
{
    $test_location = Get-ComputeTestLocation;
    if ($test_location -eq '' -or $test_location -eq $null)
    {
        $test_location = 'westus';
    }

    return $test_location;
}


function Create-VirtualMachine($rgname, $vmname, $loc)
{
    
    $rgname = if ([string]::IsNullOrEmpty($rgname)) { Get-ComputeTestResourceName } else { $rgname }
    $vmname = if ([string]::IsNullOrEmpty($vmname)) { 'vm' + $rgname } else { $vmname }
    $loc = if ([string]::IsNullOrEmpty($loc)) { Get-ComputeVMLocation } else { $loc }
    Write-Host $vmname

    
    $g = New-AzureRmResourceGroup -Name $rgname -Location $loc -Force;

    
    $vmsize = 'Standard_A2';
    $p = New-AzureRmVMConfig -VMName $vmname -VMSize $vmsize;
    Assert-AreEqual $p.HardwareProfile.VmSize $vmsize;

    
    $subnet = New-AzureRmVirtualNetworkSubnetConfig -Name ('subnet' + $rgname) -AddressPrefix "10.0.0.0/24";
    $vnet = New-AzureRmVirtualNetwork -Force -Name ('vnet' + $rgname) -ResourceGroupName $rgname -Location $loc -AddressPrefix "10.0.0.0/16" -Subnet $subnet;
    $vnet = Get-AzureRmVirtualNetwork -Name ('vnet' + $rgname) -ResourceGroupName $rgname;
    $subnetId = $vnet.Subnets[0].Id;
    $pubip = New-AzureRmPublicIpAddress -Force -Name ('pubip' + $rgname) -ResourceGroupName $rgname -Location $loc -AllocationMethod Dynamic -DomainNameLabel ('pubip' + $rgname);
    $pubip = Get-AzureRmPublicIpAddress -Name ('pubip' + $rgname) -ResourceGroupName $rgname;
    $pubipId = $pubip.Id;
    $nic = New-AzureRmNetworkInterface -Force -Name ('nic' + $rgname) -ResourceGroupName $rgname -Location $loc -SubnetId $subnetId -PublicIpAddressId $pubip.Id;
    $nic = Get-AzureRmNetworkInterface -Name ('nic' + $rgname) -ResourceGroupName $rgname;
    $nicId = $nic.Id;

    $p = Add-AzureRmVMNetworkInterface -VM $p -Id $nicId;
    Assert-AreEqual $p.NetworkProfile.NetworkInterfaces.Count 1;
    Assert-AreEqual $p.NetworkProfile.NetworkInterfaces[0].Id $nicId;

    
    $stoname = 'sto' + $rgname;
    $stotype = 'Standard_GRS';
    $sa = New-AzureRmStorageAccount -ResourceGroupName $rgname -Name $stoname -Location $loc -Type $stotype;
    Retry-IfException { $global:stoaccount = Get-AzureRmStorageAccount -ResourceGroupName $rgname -Name $stoname; }
    $stokey = (Get-AzureRmStorageAccountKey -ResourceGroupName $rgname -Name $stoname).Key1;

    $osDiskName = 'osDisk';
    $osDiskCaching = 'ReadWrite';
    $osDiskVhdUri = "https://$stoname.blob.core.windows.net/test/os.vhd";
    $dataDiskVhdUri1 = "https://$stoname.blob.core.windows.net/test/data1.vhd";
    $dataDiskVhdUri2 = "https://$stoname.blob.core.windows.net/test/data2.vhd";
    $dataDiskVhdUri3 = "https://$stoname.blob.core.windows.net/test/data3.vhd";

    $p = Set-AzureRmVMOSDisk -VM $p -Name $osDiskName -VhdUri $osDiskVhdUri -Caching $osDiskCaching -CreateOption FromImage;

    $p = Add-AzureRmVMDataDisk -VM $p -Name 'testDataDisk1' -Caching 'ReadOnly' -DiskSizeInGB 10 -Lun 1 -VhdUri $dataDiskVhdUri1 -CreateOption Empty;
    $p = Add-AzureRmVMDataDisk -VM $p -Name 'testDataDisk2' -Caching 'ReadOnly' -DiskSizeInGB 11 -Lun 2 -VhdUri $dataDiskVhdUri2 -CreateOption Empty;
    $p = Add-AzureRmVMDataDisk -VM $p -Name 'testDataDisk3' -Caching 'ReadOnly' -DiskSizeInGB 12 -Lun 3 -VhdUri $dataDiskVhdUri3 -CreateOption Empty;
    $p = Remove-AzureRmVMDataDisk -VM $p -Name 'testDataDisk3';

    Assert-AreEqual $p.StorageProfile.OsDisk.Caching $osDiskCaching;
    Assert-AreEqual $p.StorageProfile.OsDisk.Name $osDiskName;
    Assert-AreEqual $p.StorageProfile.OsDisk.Vhd.Uri $osDiskVhdUri;
    Assert-AreEqual $p.StorageProfile.DataDisks.Count 2;
    Assert-AreEqual $p.StorageProfile.DataDisks[0].Caching 'ReadOnly';
    Assert-AreEqual $p.StorageProfile.DataDisks[0].DiskSizeGB 10;
    Assert-AreEqual $p.StorageProfile.DataDisks[0].Lun 1;
    Assert-AreEqual $p.StorageProfile.DataDisks[0].Vhd.Uri $dataDiskVhdUri1;
    Assert-AreEqual $p.StorageProfile.DataDisks[1].Caching 'ReadOnly';
    Assert-AreEqual $p.StorageProfile.DataDisks[1].DiskSizeGB 11;
    Assert-AreEqual $p.StorageProfile.DataDisks[1].Lun 2;
    Assert-AreEqual $p.StorageProfile.DataDisks[1].Vhd.Uri $dataDiskVhdUri2;

    
    $user = "Foo12";
    $password = $PLACEHOLDER;
    $securePassword = ConvertTo-SecureString $password -AsPlainText -Force;
    $cred = New-Object System.Management.Automation.PSCredential ($user, $securePassword);
    $computerName = 'test';
    $vhdContainer = "https://$stoname.blob.core.windows.net/test";

    $p = Set-AzureRmVMOperatingSystem -VM $p -Windows -ComputerName $computerName -Credential $cred -ProvisionVMAgent;

    $imgRef = Get-DefaultCRPWindowsImageOffline;
    $p = ($imgRef | Set-AzureRmVMSourceImage -VM $p);

    Assert-AreEqual $p.OSProfile.AdminUsername $user;
    Assert-AreEqual $p.OSProfile.ComputerName $computerName;
    Assert-AreEqual $p.OSProfile.AdminPassword $password;
    Assert-AreEqual $p.OSProfile.WindowsConfiguration.ProvisionVMAgent $true;

    Assert-AreEqual $p.StorageProfile.ImageReference.Offer $imgRef.Offer;
    Assert-AreEqual $p.StorageProfile.ImageReference.Publisher $imgRef.PublisherName;
    Assert-AreEqual $p.StorageProfile.ImageReference.Sku $imgRef.Skus;
    Assert-AreEqual $p.StorageProfile.ImageReference.Version $imgRef.Version;

    
    $v = New-AzureRmVM -ResourceGroupName $rgname -Location $loc -VM $p;

    $vm = Get-AzureRmVM -ResourceGroupName $rgname -VMName $vmname
    return $vm
}


function Clean-ResourceGroup($rgname)
{
    Remove-AzureRmResourceGroup -Name $rgname -Force;
}


function Get-ComputeTestTag
{
    param ([string] $tagname)

    return @{ Name = $tagname; Value = (Get-Date).ToUniversalTime().ToString("u") };
}









function Retry-IfException
{
    param([ScriptBlock] $script, [int] $times = 30, [string] $message = "*")

    if ($times -le 0)
    {
        throw 'Retry time(s) should not be equal to or less than 0.';
    }

    $oldErrorActionPreferenceValue = $ErrorActionPreference;
    $ErrorActionPreference = "SilentlyContinue";

    $iter = 0;
    $succeeded = $false;
    while (($iter -lt $times) -and (-not $succeeded))
    {
        $iter += 1;

        &$script;

        if ($Error.Count -gt 0)
        {
            $actualMessage = $Error[0].Exception.Message;

            Write-Output ("Caught exception: '$actualMessage'");

            if (-not ($actualMessage -like $message))
            {
                $ErrorActionPreference = $oldErrorActionPreferenceValue;
                throw "Expected exception not received: '$message' the actual message is '$actualMessage'";
            }

            $Error.Clear();
            Wait-Seconds 10;
            continue;
        }

        $succeeded = $true;
    }

    $ErrorActionPreference = $oldErrorActionPreferenceValue;
}


function Get-RandomItemName
{
    param([string] $prefix = "crptestps")
    
    if ($prefix -eq $null -or $prefix -eq '')
    {
        $prefix = "crptestps";
    }

    $str = $prefix + ((Get-Random) % 10000);
    return $str;
}


function Get-DefaultVMSize
{
    param([string] $location = "westus")

    $vmSizes = Get-AzureRmVMSize -Location $location | where { $_.NumberOfCores -ge 4 -and $_.MaxDataDiskCount -ge 8 };

    foreach ($sz in $vmSizes)
    {
        if ($sz.Name -eq 'Standard_A3')
        {
            return $sz.Name;
        }
    }

    return $vmSizes[0].Name;
}



function Get-DefaultRDFEImage
{
    param([string] $loca = "East Asia", [string] $query = '*Windows*Data*Center*')

    $d = (Azure\Get-AzureRmVMImage | where {$_.ImageName -like $query -and ($_.Location -like "*;$loca;*" -or $_.Location -like "$loca;*" -or $_.Location -like "*;$loca" -or $_.Location -eq "$loca")});

    if ($d -eq $null)
    {
        return $null;
    }
    else
    {
        return $d[-1].ImageName;
    }
}


function Get-DefaultStorageType
{
    return 'Standard_GRS';
}


function Get-DefaultCRPImage
{
    param([string] $loc = "westus", [string] $query = '*Microsoft*Windows*Server*')

    $result = (Get-AzureRmVMImagePublisher -Location $loc) | select -ExpandProperty PublisherName | where { $_ -like $query };
    if ($result.Count -eq 1)
    {
        $defaultPublisher = $result;
    }
    else
    {
        $defaultPublisher = $result[0];
    }

    $result = (Get-AzureRmVMImageOffer -Location $loc -PublisherName $defaultPublisher) | select -ExpandProperty Offer | where { $_ -like '*Windows*' -and -not ($_ -like '*HUB')  };
    if ($result.Count -eq 1)
    {
        $defaultOffer = $result;
    }
    else
    {
        $defaultOffer = $result[0];
    }

    $result = (Get-AzureRmVMImageSku -Location $loc -PublisherName $defaultPublisher -Offer $defaultOffer) | select -ExpandProperty Skus;
    if ($result.Count -eq 1)
    {
        $defaultSku = $result;
    }
    else
    {
        $defaultSku = $result[0];
    }

    $result = (Get-AzureRmVMImage -Location $loc -Offer $defaultOffer -PublisherName $defaultPublisher -Skus $defaultSku) | select -ExpandProperty Version;
    if ($result.Count -eq 1)
    {
        $defaultVersion = $result;
    }
    else
    {
        $defaultVersion = $result[0];
    }
    
    $vmimg = Get-AzureRmVMImage -Location $loc -Offer $defaultOffer -PublisherName $defaultPublisher -Skus $defaultSku -Version $defaultVersion;

    return $vmimg;
}


function Create-ComputeVMImageObject
{
    param ([string] $publisherName, [string] $offer, [string] $skus, [string] $version)

    $img = New-Object -TypeName 'Microsoft.Azure.Commands.Compute.Models.PSVirtualMachineImage';
    $img.PublisherName = $publisherName;
    $img.Offer = $offer;
    $img.Skus = $skus;
    $img.Version = $version;

    return $img;
}


function Get-DefaultCRPWindowsImageOffline
{
    return Create-ComputeVMImageObject 'MicrosoftWindowsServer' 'WindowsServer' '2008-R2-SP1' 'latest';
}


function Get-DefaultCRPLinuxImageOffline
{
    return Create-ComputeVMImageObject 'SUSE' 'openSUSE' '13.2' 'latest';
}


function Get-MarketplaceImage
{
    param([string] $location = "westus", [string] $pubFilter = '*', [string] $offerFilter = '*')

    $imgs = Get-AzureRmVMImagePublisher -Location $location | where { $_.PublisherName -like $pubFilter } | Get-AzureRmVMImageOffer | where { $_.Offer -like $offerFilter } | Get-AzureRmVMImageSku | Get-AzureRmVMImage | Get-AzureRmVMImage | where { $_.PurchasePlan -ne $null };

    return $imgs;
}


function Get-DefaultVMConfig
{
    param([string] $location = "westus")

    
    $vmsize = Get-DefaultVMSize $location;
    $vmname = Get-RandomItemName 'crptestps';

    $vm = New-AzureRmVMConfig -VMName $vmname -VMSize $vmsize;

    return $vm;
}


function Assert-OutputContains
{
    param([string] $cmd, [string[]] $sstr)
    
    $st = Write-Verbose ('Running Command : ' + $cmd);
    $output = Invoke-Expression $cmd | Out-String;

    $max_output_len = 1500;
    if ($output.Length -gt $max_output_len)
    {
        
        $st = Write-Verbose ('Output String   : ' + $output.Substring(0, $max_output_len) + '...');
    }
    else
    {
        $st = Write-Verbose ('Output String   : ' + $output);
    }

    $index = 1;
    foreach ($str in $sstr)
    {
        $st = Write-Verbose ('Search String ' + $index++ + " : `'" + $str + "`'");
        Assert-True { $output.Contains($str) }
        $st = Write-Verbose "Found.";
    }
}



function Get-SasUri
{
    param ([string] $storageAccount, [string] $storageKey, [string] $container, [string] $file, [TimeSpan] $duration, [Microsoft.WindowsAzure.Storage.Blob.SharedAccessBlobPermissions] $type)

    $uri = [string]::Format("https://{0}.blob.core.windows.net/{1}/{2}", $storageAccount, $container, $file);

    $destUri = New-Object -TypeName System.Uri($uri);
    $cred = New-Object -TypeName Microsoft.WindowsAzure.Storage.Auth.StorageCredentials($storageAccount, $storageKey);
    $destBlob = New-Object -TypeName Microsoft.WindowsAzure.Storage.Blob.CloudPageBlob($destUri, $cred);
    $policy = New-Object Microsoft.WindowsAzure.Storage.Blob.SharedAccessBlobPolicy;
    $policy.Permissions = $type;
    $policy.SharedAccessExpiryTime = [DateTime]::UtcNow.Add($duration);
    $uri += $destBlob.GetSharedAccessSignature($policy);

    return $uri;
}


function Get-ResourceProviderLocation
{
    param ([string] $provider)

    $namespace = $provider.Split("/")[0];
    if($provider.Contains("/"))
    {
        $type = $provider.Substring($namespace.Length + 1);
        $location = Get-AzureRmResourceProvider -ProviderNamespace $namespace | where {$_.ResourceTypes[0].ResourceTypeName -eq $type};
  
        if ($location -eq $null)
        {
            return "westus";
        }
        else
        {
            return $location.Locations[0];
        }
    }
    return "westus";
}

function Get-ComputeVMLocation
{
     Get-ResourceProviderLocation "Microsoft.Compute/virtualMachines";
}

function Get-ComputeAvailabilitySetLocation
{
     Get-ResourceProviderLocation "Microsoft.Compute/availabilitySets";
}

function Get-ComputeVMExtensionLocation
{
     Get-ResourceProviderLocation "Microsoft.Compute/virtualMachines/extensions";
}

function Get-ComputeVMDiagnosticSettingLocation
{
     Get-ResourceProviderLocation "Microsoft.Compute/virtualMachines/diagnosticSettings";
}

function Get-ComputeVMMetricDefinitionLocation
{
     Get-ResourceProviderLocation "Microsoft.Compute/virtualMachines/metricDefinitions";
}

function Get-ComputeOperationLocation
{
     Get-ResourceProviderLocation "Microsoft.Compute/locations/operations";
}

function Get-ComputeVMSizeLocation
{
     Get-ResourceProviderLocation "Microsoft.Compute/locations/vmSizes";
}

function Get-ComputeUsageLocation
{
     Get-ResourceProviderLocation "Microsoft.Compute/locations/usages";
}

function Get-ComputePublisherLocation
{
     Get-ResourceProviderLocation "Microsoft.Compute/locations/publishers";
}

function Get-SubscriptionIdFromResourceGroup
{
      param ([string] $rgname)

      $rg = Get-AzureRmResourceGroup -ResourceGroupName $rgname;

      $rgid = $rg.ResourceId;

      
      
      $first = $rgid.IndexOf('/', 1);
      $last = $rgid.IndexOf('/', $first + 1);
      return $rgid.Substring($first + 1, $last - $first - 1);
}

function Get-ComputeVmssLocation
{
      Get-ResourceProviderLocation "Microsoft.Compute/virtualMachineScaleSets"
}
