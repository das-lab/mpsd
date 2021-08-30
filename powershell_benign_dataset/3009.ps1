function Mock {

    
    [CmdletBinding()]
    param(
        [string]$CommandName,
        [ScriptBlock]$MockWith = { },
        [switch]$Verifiable,
        [ScriptBlock]$ParameterFilter = { $True },
        [string]$ModuleName,
        [string[]]$RemoveParameterType,
        [string[]]$RemoveParameterValidation
    )

    Assert-DescribeInProgress -CommandName Mock
    Set-ScriptBlockHint -Hint "Unbound MockWith - Captured in Mock" -ScriptBlock $MockWith
    Set-ScriptBlockHint -Hint "Unbound ParameterFilter - Captured in Mock" -ScriptBlock $ParameterFilter

    $contextInfo = Validate-Command $CommandName $ModuleName
    $CommandName = $contextInfo.Command.Name

    if ($contextInfo.Session.Module -and $contextInfo.Session.Module.Name) {
        $ModuleName = $contextInfo.Session.Module.Name
    }
    else {
        $ModuleName = ''
    }

    if (Test-IsClosure -ScriptBlock $MockWith) {
        
        
        $mockWithCopy = $MockWith
    }
    else {
        Write-Hint "Unbinding ScriptBlock from '$(Get-ScriptBlockHint $MockWith)'"
        $mockWithCopy = [scriptblock]::Create($MockWith.ToString())
        Set-ScriptBlockHint -ScriptBlock $mockWithCopy -Hint "Unbound ScriptBlock from Mock"
        Set-ScriptBlockScope -ScriptBlock $mockWithCopy -SessionState $contextInfo.Session
    }

    $block = @{
        Mock       = $mockWithCopy
        Filter     = $ParameterFilter
        Verifiable = $Verifiable
        Scope      = $pester.CurrentTestGroup
    }

    $mock = $mockTable["$ModuleName||$CommandName"]

    if (-not $mock) {
        $metadata = $null
        $originalMetadata = $null
        $cmdletBinding = ''
        $paramBlock = ''
        $dynamicParamBlock = ''
        $dynamicParamScriptBlock = $null

        if ($contextInfo.Command.psobject.Properties['ScriptBlock'] -or $contextInfo.Command.CommandType -eq 'Cmdlet') {
            $metadata = [System.Management.Automation.CommandMetaData]$contextInfo.Command
            $null = $metadata.Parameters.Remove('Verbose')
            $null = $metadata.Parameters.Remove('Debug')
            $null = $metadata.Parameters.Remove('ErrorAction')
            $null = $metadata.Parameters.Remove('WarningAction')
            $null = $metadata.Parameters.Remove('ErrorVariable')
            $null = $metadata.Parameters.Remove('WarningVariable')
            $null = $metadata.Parameters.Remove('OutVariable')
            $null = $metadata.Parameters.Remove('OutBuffer')

            
            
            
            $dynamicParams = $metadata.Parameters.Values | & $SafeCommands['Where-Object'] { $_.IsDynamic }
            if ($null -ne $dynamicParams) {
                $dynamicparams | & $SafeCommands['ForEach-Object'] { $null = $metadata.Parameters.Remove($_.name) }
            }

            $cmdletBinding = [Management.Automation.ProxyCommand]::GetCmdletBindingAttribute($metadata)
            if ($global:PSVersionTable.PSVersion.Major -ge 3 -and $contextInfo.Command.CommandType -eq 'Cmdlet') {
                if ($cmdletBinding -ne '[CmdletBinding()]') {
                    $cmdletBinding = $cmdletBinding.Insert($cmdletBinding.Length - 2, ',')
                }
                $cmdletBinding = $cmdletBinding.Insert($cmdletBinding.Length - 2, 'PositionalBinding=$false')
            }

            
            $originalMetadata = $metadata
            $metadata = Repair-ConflictingParameters -Metadata $metadata -RemoveParameterType $RemoveParameterType -RemoveParameterValidation $RemoveParameterValidation
            $paramBlock = [Management.Automation.ProxyCommand]::GetParamBlock($metadata)

            if ($contextInfo.Command.CommandType -eq 'Cmdlet') {
                $dynamicParamBlock = "dynamicparam { Get-MockDynamicParameter -CmdletName '$($contextInfo.Command.Name)' -Parameters `$PSBoundParameters }"
            }
            else {
                $dynamicParamStatements = Get-DynamicParamBlock -ScriptBlock $contextInfo.Command.ScriptBlock

                if ($dynamicParamStatements -match '\S') {
                    $metadataSafeForDynamicParams = [System.Management.Automation.CommandMetaData]$contextInfo.Command
                    foreach ($param in $metadataSafeForDynamicParams.Parameters.Values) {
                        $param.ParameterSets.Clear()
                    }

                    $paramBlockSafeForDynamicParams = [System.Management.Automation.ProxyCommand]::GetParamBlock($metadataSafeForDynamicParams)
                    $comma = if ($metadataSafeForDynamicParams.Parameters.Count -gt 0) {
                        ','
                    }
                    else {
                        ''
                    }
                    $dynamicParamBlock = "dynamicparam { Get-MockDynamicParameter -ModuleName '$ModuleName' -FunctionName '$CommandName' -Parameters `$PSBoundParameters -Cmdlet `$PSCmdlet }"

                    $code = @"
                        $cmdletBinding
                        param(
                            [object] `${P S Cmdlet}$comma
                            $paramBlockSafeForDynamicParams
                        )

                        `$PSCmdlet = `${P S Cmdlet}

                        $dynamicParamStatements
"@

                    $dynamicParamScriptBlock = [scriptblock]::Create($code)

                    $sessionStateInternal = Get-ScriptBlockScope -ScriptBlock $contextInfo.Command.ScriptBlock

                    if ($null -ne $sessionStateInternal) {
                        Set-ScriptBlockScope -ScriptBlock $dynamicParamScriptBlock -SessionStateInternal $sessionStateInternal
                    }
                }
            }
        }

        $EscapeSingleQuotedStringContent =
        if ($global:PSVersionTable.PSVersion.Major -ge 5) {
            { [System.Management.Automation.Language.CodeGeneration]::EscapeSingleQuotedStringContent($args[0]) }
        }
        else {
            { $args[0] -replace "['‘’‚‛]", '$&$&' }
        }

        $newContent = & $SafeCommands['Get-Content'] function:\MockPrototype
        $newContent = $newContent -replace '
        $newContent = $newContent -replace '

        $canCaptureArgs = 'true'
        if ($contextInfo.Command.CommandType -eq 'Cmdlet' -or
            ($contextInfo.Command.CommandType -eq 'Function' -and $contextInfo.Command.CmdletBinding)) {
            $canCaptureArgs = 'false'
        }
        $newContent = $newContent -replace '

        $code = @"
            $cmdletBinding
            param ( $paramBlock )
            $dynamicParamBlock
            begin
            {
                `${mock call state} = @{}
                $($newContent -replace '
            }

            process
            {
                $($newContent -replace '
            }

            end
            {
                $($newContent -replace '
            }
"@

        $mockScript = [scriptblock]::Create($code)

        $mock = @{
            OriginalCommand         = $contextInfo.Command
            Blocks                  = @()
            CommandName             = $CommandName
            SessionState            = $contextInfo.Session
            Scope                   = $pester.CurrentTestGroup
            PesterState             = $pester
            Metadata                = $metadata
            OriginalMetadata        = $originalMetadata
            CallHistory             = @()
            DynamicParamScriptBlock = $dynamicParamScriptBlock
            Aliases                 = @()
            BootstrapFunctionName   = 'PesterMock_' + [Guid]::NewGuid().Guid
        }

        $mockTable["$ModuleName||$CommandName"] = $mock

        Invoke-CommonSetupInMockScope -Mock $mock -MockScript $MockScript -CommandName $CommandName
    }

    if ($null -ne $mock.Metadata -and $null -ne $block.Filter) {
        $block.Filter = New-BlockWithoutParameterAliases -Metadata $mock.Metadata -Block $block.Filter
    }

    $mock.Blocks = @(
        
        
        
        $mock.Blocks | & $SafeCommands['Where-Object'] { $_.Filter.ToString().Trim() -eq '$True' }
        if ($block.Filter.ToString().Trim() -eq '$True') {
            $block
        }

        $mock.Blocks | & $SafeCommands['Where-Object'] { $_.Filter.ToString().Trim() -ne '$True' }
        if ($block.Filter.ToString().Trim() -ne '$True') {
            $block
        }
    )
}


function Assert-VerifiableMock {
    
    [CmdletBinding()]param()
    Assert-DescribeInProgress -CommandName Assert-VerifiableMock

    $unVerified = @{ }
    $mockTable.Keys | & $SafeCommands['ForEach-Object'] {
        $m = $_;

        $mockTable[$m].blocks |
        & $SafeCommands['Where-Object'] { $_.Verifiable } |
        & $SafeCommands['ForEach-Object'] { $unVerified[$m] = $_ }
    }
    if ($unVerified.Count -gt 0) {
        foreach ($mock in $unVerified.Keys) {
            $array = $mock -split '\|\|'
            $function = $array[1]
            $module = $array[0]

            $message = "$([System.Environment]::NewLine) Expected $function "
            if ($module) {
                $message += "in module $module "
            }
            $message += "to be called with $($unVerified[$mock].Filter)"
        }
        throw $message
    }
}

function Assert-MockCalled {
    

    [CmdletBinding(DefaultParameterSetName = 'ParameterFilter')]
    param(
        [Parameter(Mandatory = $true, Position = 0)]
        [string]$CommandName,

        [Parameter(Position = 1)]
        [int]$Times = 1,

        [Parameter(ParameterSetName = 'ParameterFilter', Position = 2)]
        [ScriptBlock]$ParameterFilter = { $True },

        [Parameter(ParameterSetName = 'ExclusiveFilter', Mandatory = $true)]
        [scriptblock] $ExclusiveFilter,

        [Parameter(Position = 3)]
        [string] $ModuleName,

        [Parameter(Position = 4)]
        [ValidateScript( {
                if ([uint32]::TryParse($_, [ref] $null) -or
                    $_ -eq 'Describe' -or
                    $_ -eq 'Context' -or
                    $_ -eq 'It' -or
                    $_ -eq 'Feature' -or
                    $_ -eq 'Scenario') {
                    return $true
                }

                throw "Scope argument must either be an unsigned integer, or one of the words 'Describe', 'Context', 'It', 'Feature', or 'Scenario'."
            })]
        [string] $Scope,

        [switch]$Exactly
    )

    if ($PSCmdlet.ParameterSetName -eq 'ParameterFilter') {
        $filter = $ParameterFilter
        $filterIsExclusive = $false
    }
    else {
        $filter = $ExclusiveFilter
        $filterIsExclusive = $true
    }

    Assert-DescribeInProgress -CommandName Assert-MockCalled

    if (-not $PSBoundParameters.ContainsKey('ModuleName') -and $null -ne $pester.SessionState.Module) {
        $ModuleName = $pester.SessionState.Module.Name
    }

    $contextInfo = Validate-Command $CommandName $ModuleName
    $CommandName = $contextInfo.Command.Name

    $mock = $script:mockTable["$ModuleName||$CommandName"]

    $moduleMessage = ''
    if ($ModuleName) {
        $moduleMessage = " in module $ModuleName"
    }

    if (-not $mock) {
        throw "You did not declare a mock of the $commandName Command${moduleMessage}."
    }

    if (-not $PSBoundParameters.ContainsKey('Scope')) {
        $scope = 1
    }

    $matchingCalls = & $SafeCommands['New-Object'] System.Collections.ArrayList
    $nonMatchingCalls = & $SafeCommands['New-Object'] System.Collections.ArrayList

    foreach ($historyEntry in $mock.CallHistory) {
        if (-not (Test-MockCallScope -CallScope $historyEntry.Scope -DesiredScope $Scope)) {
            continue
        }

        $params = @{
            ScriptBlock     = $filter
            BoundParameters = $historyEntry.BoundParams
            ArgumentList    = $historyEntry.Args
            Metadata        = $mock.Metadata
        }

        if ($null -ne $mock.Metadata -and $null -ne $params.ScriptBlock) {
            $params.ScriptBlock = New-BlockWithoutParameterAliases -Metadata $mock.Metadata -Block $params.ScriptBlock
        }

        if (Test-ParameterFilter @params) {
            $null = $matchingCalls.Add($historyEntry)
        }
        else {
            $null = $nonMatchingCalls.Add($historyEntry)
        }
    }

    $lineText = $MyInvocation.Line.TrimEnd("$([System.Environment]::NewLine)")
    $line = $MyInvocation.ScriptLineNumber

    if ($matchingCalls.Count -ne $times -and ($Exactly -or ($times -eq 0))) {
        $failureMessage = "Expected ${commandName}${moduleMessage} to be called $times times exactly but was called $($matchingCalls.Count) times"
        throw ( New-ShouldErrorRecord -Message $failureMessage -Line $line -LineText $lineText)
    }
    elseif ($matchingCalls.Count -lt $times) {
        $failureMessage = "Expected ${commandName}${moduleMessage} to be called at least $times times but was called $($matchingCalls.Count) times"
        throw ( New-ShouldErrorRecord -Message $failureMessage -Line $line -LineText $lineText)
    }
    elseif ($filterIsExclusive -and $nonMatchingCalls.Count -gt 0) {
        $failureMessage = "Expected ${commandName}${moduleMessage} to only be called with with parameters matching the specified filter, but $($nonMatchingCalls.Count) non-matching calls were made"
        throw ( New-ShouldErrorRecord -Message $failureMessage -Line $line -LineText $lineText)
    }
}

function Test-MockCallScope {
    [CmdletBinding()]
    param (
        [object] $CallScope,
        [string] $DesiredScope
    )

    if ($null -eq $CallScope) {
        
        return $true
    }

    $testGroups = $pester.TestGroups
    [Array]::Reverse($testGroups)

    $target = 0
    $isNumberedScope = [int]::TryParse($DesiredScope, [ref] $target)

    
    $actualScopeNumber = -1
    $describe = -1
    $context = -1

    for ($i = 0; $i -lt $testGroups.Count; $i++) {
        if ($CallScope -eq $testGroups[$i]) {
            $actualScopeNumber = $i
            if ($isNumberedScope) {
                break
            }
        }

        if ($describe -lt 0 -and 'Describe', 'Feature' -contains $testGroups[$i].Hint) {
            $describe = $i
        }
        if ($context -lt 0 -and 'Context', 'Scenario' -contains $testGroups[$i].Hint) {
            $context = $i
        }
    }

    if ($actualScopeNumber -lt 0) {
        

        throw "Pester error: Corrupted mock call history table."
    }

    if ($isNumberedScope) {
        
        
        
        return $target -gt $actualScopeNumber
    }
    else {
        if ('Describe', 'Feature' -contains $DesiredScope) {
            return $describe -ge $actualScopeNumber
        }
        if ('Context', 'Scenario' -contains $DesiredScope) {
            return $context -ge $actualScopeNumber
        }
    }

    return $false
}

function Exit-MockScope {
    param (
        [switch] $ExitTestCaseOnly
    )

    if ($null -eq $mockTable) {
        return
    }

    $removeMockStub =
    {
        param (
            [string] $CommandName,
            [string[]] $Aliases
        )

        if ($ExecutionContext.InvokeProvider.Item.Exists("Function:\$CommandName", $true, $true)) {
            $ExecutionContext.InvokeProvider.Item.Remove("Function:\$CommandName", $false, $true, $true)
        }

        foreach ($alias in $Aliases) {
            if ($ExecutionContext.InvokeProvider.Item.Exists("Alias:$alias", $true, $true)) {
                $ExecutionContext.InvokeProvider.Item.Remove("Alias:$alias", $false, $true, $true)
            }
        }
    }

    $mockKeys = [string[]]$mockTable.Keys

    foreach ($mockKey in $mockKeys) {
        $mock = $mockTable[$mockKey]

        $shouldRemoveMock = (-not $ExitTestCaseOnly) -and (ShouldRemoveMock -Mock $mock -ActivePesterState $pester)
        if ($shouldRemoveMock) {
            $null = Invoke-InMockScope -SessionState $mock.SessionState -ScriptBlock $removeMockStub -ArgumentList $mock.BootstrapFunctionName, $mock.Aliases
            $mockTable.Remove($mockKey)
        }
        elseif ($mock.PesterState -eq $pester) {
            if (-not $ExitTestCaseOnly) {
                $mock.Blocks = @($mock.Blocks | & $SafeCommands['Where-Object'] { $_.Scope -ne $pester.CurrentTestGroup })
            }

            $testGroups = @($pester.TestGroups)

            $parentTestGroup = $null

            if ($testGroups.Count -gt 1) {
                $parentTestGroup = $testGroups[-2]
            }

            foreach ($historyEntry in $mock.CallHistory) {
                if ($ExitTestCaseOnly) {
                    if ($null -eq $historyEntry.Scope) {
                        $historyEntry.Scope = $pester.CurrentTestGroup
                    }
                }
                elseif ($parentTestGroup) {
                    if ($historyEntry.Scope -eq $pester.CurrentTestGroup) {
                        $historyEntry.Scope = $parentTestGroup
                    }
                }
            }
        }
    }
}

function ShouldRemoveMock($Mock, $ActivePesterState) {
    if ($ActivePesterState -ne $mock.PesterState) {
        return $false
    }
    if ($mock.Scope -eq $ActivePesterState.CurrentTestGroup) {
        return $true
    }

    
    
    if ($ActivePesterState.TestGroups.Count -eq 1) {
        return $true
    }
    if ($ActivePesterState.TestGroups[-2].Hint -eq 'Root') {
        return $true
    }

    return $false
}

function Validate-Command([string]$CommandName, [string]$ModuleName) {
    $module = $null
    $command = $null

    $scriptBlock = {
        $command = $ExecutionContext.InvokeCommand.GetCommand($args[0], 'All')
        while ($null -ne $command -and $command.CommandType -eq [System.Management.Automation.CommandTypes]::Alias) {
            $command = $command.ResolvedCommand
        }

        return $command
    }

    if ($ModuleName) {
        $module = Get-ScriptModule -ModuleName $ModuleName -ErrorAction Stop
        $command = & $module $scriptBlock $CommandName
    }

    $session = $pester.SessionState

    if (-not $command) {
        Set-ScriptBlockScope -ScriptBlock $scriptBlock -SessionState $session
        $command = & $scriptBlock $commandName
    }

    if (-not $command) {
        throw ([System.Management.Automation.CommandNotFoundException] "Could not find Command $commandName")
    }

    if ($module) {
        $session = Set-SessionStateHint -PassThru  -Hint "Module - $($module.Name)" -SessionState ( & $module { $ExecutionContext.SessionState } )
    }

    $hash = @{Command = $command; Session = $session }

    if ($command.CommandType -eq 'Function') {
        foreach ($mock in $mockTable.Values) {
            if ($command.Name -eq $mock.BootstrapFunctionName) {
                return @{
                    Command = $mock.OriginalCommand
                    Session = $mock.SessionState
                }
            }
        }
    }

    return $hash
}

function MockPrototype {
    if ($PSVersionTable.PSVersion.Major -ge 3) {
        [string] ${ignore preference} = 'Ignore'
    }
    else {
        [string] ${ignore preference} = 'SilentlyContinue'
    }

    
    ${get Variable Command} = & (Pester\SafeGetCommand) -Name Get-Variable -Module Microsoft.PowerShell.Utility -CommandType Cmdlet

    [object] ${a r g s} = $null
    if (${
        ${a r g s} = & ${get Variable Command} -Name args -ValueOnly -Scope Local -ErrorAction ${ignore preference}
    }
    if ($null -eq ${a r g s}) {
        ${a r g s} = @()
    }

    ${p s cmdlet} = & ${get Variable Command} -Name PSCmdlet -ValueOnly -Scope Local -ErrorAction ${ignore preference}

    
    ${session state} = if (${p s cmdlet}) {
        ${p s cmdlet}.SessionState
    }

    
    
    Invoke-Mock -CommandName '
}

function Invoke-Mock {
    

    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]
        $CommandName,

        [Parameter(Mandatory = $true)]
        [hashtable] $MockCallState,

        [string]
        $ModuleName,

        [hashtable]
        $BoundParameters = @{ },

        [object[]]
        $ArgumentList = @(),

        [object] $CallerSessionState,

        [ValidateSet('Begin', 'Process', 'End')]
        [string] $FromBlock,

        [object] $InputObject
    )

    $detectedModule = $ModuleName
    $mock = FindMock -CommandName $CommandName -ModuleName ([ref]$detectedModule)

    if ($null -eq $mock) {
        
        throw "Internal error detected:  Mock for '$CommandName' in module '$ModuleName' was called, but does not exist in the mock table."
    }

    switch ($FromBlock) {
        Begin {
            $MockCallState['InputObjects'] = & $SafeCommands['New-Object'] System.Collections.ArrayList
            $MockCallState['ShouldExecuteOriginalCommand'] = $false
            $MockCallState['BeginBoundParameters'] = $BoundParameters.Clone()
            $MockCallState['BeginArgumentList'] = $ArgumentList

            return
        }

        Process {
            $block = $null
            if ($detectedModule -eq $ModuleName) {
                $block = FindMatchingBlock -Mock $mock -BoundParameters $BoundParameters -ArgumentList $ArgumentList
            }

            if ($null -ne $block) {
                ExecuteBlock -Block $block `
                    -CommandName $CommandName `
                    -ModuleName $ModuleName `
                    -BoundParameters $BoundParameters `
                    -ArgumentList $ArgumentList `
                    -Mock $mock

                return
            }
            else {
                $MockCallState['ShouldExecuteOriginalCommand'] = $true
                if ($null -ne $InputObject) {
                    $null = $MockCallState['InputObjects'].AddRange(@($InputObject))
                }

                return
            }
        }

        End {
            if ($MockCallState['ShouldExecuteOriginalCommand']) {
                $MockCallState['BeginBoundParameters'] = Reset-ConflictingParameters -BoundParameters $MockCallState['BeginBoundParameters']

                if ($MockCallState['InputObjects'].Count -gt 0) {
                    $scriptBlock = {
                        param ($Command, $ArgumentList, $BoundParameters, $InputObjects)
                        $InputObjects | & $Command @ArgumentList @BoundParameters
                    }
                }
                else {
                    $scriptBlock = {
                        param ($Command, $ArgumentList, $BoundParameters, $InputObjects)
                        & $Command @ArgumentList @BoundParameters
                    }
                }

                $state = if ($CallerSessionState) {
                    $CallerSessionState
                }
                else {
                    $mock.SessionState
                }

                Set-ScriptBlockScope -ScriptBlock $scriptBlock -SessionState $state

                
                
                if ( $mock.OriginalCommand -like "Set-Variable" ) {
                    if ($MockCallState['BeginBoundParameters'].Keys -notcontains "Scope") {
                        $MockCallState['BeginBoundParameters'].Add( "Scope", 2)
                    }
                    
                    elseif ("Local", "0" -contains $MockCallState['BeginBoundParameters'].Scope) {
                        $MockCallState['BeginBoundParameters'].Scope = 2
                    }
                    elseif ($MockCallState['BeginBoundParameters'].Scope -match "\d+") {
                        $MockCallState['BeginBoundParameters'].Scope = 2 + $matches[0]
                    }
                    else {
                        
                    }
                }

                Write-ScriptBlockInvocationHint -Hint "Mock - Original Command" -ScriptBlock $scriptBlock
                & $scriptBlock -Command $mock.OriginalCommand `
                    -ArgumentList $MockCallState['BeginArgumentList'] `
                    -BoundParameters $MockCallState['BeginBoundParameters'] `
                    -InputObjects $MockCallState['InputObjects']
            }
        }
    }
}

function FindMock {
    param (
        [string] $CommandName,
        [ref] $ModuleName
    )

    $mock = $mockTable["$($ModuleName.Value)||$CommandName"]

    if ($null -eq $mock) {
        $mock = $mockTable["||$CommandName"]
        if ($null -ne $mock) {
            $ModuleName.Value = ''
        }
    }

    return $mock
}

function FindMatchingBlock {
    param (
        [object] $Mock,
        [hashtable] $BoundParameters = @{ },
        [object[]] $ArgumentList = @()
    )

    for ($idx = $mock.Blocks.Length; $idx -gt 0; $idx--) {
        $block = $mock.Blocks[$idx - 1]

        $params = @{
            ScriptBlock     = $block.Filter
            BoundParameters = $BoundParameters
            ArgumentList    = $ArgumentList
            Metadata        = $mock.Metadata
        }

        if (Test-ParameterFilter @params) {
            return $block
        }
    }

    return $null
}

function ExecuteBlock {
    param (
        [object] $Block,
        [object] $Mock,
        [string] $CommandName,
        [string] $ModuleName,
        [hashtable] $BoundParameters = @{ },
        [object[]] $ArgumentList = @()
    )

    $Block.Verifiable = $false

    $scope = if ($pester.InTest) {
        $null
    }
    else {
        $pester.CurrentTestGroup
    }
    $Mock.CallHistory += @{CommandName = "$ModuleName||$CommandName"; BoundParams = $BoundParameters; Args = $ArgumentList; Scope = $scope }

    $scriptBlock = {
        param (
            [Parameter(Mandatory = $true)]
            [scriptblock]
            ${Script Block},

            [hashtable]
            $___BoundParameters___ = @{ },

            [object[]]
            $___ArgumentList___ = @(),

            [System.Management.Automation.CommandMetadata]
            ${Meta data},

            [System.Management.Automation.SessionState]
            ${Session State},

            ${R e p o r t S c o p e},

            ${M o d u l e N a m e}
        )

        
        
        
        
        
        

        Set-DynamicParameterVariable -SessionState ${Session State} -Parameters $___BoundParameters___ -Metadata ${Meta data}
        
        & ${R e p o r t S c o p e} -ModuleName ${M o d u l e N a m e} -CommandName $(try {
                ${Meta data}.Name
            }
            catch {
            }) -ScriptBlock ${Script Block}
        & ${Script Block} @___BoundParameters___ @___ArgumentList___
    }

    Set-ScriptBlockScope -ScriptBlock $scriptBlock -SessionState $mock.SessionState
    $splat = @{
        'Script Block'          = $block.Mock
        '___ArgumentList___'    = $ArgumentList
        '___BoundParameters___' = $BoundParameters
        'Meta data'             = $mock.Metadata
        'Session State'         = $mock.SessionState
        'R e p o r t S c o p e' = { param ($CommandName, $ModuleName, $ScriptBlock)
            Write-ScriptBlockInvocationHint -Hint "Mock - of command $CommandName$(if ($ModuleName) { "from module $ModuleName"})" -ScriptBlock $ScriptBlock }
    }

    

    Write-ScriptBlockInvocationHint -Hint "Mock - of command $CommandName$(if ($ModuleName) { "from module $ModuleName"})" -ScriptBlock ($block.Mock)
    & $scriptBlock @splat
}

function Invoke-InMockScope {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [System.Management.Automation.SessionState]
        $SessionState,

        [Parameter(Mandatory = $true)]
        [scriptblock]
        $ScriptBlock,

        [Parameter(ValueFromRemainingArguments = $true)]
        [object[]]
        $ArgumentList = @()
    )

    if ($SessionState.Module) {
        $SessionState.Module.Invoke($ScriptBlock, $ArgumentList)
    }
    else {
        Set-ScriptBlockScope -ScriptBlock $ScriptBlock -SessionState $SessionState
        Write-ScriptBlockInvocationHint -Hint "Mock - InMockScope" -ScriptBlock $ScriptBlock
        & $ScriptBlock @ArgumentList
    }
}

function Test-ParameterFilter {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [scriptblock]
        $ScriptBlock,

        [System.Collections.IDictionary]
        $BoundParameters,

        [object[]]
        $ArgumentList,

        [System.Management.Automation.CommandMetadata]
        $Metadata
    )

    if ($null -eq $BoundParameters) {
        $BoundParameters = @{ }
    }
    if ($null -eq $ArgumentList) {
        $ArgumentList = @()
    }

    $paramBlock = Get-ParamBlockFromBoundParameters -BoundParameters $BoundParameters -Metadata $Metadata

    $scriptBlockString = "
        $paramBlock

        Set-StrictMode -Off
        $ScriptBlock
    "
    Write-Hint "Unbinding ScriptBlock from '$(Get-ScriptBlockHint $ScriptBlock)'"
    $cmd = [scriptblock]::Create($scriptBlockString)
    Set-ScriptBlockHint -ScriptBlock $cmd -Hint "Unbound ScriptBlock from Test-ParameterFilter"
    Set-ScriptBlockScope -ScriptBlock $cmd -SessionState $pester.SessionState

    Write-ScriptBlockInvocationHint -Hint "Mock - Parameter filter" -ScriptBlock $cmd
    & $cmd @BoundParameters @ArgumentList
}

function Get-ParamBlockFromBoundParameters {
    param (
        [System.Collections.IDictionary] $BoundParameters,
        [System.Management.Automation.CommandMetadata] $Metadata
    )

    $params = foreach ($paramName in $BoundParameters.get_Keys()) {
        if (IsCommonParameter -Name $paramName -Metadata $Metadata) {
            continue
        }

        "`${$paramName}"
    }

    $params = $params -join ','

    if ($null -ne $Metadata) {
        $cmdletBinding = [System.Management.Automation.ProxyCommand]::GetCmdletBindingAttribute($Metadata)
    }
    else {
        $cmdletBinding = ''
    }

    return "$cmdletBinding param ($params)"
}

function IsCommonParameter {
    param (
        [string] $Name,
        [System.Management.Automation.CommandMetadata] $Metadata
    )

    if ($null -ne $Metadata) {
        if ([System.Management.Automation.Internal.CommonParameters].GetProperty($Name)) {
            return $true
        }
        if ($Metadata.SupportsShouldProcess -and [System.Management.Automation.Internal.ShouldProcessParameters].GetProperty($Name)) {
            return $true
        }
        if ($PSVersionTable.PSVersion.Major -ge 3 -and $Metadata.SupportsPaging -and [System.Management.Automation.PagingParameters].GetProperty($Name)) {
            return $true
        }
        if ($Metadata.SupportsTransactions -and [System.Management.Automation.Internal.TransactionParameters].GetProperty($Name)) {
            return $true
        }
    }

    return $false
}

function Set-DynamicParameterVariable {
    

    param (
        [Parameter(Mandatory = $true)]
        [System.Management.Automation.SessionState]
        $SessionState,

        [hashtable]
        $Parameters,

        [System.Management.Automation.CommandMetadata]
        $Metadata
    )

    if ($null -eq $Parameters) {
        $Parameters = @{ }
    }

    foreach ($keyValuePair in $Parameters.GetEnumerator()) {
        $variableName = $keyValuePair.Key

        if (-not (IsCommonParameter -Name $variableName -Metadata $Metadata)) {
            if ($ExecutionContext.SessionState -eq $SessionState) {
                & $SafeCommands['Set-Variable'] -Scope 1 -Name $variableName -Value $keyValuePair.Value -Force -Confirm:$false -WhatIf:$false
            }
            else {
                $SessionState.PSVariable.Set($variableName, $keyValuePair.Value)
            }
        }
    }
}

function Get-DynamicParamBlock {
    param (
        [scriptblock] $ScriptBlock
    )

    if ($PSVersionTable.PSVersion.Major -le 2) {
        $flags = [System.Reflection.BindingFlags]'Instance, NonPublic'
        $dynamicParams = [scriptblock].GetField('_dynamicParams', $flags).GetValue($ScriptBlock)

        if ($null -ne $dynamicParams) {
            return $dynamicParams.ToString()

        }
    }
    else {
        If ( $ScriptBlock.AST.psobject.Properties.Name -match "Body") {
            if ($null -ne $ScriptBlock.Ast.Body.DynamicParamBlock) {
                $statements = $ScriptBlock.Ast.Body.DynamicParamBlock.Statements |
                & $SafeCommands['Select-Object'] -ExpandProperty Extent |
                & $SafeCommands['Select-Object'] -ExpandProperty Text

                return $statements -join "$([System.Environment]::NewLine)"
            }
        }
    }
}

function Get-MockDynamicParameter {
    

    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, ParameterSetName = 'Cmdlet')]
        [string] $CmdletName,

        [Parameter(Mandatory = $true, ParameterSetName = 'Function')]
        [string] $FunctionName,

        [Parameter(ParameterSetName = 'Function')]
        [string] $ModuleName,

        [System.Collections.IDictionary] $Parameters,

        [object] $Cmdlet
    )

    switch ($PSCmdlet.ParameterSetName) {
        'Cmdlet' {
            Get-DynamicParametersForCmdlet -CmdletName $CmdletName -Parameters $Parameters
        }

        'Function' {
            Get-DynamicParametersForMockedFunction -FunctionName $FunctionName -ModuleName $ModuleName -Parameters $Parameters -Cmdlet $Cmdlet
        }
    }
}

