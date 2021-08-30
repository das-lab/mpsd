function Import-PSFConfig
{

	[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingEmptyCatchBlock", "")]
	[CmdletBinding(DefaultParameterSetName = "Path", HelpUri = 'https://psframework.org/documentation/commands/PSFramework/Import-PSFConfig')]
	param (
		[Parameter(Mandatory = $true, ValueFromPipeline = $true, ParameterSetName = "Path")]
		[string[]]
		$Path,
		
		[Parameter(ParameterSetName = "ModuleName", Mandatory = $true)]
		[string]
		$ModuleName,
		
		[Parameter(ParameterSetName = "ModuleName")]
		[int]
		$ModuleVersion = 1,
		
		[Parameter(ParameterSetName = "ModuleName")]
		[PSFramework.Configuration.ConfigScope]
		$Scope = "FileUserLocal, FileUserShared, FileSystem",
		
		[Parameter(ParameterSetName = "Path")]
		[PsfValidateSet(TabCompletion = 'PSFramework-Config-Schema')]
		[string]
		$Schema = "Default",
		
		[Parameter(ParameterSetName = "Path")]
		[string[]]
		$IncludeFilter,
		
		[Parameter(ParameterSetName = "Path")]
		[string[]]
		$ExcludeFilter,
		
		[Parameter(ParameterSetName = "Path")]
		[switch]
		$Peek,
		
		[Parameter(ParameterSetName = 'Path')]
		[switch]
		$AllowDelete,
		
		[switch]
		$PassThru,
		
		[switch]
		$EnableException
	)
	
	begin
	{
		Write-PSFMessage -Level InternalComment -Message "Bound parameters: $($PSBoundParameters.Keys -join ", ")" -Tag 'debug', 'start', 'param'
		
		$settings = @{
			IncludeFilter = $IncludeFilter
			ExcludeFilter = $ExcludeFilter
			Peek		  = $Peek.ToBool()
			AllowDelete   = $AllowDelete.ToBool()
			EnableException = $EnableException.ToBool()
			Cmdlet	      = $PSCmdlet
			Path		  = (Get-Location).Path
			PassThru      = $PassThru.ToBool()
		}
		
		$schemaScript = [PSFramework.Configuration.ConfigurationHost]::Schemata[$Schema]
	}
	process
	{
		
		foreach ($item in $Path)
		{
			try { $resolvedItem = Resolve-PSFPath -Path $item -Provider FileSystem }
			catch { $resolvedItem = $item }
			
			foreach ($rItem in $resolvedItem)
			{
				& $schemaScript $rItem $settings
			}
		}
		
		
		
		if ($ModuleName)
		{
			$data = Read-PsfConfigPersisted -Module $ModuleName -Scope $Scope -ModuleVersion $ModuleVersion
			
			foreach ($value in $data.Values)
			{
				if (-not $value.KeepPersisted) { Set-PSFConfig -FullName $value.FullName -Value $value.Value -EnableException:$EnableException -PassThru:$PassThru }
				else { Set-PSFConfig -FullName $value.FullName -Value ([PSFramework.Configuration.ConfigurationHost]::ConvertFromPersistedValue($value.Value, $value.Type)) -EnableException:$EnableException -PassThru:$PassThru }
			}
		}
		
	}
}