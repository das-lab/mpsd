
function Should-BeNullOrEmpty([object[]] $ActualValue, [switch] $Negate, [string] $Because) {
    
    if ($null -eq $ActualValue -or $ActualValue.Count -eq 0) {
        $succeeded = $true
    }
    elseif ($ActualValue.Count -eq 1) {
        $expandedValue = $ActualValue[0]
        if ($expandedValue -is [hashtable]) {
            $succeeded = $expandedValue.Count -eq 0
        }
        else {
            $succeeded = [String]::IsNullOrEmpty($expandedValue)
        }
    }
    else {
        $succeeded = $false
    }

    if ($Negate) {
        $succeeded = -not $succeeded
    }

    $failureMessage = ''

    if (-not $succeeded) {
        if ($Negate) {
            $failureMessage = NotShouldBeNullOrEmptyFailureMessage -Because $Because
        }
        else {
            $failureMessage = ShouldBeNullOrEmptyFailureMessage -ActualValue $ActualValue -Because $Because
        }
    }

    return New-Object psobject -Property @{
        Succeeded      = $succeeded
        FailureMessage = $failureMessage
    }
}

function ShouldBeNullOrEmptyFailureMessage($ActualValue, $Because) {
    return "Expected `$null or empty,$(Format-Because $Because) but got $(Format-Nicely $ActualValue)."
}

function NotShouldBeNullOrEmptyFailureMessage ($Because) {
    return "Expected a value,$(Format-Because $Because) but got `$null or empty."
}

Add-AssertionOperator -Name               BeNullOrEmpty `
    -InternalName       Should-BeNullOrEmpty `
    -Test               ${function:Should-BeNullOrEmpty} `
    -SupportsArrayInput
