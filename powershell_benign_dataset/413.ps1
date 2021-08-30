function Read-PsfConfigPersisted
{

	[OutputType([System.Collections.Hashtable])]
	[CmdletBinding()]
	Param (
		[PSFramework.Configuration.ConfigScope]
		$Scope,
		
		[string]
		$Module,
		
		[int]
		$ModuleVersion = 1,
		
		[System.Collections.Hashtable]
		$Hashtable,
		
		[switch]
		$Default
	)
	
	begin
	{
		
		function New-ConfigItem
		{
			[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseShouldProcessForStateChangingFunctions", "")]
			[CmdletBinding()]
			param (
				$FullName,
				
				$Value,
				
				$Type,
				
				[switch]
				$KeepPersisted,
				
				[switch]
				$Enforced,
				
				[switch]
				$Policy
			)
			
			[pscustomobject]@{
				FullName      = $FullName
				Value         = $Value
				Type          = $Type
				KeepPersisted = $KeepPersisted
				Enforced      = $Enforced
				Policy        = $Policy
			}
		}
		
		function Read-Registry
		{
			[CmdletBinding()]
			param (
				$Path,
				
				[switch]
				$Enforced
			)
			
			if (-not (Test-Path $Path)) { return }
			
			$common = 'PSPath', 'PSParentPath', 'PSChildName', 'PSDrive', 'PSProvider'
			
			foreach ($item in ((Get-ItemProperty -Path $Path -ErrorAction Ignore).PSObject.Properties | Where-Object Name -NotIn $common))
			{
				if ($item.Value -like "Object:*")
				{
					$data = $item.Value.Split(":", 2)
					New-ConfigItem -FullName $item.Name -Type $data[0] -Value $data[1] -KeepPersisted -Enforced:$Enforced -Policy
				}
				else
				{
					try { New-ConfigItem -FullName $item.Name -Value ([PSFramework.Configuration.ConfigurationHost]::ConvertFromPersistedValue($item.Value)) -Policy }
					catch
					{
						Write-PSFMessage -Level Warning -Message "Failed to load configuration from Registry: $($item.Name)" -ErrorRecord $_ -Target "$Path : $($item.Name)"
					}
				}
			}
		}
		
		
		if (-not $Hashtable) { $results = @{ } }
		else { $results = $Hashtable }
		
		if ($Module) { $filename = "$($Module.ToLower())-$($ModuleVersion).json" }
		else { $filename = "psf_config.json" }
	}
	process
	{
		
		if ($Scope -band 64)
		{
			foreach ($item in (Read-PsfConfigFile -Path (Join-Path $script:path_FileSystem $filename)))
			{
				if (-not $Default) { $results[$item.FullName] = $item }
				elseif (-not $results.ContainsKey($item.FullName)) { $results[$item.FullName] = $item }
			}
		}
		
		
		
		if (($Scope -band 4) -and (-not $script:NoRegistry))
		{
			foreach ($item in (Read-Registry -Path $script:path_RegistryMachineDefault))
			{
				if (-not $Default) { $results[$item.FullName] = $item }
				elseif (-not $results.ContainsKey($item.FullName)) { $results[$item.FullName] = $item }
			}
		}
		
		
		
		if ($Scope -band 32)
		{
			foreach ($item in (Read-PsfConfigFile -Path (Join-Path $script:path_FileUserShared $filename)))
			{
				if (-not $Default) { $results[$item.FullName] = $item }
				elseif (-not $results.ContainsKey($item.FullName)) { $results[$item.FullName] = $item }
			}
		}
		
		
		
		if (($Scope -band 1) -and (-not $script:NoRegistry))
		{
			foreach ($item in (Read-Registry -Path $script:path_RegistryUserDefault))
			{
				if (-not $Default) { $results[$item.FullName] = $item }
				elseif (-not $results.ContainsKey($item.FullName)) { $results[$item.FullName] = $item }
			}
		}
		
		
		
		if ($Scope -band 16)
		{
			foreach ($item in (Read-PsfConfigFile -Path (Join-Path $script:path_FileUserLocal $filename)))
			{
				if (-not $Default) { $results[$item.FullName] = $item }
				elseif (-not $results.ContainsKey($item.FullName)) { $results[$item.FullName] = $item }
			}
		}
		
		
		
		if (($Scope -band 2) -and (-not $script:NoRegistry))
		{
			foreach ($item in (Read-Registry -Path $script:path_RegistryUserEnforced -Enforced))
			{
				if (-not $Default) { $results[$item.FullName] = $item }
				elseif (-not $results.ContainsKey($item.FullName)) { $results[$item.FullName] = $item }
			}
		}
		
		
		
		if (($Scope -band 8) -and (-not $script:NoRegistry))
		{
			foreach ($item in (Read-Registry -Path $script:path_RegistryMachineEnforced -Enforced))
			{
				if (-not $Default) { $results[$item.FullName] = $item }
				elseif (-not $results.ContainsKey($item.FullName)) { $results[$item.FullName] = $item }
			}
		}
		
	}
	end
	{
		$results
	}
}