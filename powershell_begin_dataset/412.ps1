function Read-PsfConfigFile
{

	[CmdletBinding()]
	param (
		[Parameter(Mandatory = $true, ParameterSetName = 'Path')]
		[string]
		$Path,
		
		[Parameter(Mandatory = $true, ParameterSetName = 'Weblink')]
		[string]
		$Weblink,
		
		[Parameter(Mandatory = $true, ParameterSetName = 'RawJson')]
		[string]
		$RawJson
	)
	
	
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
			FullName	    = $FullName
			Value		    = $Value
			Type		    = $Type
			KeepPersisted   = $KeepPersisted
			Enforced	    = $Enforced
			Policy		    = $Policy
		}
	}
	
	function Get-WebContent
	{
		[CmdletBinding()]
		param (
			[string]
			$WebLink
		)
		
		$webClient = New-Object System.Net.WebClient
		$webClient.Encoding = [System.Text.Encoding]::UTF8
		$webClient.DownloadString($WebLink)
	}
	
	
	if ($Path)
	{
		if (-not (Test-Path $Path)) { return }
		$data = Get-Content -Path $Path -Encoding UTF8 | ConvertFrom-Json -ErrorAction Stop
	}
	if ($Weblink)
	{
		$data = Get-WebContent -WebLink $Weblink | ConvertFrom-Json -ErrorAction Stop
	}
	if ($RawJson)
	{
		$data = $RawJson | ConvertFrom-Json -ErrorAction Stop
	}
	
	foreach ($item in $data)
	{
		
		if (-not $item.Version)
		{
			New-ConfigItem -FullName $item.FullName -Value ([PSFramework.Configuration.ConfigurationHost]::ConvertFromPersistedValue($item.Value, $item.Type))
		}
		
		
		
		if ($item.Version -eq 1)
		{
			if ((-not $item.Style) -or ($item.Style -eq "Simple")) { New-ConfigItem -FullName $item.FullName -Value $item.Data }
			else
			{
				if (($item.Type -eq "Object") -or ($item.Type -eq 12))
				{
					New-ConfigItem -FullName $item.FullName -Value $item.Value -Type "Object" -KeepPersisted
				}
				else
				{
					New-ConfigItem -FullName $item.FullName -Value ([PSFramework.Configuration.ConfigurationHost]::ConvertFromPersistedValue($item.Value, $item.Type))
				}
			}
		}
		
	}
}