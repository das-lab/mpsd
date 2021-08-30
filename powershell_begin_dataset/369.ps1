function Import-PSFLocalizedString
{

	[PSFramework.PSFCore.NoJeaCommand()]
	[CmdletBinding()]
	param (
		[Parameter(Mandatory = $true)]
		[string]
		$Path,
		
		[Parameter(Mandatory = $true)]
		[string]
		$Module,
		
		[PsfValidateSet(TabCompletion = 'PSFramework-LanguageNames', NoResults = 'Continue')]
		[string]
		$Language = 'en-US'
	)
	
	begin
	{
		try { $resolvedPath = Resolve-PSFPath -Path $Path -Provider FileSystem }
		catch { Stop-PSFFunction -Message "Failed to resolve path: $Path" -EnableException $true -Cmdlet $PSCmdlet -ErrorRecord $_ }
	}
	process
	{
		foreach ($pathItem in $resolvedPath)
		{
			$data = Import-PSFPowerShellDataFile -Path $pathItem
			foreach ($key in $data.Keys)
			{
				[PSFramework.Localization.LocalizationHost]::Write($Module, $key, $Language, $data[$key])
			}
		}
	}
}