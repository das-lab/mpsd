














function Get-AzureRmSecurityTask-SubscriptionScope
{
    $tasks = Get-AzSecurityTask
	Validate-Tasks $tasks
}


function Get-AzureRmSecurityTask-ResourceGroupScope
{
	$rgName = Get-TestResourceGroupName

    $tasks = Get-AzSecurityTask -ResourceGroupName $rgName
	Validate-Tasks $tasks
}


function Get-AzureRmSecurityTask-SubscriptionLevelResource
{
	$task = Get-AzSecurityTask | where { $_.Id -notlike "*resourceGroups*" } | Select -First 1
    $fetchedTask = Get-AzSecurityTask -Name $task.Name
	Validate-Task $fetchedTask
}


function Get-AzureRmSecurityTask-ResourceGroupLevelResource
{
	$task = Get-AzSecurityTask | where { $_.Id -like "*resourceGroups*" } | Select -First 1
	$rgName = Extract-ResourceGroup -ResourceId $task.Id

    $fetchedTask = Get-AzSecurityTask -ResourceGroupName $rgName -Name $task.Name
	Validate-Task $fetchedTask
}


function Get-AzureRmSecurityTask-ResourceId
{
	$task = Get-AzSecurityTask | Select -First 1

    $fetchedTask = Get-AzSecurityTask -ResourceId $task.Id
	Validate-Task $fetchedTask
}


function Validate-Tasks
{
	param($tasks)

    Assert-True { $tasks.Count -gt 0 }

	Foreach($task in $tasks)
	{
		Validate-Task $task
	}
}


function Validate-Task
{
	param($task)

	Assert-NotNull $task
}