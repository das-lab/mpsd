














function Test-MonitoringRelatedCommands{

	
	try
	{
		$location = "West US 2"
		
		$cluster = Create-Cluster -Location $location

		$workspaceName = Generate-Name("workspace-ps-test")
		$resourceGroupName = $cluster.ResourceGroup

		
		$sku = "pernode"
		$workspace = New-AzOperationalInsightsWorkspace -Location $location -Name $workspaceName -ResourceGroupName $resourceGroupName -Sku $sku

		
		$keys = Get-AzOperationalInsightsWorkspaceSharedKey -ResourceGroupName $resourceGroupName -Name $workspace.Name
		Assert-NotNull $keys
		
		$result = Get-AzHDInsightMonitoring -ClusterName $cluster.Name -ResourceGroupName $cluster.ResourceGroup
		Assert-Null $result.WorkspaceId
		
		
		$workspaceId = $workspace.CustomerId
		$primaryKey = $keys.PrimarySharedKey

		Assert-NotNull $workspaceId
		Assert-NotNull $primaryKey
		Enable-AzHDInsightMonitoring -ClusterName $cluster.Name -ResourceGroup $cluster.ResourceGroup -WorkspaceId $workspaceId -Primary  $primaryKey
		
		$result = Get-AzHDInsightMonitoring -ClusterName $cluster.Name -ResourceGroupName $cluster.ResourceGroup
		Assert-True {$result.ClusterMonitoringEnabled}
		Assert-AreEqual $result.WorkspaceId $workspaceId
		
		
		Disable-AzHDInsightMonitoring -ClusterName $cluster.Name -ResourceGroupName $cluster.ResourceGroup
		$result = Get-AzHDInsightMonitoring -ClusterName $cluster.Name -ResourceGroupName $cluster.ResourceGroup
		Assert-False {$result.ClusterMonitoringEnabled}
		Assert-Null $result.WorkspaceId
	}
	finally
	{
		
		Remove-AzHDInsightCluster -ClusterName $cluster.Name
		Remove-AzResourceGroup -ResourceGroupName $cluster.ResourceGroup
	}
}
