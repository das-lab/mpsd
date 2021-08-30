


function Reset-AzureRmVMAdminPassword
{
	
	[CmdletBinding()]
	param
	(
		[Parameter(Mandatory, ValueFromPipelineByPropertyName)]
		[ValidateNotNullOrEmpty()]
		[Alias('Name')]
		[string]$VMName,
		
		[Parameter(Mandatory, ValueFromPipelineByPropertyName)]
		[ValidateNotNullOrEmpty()]
		[string]$ResourceGroupName,
		
		[Parameter(Mandatory)]
		[ValidateNotNullOrEmpty()]
		[pscredential]$Credential,
	
		[Parameter()]
		[ValidateNotNullOrEmpty()]
		[switch]$Restart
		
	)
	begin {
		$ErrorActionPreference = 'Stop'
	}
	process {
		try
		{
			$vm = Get-AzureRmVm -Name $VMName -ResourceGroupName $ResourceGroupName
			
			if ($vm.OSProfile.WindowsConfiguration.ProvisionVMAgent -eq $false)
			{
				throw 'VM agent has not been installed.'
			}
			
			$typeParams = @{
				'PublisherName' = 'Microsoft.Compute'
				'Type' = 'VMAccessAgent'
				'Location' = $vm.Location
			}
			
			$typeHandlerVersion = (Get-AzureRmVMExtensionImage @typeParams | Sort-Object Version -Descending | Select-Object -first 1).Version
			
			
			$extensionParams = @{
				'VMName' = $VMName
				'Username' = $vm.OSProfile.AdminUsername
				'Password' = $Credential.GetNetworkCredential().Password
				'ResourceGroupName' = $ResourceGroupName
				'Name' = 'AdminPasswordReset'
				'Location' = $vm.Location
				'TypeHandlerVersion' = $typeHandlerVersion
			}
			
			Write-Verbose -Message 'Resetting admin password...'
			$result = Set-AzureRmVMAccessExtension @extensionParams
			if ($result.StatusCode -ne 'OK')
			{
				throw $result.Error
			}
			
			Write-Verbose -Message 'Successfully changed admin password.'
			
			if ($Restart.IsPresent)
			{
				Write-Verbose -Message 'Restarting VM...'
				$result = $vm | Restart-AzureRmVM
				if ($result.StatusCode -ne 'OK')
				{
					throw $result.Error
				}
				Write-Verbose -Message 'Successfully restarted VM.'
			}
			else
			{
				Write-Warning -Message 'You must restart the VM for the password change to take effect.'
			}
		}
		catch
		{
			Write-Error $_.Exception.Message
		}
	}
}