function BuildSetup {
    
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [scriptblock]$setup
    )

    $psake.context.Peek().buildSetupScriptBlock = $setup
}