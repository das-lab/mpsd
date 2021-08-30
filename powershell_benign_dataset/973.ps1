

$SubscriptionId = ''

$resourceGroupName = "myResourceGroup-$(Get-Random)"
$location = "westus2"

$vNetName = "myVnet-$(Get-Random)"
$vNetAddressPrefix = "10.0.0.0/16"
$defaultSubnetName = "myDefaultSubnet-$(Get-Random)"
$defaultSubnetAddressPrefix = "10.0.0.0/24"
$miSubnetName = "myMISubnet-$(Get-Random)"
$miSubnetAddressPrefix = "10.0.0.0/24"

$instanceName = "myMIName-$(Get-Random)"

$miAdminSqlLogin = "SqlAdmin"
$miAdminSqlPassword = "ChangeYourAdminPassword1"

$edition = "General Purpose"
$vCores = 8
$maxStorage = 256
$computeGeneration = "Gen4"
$license = "LicenseIncluded" 


Set-AzContext -SubscriptionId $subscriptionId 


$resourceGroup = New-AzResourceGroup -Name $resourceGroupName -Location $location


$virtualNetwork = New-AzVirtualNetwork `
                      -ResourceGroupName $resourceGroupName `
                      -Location $location `
                      -Name $vNetName `
                      -AddressPrefix $vNetAddressPrefix

                  Add-AzVirtualNetworkSubnetConfig `
                      -Name $miSubnetName `
                      -VirtualNetwork $virtualNetwork `
                      -AddressPrefix $miSubnetAddressPrefix `
                  | Set-AzVirtualNetwork

$virtualNetwork = Get-AzVirtualNetwork -Name $vNetName -ResourceGroupName $resourceGroupName

$miSubnetConfig = Get-AzVirtualNetworkSubnetConfig `
                        -Name $miSubnetName `
                        -VirtualNetwork $virtualNetwork 

$miSubnetConfigId = $miSubnetConfig.Id

$networkSecurityGroupMiManagementService = New-AzNetworkSecurityGroup `
                      -Name 'myNetworkSecurityGroupMiManagementService' `
                      -ResourceGroupName $resourceGroupName `
                      -location $location

$routeTableMiManagementService = New-AzRouteTable `
                      -Name 'myRouteTableMiManagementService' `
                      -ResourceGroupName $resourceGroupName `
                      -location $location

Set-AzVirtualNetworkSubnetConfig `
                      -VirtualNetwork $virtualNetwork `
                      -Name $miSubnetName `
                      -AddressPrefix $miSubnetAddressPrefix `
                      -NetworkSecurityGroup $networkSecurityGroupMiManagementService `
                      -RouteTable $routeTableMiManagementService | `
                    Set-AzVirtualNetwork

Get-AzNetworkSecurityGroup `
                      -ResourceGroupName $resourceGroupName `
                      -Name "myNetworkSecurityGroupMiManagementService" `
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
                      -SourceAddressPrefix $miSubnetAddressPrefix `
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
                      -DestinationAddressPrefix $miSubnetAddressPrefix `
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
                      -Name "myRouteTableMiManagementService" `
                      | Add-AzRouteConfig `
                      -Name "ToManagedInstanceManagementService" `
                      -AddressPrefix 0.0.0.0/0 `
                      -NextHopType Internet `
                      | Add-AzRouteConfig `
                      -Name "ToLocalClusterNode" `
                      -AddressPrefix $miSubnetAddressPrefix `
                      -NextHopType VnetLocal `
                     | Set-AzRouteTable


New-AzSqlInstance -Name $instanceName `
                      -ResourceGroupName $resourceGroupName -Location westus2 -SubnetId $miSubnetConfigId `
                      -AdministratorCredential (Get-Credential) `
                      -StorageSizeInGB $maxStorage -VCore $vCores -Edition $edition `
                      -ComputeGeneration $computeGeneration -LicenseType $license





