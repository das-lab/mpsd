


















$global:resourceType = "Microsoft.IoTCentral/IotApps"


function Test-IotCentralAppLifecycleManagement{
	
	$rgname = Get-ResourceGroupName
	$rname = Get-ResourceName
	$subdomain = ($rname) + "subdomain"
	$location = Get-Location "Microsoft.IoTCentral" "IotApps"
	$sku = "S1"
	$displayName = "Custom IoT Central App DisplayName"
	$tagKey = "key1"
	$tagValue = "value1"
	$tags = @{ $tagKey = $tagValue }
	
	try
	{
		

		
		New-AzResourceGroup -Name $rgname -Location $location

		
		$created = New-AzIotCentralApp -ResourceGroupName $rgname -Name $rname -Subdomain $subdomain -Sku $sku -DisplayName $displayName -Tag $tags
		$actual = Get-AzIotCentralApp -ResourceGroupName $rgname -Name $rname

		$list = Get-AzIotCentralApp -ResourceGroupName $rgname
	
		
		Assert-AreEqual $actual.Name $rname
		Assert-AreEqual $actual.Subdomain $subdomain
		Assert-AreEqual $actual.DisplayName $displayName
		Assert-AreEqual $actual.Tag.Item($tagkey) $tagvalue
		Assert-AreEqual 1 @($list).Count
		Assert-AreEqual $actual.Name $list[0].Name

		
		$rname1 = $rname
		$rname2 = ($rname1) + "-2"

		New-AzIotCentralApp $rgname $rname2 $rname2
		$list = Get-AzIotCentralApp -ResourceGroupName $rgname
		$app1 = $list | where {$_.Name -eq $rname1} | Select-Object -First 1
		$app2 = $list | where {$_.Name -eq $rname2} | Select-Object -First 1

		
		Assert-AreEqual 2 @($list).Count
		Assert-AreEqual $rname1 $app1.Name
		Assert-AreEqual $rname2 $app2.Name
		Assert-AreEqual $subdomain $app1.Subdomain
		Assert-AreEqual $rname2 $app2.Subdomain
		Assert-AreEqual $resourceType $app1.Type
		Assert-AreEqual $resourceType $app2.Type

		
		$emptyrg = ($rgname) + "empty"
		New-AzResourceGroup -Name $emptyrg -Location $location
		$listViaDirect = Get-AzIotCentralApp -ResourceGroupName $emptyrg

		
		Assert-AreEqual 0 @($listViaDirect).Count

		
		$tt1 = $tagKey
		$tv1 = $tagValue
		$tt2 = "tt2"
		$tv2 = "tv2"
		$displayName = "New Custom Display Name."
		$newSubdomain = $subdomain + "new"
		$tags = $actual.Tag
		$tags.add($tt2, $tv2)
		
		$job = Set-AzIotCentralApp -ResourceGroupName $rgname -Name $rname -Tag $tags -DisplayName $displayName -Subdomain $newSubdomain -AsJob
		$job | Wait-Job
		$result = $job | Receive-Job

		$actual = Get-AzIotCentralApp -ResourceGroupName $rgname -Name $rname

		
		Assert-AreEqual $actual.Tag.Count 2
		Assert-AreEqual $actual.Tag.Item($tt1) $tv1
		Assert-AreEqual $actual.Tag.Item($tt2) $tv2
		Assert-AreEqual $actual.DisplayName $displayName
		Assert-AreEqual $actual.Subdomain $newSubdomain
		Assert-AreEqual $actual.Name $rname

		
		
		
		Get-AzIotCentralApp -ResourceGroupName $rgname | Remove-AzIotCentralApp

		$list = Get-AzIotCentralApp -ResourceGroupName $rgname
		Assert-AreEqual 0 @($list).Count
	}
	finally{
		
		
	}
}