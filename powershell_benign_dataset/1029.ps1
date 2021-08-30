Login-AzAccount
Get-AzSubscription
Set-AzContext -SubscriptionId "yourSubscriptionID"

$RGname="sfclustertutorialgroup"
$port=8081
$rulename="allowAppPort$port"
$nsgname="sf-vnet-security"


$nsg = Get-AzNetworkSecurityGroup -Name $nsgname -ResourceGroupName $RGname


$nsg | Add-AzNetworkSecurityRuleConfig -Name $rulename -Description "Allow app port" -Access Allow `
    -Protocol * -Direction Inbound -Priority 3891 -SourceAddressPrefix "*" -SourcePortRange * `
    -DestinationAddressPrefix * -DestinationPortRange $port


$nsg | Set-AzNetworkSecurityGroup
