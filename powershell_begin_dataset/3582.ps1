














function Test-CrudApiManagement {
    
    $location = Get-ProviderLocation "Microsoft.ApiManagement/service"
    $resourceGroupName = Get-ResourceGroupName
    $apiManagementName = Get-ApiManagementServiceName
    $organization = "apimpowershellorg"
    $adminEmail = "apim@powershell.org"
    $secondApiManagementName = Get-ApiManagementServiceName
    $secondOrganization = "second.apimpowershellorg"
    $secondAdminEmail = "second.apim@powershell.org"
    $secondSku = "Basic"
    $secondSkuCapacity = 2
	$enableTls=@{"Tls10" = "True"}
	$enable3DES=@{"TripleDes168" = "True"}
	$thirdApiManagementName = Get-ApiManagementServiceName
	$thirdSku = "Consumption"
	$thirdServiceLocation = "West Europe"

    try {
        
        New-AzResourceGroup -Name $resourceGroupName -Location $location
        
		
		$sslSetting = New-AzApiManagementSslSetting -FrontendProtocol $enableTls -CipherSuite $enable3DES
        
        $result = New-AzApiManagement -ResourceGroupName $resourceGroupName -Location $location -Name $apiManagementName -Organization $organization -AdminEmail $adminEmail -SslSetting $sslSetting

        Assert-AreEqual $resourceGroupName $result.ResourceGroupName
        Assert-AreEqual $apiManagementName $result.Name
        Assert-AreEqual $location $result.Location
        Assert-AreEqual "Developer" $result.Sku
        Assert-AreEqual 1 $result.Capacity
        Assert-AreEqual "None" $result.VpnType
		Assert-NotNull $result.SslSetting
		Assert-AreEqual "True" $result.SslSetting.FrontendProtocol["Tls10"]
		Assert-AreEqual "True" $result.SslSetting.CipherSuite["TripleDes168"]

        
        $token = Get-AzApiManagementSsoToken -ResourceGroupName $resourceGroupName -Name $apiManagementName
        Assert-NotNull $token

        
        $apimServicesInGroup = Get-AzApiManagement -ResourceGroupName $resourceGroupName
        Assert-True {$apimServicesInGroup.Count -ge 1}
        
        
        $secondResult = New-AzApiManagement -ResourceGroupName $resourceGroupName -Location $location -Name $secondApiManagementName -Organization $secondOrganization -AdminEmail $secondAdminEmail -Sku $secondSku -Capacity $secondSkuCapacity
        Assert-AreEqual $resourceGroupName $secondResult.ResourceGroupName
        Assert-AreEqual $secondApiManagementName $secondResult.Name
        Assert-AreEqual $location $secondResult.Location
        Assert-AreEqual $secondSku $secondResult.Sku
        Assert-AreEqual $secondSkuCapacity $secondResult.Capacity

        
        $secondToken = Get-AzApiManagementSsoToken -ResourceGroupName $resourceGroupName -Name $secondApiManagementName
        Assert-NotNull $secondToken

        
        $allServices = Get-AzApiManagement
        Assert-True {$allServices.Count -ge 2}
				
        
        $thirdResult = New-AzApiManagement -ResourceGroupName $resourceGroupName -Location $thirdServiceLocation -Name $thirdApiManagementName -Organization $secondOrganization -AdminEmail $secondAdminEmail -Sku $thirdSku
        Assert-AreEqual $resourceGroupName $thirdResult.ResourceGroupName
        Assert-AreEqual $thirdApiManagementName $thirdResult.Name
        Assert-AreEqual $thirdServiceLocation $thirdResult.Location
        Assert-AreEqual $thirdSku $thirdResult.Sku

		
        $allServices = Get-AzApiManagement
        Assert-True {$allServices.Count -ge 3}
		        
        $found = 0
        for ($i = 0; $i -lt $allServices.Count; $i++) {
            if ($allServices[$i].Name -eq $apiManagementName) {
                $found = $found + 1
                Assert-AreEqual $location $allServices[$i].Location
                Assert-AreEqual $resourceGroupName $allServices[$i].ResourceGroupName
        
                Assert-AreEqual "Developer" $allServices[$i].Sku
                Assert-AreEqual 1 $allServices[$i].Capacity
            }

            if ($allServices[$i].Name -eq $secondApiManagementName) {
                $found = $found + 1
                Assert-AreEqual $location $allServices[$i].Location
                Assert-AreEqual $resourceGroupName $allServices[$i].ResourceGroupName
        
                Assert-AreEqual $secondSku $allServices[$i].Sku
                Assert-AreEqual $secondSkuCapacity $allServices[$i].Capacity
            }
			
            if ($allServices[$i].Name -eq $thirdApiManagementName) {
                $found = $found + 1
                Assert-AreEqual $thirdServiceLocation $allServices[$i].Location
                Assert-AreEqual $resourceGroupName $allServices[$i].ResourceGroupName
        
                Assert-AreEqual $thirdSku $allServices[$i].Sku
            }
        }
        Assert-True {$found -eq 3} "Api Management services created earlier is not found."
        
        
        Get-AzApiManagement -ResourceGroupName $resourceGroupName | Remove-AzApiManagement

        $allServices = Get-AzApiManagement -ResourceGroupName $resourceGroupName
        Assert-AreEqual 0 $allServices.Count
    }
    finally {
        
        Clean-ResourceGroup $resourceGroupName
    }
}


