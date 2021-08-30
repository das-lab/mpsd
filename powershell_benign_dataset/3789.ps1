Param(
  [Parameter(Mandatory = $false,
             HelpMessage="Identifier of the Azure subscription to be used. Default subscription will be used if not specified.")]
  [ValidateNotNullOrEmpty()]
  [string]$subscriptionId,

  [Parameter(Mandatory = $true, 
             HelpMessage="Name of the resource group to which the KeyVault belongs to.  A new resource group with this name will be created if one doesn't exist")]
  [ValidateNotNullOrEmpty()]
  [string]$resourceGroupName,

  [Parameter(Mandatory = $true,
             HelpMessage="Location of the KeyVault. Important note: Make sure the KeyVault and VMSS to be encrypted are in the same location.")]
  [ValidateNotNullOrEmpty()]
  [string]$location,

  [Parameter(Mandatory = $true,
             HelpMessage="Name of the KeyVault in which encryption keys are to be placed. A new vault with this name will be created if one doesn't exist")]
  [ValidateNotNullOrEmpty()]
  [string]$keyVaultName,

  [Parameter(Mandatory = $false,
             HelpMessage="Name of optional key encryption key in KeyVault. A new key with this name will be created if one doesn't exist")]
  [ValidateNotNullOrEmpty()]
  [string]$keyEncryptionKeyName,

  [Parameter(Mandatory = $false,
             HelpMessage="Name of the VMSS to be encrypted")]
  [ValidateNotNullOrEmpty()]
  [string]$VmssName
)

