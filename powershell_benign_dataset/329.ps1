function Import-PSFPowerShellDataFile
{

	[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingInvokeExpression", "")]
	[CmdletBinding()]
	Param (
		[Parameter(ParameterSetName = 'ByPath')]
		[string[]]
		$Path,
		
		[Parameter(ValueFromPipelineByPropertyName = $true, ParameterSetName = 'ByLiteralPath')]
		[Alias('PSPath')]
		[string[]]
		$LiteralPath
	)
	
	process
	{
		
		
		
		if (($ExecutionContext.Host.Runspace.InitialSessionState.LanguageMode -eq 'NoLanguage') -or ($PSVersionTable.PSVersion.Major -lt 5))
		{
			foreach ($resolvedPath in ($Path | Resolve-PSFPath -Provider FileSystem | Select-Object -Unique))
			{
				Invoke-Expression (Get-Content -Path $resolvedPath -Raw)
			}
			foreach ($pathItem in $LiteralPath)
			{
				Invoke-Expression (Get-Content -Path $pathItem -Raw)
			}
		}
		else
		{
			Import-PowerShellDataFile @PSBoundParameters
		}
	}
}
