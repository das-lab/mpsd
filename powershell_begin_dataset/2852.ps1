function Include {
    
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$fileNamePathToInclude
    )

    Assert (test-path $fileNamePathToInclude -pathType Leaf) ($msgs.error_invalid_include_path -f $fileNamePathToInclude)

    $psake.context.Peek().includes.Enqueue((Resolve-Path $fileNamePathToInclude));
}
