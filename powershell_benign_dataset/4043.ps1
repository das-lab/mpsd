














function Test-SubscriptionGetResourceUsage
{
    $subscriptionResourceUsage = Get-AzCdnSubscriptionResourceUsage

    Assert-True {$subscriptionResourceUsage.Count -eq 1}
	Assert-True {$subscriptionResourceUsage[0].CurrentValue -eq 16}
}


function Test-SubscriptionEdgeNode
{
    $edgeNodes = Get-AzCdnEdgeNodes

    Assert-False {$edgeNodes -eq $null}
}