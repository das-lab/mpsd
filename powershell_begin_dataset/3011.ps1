if (($PSVersionTable.ContainsKey('PSEdition')) -and ($PSVersionTable.PSEdition -eq 'Core')) {
    & $SafeCommands["Add-Type"] -Path "${Script:PesterRoot}/lib/Gherkin/core/Gherkin.dll"
}
else {
    & $SafeCommands["Import-Module"] -Name "${Script:PesterRoot}/lib/Gherkin/legacy/Gherkin.dll"
}

$GherkinSteps = @{}
$GherkinHooks = @{
    BeforeEachFeature  = @()
    BeforeEachScenario = @()
    AfterEachFeature   = @()
    AfterEachScenario  = @()
}

function Invoke-GherkinHook {
    
    [CmdletBinding()]
    param([string]$Hook, [string]$Name, [string[]]$Tags)

    if ($GherkinHooks.${Hook}) {
        foreach ($GherkinHook in $GherkinHooks.${Hook}) {
            if ($GherkinHook.Tags -and $Tags) {
                :tags foreach ($hookTag in $GherkinHook.Tags) {
                    foreach ($testTag in $Tags) {
                        if ($testTag -match "^($hookTag)$") {
                            & $hook.Script $Name
                            break :tags
                        }
                    }
                }
            }
            elseif ($GherkinHook.Tags) {
                
            }
            else {
                & $GherkinHook.Script $Name
            }
        } 
    }
}