function Get-DynamicParametersForCmdlet {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string] $CmdletName,

        [ValidateScript( {
                if ($PSVersionTable.PSVersion.Major -ge 3 -and
                    $null -ne $_ -and
                    $_.GetType().FullName -ne 'System.Management.Automation.PSBoundParametersDictionary') {
                    throw 'The -Parameters argument must be a PSBoundParametersDictionary object ($PSBoundParameters).'
                }

                return $true
            })]
        [System.Collections.IDictionary] $Parameters
    )

    try {
        $command = & $SafeCommands['Get-Command'] -Name $CmdletName -CommandType Cmdlet -ErrorAction Stop

        if (@($command).Count -gt 1) {
            throw "Name '$CmdletName' resolved to multiple Cmdlets"
        }
    }
    catch {
        $PSCmdlet.ThrowTerminatingError($_)
    }

    if ($null -eq $command.ImplementingType.GetInterface('IDynamicParameters', $true)) {
        return
    }

    if ('5.0.10586.122' -lt $PSVersionTable.PSVersion) {
        
        

        if ($null -eq $Parameters) {
            $paramsArg = @()
        }
        else {
            $paramsArg = @($Parameters)
        }

        $command = $ExecutionContext.InvokeCommand.GetCommand($CmdletName, [System.Management.Automation.CommandTypes]::Cmdlet, $paramsArg)
        $paramDictionary = [System.Management.Automation.RuntimeDefinedParameterDictionary]::new()

        foreach ($param in $command.Parameters.Values) {
            if (-not $param.IsDynamic) {
                continue
            }
            if ($Parameters.ContainsKey($param.Name)) {
                continue
            }

            $dynParam = [System.Management.Automation.RuntimeDefinedParameter]::new($param.Name, $param.ParameterType, $param.Attributes)
            $paramDictionary.Add($param.Name, $dynParam)
        }

        return $paramDictionary
    }
    else {
        if ($null -eq $Parameters) {
            $Parameters = @{ }
        }

        $cmdlet = & $SafeCommands['New-Object'] $command.ImplementingType.FullName

        $flags = [System.Reflection.BindingFlags]'Instance, Nonpublic'
        $context = $ExecutionContext.GetType().GetField('_context', $flags).GetValue($ExecutionContext)
        [System.Management.Automation.Cmdlet].GetProperty('Context', $flags).SetValue($cmdlet, $context, $null)

        foreach ($keyValuePair in $Parameters.GetEnumerator()) {
            $property = $cmdlet.GetType().GetProperty($keyValuePair.Key)
            if ($null -eq $property -or -not $property.CanWrite) {
                continue
            }

            $isParameter = [bool]($property.GetCustomAttributes([System.Management.Automation.ParameterAttribute], $true))
            if (-not $isParameter) {
                continue
            }

            $property.SetValue($cmdlet, $keyValuePair.Value, $null)
        }

        try {
            
            
            

            
            
            

            
            

            , $cmdlet.GetDynamicParameters()
        }
        catch [System.NotImplementedException] {
            
        }
    }
}

