
function Test-CDotNet
{
    
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true,ParameterSetName='v2')]
        [Switch]
        
        $V2,

        [Parameter(Mandatory=$true,ParameterSetName='v4Client')]
        [Parameter(Mandatory=$true,ParameterSetName='v4Full')]
        [Switch]
        
        $V4,

        [Parameter(Mandatory=$true,ParameterSetName='v4Client')]
        [Switch]
        
        $Client,

        [Parameter(Mandatory=$true,ParameterSetName='v4Full')]
        [Switch]
        
        $Full
    )

    Set-StrictMode -Version 'Latest'

    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    $runtimeSetupRegPath = switch( $PSCmdlet.ParameterSetName )
    {
        'v2' { 'hklm:\SOFTWARE\Microsoft\NET Framework Setup\NDP\v2.0.50727' }
        'v4Client' { 'hklm:\SOFTWARE\Microsoft\NET Framework Setup\NDP\v4\Client' }
        'v4Full' { 'hklm:\SOFTWARE\Microsoft\NET Framework Setup\NDP\v4\Full' }
        default { Write-Error ('Unknown parameter set ''{0}''.' -f $PSCmdlet.ParameterSetName) }
    }

    if( -not $runtimeSetupRegPath )
    {
        return
    }

    if( -not (Test-CRegistryKeyValue -Path $runtimeSetupRegPath -Name 'Install') )
    {
        return $false
    }

    $value = Get-CRegistryKeyValue -Path $runtimeSetupRegPath -Name 'Install'
    return ($value -eq 1)
}