function Test-BackupRestoreApiManagement {
    
    $location = Get-ProviderLocation "Microsoft.ApiManagement/service"
    $resourceGroupName = Get-ResourceGroupName
    $storageLocation = Get-ProviderLocation "Microsoft.ClassicStorage/storageAccounts"
    $storageAccountName = Get-ApiManagementServiceName
    $apiManagementName = Get-ApiManagementServiceName
    $organization = "apimpowershellorg"
    $adminEmail = "apim@powershell.org"
    $containerName = "backups"
    $backupName = $apiManagementName + ".apimbackup"

    
    try {
        New-AzResourceGroup -Name $resourceGroupName -Location $location -Force

        
        New-AzStorageAccount -StorageAccountName $storageAccountName -Location $storageLocation -ResourceGroupName $resourceGroupName -Type Standard_LRS
        $storageKey = (Get-AzStorageAccountKey -ResourceGroupName $resourceGroupName -StorageAccountName $storageAccountName).Key1
        $storageContext = New-AzStorageContext -StorageAccountName $storageAccountName -StorageAccountKey $storageKey
        
        
        $apiManagementService = New-AzApiManagement -ResourceGroupName $resourceGroupName -Location $location -Name $apiManagementName -Organization $organization -AdminEmail $adminEmail

        
        Backup-AzApiManagement -ResourceGroupName $resourceGroupName -Name $apiManagementName -StorageContext $storageContext -TargetContainerName $containerName -TargetBlobName $backupName

        
        $restoreResult = Restore-AzApiManagement -ResourceGroupName $resourceGroupName -Name $apiManagementName -StorageContext $storageContext -SourceContainerName $containerName -SourceBlobName $backupName -PassThru

        Assert-AreEqual $resourceGroupName $restoreResult.ResourceGroupName
        Assert-AreEqual $apiManagementName $restoreResult.Name
        Assert-AreEqual $location $restoreResult.Location
        Assert-AreEqual "Developer" $restoreResult.Sku
        Assert-AreEqual 1 $restoreResult.Capacity
        Assert-AreEqual "Succeeded" $restoreResult.ProvisioningState
    }
    finally {
        
        Clean-ResourceGroup $resourceGroupName    
    }   
}


