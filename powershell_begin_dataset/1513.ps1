













function Assert-LastProcessFailed
{
    
    [CmdletBinding()]
    param(
        [Parameter(Position=0)]
        [string]
        
        $Message
    )

    Set-StrictMode -Version 'Latest'

    if( $LastExitCode -eq 0 )
    {
        Fail "Expected process to fail, but it succeeded (exit code: $LastExitCode).  $Message" 
    }
}

