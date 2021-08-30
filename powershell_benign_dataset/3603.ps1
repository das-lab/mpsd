














function Get-AzureRmSecurityWorkspaceSetting-SubscriptionScope
{
	Set-AzureRmSecurityWorkspaceSetting-SubscriptionLevelResource

    $workspaceSettings = Get-AzSecurityWorkspaceSetting
	Validate-WorkspaceSettings $workspaceSettings
}


function Get-AzureRmSecurityWorkspaceSetting-SubscriptionLevelResource
{
	Set-AzureRmSecurityWorkspaceSetting-SubscriptionLevelResource

    $workspaceSettings = Get-AzSecurityWorkspaceSetting -Name "default"
	Validate-WorkspaceSettings $workspaceSettings
}


function Get-AzureRmSecurityWorkspaceSetting-ResourceId
{
	$workspaceSetting = Set-AzureRmSecurityWorkspaceSetting-SubscriptionLevelResource
    $fetchedWorkspaceSettings = Get-AzSecurityWorkspaceSetting -ResourceId $workspaceSetting.Id
	Validate-WorkspaceSetting $fetchedWorkspaceSettings
}


function Set-AzureRmSecurityWorkspaceSetting-SubscriptionLevelResource
{
	$rgName = Get-TestResourceGroupName
	$wsName = "securityuserws"

	return Set-AzSecurityWorkspaceSetting -Name "default" -Scope "/subscriptions/487bb485-b5b0-471e-9c0d-10717612f869" -WorkspaceId  "/subscriptions/487bb485-b5b0-471e-9c0d-10717612f869/resourcegroups/mainws/providers/microsoft.operationalinsights/workspaces/securityuserws"
}


function Remove-AzureRmSecurityWorkspaceSetting-SubscriptionLevelResource
{
	Set-AzureRmSecurityWorkspaceSetting-SubscriptionLevelResource

    Remove-AzSecurityWorkspaceSetting -Name "default"
}


function Validate-WorkspaceSettings
{
	param($workspaceSettings)

    Assert-True { $workspaceSettings.Count -gt 0 }

	Foreach($workspaceSetting in $workspaceSettings)
	{
		Validate-WorkspaceSetting $workspaceSetting
	}
}


function Validate-WorkspaceSetting
{
	param($workspaceSetting)

	Assert-NotNull $workspaceSetting
}