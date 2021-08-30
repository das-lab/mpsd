





















function Get-BudgetName
{
    return "Budget-" + (getAssetName)
}


function Get-NotificationKey
{
    return "NotificationKey-" + (getAssetName)
}


function Get-ResourceGroupName
{
    return "RG-" + (getAssetName)
}


function Test-BudgetAtSubscriptionLevel
{
	
	$budgetName = Get-BudgetName
	$notificationKey = Get-NotificationKey
	$startDate = Get-Date -Day 1
	$endDate = ($startDate).AddMonths(3).AddDays(-1)

	Write-Debug "Create a new budget $budgetName at subscription level"
    $budgetNew = New-AzConsumptionBudget -Amount 6000 -Name $budgetName -Category Cost -StartDate $startDate -EndDate $endDate -TimeGrain Monthly
	Assert-NotNull $budgetNew
	Assert-AreEqual 6000 $budgetNew.Amount
	Assert-AreEqual $budgetName $budgetNew.Name
	Assert-AreEqual Cost $budgetNew.Category
	Assert-AreEqual Monthly $budgetNew.TimeGrain

	Write-Debug "Get the budget $budgetName"
	$budgetGet = Get-AzConsumptionBudget -Name $budgetName
	Assert-NotNull $budgetGet
	Assert-AreEqual 6000 $budgetGet.Amount
	Assert-AreEqual $budgetName $budgetGet.Name
	Assert-AreEqual Cost $budgetGet.Category
	Assert-AreEqual Monthly $budgetGet.TimeGrain

	Write-Debug "Update the budget $budgetName with amount change to 7500"
	$budgetSet1 = Get-AzConsumptionBudget -Name $budgetName | Set-AzConsumptionBudget -Amount 7500
	Assert-NotNull $budgetSet1
	Assert-AreEqual 7500 $budgetSet1.Amount

	Write-Debug "Update the budget $budgetName with a notification $notificationKey when cost or usage reaches a threshold of 90 percent of amount"
	$budgetSet2 = Set-AzConsumptionBudget -Name $budgetName -NotificationKey $notificationKey -NotificationEnabled -NotificationThreshold 90 -ContactEmail johndoe@contoso.com,janesmith@contoso.com -ContactRole Owner,Reader,Contributor
	Assert-NotNull $budgetSet2
	Assert-AreEqual $budgetName $budgetSet2.Name
	Assert-AreEqual 1 $budgetSet2.Notification.Count

	Write-Debug "Remove the budget $budgetName"
	$response = Remove-AzConsumptionBudget -Name $budgetName -PassThru
	Assert-AreEqual True $response

	Assert-Throws {Get-AzConsumptionBudget -Name $budgetName}
}


function Test-BudgetAtResourceGroupLevel
{
	
	$budgetName = Get-BudgetName
	$notificationKey1 = Get-NotificationKey
	$notificationKey2 = Get-NotificationKey
	
	$resourceGroupName = Get-ResourceGroupName
	$startDate = Get-Date -Day 1
	$endDate = ($startDate).AddMonths(3).AddDays(-1)

	
	New-AzResourceGroup -Name $resourceGroupName -Location 'West US' -Force

	try 
	{
		
		Write-Debug "Create a new budget $budgetName at resource group level"
		$budgetNew = New-AzConsumptionBudget -Amount 6000 -Name $budgetName -ResourceGroupName $resourceGroupName -Category Cost -StartDate $startDate -EndDate $endDate -TimeGrain Monthly
		Assert-NotNull $budgetNew
		Assert-AreEqual 6000 $budgetNew.Amount
		Assert-AreEqual $budgetName $budgetNew.Name
		Assert-AreEqual Cost $budgetNew.Category
		Assert-AreEqual Monthly $budgetNew.TimeGrain

		
		Write-Debug "Get the budget $budgetName"
		$budgetGet = Get-AzConsumptionBudget -Name $budgetName -ResourceGroupName $resourceGroupName
		Assert-NotNull $budgetGet
		Assert-AreEqual 6000 $budgetGet.Amount
		Assert-AreEqual $budgetName $budgetGet.Name
		Assert-AreEqual Cost $budgetGet.Category
		Assert-AreEqual Monthly $budgetGet.TimeGrain

		
		Write-Debug "Update the budget $budgetName with a notification $notificationKey when cost reaches a threshold of 90 percent of amount"
		$budgetSet1 = Set-AzConsumptionBudget -Name $budgetName -ResourceGroupName $resourceGroupName -NotificationKey $notificationKey1 -NotificationEnabled -NotificationThreshold 90 -ContactEmail johndoe@contoso.com,janesmith@contoso.com -ContactRole Owner,Reader,Contributor
		Assert-NotNull $budgetSet1
		Assert-AreEqual $budgetName $budgetSet1.Name
		Assert-AreEqual 1 $budgetSet1.Notification.Count

		Write-Debug "Update the budget $budgetName with a second notificaiton $notificationKey when cost reaches a threshold of 150 percent of amount"
		$budgetSet2 = Set-AzConsumptionBudget -Name $budgetName -ResourceGroupName $resourceGroupName -NotificationKey $notificationKey2 -NotificationEnabled -NotificationThreshold 150 -ContactEmail johndoe@contoso.com,janesmith@contoso.com -ContactRole Owner,Reader,Contributor
		Assert-NotNull $budgetSet2
		Assert-AreEqual $budgetName $budgetSet2.Name
		Assert-AreEqual 2 $budgetSet2.Notification.Count

		
		Write-Debug "Remove the budget $budgetName"
		$response = Remove-AzConsumptionBudget -Name $budgetName -ResourceGroupName $resourceGroupName -PassThru
		Assert-AreEqual True $response

		Assert-Throws {Get-AzConsumptionBudget -Name $budgetName -ResourceGroupName $resourceGroupName}		
	}
	finally 
	{	
		
		Remove-AzResourceGroup -Name $resourceGroupName -Force
	}	
}


function Test-GetBudgets
{
	
	$startDate = Get-Date -Day 1
	$endDate = ($startDate).AddMonths(3).AddDays(-1)
	$budgetName = Get-BudgetName
	$budgetNew = New-AzConsumptionBudget -Amount 6000 -Name $budgetName -Category Cost -StartDate $startDate -EndDate $endDate -TimeGrain Monthly
	Assert-NotNull $budgetNew

	
    $budgets = Get-AzConsumptionBudget 
	Assert-NotNull $budgets

	
	$response = Get-AzConsumptionBudget -Name $budgetName | Remove-AzConsumptionBudget -PassThru
	Assert-AreEqual True $response

	Assert-Throws {Get-AzConsumptionBudget -Name $budgetName}
}