function Get-DynamicParametersForMockedFunction {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]
        $FunctionName,

        [string]
        $ModuleName,

        [System.Collections.IDictionary]
        $Parameters,

        [object]
        $Cmdlet
    )

    $mock = $mockTable["$ModuleName||$FunctionName"]

    if (-not $mock) {
        throw "Internal error detected:  Mock for '$FunctionName' in module '$ModuleName' was called, but does not exist in the mock table."
    }

    if ($mock.DynamicParamScriptBlock) {
        $splat = @{ 'P S Cmdlet' = $Cmdlet }
        return & $mock.DynamicParamScriptBlock @Parameters @splat
    }
}

function Test-IsClosure {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [scriptblock]
        $ScriptBlock
    )

    $sessionStateInternal = Get-ScriptBlockScope -ScriptBlock $ScriptBlock
    if ($null -eq $sessionStateInternal) {
        return $false
    }

    $flags = [System.Reflection.BindingFlags]'Instance,NonPublic'
    $module = $sessionStateInternal.GetType().GetProperty('Module', $flags).GetValue($sessionStateInternal, $null)

    return (
        $null -ne $module -and
        $module.Name -match '^__DynamicModule_([a-f\d-]+)$' -and
        $null -ne ($matches[1] -as [guid])
    )
}

