


















$global:resourceType = "Microsoft.HealthcareApis/services"


function Test-AzRmHealthcareApisService{
	
	$rgname = Get-ResourceGroupName
	$rname = Get-ResourceName
	$location = Get-Location
	$offerThroughput =  Get-OfferThroughput
	$kind = Get-Kind
	$object_id = Get-AccessPolicyObjectID;
	
	try
	{
		
		
		New-AzResourceGroup -Name $rgname -Location $location

	
		
		$created = New-AzHealthcareApisService -Name $rname -ResourceGroupName  $rgname -Location $location -Kind $kind -AccessPolicyObjectId $object_id -CosmosOfferThroughput $offerThroughput;
	
	    $actual = Get-AzHealthcareApisService -ResourceGroupName $rgname -Name $rname

		
		Assert-AreEqual $actual.Name $rname
		Assert-AreEqual $actual.CosmosDbOfferThroughput $offerThroughput
		Assert-AreEqual $actual.Kind $kind
		
		$newOfferThroughput = $offerThroughput - 600
		$updated = Set-AzHealthcareApisService -ResourceId $actual.Id -CosmosOfferThroughput $newOfferThroughput;

		$updatedAccount = Get-AzHealthcareApisService -ResourceGroupName $rgname -Name $rname
		
		Assert-AreEqual $updatedAccount.Name $rname
		Assert-AreEqual $updatedAccount.CosmosDbOfferThroughput $newOfferThroughput

		$rname1 = $rname + "1"
		$created1 = New-AzHealthcareApisService -Name $rname1 -ResourceGroupName  $rgname -Location $location -AccessPolicyObjectId $object_id -CosmosOfferThroughput $offerThroughput;
		
		$actual1 = Get-AzHealthcareApisService -ResourceGroupName $rgname -Name $rname1

		
		Assert-AreEqual $actual1.Name $rname1
		Assert-AreEqual $actual1.CosmosDbOfferThroughput $offerThroughput

		$list = Get-AzHealthcareApisService -ResourceGroupName $rgname

		$app1 = $list | where {$_.Name -eq $rname} | Select-Object -First 1
		$app2 = $list | where {$_.Name -eq $rname1} | Select-Object -First 1

		Assert-AreEqual 2 @($list).Count
		Assert-AreEqual $rname $app1.Name
		Assert-AreEqual $rname1 $app2.Name

		$list | Remove-AzHealthcareApisService

		$list = Get-AzHealthcareApisService -ResourceGroupName $rgname
		
		Assert-AreEqual 0 @($list).Count
	}
	finally{
		
		Remove-AzResourceGroup -Name $rgname -Force
	}
}