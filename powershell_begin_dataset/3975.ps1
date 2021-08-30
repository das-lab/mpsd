














function DeleteIfExistsNetworkWatcher($location)
{
	
	$nwlist = Get-AzNetworkWatcher
	foreach ($i in $nwlist)
	{
		if($i.Location -eq "$location") 
		{
			$nw=$i
		}
	}

	
	if ($nw) 
	{
		$job = Remove-AzNetworkWatcher -NetworkWatcher $nw -AsJob
		$job | Wait-Job
	}
}


function Test-NetworkWatcherCRUD
{
    
    $rgname = Get-ResourceGroupName
    $nwName = Get-ResourceName
	$rglocation = Get-ProviderLocation ResourceManagement
    $resourceTypeParent = "Microsoft.Network/networkWatchers"
    $location = Get-ProviderLocation $resourceTypeParent "westcentralus"
    
    try 
    {
        $resourceGroup = New-AzResourceGroup -Name $rgname -Location  $rglocation -Tags @{ testtag = "testval" }
        
		DeleteIfExistsNetworkWatcher -location $location

        
        $tags = @{"key1" = "value1"; "key2" = "value2"}
        $nw = New-AzNetworkWatcher -Name $nwName -ResourceGroupName $rgname -Location $location -Tag $tags

        Assert-AreEqual $nw.Name $nwName
        Assert-AreEqual "Succeeded" $nw.ProvisioningState
		
        
        $getNW = Get-AzNetworkWatcher -ResourceGroupName $rgname -Name $nwName
		
        Assert-AreEqual $getNW.Name $nwName		
        Assert-AreEqual "Succeeded" $nw.ProvisioningState
		
        
        $listNWByRg = Get-AzNetworkWatcher -ResourceGroupName $rgname
        $listNW = Get-AzNetworkWatcher
		
        Assert-AreEqual 1 @($listNWByRg).Count

        $listNW = Get-AzNetworkWatcher -ResourceGroupName "*"
        Assert-True { $listNW.Count -ge 0 }

        $listNW = Get-AzNetworkWatcher -Name "*"
        Assert-True { $listNW.Count -ge 0 }

        $listNW = Get-AzNetworkWatcher -ResourceGroupName "*" -Name "*"
        Assert-True { $listNW.Count -ge 0 }
		
        
        $job = Remove-AzNetworkWatcher -ResourceGroupName $rgname -name $nwName -AsJob
        $job | Wait-Job
        $delete = $job | Receive-Job
		
        $list = Get-AzNetworkWatcher -ResourceGroupName $rgname
        Assert-AreEqual 0 @($list).Count
    }
    finally
    {
        
        Clean-ResourceGroup $rgname
    }
}
