function Export-PSFConfig
{

	[CmdletBinding(DefaultParameterSetName = 'FullName', HelpUri = 'https://psframework.org/documentation/commands/PSFramework/Export-PSFConfig')]
	Param (
		[Parameter(ParameterSetName = "FullName", Position = 0, Mandatory = $true)]
		[string]
		$FullName,
		
		[Parameter(ParameterSetName = "Module", Position = 0, Mandatory = $true)]
		[string]
		$Module,
		
		[Parameter(ParameterSetName = "Module", Position = 1)]
		[string]
		$Name = "*",
		
		[Parameter(ParameterSetName = "Config", Position = 0, Mandatory = $true, ValueFromPipeline = $true)]
		[PSFramework.Configuration.Config[]]
		$Config,
		
		[Parameter(ParameterSetName = "ModuleName", Mandatory = $true)]
		[string]
		$ModuleName,
		
		[Parameter(ParameterSetName = "ModuleName")]
		[int]
		$ModuleVersion = 1,
		
		[Parameter(ParameterSetName = "ModuleName")]
		[PSFramework.Configuration.ConfigScope]
		$Scope = "FileUserShared",
		
		[Parameter(Position = 1, Mandatory = $true, ParameterSetName = 'Config')]
		[Parameter(Position = 1, Mandatory = $true, ParameterSetName = 'FullName')]
		[Parameter(Position = 2, Mandatory = $true, ParameterSetName = 'Module')]
		[string]
		$OutPath,
		
		[switch]
		$SkipUnchanged,
		
		[switch]
		$EnableException
	)
	
	begin
	{
		Write-PSFMessage -Level InternalComment -Message "Bound parameters: $($PSBoundParameters.Keys -join ", ")" -Tag 'debug', 'start', 'param'
		
		$items = @()
		
		if (($Scope -band 15) -and ($ModuleName))
		{
			Stop-PSFFunction -Message "Cannot export modulecache to registry! Please pick a file scope for your export destination" -EnableException $EnableException -Category InvalidArgument -Tag 'fail', 'scope', 'registry'
			return
		}
	}
	process
	{
		if (Test-PSFFunctionInterrupt) { return }
		
		if (-not $ModuleName)
		{
			foreach ($item in $Config) { $items += $item }
			if ($FullName) { $items = Get-PSFConfig -FullName $FullName }
			if ($Module) { $items = Get-PSFConfig -Module $Module -Name $Name }
		}
	}
	end
	{
		if (Test-PSFFunctionInterrupt) { return }
		
		if (-not $ModuleName)
		{
			try { Write-PsfConfigFile -Config ($items | Where-Object { -not $SkipUnchanged -or -not $_.Unchanged } ) -Path $OutPath -Replace }
			catch
			{
				Stop-PSFFunction -Message "Failed to export to file" -EnableException $EnableException -ErrorRecord $_ -Tag 'fail', 'export'
				return
			}
		}
		else
		{
			if ($Scope -band 16)
			{
				Write-PsfConfigFile -Config (Get-PSFConfig -Module $ModuleName -Force | Where-Object ModuleExport | Where-Object Unchanged -NE $true) -Path (Join-Path $script:path_FileUserLocal "$($ModuleName.ToLower())-$($ModuleVersion).json")
			}
			if ($Scope -band 32)
			{
				Write-PsfConfigFile -Config (Get-PSFConfig -Module $ModuleName -Force | Where-Object ModuleExport | Where-Object Unchanged -NE $true)  -Path (Join-Path $script:path_FileUserShared "$($ModuleName.ToLower())-$($ModuleVersion).json")
			}
			if ($Scope -band 64)
			{
				Write-PsfConfigFile -Config (Get-PSFConfig -Module $ModuleName -Force | Where-Object ModuleExport | Where-Object Unchanged -NE $true)  -Path (Join-Path $script:path_FileSystem "$($ModuleName.ToLower())-$($ModuleVersion).json")
			}
		}
	}
}