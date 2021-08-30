













function Test-NodeExists
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
        
        $DefaultNamespacePrefix
    )

    Set-StrictMode -Version 'Latest'

    $nsManager = New-Object 'System.Xml.XmlNamespaceManager' $xml.NameTable
    if( $xml.DocumentElement.NamespaceURI -ne '' -and $xml.DocumentElement.Prefix -eq '' )
    {
        Write-Debug -Message "XML document has a default namespace, setting prefix to '$defaultNamespacePrefix'."
        $nsManager.AddNamespace($defaultNamespacePrefix, $xml.DocumentElement.NamespaceURI)
    }
    
    $node = $xml.SelectSingleNode( $xpath, $nsManager )
    return ($node -ne $null)
}

