














function Get-AzureRmSecurityAlert-SubscriptionScope
{
    $alerts = Get-AzSecurityAlert
	Validate-Alerts $alerts
}


function Get-AzureRmSecurityAlert-ResourceGroupScope
{
	$rgName = Get-TestResourceGroupName

    $alerts = Get-AzSecurityAlert -ResourceGroupName $rgName
	Validate-Alerts $alerts
}


function Get-AzureRmSecurityAlert-ResourceGroupLevelResource
{
	$alerts = Get-AzSecurityAlert

	$alert = $alerts | where { $_.Id -like "*resourceGroups*" } | Select -First 1
	$location = Extract-ResourceLocation -ResourceId $alert.Id
	$rgName = Extract-ResourceGroup -ResourceId $alert.Id

    $fetchedAlert = Get-AzSecurityAlert -ResourceGroupName $rgName -Location $location -Name $alert.Name
	Validate-Alert $fetchedAlert
}


function Get-AzureRmSecurityAlert-SubscriptionLevelResource
{
	$alerts = Get-AzSecurityAlert
	$alert = $alerts | where { $_.Id -notlike "*resourceGroups*" } | Select -First 1
	$location = Extract-ResourceLocation -ResourceId $alert.Id

    $fetchedAlert = Get-AzSecurityAlert -Location $location -Name $alert.Name
	Validate-Alert $fetchedAlert
}


function Get-AzureRmSecurityAlert-ResourceId
{
	$alerts = Get-AzSecurityAlert
	$alert = $alerts | Select -First 1

    $alerts = Get-AzSecurityAlert -ResourceId $alert.Id
	Validate-Alerts $alerts
}


function Set-AzureRmSecurityAlert-ResourceGroupLevelResource
{
	$alerts = Get-AzSecurityAlert

	$alert = $alerts | where { $_.Id -like "*resourceGroups*" } | Select -First 1
	$location = Extract-ResourceLocation -ResourceId $alert.Id
	$rgName = Extract-ResourceGroup -ResourceId $alert.Id

    Set-AzSecurityAlert -ResourceGroupName $rgName -Location $location -Name $alert.Name -ActionType "Activate"

	$fetchedAlert = Get-AzSecurityAlert -ResourceGroupName $rgName -Location $location -Name $alert.Name

	Validate-AlertActivity -alert $fetchedAlert
}


function Set-AzureRmSecurityAlert-SubscriptionLevelResource
{
	$alerts = Get-AzSecurityAlert
	$alert = $alerts | where { $_.Id -notlike "*resourceGroups*" } | Select -First 1
	$location = Extract-ResourceLocation -ResourceId $alert.Id

    Set-AzSecurityAlert -Location $location -Name $alert.Name -ActionType "Activate"

	$fetchedAlert = Get-AzSecurityAlert -Location $location -Name $alert.Name

	Validate-AlertActivity -alert $fetchedAlert
}


function Set-AzureRmSecurityAlert-ResourceId
{
	$alerts = Get-AzSecurityAlert
	$alert = $alerts | Select -First 1

    Set-AzSecurityAlert -ResourceId $alert.Id -ActionType "Activate"

	$fetchedAlert = Get-AzSecurityAlert -ResourceId $alert.Id

	Validate-AlertActivity -alert $fetchedAlert
}


function Validate-Alerts
{
	param($alerts)

    Assert-True { $alerts.Count -gt 0 }

	Foreach($alert in $alerts)
	{
		Validate-Alert $alert
	}
}


function Validate-Alert
{
	param($alert)

	Assert-NotNull $alert
}



function Validate-AlertActivity
{
	param($alert)

	Assert-NotNull $alert
	Assert-True { $alert.State -eq "Active" }
}