function Test-ApiManagementVirtualNetworkCRUD {
    
    $primarylocation = "North Central US"
    $secondarylocation = "South Central US"
    $resourceGroupName = Get-ResourceGroupName    
    $apiManagementName = Get-ApiManagementServiceName
    $organization = "apimpowershellorg"
    $adminEmail = "apim@powershell.org"
    $sku = "Developer"
    $capacity = 1
    $primarySubnetResourceId = "/subscriptions/a200340d-6b82-494d-9dbf-687ba6e33f9e/resourceGroups/powershelltest/providers/Microsoft.Network/virtualNetworks/powershellvnetncu/subnets/default"
    $additionalSubnetResourceId = "/subscriptions/a200340d-6b82-494d-9dbf-687ba6e33f9e/resourceGroups/powershelltest/providers/Microsoft.Network/virtualNetworks/powershellvnetscu/subnets/default"
    $vpnType = "External" 
 
    try {
        
        New-AzResourceGroup -Name $resourceGroupName -Location $primarylocation
 
        
        $virtualNetwork = New-AzApiManagementVirtualNetwork -SubnetResourceId $primarySubnetResourceId
         
        
        $result = New-AzApiManagement -ResourceGroupName $resourceGroupName -Location $primarylocation -Name $apiManagementName -Organization $organization -AdminEmail $adminEmail -VpnType $vpnType -VirtualNetwork $virtualNetwork -Sku $sku -Capacity $capacity
 
        Assert-AreEqual $resourceGroupName $result.ResourceGroupName
        Assert-AreEqual $apiManagementName $result.Name
        Assert-AreEqual $primarylocation $result.Location
        Assert-AreEqual $sku $result.Sku
        Assert-AreEqual 1 $result.Capacity
        Assert-AreEqual $vpnType $result.VpnType
        Assert-Null $result.PrivateIPAddresses
        Assert-NotNull $result.PublicIPAddresses
        Assert-AreEqual $primarySubnetResourceId $result.VirtualNetwork.SubnetResourceId

		$networkStatus = Get-AzApiManagementNetworkStatus -ResourceGroupName $resourceGroupName -Name $apiManagementName
        Assert-NotNull $networkStatus
		Assert-NotNull $networkStatus.DnsServers
		Assert-NotNull $networkStatus.ConnectivityStatus

        
        $service = Get-AzApiManagement -ResourceGroupName $resourceGroupName -Name $apiManagementName
        $vpnType = "Internal"
        $service.VirtualNetwork = $virtualNetwork
        $service.VpnType = $vpnType
        
        $sku = "Premium"
        $service.Sku = $sku
        
        
        $additionalRegionVirtualNetwork = New-AzApiManagementVirtualNetwork -SubnetResourceId $additionalSubnetResourceId

        $service = Add-AzApiManagementRegion -ApiManagement $service -Location $secondarylocation -VirtualNetwork $additionalRegionVirtualNetwork
        
        $service = Set-AzApiManagement -InputObject $service -PassThru

        Assert-AreEqual $resourceGroupName $service.ResourceGroupName
        Assert-AreEqual $apiManagementName $service.Name
        Assert-AreEqual $sku $service.Sku
        Assert-AreEqual $primarylocation $service.Location
        Assert-AreEqual "Succeeded" $service.ProvisioningState
        Assert-AreEqual $vpnType $service.VpnType
        Assert-NotNull $service.VirtualNetwork
        Assert-NotNull $service.VirtualNetwork.SubnetResourceId
        Assert-NotNull $service.PrivateIPAddresses
        Assert-NotNull $service.PublicIPAddresses
        Assert-AreEqual $primarySubnetResourceId $service.VirtualNetwork.SubnetResourceId

        
        Assert-AreEqual 1 $service.AdditionalRegions.Count
        $found = 0
        for ($i = 0; $i -lt $service.AdditionalRegions.Count; $i++) {
            if ($service.AdditionalRegions[$i].Location -eq $secondarylocation) {
                $found = $found + 1
                Assert-AreEqual $sku $service.AdditionalRegions[$i].Sku
                Assert-AreEqual 1 $service.AdditionalRegions[$i].Capacity
                Assert-NotNull $service.AdditionalRegions[$i].VirtualNetwork
                Assert-AreEqual $additionalSubnetResourceId $service.AdditionalRegions[$i].VirtualNetwork.SubnetResourceId
                Assert-NotNull $service.AdditionalRegions[$i].PrivateIPAddresses
                Assert-NotNull $service.AdditionalRegions[$i].PublicIPAddresses
            }
        }
        
        Assert-True {$found -eq 1} "Api Management regions created earlier is not found."

		
		$networkStatus = Get-AzApiManagementNetworkStatus -ApiManagementObject $service
        Assert-NotNull $networkStatus
		Assert-NotNull $networkStatus.DnsServers
		Assert-NotNull $networkStatus.ConnectivityStatus

    }
    finally {
        
        Clean-ResourceGroup $resourceGroupName    
    }
}


