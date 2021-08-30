function Write-PsfConfigFile
{

	[CmdletBinding()]
	Param (
		[PSFramework.Configuration.Config[]]
		$Config,
		
		[string]
		$Path,
		
		[switch]
		$Replace
	)
	
	begin
	{
		$parent = Split-Path -Path $Path
		if (-not (Test-Path $parent))
		{
			$null = New-Item $parent -ItemType Directory -Force
		}
		
		$data = @{ }
		if ((Test-Path $Path) -and (-not $Replace))
		{
			foreach ($item in (Get-Content -Path $Path -Encoding UTF8 | ConvertFrom-Json))
			{
				$data[$item.FullName] = $item
			}
		}
	}
	process
	{
		foreach ($item in $Config)
		{
			$datum = @{
				Version  = 1
				FullName = $item.FullName
			}
			if ($item.SimpleExport)
			{
				$datum["Data"] = $item.Value
			}
			else
			{
				$persisted = [PSFramework.Configuration.ConfigurationHost]::ConvertToPersistedValue($item.Value)
				$datum["Value"] = $persisted.PersistedValue
				$datum["Type"] = $persisted.PersistedType
				$datum["Style"] = "default"
			}
			
			$data[$item.FullName] = [pscustomobject]$datum
		}
	}
	end
	{
		$data.Values | ConvertTo-Json | Set-Content -Path $Path -Encoding UTF8 -ErrorAction Stop
	}
}