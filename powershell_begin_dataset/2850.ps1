function BuildTearDown {
    
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [scriptblock]$setup
    )

    $psake.context.Peek().buildTearDownScriptBlock = $setup
}