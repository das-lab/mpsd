function Should-FileContentMatchExactly($ActualValue, $ExpectedContent, [switch] $Negate, [String] $Because) {
    
    $succeeded = (@(& $SafeCommands['Get-Content'] -Encoding UTF8 $ActualValue) -cmatch $ExpectedContent).Count -gt 0

    if ($Negate) {
        $succeeded = -not $succeeded
    }

    $failureMessage = ''

    if (-not $succeeded) {
        if ($Negate) {
            $failureMessage = NotShouldFileContentMatchExactlyFailureMessage -ActualValue $ActualValue -ExpectedContent $ExpectedContent -Because $Because
        }
        else {
            $failureMessage = ShouldFileContentMatchExactlyFailureMessage -ActualValue $ActualValue -ExpectedContent $ExpectedContent -Because $Because
        }
    }

    return & $SafeCommands['New-Object'] psobject -Property @{
        Succeeded      = $succeeded
        FailureMessage = $failureMessage
    }
}

function ShouldFileContentMatchExactlyFailureMessage($ActualValue, $ExpectedContent) {
    return "Expected $(Format-Nicely $ExpectedContent) to be case sensitively found in file $(Format-Nicely $ActualValue),$(Format-Because $Because) but it was not found."
}

function NotShouldFileContentMatchExactlyFailureMessage($ActualValue, $ExpectedContent) {
    return "Expected $(Format-Nicely $ExpectedContent) to not be case sensitively found in file $(Format-Nicely $ActualValue),$(Format-Because $Because) but it was found."
}

Add-AssertionOperator -Name         FileContentMatchExactly `
    -InternalName Should-FileContentMatchExactly `
    -Test         ${function:Should-FileContentMatchExactly}
