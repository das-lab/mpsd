













function Assert-FileContains
{
    
    [CmdletBinding()]
    param(
        [Parameter(Position=0)]
        [string]
        
        $Path,

        [Parameter(Position=1)]
        [string]
        
        $Needle,

        [Parameter(Position=2)]
        
        $Message
    )

    Set-StrictMode -Version 'Latest'

    Write-Debug -Message "Checking if '$Path' contains expected content."
    $actualContents = Get-Content -Path $Path -Raw
    if( $actualContents -eq $null )
    {
        Fail ('File ''{0}'' is empty and does not contain ''{1}''. {2}' -f $Path,$Needle,$Message)
        return
    }

    Write-Debug -Message "Actual:`n$actualContents"
    Write-Debug -Message "Expected:`n$Needle"
    if( $actualContents -notmatch ([Text.RegularExpressions.Regex]::Escape($Needle)) )
    {
        Fail ("File '{0}' does not contain '{1}'. {2}" -f $Path,$Needle,$Message)
    }
}

