function TaskSetup {
    
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [scriptblock]$setup
    )

    $psake.context.Peek().taskSetupScriptBlock = $setup
}
