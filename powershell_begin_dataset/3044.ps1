function Should-BeTrue($ActualValue, [switch] $Negate, [string] $Because) {
    
    if ($Negate) {
        return Should-BeFalse -ActualValue $ActualValue -Negate:$false -Because $Because
    }

    if (-not $ActualValue) {
        $failureMessage = "Expected `$true,$(Format-Because $Because) but got $(Format-Nicely $ActualValue)."
        return New-Object psobject -Property @{
            Succeeded      = $false
            FailureMessage = $failureMessage
        }
    }

    return New-Object psobject -Property @{
        Succeeded = $true
    }
}

function Should-BeFalse($ActualValue, [switch] $Negate, $Because) {
    
    if ($Negate) {
        return Should-BeTrue -ActualValue $ActualValue -Negate:$false -Because $Because
    }

    if ($ActualValue) {
        $failureMessage = "Expected `$false,$(Format-Because $Because) but got $(Format-Nicely $ActualValue)."
        return New-Object psobject -Property @{
            Succeeded      = $false
            FailureMessage = $failureMessage
        }
    }

    return New-Object psobject -Property @{
        Succeeded = $true
    }
}


Add-AssertionOperator -Name         BeTrue `
    -InternalName Should-BeTrue `
    -Test         ${function:Should-BeTrue}

Add-AssertionOperator -Name         BeFalse `
    -InternalName Should-BeFalse `
    -Test         ${function:Should-BeFalse}




function ShouldBeTrueFailureMessage($ActualValue) {
}
function NotShouldBeTrueFailureMessage($ActualValue) {
}
function ShouldBeFalseFailureMessage($ActualValue) {
}
function NotShouldBeFalseFailureMessage($ActualValue) {
}
