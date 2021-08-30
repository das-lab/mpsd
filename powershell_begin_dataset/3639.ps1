














function Test-ServerDisasterRecoveryConfiguration
{
    Test-ServerDisasterRecoveryConfigurationInternal
}


function Test-ServerDisasterRecoveryConfigurationInternal ($location1 = "North Europe", $location2 = "Southeast Asia")
{
    
    $rg1 = Create-ResourceGroupForTest $location1
    $rg2 = Create-ResourceGroupForTest $location2
    
    try
    {
        $server1 = Create-ServerForTest $rg1 $location1
        $server2 = Create-ServerForTest $rg2 $location2
        $failoverPolicy = "Off"
        $sdrcName = "test-sdrc-alias"

        
        
        $job = New-AzSqlServerDisasterRecoveryConfiguration -ResourceGroupName $rg1.ResourceGroupName `
			-ServerName $server1.ServerName -VirtualEndpointName $sdrcName -PartnerResourceGroupName $rg2.ResourceGroupName `
			-PartnerServerName $server2.ServerName -AsJob
		$job | Wait-Job
		$sdrc = $job.Output

        GetSdrcCheck $rg1 $server1 $sdrcName $rg2 $server2 $failoverPolicy "Primary"
        GetSdrcCheck $rg2 $server2 $sdrcName $rg1 $server1 $failoverPolicy "Secondary"

        
        
        Set-AzSqlServerDisasterRecoveryConfiguration -ResourceGroupName $rg2.ResourceGroupName `
			-ServerName $server2.ServerName -VirtualEndpointName $sdrcName -Failover

        GetSdrcCheck $rg2 $server2 $sdrcName $rg1 $server1 $failoverPolicy "Primary"
        GetSdrcCheck $rg1 $server1 $sdrcName $rg2 $server2 $failoverPolicy "Secondary"

        
        
        $job = Set-AzSqlServerDisasterRecoveryConfiguration -ResourceGroupName $rg1.ResourceGroupName `
			-ServerName $server1.ServerName -VirtualEndpointName $sdrcName -Failover -AsJob
		$job | Wait-Job

        GetSdrcCheck $rg1 $server1 $sdrcName $rg2 $server2 $failoverPolicy "Primary"
        GetSdrcCheck $rg2 $server2 $sdrcName $rg1 $server1 $failoverPolicy "Secondary"

        
        
        Remove-AzSqlServerDisasterRecoveryConfiguration  -ResourceGroupName $rg1.ResourceGroupName `
			-ServerName $server1.ServerName -VirtualEndpointName $sdrcName -Force
    }
    finally
    {
        Remove-ResourceGroupForTest $rg1
        Remove-ResourceGroupForTest $rg2
    }
}

function GetSdrcCheck ($resourceGroup, $server, $virtualEndpointName, $partnerResourceGroup, $partnerServer, $failoverPolicy, $role)
{
    $sdrcGet = Get-AzSqlServerDisasterRecoveryConfiguration -ResourceGroupName $resourceGroup.ResourceGroupName -ServerName $server.ServerName -VirtualEndpointName $virtualEndpointName

    Assert-AreEqual $resourceGroup.ResourceGroupName $sdrcGet.ResourceGroupName
    Assert-AreEqual $server.ServerName $sdrcGet.ServerName
    Assert-AreEqual $virtualEndpointName $sdrcGet.VirtualEndpointName
    Assert-AreEqual $partnerServer.ServerName $sdrcGet.PartnerServerName
    Assert-AreEqual $failoverPolicy $sdrcGet.FailoverPolicy
    Assert-AreEqual $role $sdrcGet.Role
}