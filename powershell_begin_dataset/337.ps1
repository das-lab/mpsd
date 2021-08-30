function Remove-PSFAlias
{

	[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseShouldProcessForStateChangingFunctions", "")]
	[CmdletBinding()]
	param (
		[Parameter(ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true, Mandatory = $true)]
		[string[]]
		$Name,
		
		[switch]
		$Force
	)
	
	process
	{
		foreach ($alias in $Name)
		{
			try { [PSFramework.Utility.UtilityHost]::RemovePowerShellAlias($alias, $Force.ToBool()) }
			catch { Stop-PSFFunction -Message $_ -EnableException $true -Cmdlet $PSCmdlet -ErrorRecord $_ -OverrideExceptionMessage }
		}
	}
}