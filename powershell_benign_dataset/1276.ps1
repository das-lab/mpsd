
function Get-CServiceConfiguration
{
    
    [CmdletBinding()]
    [OutputType([Carbon.Service.ServiceInfo])]
    param(
        [Parameter(Mandatory=$true,ValueFromPipelineByPropertyName=$true,Position=0)]
        [string]
        
        $Name,

        [Parameter(ValueFromPipelineByPropertyName=$true)]
        [Alias('MachineName')]
        [string]
        
        $ComputerName
    )

    begin
    {
        Set-StrictMode -Version 'Latest'
        Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState
    }

    process
    {
        $optionalParams = @{ }
        if( $ComputerName )
        {
            $optionalParams['ComputerName'] = $ComputerName
        }

        if( -not (Get-Service -Name $Name @optionalParams -ErrorAction $ErrorActionPreference) )
        {
            return
        }

        New-Object 'Carbon.Service.ServiceInfo' $Name,$ComputerName
    }
}