function Invoke-Gherkin {
    
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param(
        [Parameter(Mandatory = $True, ParameterSetName = "RetestFailed")]
        [switch]$FailedLast,

        [Parameter(Position = 0, Mandatory = $False)]
        [Alias('Script', 'relative_path')]
        [string]$Path = $Pwd,

        [Parameter(Position = 1, Mandatory = $False)]
        [Alias("Name", "TestName")]
        [string[]]$ScenarioName,

        [Parameter(Position = 2, Mandatory = $False)]
        [switch]$EnableExit,

        [Parameter(Position = 4, Mandatory = $False)]
        [Alias('Tags')]
        [string[]]$Tag,

        [string[]]$ExcludeTag,

        [object[]] $CodeCoverage = @(),

        [Switch]$Strict,

        [string] $OutputFile,

        [ValidateSet('NUnitXml')]
        [string] $OutputFormat = 'NUnitXml',

        [Switch]$Quiet,

        [object]$PesterOption,

        [Pester.OutputTypes]$Show = 'All',

        [switch]$PassThru
    )
    begin {
        & $SafeCommands["Import-LocalizedData"] -BindingVariable Script:ReportStrings -BaseDirectory $PesterRoot -FileName Gherkin.psd1 -ErrorAction SilentlyContinue

        
        If ([String]::IsNullOrEmpty($ReportStrings)) {

            & $SafeCommands["Import-LocalizedData"] -BaseDirectory $PesterRoot -BindingVariable Script:ReportStrings -UICulture 'en-US' -FileName Gherkin.psd1 -ErrorAction Stop

        }

        
        $CWD = [Environment]::CurrentDirectory
        $Location = & $SafeCommands["Get-Location"]
        [Environment]::CurrentDirectory = & $SafeCommands["Get-Location"] -PSProvider FileSystem

        $script:GherkinSteps = @{}
        $script:GherkinHooks = @{
            BeforeEachFeature  = @()
            BeforeEachScenario = @()
            AfterEachFeature   = @()
            AfterEachScenario  = @()
        }
    }
    end {
        if ($PSBoundParameters.ContainsKey('Quiet')) {
            & $SafeCommands["Write-Warning"] 'The -Quiet parameter has been deprecated; please use the new -Show parameter instead. To get no output use -Show None.'
            & $SafeCommands["Start-Sleep"] -Seconds 2

            if (!$PSBoundParameters.ContainsKey('Show')) {
                $Show = [Pester.OutputTypes]::None
            }
        }

        if ($PSCmdlet.ParameterSetName -eq "RetestFailed" -and $FailedLast) {
            $ScenarioName = $script:GherkinFailedLast
            if (!$ScenarioName) {
                throw "There are no existing failed tests to re-run."
            }
        }
        $sessionState = Set-SessionStateHint -PassThru  -Hint "Caller - Captured in Invoke-Gherkin" -SessionState $PSCmdlet.SessionState
        $pester = New-PesterState -TagFilter $Tag -ExcludeTagFilter $ExcludeTag -TestNameFilter $ScenarioName -SessionState $sessionState -Strict:$Strict  -Show $Show -PesterOption $PesterOption |
            & $SafeCommands["Add-Member"] -MemberType NoteProperty -Name Features -Value (& $SafeCommands["New-Object"] System.Collections.Generic.List[PSObject] ) -PassThru |
            & $SafeCommands["Add-Member"] -MemberType ScriptProperty -Name FailedScenarios -PassThru -Value {
            $Names = $this.TestResult | & $SafeCommands["Group-Object"] Describe |
                & $SafeCommands["Where-Object"] { $_.Group |
                    & $SafeCommands["Where-Object"] { -not $_.Passed } } |
                & $SafeCommands["Select-Object"] -ExpandProperty Name
            $this.Features | Select-Object -ExpandProperty Scenarios | & $SafeCommands["Where-Object"] { $Names -contains $_.Name }
        } |
            & $SafeCommands["Add-Member"] -MemberType ScriptProperty -Name PassedScenarios -PassThru -Value {
            $Names = $this.TestResult | & $SafeCommands["Group-Object"] Describe |
                & $SafeCommands["Where-Object"] { -not ($_.Group |
                        & $SafeCommands["Where-Object"] { -not $_.Passed }) } |
                & $SafeCommands["Select-Object"] -ExpandProperty Name
            $this.Features | Select-Object -ExpandProperty Scenarios | & $SafeCommands["Where-Object"] { $Names -contains $_.Name }
        }

        Write-PesterStart $pester $Path

        Enter-CoverageAnalysis -CodeCoverage $CodeCoverage -PesterState $pester

        foreach ($FeatureFile in & $SafeCommands["Get-ChildItem"] $Path -Filter "*.feature" -Recurse ) {
            Invoke-GherkinFeature $FeatureFile -Pester $pester
        }

        
        $Script:GherkinSteps.Clear()

        $Location | & $SafeCommands["Set-Location"]
        [Environment]::CurrentDirectory = $CWD

        $pester | Write-PesterReport
        $coverageReport = Get-CoverageReport -PesterState $pester
        Write-CoverageReport -CoverageReport $coverageReport
        Exit-CoverageAnalysis -PesterState $pester

        if (& $SafeCommands["Get-Variable"]-Name OutputFile -ValueOnly -ErrorAction $script:IgnoreErrorPreference) {
            Export-PesterResults -PesterState $pester -Path $OutputFile -Format $OutputFormat
        }

        if ($PassThru) {
            
            $properties = @(
                "Path", "Features", "TagFilter", "TestNameFilter", "TotalCount", "PassedCount", "FailedCount", "Time", "TestResult", "PassedScenarios", "FailedScenarios"

                if ($CodeCoverage) {
                    @{ Name = 'CodeCoverage'; Expression = { $coverageReport } }
                }
            )
            $result = $pester | & $SafeCommands["Select-Object"] -Property $properties
            $result.PSTypeNames.Insert(0, "Pester.Gherkin.Results")
            $result
        }
        $script:GherkinFailedLast = @($pester.FailedScenarios.Name)
        if ($EnableExit) {
            Exit-WithCode -FailedCount $pester.FailedCount
        }
    }
}

