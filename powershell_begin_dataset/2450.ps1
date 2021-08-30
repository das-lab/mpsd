function Remove-OnlineVM
{
	
	
	[CmdletBinding(SupportsShouldProcess)]
	param
	(
		[Parameter(Mandatory, ValueFromPipeline)]
		[ValidateNotNullOrEmpty()]
		[VMware.VimAutomation.ViCore.Impl.V1.Inventory.VirtualMachineImpl[]]$VM
	)
	process
	{
		foreach ($v in $VM)
		{
			$vmName = $v.Name
			if ($PSCmdlet.ShouldProcess($vmName, 'Remove VM'))
			{
				if ((vmware.vimautomation.core\Get-VM -Name $vmName).PowerState -eq 'PoweredOn')
				{
					Write-Verbose -Message "[$vmName)] is online. Shutting down now."
					$v | vmware.vimautomation.core\Stop-VM -Confirm:$false
				}
				$v | vmware.vimautomation.core\Remove-VM -Confirm:$false
			}
		}
	}
}