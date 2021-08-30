














function Test-SetGatewayCredential{

	
	try
	{
		
		$cluster= Create-Cluster

		$username = "admin"
		$textPassword= "YourPw!00953"
		$password = ConvertTo-SecureString $textPassword -AsPlainText -Force
		$credential = New-Object System.Management.Automation.PSCredential($username, $password)

		$gatewaySettings = Set-AzHDInsightGatewayCredential -ClusterName $cluster.Name -ResourceGroupName $cluster.ResourceGroup -HttpCredential $credential

		Assert-True {$gatewaySettings.Password -eq $textPassword }
	}
	finally
	{
		
		Remove-AzHDInsightCluster -ClusterName $cluster.Name
		Remove-AzResourceGroup -ResourceGroupName $cluster.ResourceGroup
	}
}
