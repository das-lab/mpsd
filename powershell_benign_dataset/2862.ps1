
function TaskTearDown {
    
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [scriptblock]$teardown
    )

    $psake.context.Peek().taskTearDownScriptBlock = $teardown
}
