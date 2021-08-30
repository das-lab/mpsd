
$registrationEvent = {

}



$begin_event = {
    if (-not (Get-Module -Name 'PSGELF')) {
        Import-Module -Name 'PSGELF'
    }
}


$start_event = {
    $gelf_gelfserver = Get-PSFConfigValue -FullName 'PSFramework.Logging.GELF.GelfServer'
    $gelf_port = Get-PSFConfigValue -FullName 'PSFramework.Logging.GELF.Port'
    $gelf_encrypt = Get-PSFConfigValue -FullName 'PSFramework.Logging.GELF.Encrypt'

    $gelf_paramSendPsgelfTcp = @{
        'GelfServer' = $gelf_gelfserver
        'Port' = $gelf_port
        'Encrypt' = $gelf_encrypt
    }
}


$message_Event = {
	Param (
		$Message
    )

    $gelf_params = $gelf_paramSendPsgelfTcp.Clone()
    $gelf_params['ShortMessage'] = $Message.LogMessage
    $gelf_params['HostName'] = $Message.ComputerName
    $gelf_params['DateTime'] = $Message.Timestamp

    $gelf_params['Level'] = switch ($Message.Level) {
        'Critical' { 1 }
        'Important' { 1 }
        'Output' { 3 }
        'Host' { 4 }
        'Significant' { 5 }
        'VeryVerbose' { 6 }
        'Verbose' { 6 }
        'SomewhatVerbose' { 6 }
        'System' { 6 }

        default { 7 }
    }

    if ($Message.ErrorRecord) {
        $gelf_params['FullMessage'] = $Message.ErrorRecord | ConvertTo-Json
    }

    
    $gelf_properties = $Message.PSObject.Properties | Where-Object {
        $_.Name -notin @('Message', 'LogMessage', 'ComputerName', 'Timestamp', 'Level', 'ErrorRecord')
    }

    $gelf_params['AdditionalField'] = @{}
    foreach ($gelf_property in $gelf_properties) {
        $gelf_params['AdditionalField'][$gelf_property.Name] = $gelf_property.Value
    }

    PSGELF\Send-PSGelfTCP @gelf_params
}

$error_Event = {
    Param (
        $ErrorItem
    )

}


$end_event = {

}


$final_event = {

}




$configurationParameters = {
	$configroot = "PSFramework.Logging.GELF"

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
	$configroot = "PSFramework.Logging.GELF"

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
	if (Get-Module -Name PSGELF -ListAvailable) {
        return $true
    }
    else {
        return $false
    }
}


$installationParameters = {
	
}


$installationScript = {
    
    if (-not (Get-Module -Name PSGELF -ListAvailable)) {
        Install-Module -Name PSGELF
    }
}



$configuration_Settings = {
	Set-PSFConfig -Module PSFramework -Name 'Logging.GELF.GelfServer' -Value "" -Initialize -Validation string -Handler { } -Description "The GELF server to send logs to"
	Set-PSFConfig -Module PSFramework -Name 'Logging.GELF.Port' -Value "" -Initialize -Validation string -Handler { } -Description "The port number the GELF server listens on"
	Set-PSFConfig -Module PSFramework -Name 'Logging.GELF.Encrypt' -Value $true -Initialize -Validation bool -Handler { } -Description "Whether to use TLS encryption when communicating with the GELF server"

	Set-PSFConfig -Module LoggingProvider -Name 'GELF.Enabled' -Value $false -Initialize -Validation "bool" -Handler { if ([PSFramework.Logging.ProviderHost]::Providers['gelf']) { [PSFramework.Logging.ProviderHost]::Providers['gelf'].Enabled = $args[0] } } -Description "Whether the logging provider should be enabled on registration"
	Set-PSFConfig -Module LoggingProvider -Name 'GELF.AutoInstall' -Value $false -Initialize -Validation "bool" -Handler { } -Description "Whether the logging provider should be installed on registration"
	Set-PSFConfig -Module LoggingProvider -Name 'GELF.InstallOptional' -Value $false -Initialize -Validation "bool" -Handler { } -Description "Whether installing the logging provider is mandatory, in order for it to be enabled"
	Set-PSFConfig -Module LoggingProvider -Name 'GELF.IncludeModules' -Value @() -Initialize -Validation "stringarray" -Handler { if ([PSFramework.Logging.ProviderHost]::Providers['gelf']) { ([PSFramework.Logging.ProviderHost]::Providers['gelf'].IncludeModules = $args[0] | Write-Output) } } -Description "Module whitelist. Only messages from listed modules will be logged"
	Set-PSFConfig -Module LoggingProvider -Name 'GELF.ExcludeModules' -Value @() -Initialize -Validation "stringarray" -Handler { if ([PSFramework.Logging.ProviderHost]::Providers['gelf']) { ([PSFramework.Logging.ProviderHost]::Providers['gelf'].ExcludeModules = $args[0] | Write-Output) } } -Description "Module blacklist. Messages from listed modules will not be logged"
	Set-PSFConfig -Module LoggingProvider -Name 'GELF.IncludeTags' -Value @() -Initialize -Validation "stringarray" -Handler { if ([PSFramework.Logging.ProviderHost]::Providers['gelf']) { ([PSFramework.Logging.ProviderHost]::Providers['gelf'].IncludeTags = $args[0] | Write-Output) } } -Description "Tag whitelist. Only messages with these tags will be logged"
	Set-PSFConfig -Module LoggingProvider -Name 'GELF.ExcludeTags' -Value @() -Initialize -Validation "stringarray" -Handler { if ([PSFramework.Logging.ProviderHost]::Providers['gelf']) { ([PSFramework.Logging.ProviderHost]::Providers['gelf'].ExcludeTags = $args[0] | Write-Output) } } -Description "Tag blacklist. Messages with these tags will not be logged"
}

Register-PSFLoggingProvider -Name "gelf" -RegistrationEvent $registrationEvent -BeginEvent $begin_event -StartEvent $start_event -MessageEvent $message_Event -ErrorEvent $error_Event -EndEvent $end_event -FinalEvent $final_event -ConfigurationParameters $configurationParameters -ConfigurationScript $configurationScript -IsInstalledScript $isInstalledScript -InstallationScript $installationScript -InstallationParameters $installationParameters -ConfigurationSettings $configuration_Settings