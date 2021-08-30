

function Get-AzrAvailableLun
{
	
	[CmdletBinding()]
	param
	(
		[Parameter(Mandatory)]
		[ValidateNotNullOrEmpty()]
		[Microsoft.Azure.Commands.Compute.Models.PSVirtualMachine]$VM
	)
	process
	{
		$luns = $VM.StorageProfile.DataDisks
		if ($luns.Count -eq 0)
		{
			Write-Verbose -Message "No data disks found attached to VM: [$($VM.Name)]"
			0
		}
		else
		{
			Write-Verbose -Message "Finding the next available LUN for VM: [$($VM.Name)]"
			$lun = ($luns.Lun | Measure-Object -Maximum).maximum + 1
			Write-Verbose -Message "Next available LUN is: [$($lun)]"
			$lun
		}
	}
}