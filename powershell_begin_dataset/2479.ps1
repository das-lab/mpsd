function Remove-AzrVirtualMachine {
	
	[CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High')]
	param
	(
		[Parameter(Mandatory, ValueFromPipelineByPropertyName)]
		[ValidateNotNullOrEmpty()]
		[Alias('Name')]
		[string]$VMName,
		
		[Parameter(Mandatory, ValueFromPipelineByPropertyName)]
		[ValidateNotNullOrEmpty()]
		[string]$ResourceGroupName,

		[Parameter()]
		[pscredential]$Credential,

		[Parameter()]
		[ValidateNotNullOrEmpty()]
		[switch]$Wait
		
	)
	process {
		$scriptBlock = {
			param ($VMName,
				$ResourceGroupName)
			$commonParams = @{
				'Name'              = $VMName;
				'ResourceGroupName' = $ResourceGroupName
			}
			$vm = Get-AzVm @commonParams
				
			
			if ($vm.DiagnosticsProfile.bootDiagnostics) {
				Write-Verbose -Message 'Removing boot diagnostics storage container...'
				$diagSa = [regex]::match($vm.DiagnosticsProfile.bootDiagnostics.storageUri, '^http[s]?://(.+?)\.').groups[1].value
				if ($vm.Name.Length -gt 9) {
					$i = 9
				} else {
					$i = $vm.Name.Length - 1
				}

				
				$azResourceParams = @{
					'ResourceName'      = $VMName
					'ResourceType'      = 'Microsoft.Compute/virtualMachines'
					'ResourceGroupName' = $ResourceGroupName
				}
				$vmResource = Get-AzResource @azResourceParams
				$vmId = $vmResource.Properties.VmId
				

				$diagContainerName = ('bootdiagnostics-{0}-{1}' -f $vm.Name.ToLower().Substring(0, $i), $vmId)
				$diagSaRg = (Get-AzStorageAccount | where { $_.StorageAccountName -eq $diagSa }).ResourceGroupName
				$saParams = @{
					'ResourceGroupName' = $diagSaRg
					'Name'              = $diagSa
				}
					
				Get-AzStorageAccount @saParams | Get-AzStorageContainer | where { $_.Name-eq $diagContainerName } | Remove-AzStorageContainer -Force
			}
			
				
			Write-Verbose -Message 'Removing the Azure VM...'
			$null = $vm | Remove-AzVM -Force
			Write-Verbose -Message 'Removing the Azure network interface...'
			foreach($nicUri in $vm.NetworkProfile.NetworkInterfaces.Id) {
				$nic = Get-AzNetworkInterface -ResourceGroupName $vm.ResourceGroupName -Name $nicUri.Split('/')[-1]
				Remove-AzNetworkInterface -Name $nic.Name -ResourceGroupName $vm.ResourceGroupName -Force
				foreach($ipConfig in $nic.IpConfigurations) {
					if($ipConfig.PublicIpAddress -ne $null) {
						Write-Verbose -Message 'Removing the Public IP Address...'
						Remove-AzPublicIpAddress -ResourceGroupName $vm.ResourceGroupName -Name $ipConfig.PublicIpAddress.Id.Split('/')[-1] -Force
					} 
				}
			} 

				
			
			Write-Verbose -Message 'Removing OS disk...'
			if ('Uri' -in $vm.StorageProfile.OSDisk.Vhd) {
				
				$osDiskId = $vm.StorageProfile.OSDisk.Vhd.Uri
				$osDiskContainerName = $osDiskId.Split('/')[-2]

				
				$osDiskStorageAcct = Get-AzStorageAccount | where { $_.StorageAccountName -eq $osDiskId.Split('/')[2].Split('.')[0] }
				$osDiskStorageAcct | Remove-AzStorageBlob -Container $osDiskContainerName -Blob $osDiskId.Split('/')[-1]

				
				Write-Verbose -Message 'Removing the OS disk status blob...'
				$osDiskStorageAcct | Get-AzStorageBlob -Container $osDiskContainerName -Blob "$($vm.Name)*.status" | Remove-AzStorageBlob
				
			} else {
				
				Get-AzDisk | where { $_.ManagedBy -eq $vm.Id } | Remove-AzDisk -Force
			}
			
			
			if ('DataDiskNames' -in $vm.PSObject.Properties.Name -and @($vm.DataDiskNames).Count -gt 0) {
				Write-Verbose -Message 'Removing data disks...'
				foreach ($uri in $vm.StorageProfile.DataDisks.Vhd.Uri) {
					$dataDiskStorageAcct = Get-AzStorageAccount -Name $uri.Split('/')[2].Split('.')[0]
					$dataDiskStorageAcct | Remove-AzStorageBlob -Container $uri.Split('/')[-2] -Blob $uri.Split('/')[-1]
				}
			}
		}
			
		if ($Wait.IsPresent) {
			& $scriptBlock -VMName $VMName -ResourceGroupName $ResourceGroupName
		} else {
			$initScript = {
				$null = Login-AzAccount -Credential $Credential
			}
			$jobParams = @{
				'ScriptBlock'          = $scriptBlock
				'InitializationScript' = $initScript
				'ArgumentList'         = @($VMName, $ResourceGroupName)
				'Name'                 = "Azure VM $VMName Removal"
			}
			Start-Job @jobParams 
		}
	}
}