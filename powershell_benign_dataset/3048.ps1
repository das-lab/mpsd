function Should-FileContentMatchMultiline($ActualValue, $ExpectedContent, [switch] $Negate, [String] $Because) {
    
    $succeeded = [bool] ((& $SafeCommands['Get-Content'] $ActualValue -Delimiter ([char]0)) -match $ExpectedContent)

    if ($Negate) {
        $succeeded = -not $succeeded
    }

    $failureMessage = ''

    if (-not $succeeded) {
        if ($Negate) {
            $failureMessage = NotShouldFileContentMatchMultilineFailureMessage -ActualValue $ActualValue -ExpectedContent $ExpectedContent -Because $Because
        }
        else {
            $failureMessage = ShouldFileContentMatchMultilineFailureMessage -ActualValue $ActualValue -ExpectedContent $ExpectedContent -Because $Because
        }
    }

    return New-Object psobject -Property @{
        Succeeded      = $succeeded
        FailureMessage = $failureMessage
    }
}

function ShouldFileContentMatchMultilineFailureMessage($ActualValue, $ExpectedContent, $Because) {
    return "Expected $(Format-Nicely $ExpectedContent) to be found in file $(Format-Nicely $ActualValue),$(Format-Because $Because) but it was not found."
}

function NotShouldFileContentMatchMultilineFailureMessage($ActualValue, $ExpectedContent, $Because) {
    return "Expected $(Format-Nicely $ExpectedContent) to not be found in file $(Format-Nicely $ActualValue),$(Format-Because $Because) but it was found."
}

Add-AssertionOperator -Name         FileContentMatchMultiline `
    -InternalName Should-FileContentMatchMultiline `
    -Test         ${function:Should-FileContentMatchMultiline}
