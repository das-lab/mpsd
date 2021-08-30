function Should-BeIn($ActualValue, $ExpectedValue, [switch] $Negate, [string] $Because) {
    
    [bool] $succeeded = $ExpectedValue -contains $ActualValue
    if ($Negate) {
        $succeeded = -not $succeeded
    }

    if (-not $succeeded) {
        if ($Negate) {
            return New-Object psobject -Property @{
                Succeeded      = $false
                FailureMessage = "Expected collection $(Format-Nicely $ExpectedValue) to not contain $(Format-Nicely $ActualValue),$(Format-Because $Because) but it was found."
            }
        }
        else {
            return New-Object psobject -Property @{
                Succeeded      = $false
                FailureMessage = "Expected collection $(Format-Nicely $ExpectedValue) to contain $(Format-Nicely $ActualValue),$(Format-Because $Because) but it was not found."
            }
        }
    }

    return New-Object psobject -Property @{
        Succeeded = $true
    }
}

Add-AssertionOperator -Name         BeIn `
    -InternalName Should-BeIn `
    -Test         ${function:Should-BeIn}


function ShouldBeInFailureMessage() {
}
function NotShouldBeInFailureMessage() {
}