function Test-ApiManagementHostnamesCRUD {
    
    $location = "North Central US"
    $certFilePath = "$TestOutputRoot/powershelltest.pfx";
    $certPassword = "Password";
    $certSubject = "CN=*.msitesting.net"
    $certThumbprint = "8E989652CABCF585ACBFCB9C2C91F1D174FDB3A2"
    $portalHostName = "portalsdk.msitesting.net"
    $proxyHostName1 = "gateway1.msitesting.net"
    $proxyHostName2 = "gateway2.msitesting.net"
    $managementHostName = "mgmt.msitesting.net"
    $resourceGroupName = Get-ResourceGroupName
    $apiManagementName = Get-ApiManagementServiceName
    $organization = "apimpowershellorg"
    $adminEmail = "apim@powershell.org"
    $sku = "Premium" 
    $capacity = 1
    
    try {
        
        New-AzResourceGroup -Name $resourceGroupName -Location $location

        
        $securePfxPassword = ConvertTo-SecureString $certPassword -AsPlainText -Force
        $customProxy1 = New-AzApiManagementCustomHostnameConfiguration -Hostname $proxyHostName1 -HostnameType Proxy -PfxPath $certFilePath -PfxPassword $securePfxPassword -DefaultSslBinding
        $customProxy2 = New-AzApiManagementCustomHostnameConfiguration -Hostname $proxyHostName2 -HostnameType Proxy -PfxPath $certFilePath -PfxPassword $securePfxPassword
        $customPortal = New-AzApiManagementCustomHostnameConfiguration -Hostname $portalHostName -HostnameType Portal -PfxPath $certFilePath -PfxPassword $securePfxPassword
        $customMgmt = New-AzApiManagementCustomHostnameConfiguration -Hostname $managementHostName -HostnameType Management -PfxPath $certFilePath -PfxPassword $securePfxPassword
        $customHostnames = @($customProxy1, $customProxy2, $customPortal, $customMgmt)

        
        $result = New-AzApiManagement -ResourceGroupName $resourceGroupName -Location $location -Name $apiManagementName -Organization $organization -AdminEmail $adminEmail -Sku $sku -Capacity $capacity -CustomHostnameConfiguration $customHostnames

        Assert-AreEqual $resourceGroupName $result.ResourceGroupName
        Assert-AreEqual $apiManagementName $result.Name
        Assert-AreEqual $location $result.Location
        Assert-AreEqual $sku $result.Sku
        Assert-AreEqual 1 $result.Capacity
        Assert-AreEqual "None" $result.VpnType
        
        
        Assert-NotNull $result.ProxyCustomHostnameConfiguration
        Assert-AreEqual 3 $result.ProxyCustomHostnameConfiguration.Count
        for ($i = 0; $i -lt $result.ProxyCustomHostnameConfiguration.Count; $i++) {
            if ($result.ProxyCustomHostnameConfiguration[$i].Hostname -eq $proxyHostName1) {
                $found = $found + 1
                Assert-AreEqual Proxy $result.ProxyCustomHostnameConfiguration[$i].HostnameType
                Assert-AreEqual $certThumbprint $result.ProxyCustomHostnameConfiguration[$i].CertificateInformation.Thumbprint
                Assert-True {$result.ProxyCustomHostnameConfiguration[$i].DefaultSslBinding}
                Assert-False {$result.ProxyCustomHostnameConfiguration[$i].NegotiateClientCertificate}
                Assert-Null $result.ProxyCustomHostnameConfiguration[$i].KeyVaultId
            }
            if ($result.ProxyCustomHostnameConfiguration[$i].Hostname -eq $proxyHostName2) {
                $found = $found + 1
                Assert-AreEqual Proxy $result.ProxyCustomHostnameConfiguration[$i].HostnameType
                Assert-AreEqual $certThumbprint $result.ProxyCustomHostnameConfiguration[$i].CertificateInformation.Thumbprint
                
                Assert-True {$result.ProxyCustomHostnameConfiguration[$i].DefaultSslBinding}
                Assert-False {$result.ProxyCustomHostnameConfiguration[$i].NegotiateClientCertificate}
                Assert-Null $result.ProxyCustomHostnameConfiguration[$i].KeyVaultId
            }
        }

        
        Assert-NotNull $result.PortalCustomHostnameConfiguration
        Assert-AreEqual $portalHostName $result.PortalCustomHostnameConfiguration.Hostname
        Assert-AreEqual Portal $result.PortalCustomHostnameConfiguration.HostnameType
        Assert-AreEqual $certThumbprint $result.PortalCustomHostnameConfiguration.CertificateInformation.Thumbprint

        
        Assert-NotNull $result.ManagementCustomHostnameConfiguration
        Assert-AreEqual $managementHostName $result.ManagementCustomHostnameConfiguration.Hostname
        Assert-AreEqual Management $result.ManagementCustomHostnameConfiguration.HostnameType
        Assert-AreEqual $certThumbprint $result.ManagementCustomHostnameConfiguration.CertificateInformation.Thumbprint

        
        Assert-Null $result.ScmCustomHostnameConfiguration
        
        
        $result.ManagementCustomHostnameConfiguration = $null
        $result.PortalCustomHostnameConfiguration = $null
        $result.ProxyCustomHostnameConfiguration = @($customProxy1)

        
        $certificateStoreLocation = "CertificateAuthority"
        $systemCert = New-AzApiManagementSystemCertificate -StoreName $certificateStoreLocation -PfxPath $certFilePath -PfxPassword $securePfxPassword
        $result.SystemCertificates = @($systemCert)
        
        
        $result = Set-AzApiManagement -InputObject $result -PassThru 

        Assert-AreEqual $resourceGroupName $result.ResourceGroupName
        Assert-AreEqual $apiManagementName $result.Name
        Assert-AreEqual $location $result.Location
        Assert-AreEqual $sku $result.Sku
        Assert-AreEqual 1 $result.Capacity
        Assert-AreEqual "None" $result.VpnType
        
        
        Assert-NotNull $result.ProxyCustomHostnameConfiguration
        Assert-AreEqual 2 $result.ProxyCustomHostnameConfiguration.Count
        for ($i = 0; $i -lt $result.ProxyCustomHostnameConfiguration.Count; $i++) {
            if ($result.ProxyCustomHostnameConfiguration[$i].Hostname -eq $proxyHostName1) {
                $found = $found + 1
                Assert-AreEqual Proxy $result.ProxyCustomHostnameConfiguration[$i].HostnameType
                Assert-AreEqual $certThumbprint $result.ProxyCustomHostnameConfiguration[$i].CertificateInformation.Thumbprint
                Assert-True {$result.ProxyCustomHostnameConfiguration[$i].DefaultSslBinding}
                Assert-False {$result.ProxyCustomHostnameConfiguration[$i].NegotiateClientCertificate}
                Assert-Null $result.ProxyCustomHostnameConfiguration[$i].KeyVaultId
            }
        }

        
        Assert-Null $result.PortalCustomHostnameConfiguration
        
        Assert-Null $result.ManagementCustomHostnameConfiguration
        
        Assert-Null $result.ScmCustomHostnameConfiguration
        
        Assert-NotNull $result.SystemCertificates
        Assert-AreEqual 1 $result.SystemCertificates.Count
        Assert-AreEqual $certificateStoreLocation $result.SystemCertificates.StoreName
        Assert-AreEqual $certThumbprint $result.SystemCertificates.CertificateInformation.Thumbprint
    }
    finally {
        
        Clean-ResourceGroup $resourceGroupName   
    }
}


