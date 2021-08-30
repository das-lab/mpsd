













function Assert-LastProcessSucceeded
{
    
    [CmdletBinding()]
    param(
        [Parameter(Position=0)]
        [string]
        
        $Message
    )

    if( $LastExitCode -ne 0 )
    {
        Fail "Expected process to succeed, but it failed (exit code: $LastExitCode).  $Message" 
    }
}