function Import-GherkinSteps {
    

    [CmdletBinding()]
    param(

        [Alias("PSPath")]
        [Parameter(Mandatory = $True, Position = 0, ValueFromPipelineByPropertyName = $True)]
        $StepPath,

        [PSObject]$Pester
    )
    begin {
        
        $Script:GherkinSteps.Clear()
        
        $Script:GherkinHooks.Clear()
    }
    process {
        $StepFiles = & $SafeCommands["Get-ChildItem"] $StepPath -Filter "*.?teps.ps1" -Include "*.[sS]teps.ps1" -Recurse

        foreach ($StepFile in $StepFiles) {
            $invokeTestScript = {
                [CmdletBinding()]
                param (
                    [Parameter(Position = 0)]
                    [string] $Path
                )

                & $Path
            }

            Set-ScriptBlockScope -ScriptBlock $invokeTestScript -SessionState $Pester.SessionState

            & $invokeTestScript $StepFile.FullName
        }

        & $SafeCommands["Write-Verbose"] "Loaded $($Script:GherkinSteps.Count) step definitions from $(@($StepFiles).Count) steps file(s)"
    }
}

function Import-GherkinFeature {
    
    [CmdletBinding()]
    param($Path, [PSObject]$Pester)
    $Background = $null

    $parser = & $SafeCommands["New-Object"] Gherkin.Parser
    $Feature = $parser.Parse($Path).Feature | Convert-Tags
    $Scenarios = $(
        :scenarios foreach ($Child in $Feature.Children) {
            $null = & $SafeCommands["Add-Member"] -MemberType "NoteProperty" -InputObject $Child.Location -Name "Path" -Value $Path
            foreach ($Step in $Child.Steps) {
                $null = & $SafeCommands["Add-Member"] -MemberType "NoteProperty" -InputObject $Step.Location -Name "Path" -Value $Path
            }

            switch ($Child.Keyword.Trim()) {
                { (Test-Keyword $_ 'scenario' $Feature.Language) -or (Test-Keyword $_ 'scenarioOutline' $Feature.Language) } {
                    $Scenario = Convert-Tags -InputObject $Child -BaseTags $Feature.Tags
                }
                { Test-Keyword $_ 'background' $Feature.Language } {
                    $Background = Convert-Tags -InputObject $Child -BaseTags $Feature.Tags
                    continue scenarios
                }
                default {
                    & $SafeCommands["Write-Warning"] "Unexpected Feature Child: $_"
                }
            }

            if ( $Scenario -is [Gherkin.Ast.ScenarioOutline] ) {
                
                $ScenarioIndex = 0
                foreach ($ExampleSet in $Scenario.Examples) {
                    ${Column Names} = @($ExampleSet.TableHeader.Cells | & $SafeCommands["Select-Object"] -ExpandProperty Value)
                    $NamesPattern = "<(?:" + (${Column Names} -join "|") + ")>"
                    
                    $ExampleSetIndex = 0
                    foreach ($Example in $ExampleSet.TableBody) {
                        $ScenarioIndex++
                        $ExampleSetIndex++
                        $Steps = foreach ($Step in $Scenario.Steps) {
                            [string]$StepText = $Step.Text
                            if ($StepText -match $NamesPattern) {
                                for ($n = 0; $n -lt ${Column Names}.Length; $n++) {
                                    $Name = ${Column Names}[$n]
                                    if ($Example.Cells[$n].Value -and $StepText -match "<${Name}>") {
                                        $StepText = $StepText -replace "<${Name}>", $Example.Cells[$n].Value
                                    }
                                }
                            }
                            if ($StepText -ne $Step.Text) {
                                & $SafeCommands["New-Object"] Gherkin.Ast.Step $Step.Location, $Step.Keyword.Trim(), $StepText, $Step.Argument
                            }
                            else {
                                $Step
                            }
                        }
                        $ScenarioName = $Scenario.Name
                        if ($ExampleSet.Name) {
                            
                            $ScenarioName = $ScenarioName + " [$($ExampleSet.Name.Trim()) $ExampleSetIndex]"
                        }
                        else {
                            
                            $ScenarioName = $ScenarioName + " [$ScenarioIndex]"
                        }
                        & $SafeCommands["New-Object"] Gherkin.Ast.Scenario $ExampleSet.Tags, $Scenario.Location, $Scenario.Keyword.Trim(), $ScenarioName, $Scenario.Description, $Steps | Convert-Tags $Scenario.Tags
                    }
                }
            }
            else {
                $Scenario
            }
        }
    )

    & $SafeCommands["Add-Member"] -MemberType NoteProperty -InputObject $Feature -Name Scenarios -Value $Scenarios -Force
    return $Feature, $Background, $Scenarios
}

