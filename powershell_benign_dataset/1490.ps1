













function Assert-FileExists
{
    
    [CmdletBinding()]
    param(
        [Parameter(Position=0)]
        [string]
        
        $Path,

        [Parameter(Position=1)]
        [string]
        
        $Message
    )

    Set-StrictMode -Version 'Latest'

    Write-Debug -Message "Testing if file '$Path' exists."
    if( -not (Test-Path $Path -PathType Leaf) )
    {
        Fail "File $Path does not exist. $Message"
    }
}

