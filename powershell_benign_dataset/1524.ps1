













function Assert-False
{
    
    [CmdletBinding()]
    param(
        [Parameter(Position=0)]
        [object]
        
        $InputObject,
        
        [Parameter(Position=1)]
        [string]
        
        $Message
    )

    Set-StrictMode -Version 'Latest'

    if( $InputObject )
    {
        Fail "Expected false, but was true. $Message"
    }
}

