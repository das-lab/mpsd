













function Assert-NodeExists
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

    if( -not (Test-NodeExists $xml $xpath $defaultNamespacePrefix) )
    {
        Fail "Couldn't find node with xpath '$xpath': $message"
    }
}

