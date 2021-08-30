













function Assert-ContainsNotLike
{
    
    [CmdletBinding()]
    param(
        [Parameter(Position=0)]
        [object]
        
        $Haystack, 

        [Parameter(Position=1)]
        [object]
        
        $Needle, 

        [Parameter(Position=2)]
        [string]
        
        $Message
    )

    Set-StrictMode -Version 'Latest'

    foreach( $item in $Haystack )
    {
        if( $item -like "*$Needle*" )
        {
            Fail "Found '$Needle': $Message"
        }
    }
}

