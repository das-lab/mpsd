













function Assert-NodeDoesNotExist
{
    
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true,Position=0)]
        [xml]
        
        $Xml,

        [Parameter(Mandatory=$true,Position=1)]
        [string]
        
        $XPath,

        [Parameter(Position=2)]
        [string]
        
        $DefaultNamespacePrefix, 

        [Parameter(Position=3)]
        [string]
        
        $Message
    )

    Set-StrictMode -Version 'Latest'

    if( Test-NodeExists $Xml $XPath $DefaultNamespacePrefix )
    {
        Fail "Found node with XPath '$XPath': $Message"
    }
}

