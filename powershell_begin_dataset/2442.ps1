function Remove-OnlineVM
{
	
	
	[CmdletBinding(SupportsShouldProcess)]
	param
	(
		[Parameter(Mandatory, ValueFromPipeline)]
		[ValidateNotNullOrEmpty()]
		[Microsoft.HyperV.PowerShell.VirtualMachine[]]$VM,
		
		[Parameter(Mandatory, ValueFromPipelineByPropertyName)]
		[ValidateNotNullOrEmpty()]
		[Alias('ComputerName')]
		[string]$Server,
		
		[Parameter()]
		[ValidateNotNullOrEmpty()]
		[pscredential]$Credential
	)
	process
	{
		foreach ($v in $VM)
		{
			$vmName = $v.Name
			if ($PSCmdlet.ShouldProcess($vmName,'Remove VM'))
			{
				if ((Get-VM -ComputerName $Server -Name $vmName).State -eq 'Running')
				{
					Write-Verbose -Message "[$vmName)] is online. Shutting down now."
					$v | Stop-VM -Force
				}
				$v | Remove-VM -Force
			}
		}
	}
}