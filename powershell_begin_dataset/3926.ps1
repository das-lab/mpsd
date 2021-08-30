




















function Test-AzureIotDpsLinkedHubLifeCycle
{
	$Location = Get-Location "Microsoft.Devices" "Device Provisioning Service" 
	$IotDpsName = getAssetName 
	$ResourceGroupName = getAssetName 
	$IotHubName = getAssetName
	$hubKeyName = "ServiceKey"
	$Sku = "S1"

	
	$LinkedHubName = [string]::Format("{0}.azure-devices.net",$IotHubName)
	$AllocationWeight = 10

	
	$resourceGroup = New-AzResourceGroup -Name $ResourceGroupName -Location $Location 

	
	$iotDps = New-AzIoTDps -ResourceGroupName $ResourceGroupName -Name $IotDpsName -Location $Location
	Assert-True { $iotDps.Name -eq $IotDpsName }
	Assert-True { $iotDps.Properties.IotHubs.Count -eq 0 }

	
	$iotHub = New-AzIoTHub -Name $IotHubName -ResourceGroupName $ResourceGroupName -Location $Location -SkuName $Sku -Units 1
	Assert-True { $iotHub.Name -eq $IotHubName }

	
	$hubKeys = Add-AzIoTHubKey -Name $IotHubName -ResourceGroupName $ResourceGroupName -KeyName $hubKeyName -Rights ServiceConnect
	Assert-True { $hubKeys.Count -gt 1 }

	
	$hubKey = Get-AzIoTHubKey -Name $IotHubName -ResourceGroupName $ResourceGroupName -KeyName $hubKeyName

	$HubConnectionString = [string]::Format("HostName={0};SharedAccessKeyName={1};SharedAccessKey={2}",$iotHub.Properties.HostName,$hubKey.KeyName,$hubKey.PrimaryKey)

	
	$linkedHub = Add-AzIoTDpsHub -ResourceGroupName $ResourceGroupName -Name $IotDpsName -IotHubConnectionString $HubConnectionString -IotHubLocation $iotHub.Location
	Assert-True { $linkedHub.Count -eq 1 }
	Assert-True { $linkedHub.LinkedHubName -eq $iotHub.Properties.HostName }
	Assert-True { $linkedHub.Location -eq $iotHub.Location }

	
	$updatedLinkedHub = Update-AzIoTDpsHub -ResourceGroupName $ResourceGroupName -Name $IotDpsName -LinkedHubName $LinkedHubName -AllocationWeight $AllocationWeight
	Assert-False { $updatedLinkedHub.ApplyAllocationPolicy }
	Assert-True { $updatedLinkedHub.AllocationWeight -eq $AllocationWeight }

	
	$linkedHub1 = Get-AzIoTDpsHub -ResourceGroupName $ResourceGroupName -Name $IotDpsName -LinkedHubName $LinkedHubName
	Assert-True { $linkedHub1.Count -eq 1 }
	Assert-True { $linkedHub1.LinkedHubName -eq $LinkedHubName }
	Assert-True { $linkedHub1.Location -eq $Location }
	Assert-False { $linkedHub1.ApplyAllocationPolicy }
	Assert-True { $linkedHub1.AllocationWeight -eq $AllocationWeight }

	
	$result = Remove-AzIoTDpsHub -ResourceGroupName $ResourceGroupName -Name $IotDpsName -LinkedHubName $LinkedHubName -PassThru
	Assert-True { $result }

	
	Remove-AzResourceGroup -Name $ResourceGroupName -force
}
