function In {
    
    [CmdletBinding()]
    param(
        $path,
        [ScriptBlock] $execute
    )
    Assert-DescribeInProgress -CommandName In

    $old_pwd = $pwd
    & $SafeCommands['Push-Location'] $path
    $pwd = $path
    try {
        Write-ScriptBlockInvocationHint -Hint "In" -ScriptBlock $execute
        & $execute
    }
    finally {
        & $SafeCommands['Pop-Location']
        $pwd = $old_pwd
    }
}
