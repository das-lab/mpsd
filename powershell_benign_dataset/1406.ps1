
function Test-CTypeDataMember
{
    
    [CmdletBinding()]
    [OutputType([bool])]
    param(
        [Parameter(Mandatory=$true)]
        [string]
        
        $TypeName,

        [Parameter(Mandatory=$true)]
        [string]
        
        $MemberName
    )

    Set-StrictMode -Version 'Latest'

    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    $typeData = Get-TypeData -TypeName $TypeName
    if( -not $typeData )
    {
        
        return $false
    }

    return $typeData.Members.ContainsKey( $MemberName )
}


