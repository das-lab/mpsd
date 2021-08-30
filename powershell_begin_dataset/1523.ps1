













function Assert-GreaterThan
{
    
    [CmdletBinding()]
    param(
        [Parameter(Position=0)]
        [object]
        
        $InputObject, 

        [Parameter(Position=1)]
        [object]
        
        $LowerBound, 

        [Parameter(Position=2)]
        [string]
        
        $Message
    )

    Set-StrictMode -Version 'Latest'

    if( -not ($InputObject -gt $LowerBound ) )
    {
        Fail "'$InputObject' is not greater than '$LowerBound': $message"
    }
}

