













function Assert-DirectoryDoesNotExist
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

    if( Test-Path -Path $Path -PathType Container )
    {
        Fail "Directory '$Path' exists. $Message"
    }
}

