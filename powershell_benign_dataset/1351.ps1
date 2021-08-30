

function Resolve-CIdentity
{
    
    [CmdletBinding(DefaultParameterSetName='ByName')]
    [OutputType([Carbon.Identity])]
    param(
        [Parameter(Mandatory=$true,ParameterSetName='ByName',Position=0)]
        [string]
        
        $Name,

        [Parameter(Mandatory=$true,ParameterSetName='BySid')]
        
        $SID
    )

    Set-StrictMode -Version 'Latest'

    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState
    
    if( $PSCmdlet.ParameterSetName -eq 'BySid' )
    {
        $SID = ConvertTo-CSecurityIdentifier -SID $SID
        if( -not $SID )
        {
            return
        }

        $id = [Carbon.Identity]::FindBySid( $SID )
        if( -not $id )
        {
            Write-Error ('Identity ''{0}'' not found.' -f $SID) -ErrorAction $ErrorActionPreference
        }
        return $id
    }
    
    if( -not (Test-CIdentity -Name $Name) )
    {
        Write-Error ('Identity ''{0}'' not found.' -f $Name) -ErrorAction $ErrorActionPreference
        return
    }

    return [Carbon.Identity]::FindByName( $Name ) 
}