function Remove-MockFunctionsAndAliases {
    
    
    
    
    
    
    
    foreach ($alias in (& $script:SafeCommands['Get-Alias'] -Definition "PesterMock_*")) {
        & $script:SafeCommands['Remove-Item'] "alias:/$($alias.Name)"
    }

    foreach ($bootstrapFunction in (& $script:SafeCommands['Get-Command'] -Name "PesterMock_*")) {
        & $script:SafeCommands['Remove-Item'] "function:/$($bootstrapFunction.Name)"
    }
}

function Repair-ConflictingParameters {
    [CmdletBinding()]
    [OutputType([System.Management.Automation.CommandMetadata])]
    param(
        [Parameter(Mandatory = $true)]
        [System.Management.Automation.CommandMetadata]
        $Metadata,
        [Parameter()]
        [string[]]
        $RemoveParameterType,
        [Parameter()]
        [string[]]
        $RemoveParameterValidation
    )

    $repairedMetadata = New-Object System.Management.Automation.CommandMetadata -ArgumentList $Metadata
    $paramMetadatas = @()
    $paramMetadatas += $repairedMetadata.Parameters.Values

    $conflictingParams = Get-ConflictingParameterNames

    foreach ($paramMetadata in $paramMetadatas) {
        if ($paramMetadata.IsDynamic) {
            continue
        }

        if ($conflictingParams -contains $paramMetadata.Name) {
            $paramName = $paramMetadata.Name
            $newName = "_$paramName"
            $paramMetadata.Name = $newName
            $paramMetadata.Aliases.Add($paramName)

            $null = $repairedMetadata.Parameters.Remove($paramName)
            $repairedMetadata.Parameters.Add($newName, $paramMetadata)
        }

        $attrIndexesToRemove = New-Object System.Collections.ArrayList

        if ($RemoveParameterType -contains $paramMetadata.Name) {
            $paramMetadata.ParameterType = [object]

            for ($i = 0; $i -lt $paramMetadata.Attributes.Count; $i++) {
                $attr = $paramMetadata.Attributes[$i]
                if ($attr -is [PSTypeNameAttribute]) {
                    $null = $attrIndexesToRemove.Add($i)
                    break
                }
            }
        }

        if ($RemoveParameterValidation -contains $paramMetadata.Name) {
            for ($i = 0; $i -lt $paramMetadata.Attributes.Count; $i++) {
                $attr = $paramMetadata.Attributes[$i]
                if ($attr -is [System.Management.Automation.ValidateArgumentsAttribute]) {
                    $null = $attrIndexesToRemove.Add($i)
                }
            }
        }

        foreach ($index in $attrIndexesToRemove) {
            $null = $paramMetadata.Attributes.RemoveAt($index)
        }
    }

    $repairedMetadata
}

