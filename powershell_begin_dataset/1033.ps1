
$probename = "AppPortProbe6"
$rulename="AppPortLBRule6"
$RGname="mysftestclustergroup"
$port=8303
$subscriptionID = 'subscription ID'


Connect-AzAccount
Get-AzSubscription -SubscriptionId $subscriptionID | Select-AzSubscription 


$resource = Get-AzResource | Where {$_.ResourceGroupName –eq $RGname -and $_.ResourceType -eq "Microsoft.Network/loadBalancers"} 
$slb = Get-AzLoadBalancer -Name $resource.Name -ResourceGroupName $RGname


$slb | Add-AzLoadBalancerProbeConfig -Name $probename -Protocol Tcp -Port $port -IntervalInSeconds 15 -ProbeCount 2


$probe = Get-AzLoadBalancerProbeConfig -Name $probename -LoadBalancer $slb
$slb | Add-AzLoadBalancerRuleConfig -Name $rulename -BackendAddressPool $slb.BackendAddressPools[0] -FrontendIpConfiguration $slb.FrontendIpConfigurations[0] -Probe $probe -Protocol Tcp -FrontendPort $port -BackendPort $port


$slb | Set-AzLoadBalancer