function Invoke-GherkinFeature {
    
    [CmdletBinding()]
    param(
        [Alias("PSPath")]
        [Parameter(Mandatory = $True, Position = 0, ValueFromPipelineByPropertyName = $True)]
        [IO.FileInfo]$FeatureFile,

        [PSObject]$Pester
    )
    
    $CWD = [Environment]::CurrentDirectory
    $Location = & $SafeCommands["Get-Location"]
    [Environment]::CurrentDirectory = & $SafeCommands["Get-Location"] -PSProvider FileSystem

    try {
        $Parent = & $SafeCommands["Split-Path"] $FeatureFile.FullName
        Import-GherkinSteps -StepPath $Parent -Pester $pester
        $Feature, $Background, $Scenarios = Import-GherkinFeature -Path $FeatureFile.FullName -Pester $Pester
    }
    catch [Gherkin.ParserException] {
        & $SafeCommands["Write-Error"] -Exception $_.Exception -Message "Skipped '$($FeatureFile.FullName)' because of parser error.`n$(($_.Exception.Errors | & $SafeCommands["Select-Object"] -Expand Message) -join "`n`n")"
        continue
    }

    
    $Pester.EnterTestGroup($Feature.Name, 'Script')

    $null = $Pester.Features.Add($Feature)
    Invoke-GherkinHook BeforeEachFeature $Feature.Name $Feature.Tags

    
    if ($Pester.TestNameFilter) {
        $Scenarios = foreach ($nameFilter in $Pester.TestNameFilter) {
            $Scenarios | & $SafeCommands["Where-Object"] { $_.Name -like $NameFilter }
        }
        $Scenarios = $Scenarios | & $SafeCommands["Get-Unique"]
    }

    
    if ($Pester.TagFilter) {
        $Scenarios = $Scenarios | & $SafeCommands["Where-Object"] { & $SafeCommands["Compare-Object"] $_.Tags $Pester.TagFilter -IncludeEqual -ExcludeDifferent }
    }

    
    if ($Pester.ExcludeTagFilter) {
        $Scenarios = $Scenarios | & $SafeCommands["Where-Object"] { !(& $SafeCommands["Compare-Object"] $_.Tags $Pester.ExcludeTagFilter -IncludeEqual -ExcludeDifferent) }
    }

    if ($Scenarios) {
        Write-Describe (New-Object PSObject -Property @{Name = "$($Feature.Keyword): $($Feature.Name)"; Description = $Feature.Description })
    }

    try {
        foreach ($Scenario in $Scenarios) {
            Invoke-GherkinScenario $Pester $Scenario $Background $Feature.Language
        }
    }
    catch {
        $firstStackTraceLine = $_.ScriptStackTrace -split '\r?\n' | & $SafeCommands["Select-Object"] -First 1
        $Pester.AddTestResult("Error occurred in test script '$($Feature.Path)'", "Failed", $null, $_.Exception.Message, $firstStackTraceLine, $null, $null, $_)

        
        
        
        $Pester.TestResult[-1].Describe = "Error in $($Feature.Path)"

        $Pester.TestResult[-1] | Write-PesterResult
    }
    finally {
        $Location | & $SafeCommands["Set-Location"]
        [Environment]::CurrentDirectory = $CWD
    }

    Invoke-GherkinHook AfterEachFeature $Feature.Name $Feature.Tags

    $Pester.LeaveTestGroup($Feature.Name, 'Script')

}