function Reset-ConflictingParameters {
    [CmdletBinding()]
    [OutputType([hashtable])]
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]
        $BoundParameters
    )

    $parameters = $BoundParameters.Clone()
    $names = Get-ConflictingParameterNames

    foreach ($param in $names) {
        $fixedName = "_$param"

        if (-not $parameters.ContainsKey($fixedName)) {
            continue
        }

        $parameters[$param] = $parameters[$fixedName]
        $null = $parameters.Remove($fixedName)
    }

    $parameters
}

function Get-ConflictingParameterNames {
    $script:ConflictingParameterNames
}

function Initialize-ConflictingParameterNames {
    foreach ($var in (& $script:SafeCommands['Get-Variable'])) {
        if (($var.Options -band [System.Management.Automation.ScopedItemOptions]::Constant) -or ($var.Options -band [System.Management.Automation.ScopedItemOptions]::ReadOnly)) {
            $var.Name
        }
    }
}

function Get-ScriptBlockAST {
    param (
        [scriptblock]
        $ScriptBlock
    )

    if ($ScriptBlock.Ast -is [System.Management.Automation.Language.ScriptBlockAst]) {
        $ast = $Block.Ast.EndBlock
    }
    elseif ($ScriptBlock.Ast -is [System.Management.Automation.Language.FunctionDefinitionAst]) {
        $ast = $Block.Ast.Body.EndBlock
    }
    else {
        throw "Pester failed to parse ParameterFilter, scriptblock is invalid type. Please reformat your ParameterFilter."
    }

    return $ast
}

