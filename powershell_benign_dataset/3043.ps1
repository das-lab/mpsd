function Should-BeGreaterThan($ActualValue, $ExpectedValue, [switch] $Negate, [string] $Because) {
    
    if ($Negate) {
        return Should-BeLessOrEqual -ActualValue $ActualValue -ExpectedValue $ExpectedValue -Negate:$false -Because $Because
    }

    if ($ActualValue -le $ExpectedValue) {
        return New-Object psobject -Property @{
            Succeeded      = $false
            FailureMessage = "Expected the actual value to be greater than $(Format-Nicely $ExpectedValue),$(Format-Because $Because) but got $(Format-Nicely $ActualValue)."
        }
    }

    return New-Object psobject -Property @{
        Succeeded = $true
    }
}


function Should-BeLessOrEqual($ActualValue, $ExpectedValue, [switch] $Negate, [string] $Because) {
    
    if ($Negate) {
        return Should-BeGreaterThan -ActualValue $ActualValue -ExpectedValue $ExpectedValue -Negate:$false -Because $Because
    }

    if ($ActualValue -gt $ExpectedValue) {
        return New-Object psobject -Property @{
            Succeeded      = $false
            FailureMessage = "Expected the actual value to be less than or equal to $(Format-Nicely $ExpectedValue),$(Format-Because $Because) but got $(Format-Nicely $ActualValue)."
        }
    }

    return New-Object psobject -Property @{
        Succeeded = $true
    }
}

Add-AssertionOperator -Name         BeGreaterThan `
    -InternalName Should-BeGreaterThan `
    -Test         ${function:Should-BeGreaterThan} `
    -Alias        'GT'

Add-AssertionOperator -Name         BeLessOrEqual `
    -InternalName Should-BeLessOrEqual `
    -Test         ${function:Should-BeLessOrEqual} `
    -Alias        'LE'


function ShouldBeGreaterThanFailureMessage() {
}
function NotShouldBeGreaterThanFailureMessage() {
}

function ShouldBeLessOrEqualFailureMessage() {
}
function NotShouldBeLessOrEqualFailureMessage() {
}