function Invoke-GherkinScenario {
    
    [CmdletBinding()]
    param(
        $Pester, $Scenario, $Background, $Language
    )
    $Pester.EnterTestGroup($Scenario.Name, 'Scenario')
    try {
        
        
        Write-Context (New-Object PSObject -Property @{Name = "$(Get-Translation 'scenario' $Language): $($Scenario.Name)"; Description = $Scenario.Description })

        $script:mockTable = @{}

        
        $script:GherkinScenarioScope = New-Module Scenario {       $a = 4
        }
        $script:GherkinSessionState = Set-SessionStateHint -PassThru -Hint Scenario -SessionState $Script:GherkinScenarioScope.SessionState

        

        New-TestDrive
        Invoke-GherkinHook BeforeEachScenario $Scenario.Name $Scenario.Tags

        $testResultIndexStart = $Pester.TestResult.Count

        
        if ($Background) {
            foreach ($Step in $Background.Steps) {
                
                Invoke-GherkinStep -Step $Step -Pester $Pester -Scenario $GherkinSessionState -Visible -TestResultIndexStart $testResultIndexStart
            }
        }

        foreach ($Step in $Scenario.Steps) {
            Invoke-GherkinStep -Step $Step -Pester $Pester -Scenario $GherkinSessionState -Visible -TestResultIndexStart $testResultIndexStart
        }

        Invoke-GherkinHook AfterEachScenario $Scenario.Name $Scenario.Tags
    }
    catch {
        $firstStackTraceLine = $_.ScriptStackTrace -split '\r?\n' | & $SafeCommands["Select-Object"] -First 1
        $Pester.AddTestResult("Error occurred in scenario '$($Scenario.Name)'", "Failed", $null, $_.Exception.Message, $firstStackTraceLine, $null, $null, $_)

        
        
        
        $Pester.TestResult[-1].Describe = "Error in $($Scenario.Name)"

        $Pester.TestResult[-1] | Write-PesterResult
    }

    Remove-TestDrive
    $Pester.LeaveTestGroup($Scenario.Name, 'Scenario')
    Exit-MockScope
}

function Find-GherkinStep {
    

    [CmdletBinding()]
    param(

        [string]$Step,

        [string]$BasePath = $Pwd
    )

    $OriginalGherkinSteps = $Script:GherkinSteps
    try {
        Import-GherkinSteps $BasePath -Pester $PSCmdlet

        $KeyWord, $StepText = $Step -split "(?<=^(?:Given|When|Then|And|But))\s+"
        if (!$StepText) {
            $StepText = $KeyWord
        }

        & $SafeCommands["Write-Verbose"] "Searching for '$StepText' in $($Script:GherkinSteps.Count) steps"
        $(
            foreach ($StepCommand in $Script:GherkinSteps.Keys) {
                & $SafeCommands["Write-Verbose"] "... $StepCommand"
                if ($StepText -match "^${StepCommand}$") {
                    & $SafeCommands["Write-Verbose"] "Found match: $StepCommand"
                    $StepCommand | & $SafeCommands["Add-Member"] -MemberType NoteProperty -Name MatchCount -Value $Matches.Count -PassThru
                }
            }
        ) | & $SafeCommands["Sort-Object"] MatchCount | & $SafeCommands["Select-Object"] @{
            Name       = 'Step'
            Expression = { $Step }
        }, @{
            Name       = 'Source'
            Expression = { $Script:GherkinSteps["$_"].Source }
        }, @{
            Name       = 'Implementation'
            Expression = { $Script:GherkinSteps["$_"] }
        } -First 1

        

    }
    finally {
        $Script:GherkinSteps = $OriginalGherkinSteps
    }
}

