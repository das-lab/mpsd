













function Assert-NotEmpty
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
        Fail ("Object is null but expected it to be not empty. {0}" -f $Message)
        return
    }

    $hasLength = Get-Member -InputObject $InputObject -Name 'Length'
    $hasCount = Get-Member -InputObject $InputObject -Name 'Count'

    if( -not $hasLength -and -not $hasCount )
    {
        Fail ("Object '{0}' has no Length/Count property, so can't determine if it's empty or not. {1}" -f $InputObject,$Message)
    }

    if( ($hasLength -and $InputObject.Length -lt 1) -or ($hasCount -and $InputObject.Count -lt 1) )
    {
        Fail  ("Object '{0}' empty. {1}" -f $InputObject,$Message)
    }
}

