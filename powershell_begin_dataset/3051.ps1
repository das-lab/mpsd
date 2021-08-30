function Should-HaveParameter (
    $ActualValue,
    [String] $ParameterName,
    $Type,
    [String]$DefaultValue,
    [Switch]$Mandatory,
    [Switch]$HasArgumentCompleter,
    [Switch]$Negate,
    [String]$Because ) {
    

    if ($null -eq $ActualValue -or $ActualValue -isnot [Management.Automation.CommandInfo]) {
        throw "Input value must be non-null CommandInfo object. You can get one by calling Get-Command."
    }

    if ($null -eq $ParameterName) {
        throw "The ParameterName can't be empty"
    }

    
    function Join-And ($Items, $Threshold = 2) {

        if ($null -eq $items -or $items.count -lt $Threshold) {
            $items -join ', '
        }
        else {
            $c = $items.count
            ($items[0..($c - 2)] -join ', ') + ' and ' + $items[-1]
        }
    }

    function Add-SpaceToNonEmptyString ([string]$Value) {
        if ($Value) {
            " $Value"
        }
    }

    function Get-ParameterInfo {
        param(
            [Parameter( Mandatory = $true )]
            [Management.Automation.CommandInfo]$Command
        )
        

        function Get-TokenGroup {
            param(
                [Parameter( Mandatory = $true )]
                [System.Management.Automation.PSToken[]]$tokens
            )
            $i = $j = 0
            do {
                $token = $tokens[$i]
                if ($token.Type -eq 'GroupStart') {
                    $j++
                }
                if ($token.Type -eq 'GroupEnd') {
                    $j--
                }
                if (-not $token.PSObject.Properties.Item('Depth')) {
                    $token | Add-Member Depth -MemberType NoteProperty -Value $j
                }
                $token

                $i++
            } until ($j -eq 0 -or $i -ge $tokens.Count)
        }

        $errors = $null
        $tokens = [System.Management.Automation.PSParser]::Tokenize($Command.Definition, [Ref]$errors)

        
        $start = $tokens.IndexOf(($tokens | Where-Object { $_.Content -eq 'param' } | Select-Object -First 1)) + 1
        $paramBlock = Get-TokenGroup $tokens[$start..($tokens.Count - 1)]

        for ($i = 0; $i -lt $paramBlock.Count; $i++) {
            $token = $paramBlock[$i]

            if ($token.Depth -eq 1 -and $token.Type -eq 'Variable') {
                $paramInfo = New-Object PSObject -Property @{
                    Name = $token.Content
                } | Select-Object Name, Type, DefaultValue, DefaultValueType

                if ($paramBlock[$i + 1].Content -ne ',') {
                    $value = $paramBlock[$i + 2]
                    if ($value.Type -eq 'GroupStart') {
                        $tokenGroup = Get-TokenGroup $paramBlock[($i + 2)..($paramBlock.Count - 1)]
                        $paramInfo.DefaultValue = [String]::Join('', ($tokenGroup | ForEach-Object { $_.Content }))
                        $paramInfo.DefaultValueType = 'Expression'
                    }
                    else {
                        $paramInfo.DefaultValue = $value.Content
                        $paramInfo.DefaultValueType = $value.Type
                    }
                }
                if ($paramBlock[$i - 1].Type -eq 'Type') {
                    $paramInfo.Type = $paramBlock[$i - 1].Content
                }
                $paramInfo
            }
        }
    }

    if ($Type -is [string]) {
        
        $parsedType = ($Type -replace '^\[(.*)\]$', '$1') -as [Type]
        if ($null -eq $parsedType) {
            throw [ArgumentException]"Could not find type [$ParsedType]. Make sure that the assembly that contains that type is loaded."
        }

        $Type = $parsedType
    }
    

    $buts = @()
    $filters = @()

    $null = $ActualValue.Parameters 
    $hasKey = $ActualValue.Parameters.PSBase.ContainsKey($ParameterName)
    $filters += "to$(if ($Negate) {" not"}) have a parameter $ParameterName"

    if (-not $Negate -and -not $hasKey) {
        $buts += "the parameter is missing"
    }
    elseif ($Negate -and -not $hasKey) {
        return New-Object PSObject -Property @{ Succeeded = $true }
    }
    elseif ($Negate -and $hasKey -and -not ($Mandatory -or $Type -or $DefaultValue -or $HasArgumentCompleter)) {
        $buts += "the parameter exists"
    }
    else {
        $attributes = $ActualValue.Parameters[$ParameterName].Attributes

        if ($Mandatory) {
            $testMandatory = $attributes | Where-Object { $_ -is [System.Management.Automation.ParameterAttribute] -and $_.Mandatory }
            $filters += "which is$(if ($Negate) {" not"}) mandatory"

            if (-not $Negate -and -not $testMandatory) {
                $buts += "it wasn't mandatory"
            }
            elseif ($Negate -and $testMandatory) {
                $buts += "it was mandatory"
            }
        }

        if ($Type) {
            
            
            
            [type]$actualType = $ActualValue.Parameters[$ParameterName].ParameterType
            $testType = ($Type -eq $actualType)
            $filters += "$(if ($Negate) {"not "})of type [$($Type.FullName)]"

            if (-not $Negate -and -not $testType) {
                $buts += "it was of type [$($actualType.FullName)]"
            }
            elseif ($Negate -and $testType) {
                $buts += "it was of type [$($Type.FullName)]"
            }
        }

        if ($PSBoundParameters.Keys -contains "DefaultValue") {
            $parameterMetadata = Get-ParameterInfo $ActualValue | Where-Object { $_.Name -eq $ParameterName }
            $actualDefault = if ($parameterMetadata.DefaultValue) { $parameterMetadata.DefaultValue } else { "" }
            $testDefault = ($actualDefault -eq $DefaultValue)
            $filters += "the default value$(if ($Negate) {" not"}) to be $(Format-Nicely $DefaultValue)"

            if (-not $Negate -and -not $testDefault) {
                $buts += "the default value was $(Format-Nicely $actualDefault)"
            }
            elseif ($Negate -and $testDefault) {
                $buts += "the default value was $(Format-Nicely $DefaultValue)"
            }
        }

        if ($HasArgumentCompleter) {
            $testArgumentCompleter = $attributes | Where-Object {$_ -is [ArgumentCompleter]}
            $filters += "has ArgumentCompletion"

            if (-not $Negate -and -not $testArgumentCompleter) {
                $buts += "has no ArgumentCompletion"
            }
            elseif ($Negate -and $testArgumentCompleter) {
                $buts += "has ArgumentCompletion"
            }
        }
    }

    if ($buts.Count -ne 0) {
        $filter = Add-SpaceToNonEmptyString ( Join-And $filters -Threshold 3 )
        $but = Join-And $buts
        $failureMessage = "Expected command $($ActualValue.Name)$filter,$(Format-Because $Because) but $but."

        return New-Object PSObject -Property @{
            Succeeded      = $false
            FailureMessage = $failureMessage
        }
    }
    else {
        return New-Object PSObject -Property @{ Succeeded = $true }
    }
}

Add-AssertionOperator -Name         HaveParameter `
    -InternalName Should-HaveParameter `
    -Test         ${function:Should-HaveParameter}
