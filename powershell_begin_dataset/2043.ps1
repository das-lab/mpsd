


Describe 'Group policy settings tests' -Tag CI,RequireAdminOnWindows {
    BeforeAll {
        $originalDefaultParameterValues = $PSDefaultParameterValues.Clone()
        if ( ! $IsWindows ) {
            $PSDefaultParameterValues["it:skip"] = $true
        }
        else {
            [System.Management.Automation.Internal.InternalTestHooks]::SetTestHook('BypassGroupPolicyCaching', $True)
        }
    }
    AfterAll {
        $global:PSDefaultParameterValues = $originalDefaultParameterValues
        if ( $IsWindows ) {
            [System.Management.Automation.Internal.InternalTestHooks]::SetTestHook('BypassGroupPolicyCaching', $False)
        }
    }

    Context 'Group policy settings tests' {

        BeforeEach {
            $KeyRoot = 'HKCU:\Software\Policies\Microsoft\PowerShellCore'
            if (-not (Test-Path $KeyRoot)) {$null = New-Item $KeyRoot}

            $WinPSKeyRoot = 'HKCU:\Software\Policies\Microsoft\Windows\PowerShell'
            if (-not (Test-Path $WinPSKeyRoot)) {$null = New-Item $WinPSKeyRoot}
        }

        AfterEach {
            Remove-item $KeyRoot -Recurse -Force > $null
            Remove-item $WinPSKeyRoot -Recurse -Force > $null
        }

        It 'Execution policy test' {
            function TestFeature
            {
                param([string]$KeyPath)

                Set-ItemProperty -Path $KeyPath -Name EnableScripts -Value 1 -Force

                Set-ItemProperty -Path $KeyPath -Name ExecutionPolicy -Value 'Unrestricted' -Force
                (Get-ExecutionPolicy) | Should -Be 'Unrestricted'
                Set-ItemProperty -Path $KeyPath -Name ExecutionPolicy -Value 'AllSigned' -Force
                (Get-ExecutionPolicy) | Should -Be 'AllSigned'
                Set-ItemProperty -Path $KeyPath -Name ExecutionPolicy -Value 'RemoteSigned' -Force
                (Get-ExecutionPolicy) | Should -Be 'RemoteSigned'

                Remove-ItemProperty -Path $KeyPath -Name ExecutionPolicy -Force
            }

            TestFeature -KeyPath $KeyRoot

            Set-ItemProperty -Path $KeyRoot -Name UseWindowsPowerShellPolicySetting -Value 1 -Force
            TestFeature -KeyPath $WinPSKeyRoot
        }

        It 'Module logging policy test' {
            function TestFeature
            {
                param([string]$KeyPath)

                $ModuleToLog = 'Microsoft.PowerShell.Utility'
                $ModuleNamesKeyPath = Join-Path $KeyPath 'ModuleNames'
                if (-not (Test-Path $ModuleNamesKeyPath)) {$null = New-Item $ModuleNamesKeyPath}

                Remove-Module $ModuleToLog -ErrorAction SilentlyContinue
                Import-Module $ModuleToLog
                (Get-Module $ModuleToLog).LogPipelineExecutionDetails | Should -Be $False 

                
                [string]$RareCommand = Get-Random
                Set-ItemProperty -Path $KeyPath -Name EnableModuleLogging -Value 1 -Force
                Set-ItemProperty -Path $ModuleNamesKeyPath -Name $ModuleToLog -Value $ModuleToLog -Force

                Remove-Module $ModuleToLog -ErrorAction SilentlyContinue
                Import-Module $ModuleToLog 
                (Get-Module $ModuleToLog).LogPipelineExecutionDetails | Should -Be $True 

                Get-Alias $RareCommand -ErrorAction SilentlyContinue | Out-Null

                (Get-Module $ModuleToLog).LogPipelineExecutionDetails = $False 
                Remove-ItemProperty -Path $KeyPath -Name EnableModuleLogging -Force 
                Remove-item $ModuleNamesKeyPath -Recurse -Force
                
                
                Wait-UntilTrue -sb { Get-WinEvent -FilterHashtable @{ ProviderName="PowerShellCore"; Id = 4103 } -MaxEvents 5 | ? {$_.Message.Contains($RareCommand)} } -TimeoutInMilliseconds (5*1000) -IntervalInMilliseconds 100 | Should -BeTrue
            }

            $KeyPath = Join-Path $KeyRoot 'ModuleLogging'
            if (-not (Test-Path $KeyPath)) {$null = New-Item $KeyPath}

            TestFeature -KeyPath $KeyPath

            Set-ItemProperty -Path $KeyPath -Name UseWindowsPowerShellPolicySetting -Value 1 -Force
            $WinKeyPath = Join-Path $WinPSKeyRoot 'ModuleLogging'
            if (-not (Test-Path $WinKeyPath)) {$null = New-Item $WinKeyPath}

            TestFeature -KeyPath $WinKeyPath
        }

        It 'ScriptBlock logging policy test' {
            function TestFeature
            {
                param([string]$KeyPath)

                [string]$RareCommand = Get-Random
                Set-ItemProperty -Path $KeyPath -Name EnableScriptBlockLogging -Value 1 -Force
                Set-ItemProperty -Path $KeyPath -Name EnableScriptBlockInvocationLogging -Value 1 -Force
                Invoke-Expression "$RareCommand | Out-Null"
                Remove-ItemProperty -Path $KeyPath -Name EnableScriptBlockLogging -Force
                Remove-ItemProperty -Path $KeyPath -Name EnableScriptBlockInvocationLogging -Force
                
                
                Wait-UntilTrue -sb { $script:CreatingScriptblockEvent = Get-WinEvent -FilterHashtable @{ ProviderName="PowerShellCore"; Id = 4104 } -MaxEvents 5 | ? {$_.Message.Contains($RareCommand)}; $script:CreatingScriptblockEvent } -TimeoutInMilliseconds (5*1000) -IntervalInMilliseconds 100 | Should -BeTrue

                $sbStringStart = $script:CreatingScriptblockEvent.Message.IndexOf('ScriptBlock ID:')
                $sbStringEnd = $script:CreatingScriptblockEvent.Message.IndexOf(0x0D, $sbStringStart)
                $sbString = $script:CreatingScriptblockEvent.Message.Substring($sbStringStart, $sbStringEnd - $sbStringStart)

                $StartedScriptBlockInvocationEvent = Get-WinEvent -FilterHashtable @{ ProviderName="PowerShellCore"; Id = 4105 } -MaxEvents 5 | ? {$_.Message.Contains($sbString)}
                $StartedScriptBlockInvocationEvent | Should Not BeNullOrEmpty
                $CompletedScriptBlockInvocationEvent = Get-WinEvent -FilterHashtable @{ ProviderName="PowerShellCore"; Id = 4106 } -MaxEvents 5 | ? {$_.Message.Contains($sbString)}
                $CompletedScriptBlockInvocationEvent | Should Not BeNullOrEmpty
            }

            $KeyPath = Join-Path $KeyRoot 'ScriptBlockLogging'
            if (-not (Test-Path $KeyPath)) {$null = New-Item $KeyPath}

            TestFeature -KeyPath $KeyPath

            Set-ItemProperty -Path $KeyPath -Name UseWindowsPowerShellPolicySetting -Value 1 -Force
            $WinKeyPath = Join-Path $WinPSKeyRoot 'ScriptBlockLogging'
            if (-not (Test-Path $WinKeyPath)) {$null = New-Item $WinKeyPath}

            TestFeature -KeyPath $WinKeyPath
        }

        It 'Transcription policy test' {

            function TestFeature
            {
                param([string]$KeyPath)

                $OutputDirectory = Join-path $([System.IO.Path]::GetTempPath()) $(Get-Random)
                $null = New-Item -Type Directory -Path $OutputDirectory -Force

                Set-ItemProperty -Path $KeyPath -Name EnableTranscripting -Value 1 -Force
                Set-ItemProperty -Path $KeyPath -Name OutputDirectory -Value $OutputDirectory -Force
                Set-ItemProperty -Path $KeyPath -Name EnableInvocationHeader -Value 1 -Force

                $number = get-random
                $null = pwsh -NoProfile -NonInteractive -c "$number"

                Remove-ItemProperty -Path $KeyPath -Name OutputDirectory -Force
                Remove-ItemProperty -Path $KeyPath -Name EnableInvocationHeader -Force

                $LogPath = (gci -Path $OutputDirectory -Filter "PowerShell_transcript*.txt" -Recurse).FullName
                $Log = Get-Content $LogPath -Raw

                $Log.Contains("$number") | should be $True 
                $Log.Contains("Command start time:") | should be $True 

                Remove-Item -Path $OutputDirectory -Recurse -Force
            }

            $KeyPath = Join-Path $KeyRoot 'Transcription'
            if (-not (Test-Path $KeyPath)) {$null = New-Item $KeyPath}

            TestFeature -KeyPath $KeyPath

            Set-ItemProperty -Path $KeyPath -Name UseWindowsPowerShellPolicySetting -Value 1 -Force
            $WinKeyPath = Join-Path $WinPSKeyRoot 'Transcription'
            if (-not (Test-Path $WinKeyPath)) {$null = New-Item $WinKeyPath}

            TestFeature -KeyPath $WinKeyPath
        }

        It 'Default SourcePath on Update-Help policy test' {
            function TestFeature
            {
                param([string]$KeyPath)

                $HelpPath = Join-path 'TestDrive:\' $(Get-Random)
                $null = New-Item -Type Directory -Path $HelpPath -ErrorAction SilentlyContinue
                $ModuleName = 'Microsoft.PowerShell.Utility'
                Save-Help -Module $ModuleName -DestinationPath $HelpPath -Force

                Set-ItemProperty -Path $KeyPath -Name EnableUpdateHelpDefaultSourcePath -Value 1 -Force
                Set-ItemProperty -Path $KeyPath -Name DefaultSourcePath -Value $HelpPath -Force

                
                
                { Update-Help -Module Microsoft.PowerShell.Management -Force -ErrorAction Stop } | Should -Throw -ErrorId "UnableToRetrieveHelpInfoXml,Microsoft.PowerShell.Commands.UpdateHelpCommand"

                
                Update-Help -Module Microsoft.PowerShell.Utility -Force
            }

            $HKLM_KeyRoot = 'HKLM:\Software\Policies\Microsoft\PowerShellCore'
            if (-not (Test-Path $HKLM_KeyRoot)) {$null = New-Item $HKLM_KeyRoot}
            $KeyPath = Join-Path $HKLM_KeyRoot 'UpdatableHelp'
            if (-not (Test-Path $KeyPath)) {$null = New-Item $KeyPath}

            TestFeature -KeyPath $KeyPath

            Set-ItemProperty -Path $KeyPath -Name UseWindowsPowerShellPolicySetting -Value 1 -Force
            $HKLM_WinPSKeyRoot = 'HKLM:\Software\Policies\Microsoft\Windows\PowerShell'
            if (-not (Test-Path $HKLM_WinPSKeyRoot)) {$null = New-Item $HKLM_WinPSKeyRoot}
            $WinKeyPath = Join-Path $HKLM_WinPSKeyRoot 'UpdatableHelp'
            if (-not (Test-Path $WinKeyPath)) {$null = New-Item $WinKeyPath}

            TestFeature -KeyPath $WinKeyPath

            Remove-item $HKLM_KeyRoot -Recurse -Force
            Remove-item $HKLM_WinPSKeyRoot -Recurse -Force
        }

        It 'Session configuration policy test' {
            function TestFeature
            {
                param([string]$KeyPath)

                
                $SessionName = "TestSessionConfiguration-$(get-random)"
                Set-ItemProperty -Path $KeyPath -Name EnableConsoleSessionConfiguration -Value 1 -Force
                Set-ItemProperty -Path $KeyPath -Name ConsoleSessionConfigurationName -Value $SessionName -Force

                $LogPath = (New-TemporaryFile).FullName
                pwsh -NoProfile -NonInteractive -c "1" *> $LogPath 

                
                
                

                $Log = Get-Content $LogPath -Raw
                $Log.Contains("$SessionName") | should be $True
                Remove-Item -Path $LogPath -Force
            }

            $KeyPath = Join-Path $KeyRoot 'ConsoleSessionConfiguration'
            if (-not (Test-Path $KeyPath)) {$null = New-Item $KeyPath}

            TestFeature -KeyPath $KeyPath
        }
    }
}
