













function Assert-True
{
    
    [CmdletBinding()]
    param(
        [Parameter(Position=0)]
        [object]
        
        $Condition, 

        [Parameter(Position=1)]
        [string]
        
        $Message
    )

    Set-StrictMode -Version 'Latest'

    if( -not $condition )
    {
        Fail -Message  "Expected true but was false: $message"
    }
}

