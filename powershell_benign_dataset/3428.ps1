














function Test-GetSubscriptionsEndToEnd
{
	$allSubscriptions = Get-AzureRmSubscription
	$firstSubscription = $allSubscriptions[0]
	$id = $firstSubscription.Id
	$tenant = $firstSubscription.TenantId
	$name = $firstSubscription.Name
	$subscription = $firstSubscription
	Assert-True { $subscription -ne $null }
	Assert-AreEqual $id $subscription.Id
	$subscription = Get-AzureRmSubscription -SubscriptionId $id
	Assert-True { $subscription -ne $null }
	Assert-AreEqual $id $subscription.Id
	$subscription = Get-AzureRmSubscription -SubscriptionName $name -Tenant $tenant
	Assert-True { $subscription -ne $null }
	Assert-AreEqual $name $subscription.Name
	$subscription = Get-AzureRmSubscription -SubscriptionName $name
	Assert-True { $subscription -ne $null }
	Assert-AreEqual $name $subscription.Name
	$subscription = Get-AzureRmSubscription -SubscriptionName $name.ToUpper()
	Assert-True { $subscription -ne $null }
	Assert-AreEqual $name $subscription.Name
	$mostSubscriptions = Get-AzureRmSubscription
	Assert-True {$mostSubscriptions.Count -gt 0}
	$tenantSubscriptions = Get-AzureRmSubscription -Tenant $tenant
	Assert-True {$tenantSubscriptions.Count -gt 0}
}

function Test-PipingWithContext
{
    $allSubscriptions = Get-AzureRmSubscription
	$firstSubscription = $allSubscriptions[0]
	$id = $firstSubscription.Id
	$name = $firstSubscription.Name
	$nameContext = Get-AzureRmSubscription -SubscriptionName $name | Set-AzureRmContext
	$idContext = Get-AzureRmSubscription -SubscriptionId $id | Set-AzureRmContext
	$contextByName = Set-AzureRmContext -SubscriptionName $name
	Assert-True { $nameContext -ne $null }
	Assert-True { $nameContext.Subscription -ne $null }
	Assert-True { $nameContext.Subscription.Id -ne $null }
	Assert-True { $nameContext.Subscription.Name -ne $null }
	Assert-True { $idContext -ne $null }
	Assert-True { $idContext.Subscription -ne $null }
	Assert-True { $idContext.Subscription.Id -ne $null }
	Assert-True { $idContext.Subscription.Name -ne $null }
	Assert-AreEqual $idContext.Subscription.Id  $nameContext.Subscription.Id
	Assert-AreEqual $idContext.Subscription.Name  $nameContext.Subscription.Name
	Assert-True { $contextByName -ne $null }
	Assert-True { $contextByName.Subscription -ne $null }
	Assert-True { $contextByName.Subscription.Id -ne $null }
	Assert-True { $contextByName.Subscription.Name -ne $null }
	Assert-AreEqual $contextByName.Subscription.Name  $nameContext.Subscription.Name
}

function Test-SetAzureRmContextEndToEnd
{
    
	$allSubscriptions = Get-AzureRmSubscription
    $secondSubscription = $allSubscriptions[1]
    Assert-True { $allSubscriptions[0] -ne $null }
	Assert-True { $secondSubscription -ne $null }
    Set-AzureRmContext -SubscriptionId $secondSubscription.Id
    $context = Get-AzureRmContext
    Assert-AreEqual $context.Subscription.Id $secondSubscription.Id
    $junkSubscriptionId = "49BC3D95-9A30-40F8-81E0-3CDEF0C3F8A5"
    Assert-ThrowsContains {Set-AzureRmContext -SubscriptionId $junkSubscriptionId} "Please provide a valid tenant or a valid subscription."
}

function Test-SetAzureRmContextWithoutSubscription
{
    $allSubscriptions = Get-AzureRmSubscription
    $firstSubscription = $allSubscriptions[0]
    $id = $firstSubscription.Id
    $tenantId = $firstSubscription.TenantId

    Assert-True { $tenantId -ne $null }

    Set-AzureRmContext -TenantId $tenantId
    $context = Get-AzureRmContext

    Assert-True { $context.Subscription -ne $null }
    Assert-True { $context.Tenant -ne $null }
    Assert-AreEqual $context.Tenant.Id $firstSubscription.TenantId
    Assert-AreEqual $context.Subscription.Id $firstSubscription.Id
}