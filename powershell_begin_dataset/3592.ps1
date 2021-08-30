














function Get-AzureRmSecurityAutoProvisioningSetting-SubscriptionScope
{
    $autoProvisioningSettings = Get-AzSecurityAutoProvisioningSetting
	Validate-AutoProvisioningSettings $autoProvisioningSettings
}


function Get-AzureRmSecurityAutoProvisioningSetting-SubscriptionLevelResource
{
    $autoProvisioningSettings = Get-AzSecurityAutoProvisioningSetting -Name "default"
	Validate-AutoProvisioningSettings $autoProvisioningSettings
}


function Get-AzureRmSecurityAutoProvisioningSetting-ResourceId
{
	$autoProvisioningSetting = Get-AzSecurityAutoProvisioningSetting | Select -First 1

    $fetchedAutoProvisioningSetting = Get-AzSecurityAutoProvisioningSetting -ResourceId $autoProvisioningSetting.Id
	Validate-AutoProvisioningSetting $autoProvisioningSetting
}


function Set-AzureRmSecurityAutoProvisioningSetting-SubscriptionLevelResource
{
    Set-AzSecurityAutoProvisioningSetting -Name "default" -EnableAutoProvision
}


function Set-AzureRmSecurityAutoProvisioningSetting-ResourceId
{
	$autoProvisioningSetting = Get-AzSecurityAutoProvisioningSetting | Select -First 1
    Set-AzSecurityAutoProvisioningSetting -ResourceId $autoProvisioningSetting.Id -EnableAutoProvision
}


function Validate-AutoProvisioningSettings
{
	param($autoProvisioningSettings)

    Assert-True { $autoProvisioningSettings.Count -gt 0 }

	Foreach($autoProvisioningSetting in $autoProvisioningSettings)
	{
		Validate-AutoProvisioningSetting $autoProvisioningSetting
	}
}


function Validate-AutoProvisioningSetting
{
	param($autoProvisioningSetting)

	Assert-NotNull $autoProvisioningSetting
}