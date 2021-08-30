function Checkpoint-OnlineVM
{
	
	
	[CmdletBinding(SupportsShouldProcess,ConfirmImpact = 'High')]
	param
	(
		[Parameter(Mandatory, ValueFromPipeline)]
		[ValidateNotNullOrEmpty()]
		[Microsoft.HyperV.PowerShell.VirtualMachine[]]$VM
	)
	process
	{
		foreach ($v in $VM)
		{
			if ($PSCmdlet.ShouldProcess($v.Name,'VM shutdown'))
			{
				$v | Stop-VM -Force -PassThru | Checkpoint-VM
			}
		}
	}
}