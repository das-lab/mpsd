function FormatTaskName {
    
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        $format
    )

    $psake.context.Peek().config.taskNameFormat = $format
}
