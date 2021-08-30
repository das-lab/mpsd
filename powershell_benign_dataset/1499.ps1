













function Assert-Empty
{
    
    [CmdletBinding()]
    param(
        [Parameter(Position=0)]
        [object]
        
        $InputObject, 

        [Parameter(Position=1)]
        [string]
        
        $Message
    )

    Set-StrictMode -Version 'Latest'

    if( $InputObject -eq $null )
    {
        Fail ("Object is null but expected it to be empty. {0}" -f $Message)
        return
    }

    $hasLength = Get-Member -InputObject $InputObject -Name 'Length'
    $hasCount = Get-Member -InputObject $InputObject -Name 'Count'

    if( -not $hasLength -and -not $hasCount )
    {
        Fail ("Object '{0}' has no Length/Count property, so can't determine if it's empty. {1}" -f $InputObject,$Message)
    }

    if( ($hasLength -and $InputObject.Length -ne 0) -or ($hasCount -and $InputObject.Count -ne 0) )
    {
        Fail  ("Object '{0}' not empty. {1}" -f $InputObject,$Message)
    }
}

