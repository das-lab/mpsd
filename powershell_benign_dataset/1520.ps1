













function Assert-DoesNotContain
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

    Write-Warning ('Assert-Contains is obsolete and will be removed from a future version of Blade. Please use `Assert-That -Contains` instead.')

    if( $Haystack -contains $Needle )
    {
        Fail "Found '$Needle'. $Message"
    }
}

