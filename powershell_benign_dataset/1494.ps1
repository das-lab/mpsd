













function Assert-Like
{
    
    [CmdletBinding()]
    param(
        [Parameter(Position=0)]
        [string]
        
        $Haystack, 

        [Parameter(Position=1)]
        [string]
        
        $Needle,

        [Parameter(Position=2)]
        [string]
        
        $Message
    )

    Set-StrictMode -Version 'Latest'

    if( $haystack -notlike "*$needle*" )
    {
        Fail "'$haystack' is not like '$needle': $message" 
    }
}