function Test-ApiManagementWithAdditionalRegionsCRUD {
    
    $location = Get-ProviderLocation "Microsoft.ApiManagement/service"  
    $resourceGroupName = Get-ResourceGroupName    
    $apiManagementName = Get-ApiManagementServiceName
    $organization = "apimpowershellorg"
    $adminEmail = "apim@powershell.org"
    $sku = "Premium"
    $capacity = 1
    $firstAdditionalRegionLocation = "East US"
    $secondAdditionalRegionLocation = "South Central US"
		
    try {
        
        New-AzResourceGroup -Name $resourceGroupName -Location $location
		
        $firstAdditionalRegion = New-AzApiManagementRegion -Location $firstAdditionalRegionLocation
        $secondAdditionalRegion = New-AzApiManagementRegion -Location $secondAdditionalRegionLocation
        $regions = @($firstAdditionalRegion, $secondAdditionalRegion)
        
        
        $result = New-AzApiManagement -ResourceGroupName $resourceGroupName -Location $location -Name $apiManagementName -Organization $organization -AdminEmail $adminEmail -Sku $sku -Capacity $capacity -AdditionalRegions $regions

        Assert-AreEqual $resourceGroupName $result.ResourceGroupName
        Assert-AreEqual $apiManagementName $result.Name
        Assert-AreEqual $location $result.Location
        Assert-AreEqual $sku $result.Sku
        Assert-AreEqual $capacity $result.Capacity
        Assert-AreEqual "None" $result.VpnType
		
        Assert-AreEqual 2 $result.AdditionalRegions.Count
        $found = 0
        for ($i = 0; $i -lt $result.AdditionalRegions.Count; $i++) {
            if ($result.AdditionalRegions[$i].Location.Replace(" ", "") -eq $firstAdditionalRegionLocation.Replace(" ", "")) {
                $found = $found + 1
                Assert-AreEqual $sku $result.AdditionalRegions[$i].Sku
                Assert-AreEqual 1 $result.AdditionalRegions[$i].Capacity
                Assert-Null $result.AdditionalRegions[$i].VirtualNetwork
            }
            if ($result.AdditionalRegions[$i].Location.Replace(" ", "") -eq $secondAdditionalRegionLocation.Replace(" ", "")) {
                $found = $found + 1
                Assert-AreEqual $sku $result.AdditionalRegions[$i].Sku
                Assert-AreEqual 1 $result.AdditionalRegions[$i].Capacity
                Assert-Null $result.AdditionalRegions[$i].VirtualNetwork
            }
        }

        
        $newAdditionalRegionCapacity = 2
        $apimService = Get-AzApiManagement -ResourceGroupName $resourceGroupName -Name $apiManagementName
        $apimService = Remove-AzApiManagementRegion -ApiManagement $apimService -Location $firstAdditionalRegionLocation
        $apimService = Update-AzApiManagementRegion -ApiManagement $apimService -Location $secondAdditionalRegionLocation -Capacity $newAdditionalRegionCapacity -Sku $sku

        
        $updatedService = Set-AzApiManagement -InputObject $apimService -AssignIdentity -PassThru
        Assert-AreEqual $resourceGroupName $updatedService.ResourceGroupName
        Assert-AreEqual $apiManagementName $updatedService.Name
        Assert-AreEqual $location $updatedService.Location
        Assert-AreEqual $sku $updatedService.Sku
        Assert-AreEqual $capacity $updatedService.Capacity
        Assert-AreEqual "None" $updatedService.VpnType
		
        Assert-AreEqual 1 $updatedService.AdditionalRegions.Count
        $found = 0
        
        for ($i = 0; $i -lt $updatedService.AdditionalRegions.Count; $i++) {            
            if ($updatedService.AdditionalRegions[$i].Location.Replace(" ", "") -eq $secondAdditionalRegionLocation.Replace(" ", "")) {
                $found = $found + 1
                Assert-AreEqual $sku $updatedService.AdditionalRegions[$i].Sku
                Assert-AreEqual $newAdditionalRegionCapacity $updatedService.AdditionalRegions[$i].Capacity
                Assert-Null $updatedService.AdditionalRegions[$i].VirtualNetwork
            }
        }

        
        Assert-AreEqual "SystemAssigned" $updatedService.Identity.Type;
        Assert-NotNull $updatedService.Identity.PrincipalId;
        Assert-NotNull $updatedService.Identity.TenantId;
    }
    finally {
        
        Clean-ResourceGroup $resourceGroupName
    }
}