function New-BlockWithoutParameterAliases {
    [CmdletBinding()]
    [OutputType([scriptblock])]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNull()]
        [System.Management.Automation.CommandMetadata]
        $Metadata,
        [Parameter(Mandatory = $true)]
        [ValidateNotNull()]
        [scriptblock]
        $Block
    )
    try {
        if ($PSVersionTable.PSVersion.Major -ge 3) {
            $params = $Metadata.Parameters.Values
            $ast = Get-ScriptBlockAST $Block
            $blockText = $ast.Extent.Text
            $variables = [array]($Ast.FindAll( { param($ast) $ast -is [System.Management.Automation.Language.VariableExpressionAst] }, $true))
            [array]::Reverse($variables)

            foreach ($var in $variables) {
                $varName = $var.VariablePath.UserPath
                $length = $varName.Length

                foreach ($param in $params) {
                    if ($param.Aliases -contains $varName) {
                        $startIndex = $var.Extent.StartOffset - $ast.Extent.StartOffset + 1 

                        $blockText = $blockText.Remove($startIndex, $length).Insert($startIndex, $param.Name)

                        break 
                    }
                }
            }

            $Block = [scriptblock]::Create($blockText)
        }

        $Block
    }
    catch {
        $PSCmdlet.ThrowTerminatingError($_)
    }
}

