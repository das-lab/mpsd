


function ConvertTo-AzureSize
{
	
	[CmdletBinding()]
	[OutputType('Selected.Microsoft.Azure.Commands.Compute.Models.PSVirtualMachineSize')]
	param
	(
		[Parameter(Mandatory)]
		[ValidateNotNullOrEmpty()]
		[string]$VmmHardwareProfile,
		
		[Parameter()]
		[ValidateNotNullOrEmpty()]
		[string]$AzureLocation = 'WestUS'
		
	)
	process
	{
		try
		{
			if (-not ($hwProfile = Get-SCHardwareProfile | where { $_.Name -eq $VmmHardwareProfile }))
			{
				throw "Hardware profile not found: [$($VmmHardwareProfile)]"
			}
			
			
			
			
			$whereFilter = {
				($_.CPUCount -eq $hwProfile.CPUCount) -and
				($_.Memory -ge $hwProfile.Memory) -and
				($_.Name -match '^Standard_(?!DS?\d)\w+?\d+?|Standard_D\d+_v2$')
			}
			
			$azureProperties = @(
			'*',
			@{ Name = 'Memory'; Expression = { $_.MemoryInMb } },
			@{ Name = 'CPUCount'; Expression = { $_.NumberOfCores } }
			)
			
			$sizeParams = @{
				'Property' = $azureProperties
				'Exclude' = 'Memory', 'NumberOfCores'
			}
			
			if (-not ($azureSize = (Get-AzureRmVMSize -Location $AzureLocation | select -Property $azureProperties).where($whereFilter)))
			{
				throw "No Azure server instances found that match hardware profile [$($VmmHardwareProfile)]"
			}
			else
			{
				$azureSize
			}
		}
		catch
		{
			Write-Error -Message $_.Exception.Message
		}
	}
}