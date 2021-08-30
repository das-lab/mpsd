function It {
    
    [CmdletBinding(DefaultParameterSetName = 'Normal')]
    param(
        [Parameter(Mandatory = $true, Position = 0)]
        [string] $Name,

        [Parameter(Position = 1)]
        [ScriptBlock] $Test = {},

        [System.Collections.IDictionary[]] $TestCases,

        [Parameter(ParameterSetName = 'Pending')]
        [Switch] $Pending,

        [Parameter(ParameterSetName = 'Skip')]
        [Alias('Ignore')]
        [Switch] $Skip
    )

    ItImpl -Pester $pester -OutputScriptBlock ${function:Write-PesterResult} @PSBoundParameters
}

function ItImpl {
    [CmdletBinding(DefaultParameterSetName = 'Normal')]
    param(
        [Parameter(Mandatory = $true, Position = 0)]
        [string]$Name,

        [Parameter(Position = 1)]
        [ScriptBlock] $Test,

        [System.Collections.IDictionary[]] $TestCases,
        [Parameter(ParameterSetName = 'Pending')]
        [Switch] $Pending,

        [Parameter(ParameterSetName = 'Skip')]
        [Alias('Ignore')]
        [Switch] $Skip,

        $Pester,
        [scriptblock] $OutputScriptBlock
    )

    Assert-DescribeInProgress -CommandName It

    
    if ($PSCmdlet.ParameterSetName -ne 'Skip') {
        $Skip = $false
    }
    if ($PSCmdlet.ParameterSetName -ne 'Pending') {
        $Pending = $false
    }

    
    if (-not ($PSBoundParameters.ContainsKey('test') -or $Skip -or $Pending)) {
        If ($Name.Contains("`n")) {
            throw "Name parameter has multiple lines and no script block is provided. (Have you provided a name for the test group?)"
        }
        else {
            throw 'No test script block is provided. (Have you put the open curly brace on the next line?)'
        }
    }

    
    if ($null -eq $Test) {
        $Test = {}
    }

    
    if ($PSVersionTable.PSVersion.Major -le 2 -and
        $PSCmdlet.ParameterSetName -eq 'Normal' -and
        [String]::IsNullOrEmpty((Remove-Comments $Test.ToString()) -replace "\s")) {
        $Pending = $true
    }
    elseIf ($PSVersionTable.PSVersion.Major -gt 2) {
        
        
        $testIsEmpty =
        [String]::IsNullOrEmpty($Test.Ast.BeginBlock.Statements) -and
        [String]::IsNullOrEmpty($Test.Ast.ProcessBlock.Statements) -and
        [String]::IsNullOrEmpty($Test.Ast.EndBlock.Statements)

        if ($PSCmdlet.ParameterSetName -eq 'Normal' -and $testIsEmpty) {
            $Pending = $true
        }
    }

    $pendingSkip = @{}

    if ($PSCmdlet.ParameterSetName -eq 'Skip') {
        $pendingSkip['Skip'] = $Skip
    }
    else {
        $pendingSkip['Pending'] = $Pending
    }

    if ($null -ne $TestCases -and $TestCases.Count -gt 0) {
        foreach ($testCase in $TestCases) {
            $expandedName = [regex]::Replace($Name, '<([^>]+)>', {
                    $capture = $args[0].Groups[1].Value
                    if ($testCase.Contains($capture)) {
                        $value = $testCase[$capture]
                        
                        
                        if ($value -isnot [string] -or [string]::IsNullOrEmpty($value)) {
                            Format-Nicely $value
                        }
                        else {
                            $value
                        }
                    }
                    else {
                        "<$capture>"
                    }
                })

            $splat = @{
                Name                   = $expandedName
                Scriptblock            = $Test
                Parameters             = $testCase
                ParameterizedSuiteName = $Name
                OutputScriptBlock      = $OutputScriptBlock
            }

            Invoke-Test @splat @pendingSkip
        }
    }
    else {
        Invoke-Test -Name $Name -ScriptBlock $Test @pendingSkip -OutputScriptBlock $OutputScriptBlock
    }
}

function Invoke-Test {
    [CmdletBinding(DefaultParameterSetName = 'Normal')]
    param (
        [Parameter(Mandatory = $true)]
        [string] $Name,

        [Parameter(Mandatory = $true)]
        [ScriptBlock] $ScriptBlock,

        [scriptblock] $OutputScriptBlock,

        [System.Collections.IDictionary] $Parameters,
        [string] $ParameterizedSuiteName,

        [Parameter(ParameterSetName = 'Pending')]
        [Switch] $Pending,

        [Parameter(ParameterSetName = 'Skip')]
        [Alias('Ignore')]
        [Switch] $Skip
    )

    if ($null -eq $Parameters) {
        $Parameters = @{}
    }

    try {
        if ($Skip) {
            $Pester.AddTestResult($Name, "Skipped", $null)
        }
        elseif ($Pending) {
            $Pester.AddTestResult($Name, "Pending", $null)
        }
        else {
            
            

            $errorRecord = $null
            try {
                $pester.EnterTest()
                Invoke-TestCaseSetupBlocks

                do {
                    Write-ScriptBlockInvocationHint -Hint "It" -ScriptBlock $ScriptBlock
                    $null = & $ScriptBlock @Parameters
                } until ($true)
            }
            catch {
                $errorRecord = $_
            }
            finally {
                
                try {
                    if (-not ($Skip -or $Pending)) {
                        Invoke-TestCaseTeardownBlocks
                    }
                }
                catch {
                    $errorRecord = $_
                }

                $pester.LeaveTest()
            }

            $result = ConvertTo-PesterResult -Name $Name -ErrorRecord $errorRecord
            $orderedParameters = Get-OrderedParameterDictionary -ScriptBlock $ScriptBlock -Dictionary $Parameters
            $Pester.AddTestResult( $result.Name, $result.Result, $null, $result.FailureMessage, $result.StackTrace, $ParameterizedSuiteName, $orderedParameters, $result.ErrorRecord )
            
        }
    }
    finally {
        Exit-MockScope -ExitTestCaseOnly
    }

    if ($null -ne $OutputScriptBlock) {
        $Pester.testresult[-1] | & $OutputScriptBlock
    }
}

function Get-OrderedParameterDictionary {
    [OutputType([System.Collections.IDictionary])]
    param (
        [scriptblock] $ScriptBlock,
        [System.Collections.IDictionary] $Dictionary
    )

    $parameters = Get-ParameterDictionary -ScriptBlock $ScriptBlock

    $orderedDictionary = & $SafeCommands['New-Object'] System.Collections.Specialized.OrderedDictionary

    foreach ($parameterName in $parameters.Keys) {
        $value = $null
        if ($Dictionary.ContainsKey($parameterName)) {
            $value = $Dictionary[$parameterName]
        }

        $orderedDictionary[$parameterName] = $value
    }

    return $orderedDictionary
}

function Get-ParameterDictionary {
    param (
        [scriptblock] $ScriptBlock
    )

    $guid = [Guid]::NewGuid().Guid

    try {
        & $SafeCommands['Set-Content'] function:\$guid $ScriptBlock
        $metadata = [System.Management.Automation.CommandMetadata](& $SafeCommands['Get-Command'] -Name $guid -CommandType Function)

        return $metadata.Parameters
    }
    finally {
        if (& $SafeCommands['Test-Path'] function:\$guid) {
            & $SafeCommands['Remove-Item'] function:\$guid
        }
    }
}
