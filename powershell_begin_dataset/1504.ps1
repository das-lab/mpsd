













function Assert-Null
{
    
    [CmdletBinding()]
    param(
        [Parameter(Position=0)]
        [object]
        
        $Value, 

        [Parameter(Position=1)]
        [string]
        
        $Message
    )

    Set-StrictMode -Version 'Latest'

    if( $Value -ne $null )
    {
        Fail "Value '$Value' is not null: $Message"
    }
}

Set-Alias -Name 'Assert-IsNull' -Value 'Assert-Null'
