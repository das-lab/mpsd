function Properties {
    
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [scriptblock]$properties
    )

    $psake.context.Peek().properties.Push($properties)
}