function Test-CrudApiManagementWithExternalVpn {
    
    
    $location = "North Central US"    
    $resourceGroupName = Get-ResourceGroupName    
    $apiManagementName = Get-ApiManagementServiceName
    $organization = "apimpowershellorg"
    $adminEmail = "apim@powershell.org"
    $sku = "Developer"
    $capacity = 1
    $subnetResourceId = "/subscriptions/20010222-2b48-4245-a95c-090db6312d5f/resourceGroups/powershelltest/providers/Microsoft.Network/virtualNetworks/apimvnettest/subnets/default"
    $vpnType = "External"


    try {
        
        New-AzResourceGroup -Name $resourceGroupName -Location $location

        
        $virtualNetwork = New-AzApiManagementVirtualNetwork -Location $location -SubnetResourceId $subnetResourceId
        
        
        $result = New-AzApiManagement -ResourceGroupName $resourceGroupName -Location $location -Name $apiManagementName -Organization $organization -AdminEmail $adminEmail -VpnType $vpnType -VirtualNetwork $virtualNetwork -Sku $sku -Capacity $capacity

        Assert-AreEqual $resourceGroupName $result.ResourceGroupName
        Assert-AreEqual $apiManagementName $result.Name
        Assert-AreEqual $location $result.Location
        Assert-AreEqual $sku $result.Sku
        Assert-AreEqual 1 $result.Capacity
        Assert-AreEqual $vpnType $result.VpnType
        Assert-AreEqual $subnetResourceId $result.VirtualNetwork.SubnetResourceId

        
        Get-AzApiManagement -ResourceGroupName $resourceGroupName | Remove-AzApiManagement

        $allServices = Get-AzApiManagement -ResourceGroupName $resourceGroupName
        Assert-AreEqual 0 $allServices.Count
    }
    finally {
        
        Clean-ResourceGroup $resourceGroupName
    }
}