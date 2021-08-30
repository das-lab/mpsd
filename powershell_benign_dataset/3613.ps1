














function Test-NewAzureRmAlertRuleWebhook
{
    try
    {
        
        Assert-Throws { New-AzAlertRuleWebhook } "Cannot process command because of one or more missing mandatory parameters: ServiceUri."

		$actual = New-AzAlertRuleWebhook 'http://hello.com'
		Assert-AreEqual $actual.ServiceUri 'http://hello.com'
		Assert-NotNull $actual.Properties
		Assert-AreEqual 0 $actual.Properties.Count

		$actual = New-AzAlertRuleWebhook 'http://hello.com' @{prop1 = 'value1'}
		Assert-AreEqual $actual.ServiceUri 'http://hello.com'
		Assert-NotNull $actual.Properties
		Assert-AreEqual 1 $actual.Properties.Count
    }
    finally
    {
        
        
    }
}


function Test-NewAzureRmAlertRuleEmail
{
    try
    {
        
		Assert-Throws { New-AzAlertRuleEmail } "Either SendToServiceOwners must be set or at least one custom email must be present"

        $actual = New-AzAlertRuleEmail -SendToServiceOwner
		Assert-NotNull $actual "Result is null 1"
		Assert-Null $actual.CustomEmails "Result is not null 1"
		Assert-True { $actual.SendToServiceOwners } "a1"

		$actual = New-AzAlertRuleEmail gu@macrosoft.com
		Assert-NotNull $actual "Result is null 
		Assert-NotNull $actual.CustomEmails "Result is null 
		Assert-False { $actual.SendToServiceOwners } "a2"

		$actual = New-AzAlertRuleEmail gu@macrosoft.com, hu@megasoft.net
		Assert-NotNull $actual "Result is null 
		Assert-NotNull $actual.CustomEmails "Result is null 
		Assert-False { $actual.SendToServiceOwners } "a3"

		$actual = New-AzAlertRuleEmail hu@megasoft.net -SendToServiceOwner
		Assert-NotNull $actual "Result is null 
		Assert-NotNull $actual.CustomEmails "Result is null 
		Assert-True { $actual.SendToServiceOwners } "a4"

		$actual = New-AzAlertRuleEmail gu@macrosoft.com, hu@megasoft.net -SendToServiceOwner
		Assert-NotNull $actual "Result is null 
		Assert-NotNull $actual.CustomEmails "Result is null 
		Assert-True { $actual.SendToServiceOwners } "a5"
    }
    finally
    {
        
        
    }
}


function Test-AddAzureRmMetricAlertRule
{
    try
    {
        
        $actual = Add-AzMetricAlertRule -Name chiricutin -Location "East US" -ResourceGroup Default-Web-EastUS -Operator GreaterThan -Threshold 2 -WindowSize 00:05:00 -TargetResourceId /subscriptions/a93fb07c-6c93-40be-bf3b-4f0deba10f4b/resourceGroups/Default-Web-EastUS/providers/microsoft.web/sites/misitiooeltuyo -MetricName Requests -Description "Pura Vida" -TimeAggre Total

        
		Assert-AreEqual $actual.RequestId '47af504c-88a1-49c5-9766-e397d54e490b'
    }
    finally
    {
        
        
    }
}


function Test-AddAzureRmWebtestAlertRule
{
    try
    {
        
        $actual = Add-AzWebtestAlertRule -Name chiricutin -Location "East US" -ResourceGroup Default-Web-EastUS -WindowSize 00:05:00 -Failed 3 -MetricName Requests -TargetResourceUri /subscriptions/b67f7fec-69fc-4974-9099-a26bd6ffeda3/resourceGroups/Default-Web-EastUS/providers/Microsoft.Insights/components/misitiooeltuyo -Description "Pura Vida"

        
		Assert-AreEqual $actual.RequestId '47af504c-88a1-49c5-9766-e397d54e490b'
    }
    finally
    {
        
        
    }
}


function Test-GetAzureRmAlertRule
{
    
    $rgname = 'Default-Web-EastUS'

    try
    {
	    $actual = Get-AzAlertRule -ResourceGroup $rgname
		Assert-NotNull $actual
		Assert-AreEqual $actual.Count 1
    }
    finally
    {
        
        
    }
}


function Test-GetAzureRmAlertRuleByName
{
    
    $rgname = 'Default-Web-EastUS'

    try
    {
        $actual = Get-AzAlertRule -ResourceGroup $rgname -Name 'MyruleName'
		Assert-NotNull $actual
    }
    finally
    {
        
        
    }
}



