function Remove-PSFLicense
{

	[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Low', HelpUri = 'https://psframework.org/documentation/commands/PSFramework/Remove-PSFLicense')]
	Param (
		[Parameter(Mandatory = $true, ValueFromPipeline = $true)]
		[PSFramework.License.License[]]
		$License,
		
		[switch]
		$EnableException
	)
	
	Begin
	{
		
	}
	Process
	{
		foreach ($l in $License)
		{
			if ($PSCmdlet.ShouldProcess("$($l.Product) $($l.ProductVersion) ($($l.LicenseName))", "Remove License"))
			{
				try { [PSFramework.License.LicenseHost]::Remove($l) }
				catch
				{
					Stop-PSFFunction -Message "Failed to remove license" -ErrorRecord $_ -EnableException $EnableException -Target $l -Continue
				}
			}
		}
	}
	End
	{
		
	}
}
