


function Test-EquivalentLocation {
    [CmdletBinding()]
    [OutputType("bool")]
    param(
        [Parameter(Mandatory = $false)]
        [string]$LocationA,

        [Parameter(Mandatory = $false)]
        [string]$LocationB
    )

    $LocationA = $LocationA.TrimEnd("\/")
    $LocationB = $LocationB.TrimEnd("\/")
    return $LocationA -eq $LocationB
}