function Invoke-CommonSetupInMockScope {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNull()]
        [hashtable]
        $Mock,
        [Parameter(Mandatory = $true)]
        [ValidateNotNull()]
        [scriptblock]
        $MockScript,
        [Parameter(Mandatory = $true)]
        [ValidateNotNull()]
        [string]
        $CommandName
    )
    try {
        $scriptBlock = { $ExecutionContext.InvokeProvider.Item.Set("Function:\script:$($args[0])", $args[1], $true, $true) }
        $null = Invoke-InMockScope -SessionState $Mock.SessionState -ScriptBlock $scriptBlock -ArgumentList $Mock.BootstrapFunctionName, $MockScript

        $mock.Aliases += $CommandName

        $scriptBlock = {
            $setAlias = & (Pester\SafeGetCommand) -Name Set-Alias -CommandType Cmdlet -Module Microsoft.PowerShell.Utility
            & $setAlias -Name $args[0] -Value $args[1] -Scope Script
        }

        $null = Invoke-InMockScope -SessionState $Mock.SessionState -ScriptBlock $scriptBlock -ArgumentList $CommandName, $Mock.BootstrapFunctionName

        if ($Mock.OriginalCommand.ModuleName) {
            $aliasName = "$($Mock.OriginalCommand.ModuleName)\$($CommandName)"
            $Mock.Aliases += $aliasName

            $scriptBlock = {
                $setAlias = & (Pester\SafeGetCommand) -Name Set-Alias -CommandType Cmdlet -Module Microsoft.PowerShell.Utility
                & $setAlias -Name $args[0] -Value $args[1] -Scope Script
            }

            $null = Invoke-InMockScope -SessionState $Mock.SessionState -ScriptBlock $scriptBlock -ArgumentList $aliasName, $Mock.BootstrapFunctionName
        }

        if ($Mock.OriginalCommand.CommandType -eq 'Application') {
            $aliasWithoutExt = $CommandName -replace $Mock.OriginalCommand.Extension

            $Mock.Aliases += $aliasWithoutExt

            $scriptBlock = {
                $setAlias = & (Pester\SafeGetCommand) -Name Set-Alias -CommandType Cmdlet -Module Microsoft.PowerShell.Utility
                & $setAlias -Name $args[0] -Value $args[1] -Scope Script
            }

            $null = Invoke-InMockScope -SessionState $Mock.SessionState -ScriptBlock $scriptBlock -ArgumentList $aliasWithoutExt, $Mock.BootstrapFunctionName
        }
    }
    catch {
        $PSCmdlet.ThrowTerminatingError($_)
    }
}
