













function Assert-NotEqual
{
    
    [CmdletBinding()]
    param(
        [Parameter(Position=0)]
        
        $Expected, 
        
        [Parameter(Position=1)]
        
        $Actual, 
        
        [Parameter(Position=2)]
        
        $Message
    )

    if( $Expected -eq $Actual )
    {
        Fail ('{0} is equal to {1}. {2}' -f $Expected,$Actual,$Message)
    }
}

