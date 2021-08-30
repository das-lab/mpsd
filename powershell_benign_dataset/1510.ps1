













function Assert-Match
{
    
    param(
        [Parameter(Position=0,Mandatory=$true)]
        [string]
        
        $Haystack, 
        
        [Parameter(Position=1,Mandatory=$true)]
        [string]
        
        $Regex, 
        
        [Parameter(Position=2)]
        [string]
        
        $Message
    )
    
    if( $Haystack -notmatch $Regex )
    {
        Fail "'$Haystack' does not match '$Regex': $Message"
    }
}