$VerbosePreference = "Continue";
$ErrorActionPreference = “Stop”;





    
    

    if($subscriptionId)
    {
        Select-AzSubscription -SubscriptionId $subscriptionId;
    }

    $vmssDiskEncryptionFeature = Get-AzProviderFeature  -FeatureName "UnifiedDiskEncryption" -ProviderNamespace "Microsoft.Compute";
    if($vmssDiskEncryptionFeature -and $vmssDiskEncryptionFeature.RegistrationState -eq 'Registered')
    {
        Write-Host "AzureDiskEncryption-VMSS feature is enabled for subscription :  $subscriptionId";
    } 
    else
    {
        Write-Host "Enabling UnifiedDiskEncryption AzureDiskEncryption-VMSS feature for subscription :  ($subscriptionId)";
        
        Register-AzProviderFeature -FeatureName "UnifiedDiskEncryption" -ProviderNamespace "Microsoft.Compute";
        $vmssDiskEncryptionFeature = Get-AzProviderFeature  -FeatureName "UnifiedDiskEncryption" -ProviderNamespace "Microsoft.Compute";
        for($i = 1; i<6; i++)
        {
            if($vmssDiskEncryptionFeature -and $vmssDiskEncryptionFeature.RegistrationState -eq 'Registered')
            {
                Write-Host "AzureDiskEncryption-VMSS feature is enabled for subscription :  ($subscriptionId)";
                break;
            }  
            else
            {
                Write-Host "Sleeping 10 seconds to actiavate AzureDiskEncryption-VMSS feature . Retry count :  ($i)";
                Start-Sleep -Seconds 10;
            }         
        }
        if(!$vmssDiskEncryptionFeature -or $vmssDiskEncryptionFeature.RegistrationState -ne 'Registered')
        {
            Write-Error "AzureDiskEncryption-VMSS feature is NOT enabled . Please retry after sometime";
        } 
    }





    
    Try
    {
        $resGroup = Get-AzResourceGroup -Name $resourceGroupName -ErrorAction SilentlyContinue;
    }
    Catch [System.ArgumentException]
    {
        Write-Host "Couldn't find resource group:  ($resourceGroupName)";
        $resGroup = $null;
    }
    
    
    if (-not $resGroup)
    {
        Write-Host "Creating new resource group:  ($resourceGroupName)";
        $resGroup = New-AzResourceGroup -Name $resourceGroupName -Location $location;
        Write-Host "Created a new resource group named $resourceGroupName to place keyVault";
    }
    
    
    Try
    {
        $keyVault = Get-AzKeyVault -VaultName $keyVaultName -ErrorAction SilentlyContinue;
    }
    Catch [System.ArgumentException]
    {
        Write-Host "Couldn't find Key Vault: $keyVaultName";
        $keyVault = $null;
    }
    
    
    if (-not $keyVault)
    {
        Write-Host "Creating new key vault:  ($keyVaultName)";
        $keyVault = New-AzKeyVault -VaultName $keyVaultName -ResourceGroupName $resourceGroupName -Sku Standard -Location $location;
        Write-Host "Created a new KeyVault named $keyVaultName to store encryption keys";
    }

    
    Set-AzKeyVaultAccessPolicy -VaultName $keyVaultName -EnabledForDiskEncryption;
    
    $diskEncryptionKeyVaultUrl = $keyVault.VaultUri;
	$keyVaultResourceId = $keyVault.ResourceId;

    Write-Host "DiskEncryptionKeyVaultUrl:$diskEncryptionKeyVaultUrl" -foregroundcolor Green;
    Write-Host "DiskEncryptionKeyVaultId:$keyVaultResourceId" -foregroundcolor Green;
    
    if($keyEncryptionKeyName)
    {
        
        Try
        {
            $kek = Get-AzKeyVaultKey -VaultName $keyVaultName -Name $keyEncryptionKeyName -ErrorAction SilentlyContinue;
        }
        Catch [Microsoft.Azure.KeyVault.KeyVaultClientException]
        {
            Write-Host "Couldn't find key encryption key named : $keyEncryptionKeyName in Key Vault: $keyVaultName";
            $kek = $null;
        } 

        if(-not $kek)
        {
            Write-Host "Creating new key encryption key named:$keyEncryptionKeyName in Key Vault: $keyVaultName";
            $kek = Add-AzKeyVaultKey -VaultName $keyVaultName -Name $keyEncryptionKeyName -Destination Software -ErrorAction SilentlyContinue;
            Write-Host "Created  key encryption key named:$keyEncryptionKeyName in Key Vault: $keyVaultName";
        }

        $keyEncryptionKeyUrl = $kek.Key.Kid;
        Write-Host "keyEncryptionKeyUrl:$keyEncryptionKeyUrl" -foregroundcolor Green;
        Write-Host "KeyEncryptionKeyVaultId:$keyVaultResourceId" -foregroundcolor Green;
    }   






    if($VmssName)
    {
        Write-Host "EnablingEncryption on scale set:$VmssName";

        
        if($keyEncryptionKeyName)
        { 
            
            Set-AzVmssDiskEncryptionExtension -ResourceGroupName $resourceGroupName `
                                                   -VMScaleSetName $VmssName `
                                                   -DiskEncryptionKeyVaultUrl $diskEncryptionKeyVaultUrl `
                                                   -DiskEncryptionKeyVaultId $keyVaultResourceId `
                                                   -KeyEncryptionKeyUrl $keyEncryptionKeyUrl `
                                                   -KeyEncryptionKeyVaultId $keyVaultResourceId `
                                                   -Force;
        }
        else
        {
            Set-AzVmssDiskEncryptionExtension -ResourceGroupName $resourceGroupName `
                                                   -VMScaleSetName $VmssName `
                                                   -DiskEncryptionKeyVaultUrl $diskEncryptionKeyVaultUrl `
                                                   -DiskEncryptionKeyVaultId $keyVaultResourceId `
                                                   -Force;
        }

        
        $vmss = Get-AzVmss -ResourceGroupName $resourceGroupName -VMScaleSetName $VmssName;
        if($vmss.UpgradePolicy.Mode -eq 'Manual')
        {
            
            Update-AzVmssInstance -ResourceGroupName $resourceGroupName -VMScaleSetName $VmssName -InstanceId "*";
        }

        
        Get-AzVmssVmDiskEncryption -ResourceGroupName $resourceGroupName -VMScaleSetName $VmssName | fc;
    }
