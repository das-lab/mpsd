













function Assert-DirectoryExists
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

    if( -not (Test-Path -Path $Path -PathType Container) )
    {
        Fail "Directory $Path does not exist. $Message"
    }
}

