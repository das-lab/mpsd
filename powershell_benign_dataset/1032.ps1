Login-AzAccount
Get-AzSubscription
Set-AzContext -SubscriptionId 'yourSubscriptionId'

$groupname = "mysfclustergroup"
$start=3400
$end=4400


$resource = Get-AzResource | Where {$_.ResourceGroupName –eq $groupname -and $_.ResourceType -eq "Microsoft.Network/loadBalancers"} 
$lb = Get-AzResource -ResourceGroupName $groupname -ResourceType Microsoft.Network/loadBalancers -ResourceName $resource.Name


$lb.Properties.inboundNatPools.properties.frontendPortRangeStart = $start
$lb.Properties.inboundNatPools.properties.frontendPortRangeEnd = $end


Write-Host ($lb.Properties.inboundNatPools | Format-List | Out-String)


Set-AzResource -PropertyObject $lb.Properties -ResourceGroupName $groupname -ResourceType Microsoft.Network/loadBalancers -ResourceName $lb.name  -Force