function Test-RemoveAzureRmAlertRule
{
    
    $rgname = 'Default-Web-EastUS'

    try
    {
		Remove-AzAlertRule -ResourceGroup $rgname -name chiricutin
    }
    finally
    {
        
        
    }
}


function Test-GetAzureRmAlertHistory
{
    try
    {
		$actual = Get-AzAlertHistory -endTime 2015-02-11T20:00:00Z -detailedOutput

        
		Assert-AreEqual $actual.Count 2
    }
    finally
    {
        
        
    }
}


function Test-GetAzureRmMetricAlertRuleV2
{
    
	$sub = Get-AzContext
    $subscription = $sub.subscription.subscriptionId
	$rgname = Get-ResourceGroupName
	$location =Get-ProviderLocation ResourceManagement
	$resourceName = Get-ResourceName
	$ruleName = Get-ResourceName
	$actionGroupName = Get-ResourceName
	$targetResourceId = '/subscriptions/'+$subscription+'/resourceGroups/'+$rgname+'/providers/Microsoft.Storage/storageAccounts/'+$resourceName
	New-AzResourceGroup -Name $rgname -Location $location -Force
	New-AzStorageAccount -ResourceGroupName $rgname -Name $resourceName -Location $location -Type Standard_GRS
	$email = New-AzActionGroupReceiver -Name 'user1' -EmailReceiver -EmailAddress 'user1@example.com'
	$NewActionGroup =  Set-AzureRmActionGroup -Name $actionGroupName -ResourceGroup $rgname -ShortName ASTG -Receiver $email
	$actionGroup = New-AzActionGroup -ActionGroupId $NewActionGroup.Id
	$condition = New-AzMetricAlertRuleV2Criteria -MetricName "UsedCapacity" -Operator GreaterThan -Threshold 8 -TimeAggregation Average
	Add-AzMetricAlertRuleV2 -Name $ruleName -ResourceGroupName $rgname -WindowSize 01:00:00 -Frequency 00:01:00 -TargetResourceId $targetResourceId -Condition $condition -ActionGroup $actionGroup -Severity 3 

    try
    {
        $actual = Get-AzMetricAlertRuleV2 -ResourceGroupName $rgname -Name $ruleName
		Assert-NotNull $actual
    }
    finally
    {
        
        Remove-AzMetricAlertRuleV2 -ResourceGroupName $rgname -Name $ruleName
		Remove-AzActionGroup -ResourceGroupName $rgname -Name $actionGroupName
		Remove-AzureRmStorageAccount -ResourceGroupName $rgName -Name $resourceName 
		Remove-AzResourceGroup -Name $rgname -Force
    }
}


function Test-RemoveAzureRmAlertRuleV2
{
    
	$sub = Get-AzContext
    $subscription = $sub.subscription.subscriptionId
	$rgname = Get-ResourceGroupName
	$location =Get-ProviderLocation ResourceManagement
	$resourceName = Get-ResourceName
	$ruleName = Get-ResourceName
	$actionGroupName = Get-ResourceName
	$targetResourceId = '/subscriptions/'+$subscription+'/resourceGroups/'+$rgname+'/providers/Microsoft.Storage/storageAccounts/'+$resourceName
	New-AzResourceGroup -Name $rgname -Location $location -Force
	New-AzStorageAccount -ResourceGroupName $rgname -Name $resourceName -Location $location -Type Standard_GRS
	$email = New-AzActionGroupReceiver -Name 'user1' -EmailReceiver -EmailAddress 'user1@example.com'
	$NewActionGroup =  Set-AzureRmActionGroup -Name $actionGroupName -ResourceGroup $rgname -ShortName ASTG -Receiver $email
	$actionGroup = New-AzActionGroup -ActionGroupId $NewActionGroup.Id
	$condition = New-AzMetricAlertRuleV2Criteria -MetricName "UsedCapacity" -Operator GreaterThan -Threshold 8 -TimeAggregation Average
	Add-AzMetricAlertRuleV2 -Name $ruleName -ResourceGroupName $rgname -WindowSize 01:00:00 -Frequency 00:01:00 -TargetResourceId $targetResourceId -Condition $condition -ActionGroup $actionGroup -Severity 3 
    try
    {
		$job = Remove-AzMetricAlertRuleV2 -ResourceGroupName $rgname -Name $ruleName -AsJob
		$job|Wait-Job
		$actual = $job | Receive-Job
    }
    finally
    {
        
      Remove-AzActionGroup -ResourceGroupName $rgname -Name $actionGroupName
	  Remove-AzureRmStorageAccount -ResourceGroupName $rgName -Name $resourceName 
	  Remove-AzResourceGroup -Name $rgname -Force
    }
}