function Invoke-GherkinStep {
    
    [CmdletBinding()]
    param (
        $Step,

        [Switch]$Visible,

        $Pester,

        $ScenarioState,

        [int] $TestResultIndexStart
    )
    if ($Step -is [string]) {
        $KeyWord, $StepText = $Step -split "(?<=^(?:Given|When|Then|And|But))\s+"
        if (!$StepText) {
            $StepText = $KeyWord
            $Keyword = "Step"
        }
        $Step = @{ Text = $StepText; Keyword = $Keyword }
    }
    $DisplayText = "{0} {1}" -f $Step.Keyword.Trim(), $Step.Text

    $PesterErrorRecord = $null
    $Elapsed = $null
    $NamedArguments = @{}

    try {
        
        $StepCommand = $(
            foreach ($StepCommand in $Script:GherkinSteps.Keys) {
                if ($Step.Text -match "^${StepCommand}$") {
                    $StepCommand | & $SafeCommands["Add-Member"] -MemberType NoteProperty -Name MatchCount -Value $Matches.Count -PassThru
                }
            }
        ) | & $SafeCommands["Sort-Object"] MatchCount | & $SafeCommands["Select-Object"] -First 1

        $previousStepsNotSuccessful = $false
        
        for ($i = $TestResultIndexStart; $i -lt ($Pester.TestResult.Count); $i++) {
            $previousTestResult = $Pester.TestResult[$i].Result
            if ($previousTestResult -eq "Failed" -or $previousTestResult -eq "Inconclusive") {
                $previousStepsNotSuccessful = $true
                break
            }
        }
        if (!$StepCommand -or $previousStepsNotSuccessful) {
            $skipMessage = if (!$StepCommand) {
                "Could not find implementation for step!"
            }
            else {
                "Step skipped (previous step did not pass)"
            }
            $PesterErrorRecord = New-PesterErrorRecord -Result Inconclusive -Message $skipMessage -File $Step.Location.Path -Line $Step.Location.Line -LineText $DisplayText
        }
        else {
            $NamedArguments, $Parameters = Get-StepParameters $Step $StepCommand
            $watch = & $SafeCommands["New-Object"] System.Diagnostics.Stopwatch
            $watch.Start()
            try {
                

                if ($NamedArguments.Count) {
                    if ($NamedArguments.ContainsKey("Table")) {
                        $DisplayText += "..."
                    }
                    $ScriptBlock = { . $Script:GherkinSteps.$StepCommand @NamedArguments @Parameters }
                }
                else {
                    $ScriptBlock = { . $Script:GherkinSteps.$StepCommand @Parameters }
                }
                Set-ScriptBlockScope -ScriptBlock $Script:GherkinSteps.$StepCommand -SessionState $ScenarioState

                Write-ScriptBlockInvocationHint -Hint "Invoke-Gherkin step" -ScriptBlock $Script:GherkinSteps.$StepCommand
                $null = & $ScriptBlock
            }
            catch {
                $PesterErrorRecord = $_
            }
            $watch.Stop()
            $Elapsed = $watch.Elapsed
        }
    }
    catch {
        $PesterErrorRecord = $_
    }

    if ($Pester -and $Visible) {
        for ($p = 0; $p -lt $Parameters.Count; $p++) {
            $NamedArguments."Unnamed-$p" = $Parameters[$p]
        }

        
        if ($PesterErrorRecord.ErrorRecord) {
            $PesterErrorRecord = $PesterErrorRecord.ErrorRecord
        }

        ${Pester Result} = ConvertTo-PesterResult -ErrorRecord $PesterErrorRecord

        
        if (${Pester Result}.Result -eq 'Inconclusive') {
            ${Pester Result}.StackTrace = "At " + $Step.Keyword.Trim() + ', ' + $Step.Location.Path + ': line ' + $Step.Location.Line
        }
        else {
            
            ${Pester Result}.StackTrace += "`nFrom " + $Step.Location.Path + ': line ' + $Step.Location.Line
        }
        $Pester.AddTestResult($DisplayText, ${Pester Result}.Result, $Elapsed, ${Pester Result}.FailureMessage, ${Pester Result}.StackTrace, $null, $NamedArguments, $PesterErrorRecord)
        $Pester.TestResult[-1] | Write-PesterResult
    }
}

function Get-StepParameters {
    
    param($Step, $CommandName)
    $Null = $Step.Text -match $CommandName

    $NamedArguments = @{}
    $Parameters = @{}
    foreach ($kv in $Matches.GetEnumerator()) {
        switch ($kv.Name -as [int]) {
            0 {
            } 
            $null {
                $NamedArguments.($kv.Name) = $ExecutionContext.InvokeCommand.ExpandString($kv.Value)
            }
            default {
                $Parameters.([int]$kv.Name) = $ExecutionContext.InvokeCommand.ExpandString($kv.Value)
            }
        }
    }
    $Parameters = @($Parameters.GetEnumerator() | & $SafeCommands["Sort-Object"] Name | & $SafeCommands["Select-Object"] -ExpandProperty Value)

    
    if ($Step.Argument -is [Gherkin.Ast.DataTable]) {
        $NamedArguments.Table = $Step.Argument.Rows | ConvertTo-HashTableArray
    }
    if ($Step.Argument -is [Gherkin.Ast.DocString]) {
        
        $Parameters = @( $Parameters | & $SafeCommands["Where-Object"] { $_.Length } ) + $Step.Argument.Content
    }

    return @($NamedArguments, $Parameters)
}

