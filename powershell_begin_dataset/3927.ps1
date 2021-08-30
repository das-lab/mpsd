


















$global:resourceType = "Microsoft.Devices/ProvisioningServices"



function Test-AzureIotDpsLifeCycle
{
	$Location = Get-Location "Microsoft.Devices" "Device Provisioning Service" 
	$IotDpsName = getAssetName 
	$ResourceGroupName = getAssetName 
	$Sku = "S1"

	
	$CurrentAllocationPolicy = "Hashed"
	$NewAllocationPolicy = "GeoLatency"
	$Tag1Key = "key1"
	$Tag2Key = "key2"
	$Tag1Value = "value1"
	$Tag2Value = "value2"

	
	$allIotDps = Get-AzIotDps
	
	If ($allIotDps.Count -gt 1) {
		Assert-True { $allIotDps[0].Type -eq $global:resourceType }
	}

	
	$resourceGroup = New-AzResourceGroup -Name $ResourceGroupName -Location $Location 

	
	$newIotDps1 = New-AzIoTDps -ResourceGroupName $ResourceGroupName -Name $IotDpsName -Location $Location

	
	$iotDps = Get-AzIoTDps -ResourceGroupName $ResourceGroupName -Name $IotDpsName 
	Assert-True { $iotDps.Name -eq $IotDpsName }
	Assert-True { $iotDps.Properties.AllocationPolicy -eq $CurrentAllocationPolicy }
	Assert-True { $iotDps.Sku.Name -eq $Sku }

	
	$updatedIotDps1 = Get-AzIoTDps -ResourceGroupName $ResourceGroupName -Name $IotDpsName | Update-AzIotDps -AllocationPolicy $NewAllocationPolicy
	Assert-True { $updatedIotDps1.Properties.AllocationPolicy -eq $NewAllocationPolicy }

	
	$tags = @{}
	$tags.Add($Tag1Key, $Tag1Value)
	$updatedIotDps2 = Update-AzIoTDps -ResourceGroupName $ResourceGroupName -Name $IotDpsName -Tag $tags
	Assert-True { $updatedIotDps2.Tags.Count -eq 1 }
	Assert-True { $updatedIotDps2.Tags.Item($Tag1Key) -eq $Tag1Value }
	
	
	$tags.Clear()
	$tags.Add($Tag2Key, $Tag2Value)
	$updatedIotDps3 = Update-AzIoTDps -ResourceGroupName $ResourceGroupName -Name $IotDpsName -Tag $tags
	Assert-True { $updatedIotDps3.Tags.Count -eq 2 }
	Assert-True { $updatedIotDps3.Tags.Item($Tag1Key) -eq $Tag1Value }
	Assert-True { $updatedIotDps3.Tags.Item($Tag2Key) -eq $Tag2Value }

	
	$tags.Clear()
	$tags.Add($Tag1Key, $Tag1Value)
	$updatedIotDps4 = Update-AzIoTDps -ResourceGroupName $ResourceGroupName -Name $IotDpsName -Tag $tags -Reset
	Assert-True { $updatedIotDps4.Tags.Count -eq 1 }
	Assert-True { $updatedIotDps4.Tags.Item($Tag1Key) -eq $Tag1Value }

	
	$result = Remove-AzIoTDps -ResourceGroupName $ResourceGroupName -Name $IotDpsName -PassThru
	Assert-True { $result }

	
	Remove-AzResourceGroup -Name $ResourceGroupName -force
}
