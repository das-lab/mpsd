Register-PSFConfigSchema -Name Default -Schema {
	param (
		[string]
		$Resource,
		
		[System.Collections.Hashtable]
		$Settings
	)
	
	
	$Peek = $Settings["Peek"]
	$ExcludeFilter = $Settings["ExcludeFilter"]
	$IncludeFilter = $Settings["IncludeFilter"]
	$AllowDelete = $Settings["AllowDelete"]
	$EnableException = $Settings["EnableException"]
	Set-Location -Path $Settings["Path"]
	$PassThru = $Settings["PassThru"]
	
	
	
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
				FullName	  = $FullName
				Value		  = $Value
				Type		  = $Type
				KeepPersisted = $KeepPersisted
				Enforced	  = $Enforced
				Policy	      = $Policy
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
			$data = Get-Content -Path $Path -Encoding UTF8 -Raw | ConvertFrom-Json -ErrorAction Stop
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
	
	
	try
	{
		if ($Resource -like "http*") { $data = Read-PsfConfigFile -Weblink $Resource -ErrorAction Stop }
		else
		{
			$pathItem = $null
			try { $pathItem = Resolve-PSFPath -Path $Resource -SingleItem -Provider FileSystem }
			catch { }
			if ($pathItem) { $data = Read-PsfConfigFile -Path $pathItem -ErrorAction Stop }
			else { $data = Read-PsfConfigFile -RawJson $Resource -ErrorAction Stop }
		}
	}
	catch { Stop-PSFFunction -Message "Failed to import $Resource" -EnableException $EnableException -Tag 'fail', 'import' -ErrorRecord $_ -Continue -Target $Resource -Cmdlet $Settings["Cmdlet"] }
	
	:element foreach ($element in $data)
	{
		
		foreach ($exclusion in $ExcludeFilter)
		{
			if ($element.FullName -like $exclusion)
			{
				continue element
			}
		}
		
		
		
		if ($IncludeFilter)
		{
			$isIncluded = $false
			foreach ($inclusion in $IncludeFilter)
			{
				if ($element.FullName -like $inclusion)
				{
					$isIncluded = $true
					break
				}
			}
			
			if (-not $isIncluded) { continue }
		}
		
		
		if ($Peek) { $element }
		else
		{
			try
			{
				if (-not $element.KeepPersisted) { Set-PSFConfig -FullName $element.FullName -Value $element.Value -EnableException -AllowDelete:$AllowDelete -PassThru:$PassThru }
				else { Set-PSFConfig -FullName $element.FullName -PersistedValue $element.Value -PersistedType $element.Type -AllowDelete:$AllowDelete -PassThru:$PassThru }
			}
			catch
			{
				Stop-PSFFunction -Message "Failed to set '$($element.FullName)'" -ErrorRecord $_ -EnableException $EnableException -Tag 'fail', 'import' -Continue -Target $Resource -Cmdlet $Settings["Cmdlet"]
			}
		}
	}
}