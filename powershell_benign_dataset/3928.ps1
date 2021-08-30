




















function Test-AzureIotDpsAccessPolicyLifeCycle
{
	$Location = Get-Location "Microsoft.Devices" "Device Provisioning Service" 
	$IotDpsName = getAssetName 
	$ResourceGroupName = getAssetName 

	
	$AccessPolicyDefaultKeyName = "provisioningserviceowner"
	$AccessPolicyDefaultRights = "ServiceConfig, DeviceConnect, EnrollmentWrite"
	$NewAccessPolicyKeyName = "Access1"
	$NewAccessPolicyRights = "ServiceConfig"

	
	$resourceGroup = New-AzResourceGroup -Name $ResourceGroupName -Location $Location 

	
	$iotDps = New-AzIoTDps -ResourceGroupName $ResourceGroupName -Name $IotDpsName -Location $Location
	Assert-True { $iotDps.Name -eq $IotDpsName }

	
	$iotDpsAccessPolicy1 = Get-AzIoTDpsAccessPolicy -ResourceGroupName $ResourceGroupName -Name $IotDpsName
	Assert-True { $iotDpsAccessPolicy1.Count -eq 1 }
	Assert-True { $iotDpsAccessPolicy1.KeyName -eq $AccessPolicyDefaultKeyName }
	Assert-True { $iotDpsAccessPolicy1.Rights -eq $AccessPolicyDefaultRights }

	
	$iotDpsAccessPolicy2 = Add-AzIoTDpsAccessPolicy -ResourceGroupName $ResourceGroupName -Name $IotDpsName -KeyName $NewAccessPolicyKeyName -Permissions $NewAccessPolicyRights
	Assert-True { $iotDpsAccessPolicy2.Count -eq 2 }
	Assert-True { $iotDpsAccessPolicy2[1].KeyName -eq $NewAccessPolicyKeyName }
	Assert-True { $iotDpsAccessPolicy2[1].Rights -eq $NewAccessPolicyRights }

	
	$result = Remove-AzIoTDpsAccessPolicy -ResourceGroupName $ResourceGroupName -Name $IotDpsName -KeyName $NewAccessPolicyKeyName -PassThru
	Assert-True { $result }

	
	$iotDpsAccessPolicy3 = Update-AzIoTDpsAccessPolicy -ResourceGroupName $ResourceGroupName -Name $IotDpsName -KeyName $AccessPolicyDefaultKeyName -Permissions $NewAccessPolicyRights
	Assert-True { $iotDpsAccessPolicy3.Count -eq 1 }
	Assert-True { $iotDpsAccessPolicy3.KeyName -eq $AccessPolicyDefaultKeyName }
	Assert-True { $iotDpsAccessPolicy3.Rights -eq $NewAccessPolicyRights }

	
	$result = Remove-AzIoTDps -ResourceGroupName $ResourceGroupName -Name $IotDpsName -PassThru
	Assert-True { $result }

	
	Remove-AzResourceGroup -Name $ResourceGroupName -force
}
