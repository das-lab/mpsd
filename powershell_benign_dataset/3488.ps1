















function Test-ScriptActionRelatedCommands{

	
	try
	{
		
		$cluster = Create-Cluster
		
		$scriptActionName = Generate-Name("scriptaction")
		$uri = "https://hdiconfigactions.blob.core.windows.net/linuxhueconfigactionv02/install-hue-uber-v02.sh"
		$nodeTypes = ("Worker")
		
		
		$script = Submit-AzHDInsightScriptAction -ClusterName $cluster.Name -Name $scriptActionName -Uri $uri -NodeTypes $nodeTypes
		
		
		$getScript = Get-AzHDInsightScriptActionHistory -ClusterName $cluster.Name -ResourceGroupName $cluster.ResourceGroup `
		           | Where-Object {$_.Name -eq $script.Name }
		
		Assert-AreEqual $getScript.Name $script.Name
		
		
		Set-AzHDInsightPersistedScriptAction -ClusterName $cluster.Name -ResourceGroupName $cluster.ResourceGroup `
		-ScriptExecutionId $getScript.ScriptExecutionId
		
		
		$persistedScript = Get-AzHDInsightPersistedScriptAction -ClusterName $cluster.Name -ResourceGroupName $cluster.ResourceGroup `
		-Name $getScript.Name
		
		Assert-AreEqual $persistedScript.Name $getScript.Name
		
		
		Remove-AzHDInsightPersistedScriptAction -ClusterName $cluster.Name -ResourceGroupName $cluster.ResourceGroup `
		-Name $persistedScript.Name
		
		$persistedScript = Get-AzHDInsightPersistedScriptAction -ClusterName $cluster.Name -ResourceGroupName $cluster.ResourceGroup `
		-Name $getScript.Name
		
		Assert-Null $persistedScript
	}
	finally
	{
		
		Remove-AzHDInsightCluster -ClusterName $cluster.Name
		Remove-AzResourceGroup -ResourceGroupName $cluster.ResourceGroup
	}
}
