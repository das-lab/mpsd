













function Assert-NotNull
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
        Fail ("Value is null. {0}" -f $message)
    }
}

Set-Alias -Name 'Assert-IsNotNull' -Value 'Assert-NotNull'