function Convert-Tags {
    
    [CmdletBinding()]
    param(
        [Parameter(ValueFromPipeline = $true)]
        $InputObject,

        [Parameter(Position = 0)]
        [string[]]$BaseTags = @()
    )
    process {
        
        [string[]]$Tags = foreach ($tag in $InputObject.Tags | & $SafeCommands['Where-Object'] { $_ }) {
            $tag.Name.TrimStart("@")
        }
        & $SafeCommands["Add-Member"] -MemberType NoteProperty -InputObject $InputObject -Name Tags -Value ([string[]]($Tags + $BaseTags)) -Force
        $InputObject
    }
}

function ConvertTo-HashTableArray {
    
    [CmdletBinding()]
    param(
        [Parameter(ValueFromPipeline = $true)]
        [Gherkin.Ast.TableRow[]]$InputObject
    )
    begin {
        ${Column Names} = @()
        ${Result Table} = @()
    }
    process {
        
        ${InputObject Rows} = @($InputObject)
        if (!${Column Names}) {
            & $SafeCommands["Write-Verbose"] "Reading Names from Header"
            ${InputObject Header}, ${InputObject Rows} = ${InputObject Rows}
            ${Column Names} = @(${InputObject Header}.Cells | & $SafeCommands["Select-Object"] -ExpandProperty Value)
        }

        if ( $null -ne ${InputObject Rows} ) {
            & $SafeCommands["Write-Verbose"] "Processing $(${InputObject Rows}.Length) Rows"
            foreach (${InputObject row} in ${InputObject Rows}) {
                ${Pester Result} = @{}
                for ($n = 0; $n -lt ${Column Names}.Length; $n++) {
                    ${Pester Result}.Add(${Column Names}[$n], ${InputObject row}.Cells[$n].Value)
                }
                ${Result Table} += @(${Pester Result})
            }
        }
    }
    end {
        ${Result Table}
    }
}

function Get-Translations($TranslationKey, $Language) {
    
    if (-not (Test-Path variable:Script:GherkinLanguagesJson)) {
        $Script:GherkinLanguagesJson = ConvertFrom-Json2 (Get-Content "${Script:PesterRoot}/lib/Gherkin/gherkin-languages.json" | Out-String)
        
        
        $Script:ReportStrings.Describe = "{0}" 
        $Script:ReportStrings.Context = "{0}" 
    }
    $foundTranslations = $Script:GherkinLanguagesJson."$Language"."$TranslationKey"
    if (-not $foundTranslations) {
        Write-Warning "Translation key '$TranslationKey' is invalid"
    }
    return , $foundTranslations
}

function ConvertFrom-Json2([string] $jsonString) {
    
    if ($PSVersionTable.PSVersion.Major -le 2) {
        
        Add-Type -Assembly System.Web.Extensions
        return , (New-Object System.Web.Script.Serialization.JavaScriptSerializer).DeserializeObject($jsonString)
    }
    else {
        
        return ConvertFrom-Json $jsonString
    }
}

function Get-Translation($TranslationKey, $Language, $Index = -1) {
    
    $translations = (Get-Translations $TranslationKey $Language)
    if (-not $translations) {
        return
    }
    if ($Index -lt 0 -or $Index -ge $translations.Length) {
        
        
        $Index = if ($TranslationKey -eq "scenarioOutline" -or $TranslationKey -eq "feature" -or $TranslationKey -eq "examples") {
            0
        }
        else {
            1
        }
    }
    return $translations[$Index]
}

function Test-Keyword($Keyword, $TranslationKey, $Language) {
    
    return (Get-Translations $TranslationKey $Language) -contains $Keyword
}
