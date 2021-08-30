
function Remove-CEnvironmentVariable
{
    
    [CmdletBinding(SupportsShouldProcess=$true)]
    param(
        [Parameter(Mandatory=$true)]
        
        [string]$Name,
        
        [Parameter(ParameterSetName='ForCurrentUser')]
        
        [Switch]$ForComputer,

        [Parameter(ParameterSetName='ForCurrentUser')]
        [Parameter(Mandatory=$true,ParameterSetName='ForSpecificUser')]
        
        [Switch]$ForUser,
        
        [Parameter(ParameterSetName='ForCurrentUser')]
        
        [Switch]$ForProcess,

        [Parameter(ParameterSetName='ForCurrentUser')]
        
        
        
        [Switch]$Force,

        [Parameter(Mandatory=$true,ParameterSetName='ForSpecificUser')]
        
        [pscredential]$Credential
    )
    
    Set-StrictMode -Version 'Latest'
    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    if( $PSCmdlet.ParameterSetName -eq 'ForSpecificUser' )
    {
        $parameters = $PSBoundParameters
        $parameters.Remove('Credential')
        $job = Start-Job -ScriptBlock {
            Import-Module -Name (Join-Path -Path $using:carbonRoot -ChildPath 'Carbon.psd1')
            $VerbosePreference = $using:VerbosePreference
            $ErrorActionPreference = $using:ErrorActionPreference
            $DebugPreference = $using:DebugPreference
            $WhatIfPreference = $using:WhatIfPreference
            Remove-CEnvironmentVariable @using:parameters
        } -Credential $Credential
        $job | Wait-Job | Receive-Job
        $job | Remove-Job -Force -ErrorAction Ignore
        return
    }

    if( -not $ForProcess -and -not $ForUser -and -not $ForComputer )
    {
        Write-Error -Message ('Environment variable target not specified. You must supply one of the ForComputer, ForUser, or ForProcess switches.')
        return
    }

    Invoke-Command -ScriptBlock {
                                    if( $ForComputer )
                                    {
                                        [EnvironmentVariableTarget]::Machine
                                    }

                                    if( $ForUser )
                                    {
                                        [EnvironmentVariableTarget]::User
                                    }

                                    if( $ForProcess )
                                    {
                                        [EnvironmentVariableTarget]::Process
                                    }
                                } |
        Where-Object { $PSCmdlet.ShouldProcess( "$_-level environment variable '$Name'", "remove" ) } |
        ForEach-Object { 
                            $scope = $_
                            [Environment]::SetEnvironmentVariable( $Name, $null, $scope )
                            if( $Force -and $scope -ne [EnvironmentVariableTarget]::Process )
                            {
                                [Environment]::SetEnvironmentVariable($Name, $null, 'Process')
                            }
            }
}

