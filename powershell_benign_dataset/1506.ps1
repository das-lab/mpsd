













function Assert-LessThan
{
    
    [CmdletBinding()]
    param(
        [Parameter(Position=0)]
        [object]
        
        $ExpectedValue,

        [Parameter(Position=1)]
        [object]
        
        $UpperBound, 

        [Parameter(Position=2)]
        [string]
        
        $Message
    )

    Set-StrictMode -Version 'Latest'

    if( -not ($ExpectedValue -lt $UpperBound) )
    {
        Fail "$ExpectedValue is not less than $UpperBound : $Message" 
    }
}

