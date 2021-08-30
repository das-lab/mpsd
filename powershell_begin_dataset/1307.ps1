
function Invoke-CPowerShell
{
    
    [CmdletBinding(DefaultParameterSetName='ScriptBlock')]
    param(
        [Parameter(Mandatory=$true,ParameterSetName='ScriptBlock')]
        [ScriptBlock]
        
        $ScriptBlock,
        
        [Parameter(Mandatory=$true,ParameterSetName='Command')]
        [object]
        
        
        
        
        
        $Command,

        [Parameter(Mandatory=$true,ParameterSetName='FilePath')]
        [string]
        
        $FilePath,

        [Parameter(ParameterSetName='Command')]
        [Parameter(ParameterSetName='ScriptBlock')]
        [Parameter(ParameterSetName='FilePath')]
        [object[]]
        [Alias('Args')]
        
        $ArgumentList,

        [Parameter(ParameterSetName='Command')]
        [Switch]
        
        
        
        $Encode,
        
        [string]
        
        $OutputFormat,

        [Microsoft.PowerShell.ExecutionPolicy]
        
        $ExecutionPolicy,

        [Switch]
        
        $NonInteractive,

        [Switch]
        
        $x86,
        
        [string]
        [ValidateSet('v2.0','v4.0')]
        
        
        
        
        
        $Runtime,

        [Parameter(ParameterSetName='FilePath')]
        [Parameter(ParameterSetName='Command')]
        [pscredential]
        
        
        
        $Credential
    )
    
    Set-StrictMode -Version 'Latest'
    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    $powerShellv3Installed = Test-Path -Path HKLM:\SOFTWARE\Microsoft\PowerShell\3
    $currentRuntime = 'v{0}.0' -f $PSVersionTable.CLRVersion.Major
    if( $powerShellv3Installed )
    {
        $currentRuntime = 'v4.0'
    }

    
    if( $PSBoundParameters.ContainsKey('Runtime') )
    {
        $runtimeInstalled = switch( $Runtime )
        {
            'v2.0' { Test-CDotNet -V2 }
            'v4.0' { Test-CDotNet -V4 -Full }
            default { Write-Error ('Unknown runtime value ''{0}''.' -f $Runtime) }
        }

        if( -not $runtimeInstalled )
        {
            Write-Error ('.NET {0} not found.' -f $Runtime)
            return
        }
    }


    if( -not $Runtime )
    {
        $Runtime = $currentRuntime
    }

    if(  $PSCmdlet.ParameterSetName -eq 'ScriptBlock' -and `
         $Host.Name -eq 'Windows PowerShell ISE Host' -and `
         $Runtime -eq 'v2.0' -and `
         $powerShellv3Installed )
    {
        Write-Error ('The PowerShell ISE v{0} can''t run script blocks under .NET {1}. Please run from the PowerShell console, or save your script block into a file and re-run Invoke-CPowerShell using the `FilePath` parameter.' -f `
                        $PSVersionTable.PSVersion,$Runtime)
        return
    }

    $comPlusAppConfigEnvVarName = 'COMPLUS_ApplicationMigrationRuntimeActivationConfigPath'
    $activationConfigDir = Join-Path $env:TEMP ([IO.Path]::GetRandomFileName())
    $activationConfigPath = Join-Path $activationConfigDir powershell.exe.activation_config
    $originalCOMAppConfigEnvVar = [Environment]::GetEnvironmentVariable( $comPlusAppConfigEnvVarName )
    if( -not $powerShellv3Installed -and $currentRuntime -ne $Runtime )
    {
        $null = New-Item -Path $activationConfigDir -ItemType Directory
        @"
<?xml version="1.0" encoding="utf-8" ?>
<configuration>
  <startup useLegacyV2RuntimeActivationPolicy="true">
    <supportedRuntime version="{0}" />
  </startup>
</configuration>
"@ -f $Runtime | Out-File -FilePath $activationConfigPath -Encoding OEM
        Set-CEnvironmentVariable -Name $comPlusAppConfigEnvVarName -Value $activationConfigDir -ForProcess
    }
    
    $params = @{ }
    if( $x86 )
    {
        $params.x86 = $true
    }
    
    try
    {
        $psPath = Get-CPowerShellPath @params
        if( $ArgumentList -eq $null )
        {
            $ArgumentList = @()
        }

        $runningAScriptBlock = $PSCmdlet.ParameterSetName -eq 'ScriptBlock' 
        if( $PSCmdlet.ParameterSetName -eq 'Command' -and $Command -is [scriptblock] )
        {
            Write-Warning -Message ('Passing a script block to the Command parameter is OBSOLETE and will be removed in a future major version of Carbon. Use the `ScriptBlock` parameter instead.')
            $ScriptBlock = $Command
            $runningAScriptBlock = $true
            if( $Credential )
            {
                Write-Error -Message ('It looks like you''re trying to run a script block as another user. `Start-Process` is used to start powershell.exe as that user. Start-Process requires all arguments to be strings. Converting a script block to a string automatically is unreliable. Please convert the script block to a command string or omit the Credential parameter.')
                return
            }
        }

        $powerShellArgs = Invoke-Command -ScriptBlock {
            if( $powerShellv3Installed -and $Runtime -eq 'v2.0' )
            {
                '-Version'
                '2.0'
            }

            
            if( $NonInteractive -and -not $runningAScriptBlock )
            {
                '-NonInteractive'
            }

            '-NoProfile'

            if( $OutputFormat )
            {
                '-OutputFormat'
                $OutputFormat
            }

            if( $ExecutionPolicy -and $PSCmdlet.ParameterSetName -ne 'ScriptBlock' )
            {
                '-ExecutionPolicy'
                $ExecutionPolicy
            }
        }

        if( $runningAScriptBlock )
        {
            Write-Debug -Message ('& {0} {1} -Command {2} -Args {3}' -f $psPath,($powerShellArgs -join ' '),$ScriptBlock,($ArgumentList -join ' '))
            & $psPath $powerShellArgs -Command $ScriptBlock -Args $ArgumentList
            Write-Debug -Message ('LASTEXITCODE: {0}' -f $LASTEXITCODE)
        }
        elseif( $PSCmdlet.ParameterSetName -eq 'FilePath' )
        {
            if( $Credential )
            {
                Start-PowerShellProcess -CommandLine ('{0} -File "{1}" {2}' -f ($powerShellArgs -join " "),$FilePath,($ArgumentList -join " ")) -Credential $Credential
            }
            else
            {
                Write-Debug ('{0} {1} -File {2} {3}' -f $psPath,($powerShellArgs -join " "),$FilePath,($ArgumentList -join ' '))
                & $psPath $powerShellArgs -File $FilePath $ArgumentList
                Write-Debug ('LASTEXITCODE: {0}' -f $LASTEXITCODE)
            }
        }
        else
        {
            if( $ArgumentList )
            {
                Write-Error -Message ('Can''t use ArgumentList parameter with Command parameter because powershell.exe''s -Command parameter doesn''t support it. Please embed the argument list in your command string, or convert your command to a script block and use the `ScriptBlock` parameter.')
                return
            }

            $argName = '-Command'
            if( $Encode )
            {
                $Command = ConvertTo-CBase64 -Value $Command
                $argName = '-EncodedCommand'
            }
            if( $Credential )
            {
                Start-PowerShellProcess -CommandLine ('{0} {1} {2}' -f ($powerShellArgs -join " "),$argName,$Command) -Credential $Credential
            }
            else
            {
                Write-Debug ('{0} {1} {2} {3}' -f $psPath,($powerShellArgs -join " "),$argName,$Command)
                & $psPath $powerShellArgs $argName $Command
                Write-Debug ('LASTEXITCODE: {0}' -f $LASTEXITCODE)
            }
        }
    }
    finally
    {
        if( Test-Path -Path $activationConfigDir -PathType Leaf )
        {
            Remove-Item -Path $activationConfigDir -Recurse -Force
        }

        if( Test-Path -Path env:$comPlusAppConfigEnvVarName )
        {
            if( $originalCOMAppConfigEnvVar )
            {
                Set-CEnvironmentVariable -Name $comPlusAppConfigEnvVarName -Value $originalCOMAppConfigEnvVar -ForProcess
            }
            else
            {
                Remove-CEnvironmentVariable -Name $comPlusAppConfigEnvVarName -ForProcess
            }
        }
    }
}

