function ConvertMySqlRow-ToJson
{
		
	
	[CmdletBinding()]
	[OutputType('System.IO.FileInfo')]
	param
	(
		[Parameter(Mandatory, ValueFromPipeline)]
		[ValidateNotNullOrEmpty()]
		[System.Data.DataRow[]]$Row,
		
		[Parameter(Mandatory)]
		[ValidateNotNullOrEmpty()]
		[ValidatePattern('\.json$')]
		[ValidateScript({ -not (Test-Path -Path $_ -PathType Leaf) })]
		[string]$Path
	)
	begin
	{
		$ErrorActionPreference = 'Stop'
		$null = New-Item -Path $Path -ItemType File
	}
	process
	{
		try
		{
			foreach ($r in $row)
			{
				$properties = $r.psobject.Properties.where{ $_.Value -is [string] -and $_.Name -ne 'RowError' }
				$items = [System.Collections.ArrayList]@()
				foreach ($p in $properties)
				{
					$null = $items.Add([PSCustomObject]@{$p.Name = $p.Value })
				}
				$items | ConvertTo-Json | Out-File -Append -FilePath $Path
			}
		}
		catch
		{
			Write-Error $_.Exception.Message
		}
	}
	end
	{	
		Get-Item -Path $Path
	}
}