function Test-AddAzureRmMetricAlertRuleV2
{
	
	$sub = Get-AzContext
    $subscription = $sub.subscription.subscriptionId
	$rgname = Get-ResourceGroupName
	$location =Get-ProviderLocation ResourceManagement
	$resourceName = Get-ResourceName
	$ruleName = Get-ResourceName
	$actionGroupName = Get-ResourceName
	$targetResourceId = '/subscriptions/'+$subscription+'/resourceGroups/'+$rgname+'/providers/Microsoft.Storage/storageAccounts/'+$resourceName
	New-AzResourceGroup -Name $rgname -Location $location -Force
	New-AzStorageAccount -ResourceGroupName $rgname -Name $resourceName -Location $location -Type Standard_GRS
	$email = New-AzActionGroupReceiver -Name 'user1' -EmailReceiver -EmailAddress 'user1@example.com'
	$NewActionGroup =  Set-AzureRmActionGroup -Name $actionGroupName -ResourceGroup $rgname -ShortName ASTG -Receiver $email
	$actionGroup = New-AzActionGroup -ActionGroupId $NewActionGroup.Id
	$condition = New-AzMetricAlertRuleV2Criteria -MetricName "UsedCapacity" -Operator GreaterThan -Threshold 8 -TimeAggregation Average
    try
    {
        
        $actual = Add-AzMetricAlertRuleV2 -Name $ruleName -ResourceGroupName $rgname -WindowSize 01:00:00 -Frequency 00:01:00 -TargetResourceId $targetResourceId -Condition $condition -ActionGroup $actionGroup -Severity 3 
		Assert-AreEqual $actual.Name $ruleName
    }
    finally
    {
        
        Remove-AzMetricAlertRuleV2 -ResourceGroupName $rgname -Name $ruleName
		Remove-AzActionGroup -ResourceGroupName $rgname -Name $actionGroupName
		Remove-AzureRmStorageAccount -ResourceGroupName $rgName -Name $resourceName
		Remove-AzResourceGroup -Name $rgname -Force
    }
}

	
function Test-AddAzureRmMetricAlertRuleV2-DynamicThreshold
{
	
	$sub = Get-AzContext
    $subscription = $sub.subscription.subscriptionId
	$rgname = Get-ResourceGroupName
	$location =Get-ProviderLocation ResourceManagement
	$resourceName = Get-ResourceName
	$ruleName = Get-ResourceName
	$actionGroupName = Get-ResourceName
	$targetResourceId = '/subscriptions/'+$subscription+'/resourceGroups/'+$rgname+'/providers/Microsoft.Storage/storageAccounts/'+$resourceName
	New-AzResourceGroup -Name $rgname -Location $location -Force
	New-AzStorageAccount -ResourceGroupName $rgname -Name $resourceName -Location $location -Type Standard_GRS
	$email = New-AzActionGroupReceiver -Name 'user1' -EmailReceiver -EmailAddress 'user1@example.com'
	$NewActionGroup =  Set-AzureRmActionGroup -Name $actionGroupName -ResourceGroup $rgname -ShortName ASTG -Receiver $email
	$actionGroup = New-AzActionGroup -ActionGroupId $NewActionGroup.Id
	$condition = New-AzMetricAlertRuleV2Criteria -MetricName "Transactions" -Operator GreaterThan -DynamicThreshold -TimeAggregation Total -Sensitivity High
    try
    {
        
        $actual = Add-AzMetricAlertRuleV2 -Name $ruleName -ResourceGroupName $rgname -WindowSize 01:00:00 -Frequency 00:05:00 -TargetResourceId $targetResourceId -Condition $condition -ActionGroup $actionGroup -Severity 3 
		Assert-AreEqual $actual.Name $ruleName
    }
    finally
    {
        
        Remove-AzMetricAlertRuleV2 -ResourceGroupName $rgname -Name $ruleName
		Remove-AzActionGroup -ResourceGroupName $rgname -Name $actionGroupName
		Remove-AzureRmStorageAccount -ResourceGroupName $rgName -Name $resourceName
		Remove-AzResourceGroup -Name $rgname -Force
    }
}