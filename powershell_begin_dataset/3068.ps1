function Should-MatchExactly($ActualValue, $RegularExpression, [switch] $Negate, [string] $Because) {
    
    [bool] $succeeded = $ActualValue -cmatch $RegularExpression

    if ($Negate) {
        $succeeded = -not $succeeded
    }

    $failureMessage = ''

    if (-not $succeeded) {
        if ($Negate) {
            $failureMessage = NotShouldMatchExactlyFailureMessage -ActualValue $ActualValue -RegularExpression $RegularExpression -Because $Because
        }
        else {
            $failureMessage = ShouldMatchExactlyFailureMessage -ActualValue $ActualValue -RegularExpression $RegularExpression -Because $Because
        }
    }

    return New-Object psobject -Property @{
        Succeeded      = $succeeded
        FailureMessage = $failureMessage
    }
}

function ShouldMatchExactlyFailureMessage($ActualValue, $RegularExpression) {
    return "Expected regular expression $(Format-Nicely $RegularExpression) to case sensitively match $(Format-Nicely $ActualValue),$(Format-Because $Because) but it did not match."
}

function NotShouldMatchExactlyFailureMessage($ActualValue, $RegularExpression) {
    return "Expected regular expression $(Format-Nicely $RegularExpression) to not case sensitively match $(Format-Nicely $ActualValue),$(Format-Because $Because) but it did match."
}

Add-AssertionOperator -Name         MatchExactly `
    -InternalName Should-MatchExactly `
    -Test         ${function:Should-MatchExactly} `
    -Alias        'CMATCH'
