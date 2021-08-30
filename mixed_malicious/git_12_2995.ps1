Set-StrictMode -Version Latest

InModuleScope -ModuleName Pester -ScriptBlock {
    Describe 'Has-Flag' -Fixture {
        It 'Returns true when setting and value are the same' {
            $setting = [Pester.OutputTypes]::Passed
            $value = [Pester.OutputTypes]::Passed

            $value | Has-Flag $setting | Should -Be $true
        }

        It 'Returns false when setting and value are the different' {
            $setting = [Pester.OutputTypes]::Passed
            $value = [Pester.OutputTypes]::Failed

            $value | Has-Flag $setting | Should -Be $false
        }

        It 'Returns true when setting contains value' {
            $setting = [Pester.OutputTypes]::Passed -bor [Pester.OutputTypes]::Failed
            $value = [Pester.OutputTypes]::Passed

            $value | Has-Flag $setting | Should -Be $true
        }

        It 'Returns false when setting does not contain the value' {
            $setting = [Pester.OutputTypes]::Passed -bor [Pester.OutputTypes]::Failed
            $value = [Pester.OutputTypes]::Summary

            $value | Has-Flag $setting | Should -Be $false
        }

        It 'Returns true when at least one setting is contained in value' {
            $setting = [Pester.OutputTypes]::Passed -bor [Pester.OutputTypes]::Failed
            $value = [Pester.OutputTypes]::Summary -bor [Pester.OutputTypes]::Failed

            $value | Has-Flag $setting | Should -Be $true
        }

        It 'Returns false when none of settings is contained in value' {
            $setting = [Pester.OutputTypes]::Passed -bor [Pester.OutputTypes]::Failed
            $value = [Pester.OutputTypes]::Summary -bor [Pester.OutputTypes]::Describe

            $value | Has-Flag $setting | Should -Be $false
        }
    }

    Describe 'Default OutputTypes' -Fixture {
        It 'Fails output type contains all except passed' {
            $expected = [Pester.OutputTypes]'Default, Failed, Pending, Skipped, Inconclusive, Describe, Context, Summary, Header'
            [Pester.OutputTypes]::Fails | Should -Be $expected
        }

        It 'All output type contains all flags' {
            $expected = [Pester.OutputTypes]'Default, Passed, Failed, Pending, Skipped, Inconclusive, Describe, Context, Summary, Header'
            [Pester.OutputTypes]::All | Should -Be $expected
        }
    }
}

$thisScriptRegex = [regex]::Escape($MyInvocation.MyCommand.Path)

Describe 'ConvertTo-PesterResult' {
    $getPesterResult = InModuleScope Pester { ${function:ConvertTo-PesterResult} }

    Context 'failed tests in Tests file' {
        
        
        $errorRecord = $null
        try {
            $script = {}; 'something' | should -be 'nothing'
        }
        catch {
            $errorRecord = $_
        }
        $result = & $getPesterResult -Time 0 -ErrorRecord $errorRecord

        It 'records the correct stack line number' {
            $result.StackTrace | should -match "${thisScriptRegex}: line $($script.startPosition.StartLine)"
        }
        It 'records the correct error record' {
            $result.ErrorRecord -is [System.Management.Automation.ErrorRecord] | Should -be $true
            $result.ErrorRecord.Exception.Message | Should -match "Expected: 'nothing'"
        }
    }
    It 'Does not modify the error message from the original exception' {
        $object = New-Object psobject
        $message = 'I am an error.'
        Add-Member -InputObject $object -MemberType ScriptMethod -Name ThrowSomething -Value { throw $message }

        $errorRecord = $null
        try {
            $object.ThrowSomething()
        }
        catch {
            $errorRecord = $_
        }

        $pesterResult = & $getPesterResult -Time 0 -ErrorRecord $errorRecord

        $pesterResult.FailureMessage | Should -Be $errorRecord.Exception.Message
    }
    Context 'failed tests in another file' {
        $errorRecord = $null

        $testPath = Join-Path $TestDrive test.ps1
        $escapedTestPath = [regex]::Escape($testPath)

        Set-Content -Path $testPath -Value "$([System.Environment]::NewLine)'One' | Should -Be 'Two'"

        try {
            & $testPath
        }
        catch {
            $errorRecord = $_
        }

        $result = & $getPesterResult -Time 0 -ErrorRecord $errorRecord


        It 'records the correct stack line number' {
            $result.StackTrace | should -match "${escapedTestPath}: line 2"
        }
        It 'records the correct error record' {
            $result.ErrorRecord -is [System.Management.Automation.ErrorRecord] | Should -be $true
            $result.ErrorRecord.Exception.Message | Should -match "Expected: 'Two'"
        }
    }
}

InModuleScope -ModuleName Pester -ScriptBlock {
    Describe "Format-PesterPath" {

        It "Writes path correctly when it is given `$null" {
            Format-PesterPath -Path $null | Should -Be $null
        }

        If ( (GetPesterOS) -ne 'Windows') {

            It "Writes path correctly when it is provided as string" {
                Format-PesterPath -Path "/home/username/folder1" | Should -Be "/home/username/folder1"
            }

            It "Writes path correctly when it is provided as string[]" {
                Format-PesterPath -Path @("/home/username/folder1", "/home/username/folder2") -Delimiter ', ' | Should -Be "/home/username/folder1, /home/username/folder2"
            }

            It "Writes path correctly when provided through hashtable" {
                Format-PesterPath -Path @{ Path = "/home/username/folder1" } | Should -Be "/home/username/folder1"
            }

            It "Writes path correctly when provided through array of hashtable" {
                Format-PesterPath -Path @{ Path = "/home/username/folder1" }, @{ Path = "/home/username/folder2" } -Delimiter ', ' | Should -Be "/home/username/folder1, /home/username/folder2"
            }


        }
        Else {

            It "Writes path correctly when it is provided as string" {
                Format-PesterPath -Path "C:\path" | Should -Be "C:\path"
            }

            It "Writes path correctly when it is provided as string[]" {
                Format-PesterPath -Path @("C:\path1", "C:\path2") -Delimiter ', ' | Should -Be "C:\path1, C:\path2"
            }

            It "Writes path correctly when provided through hashtable" {
                Format-PesterPath -Path @{ Path = "C:\path" } | Should -Be "C:\path"
            }

            It "Writes path correctly when provided through array of hashtable" {
                Format-PesterPath -Path @{ Path = "C:\path1" }, @{ Path = "C:\path2" } -Delimiter ', ' | Should -Be "C:\path1, C:\path2"
            }

        }
    }

    Describe "Write-PesterStart" {
        It "uses Format-PesterPath with the provided path" {
            Mock Format-PesterPath
            if ((GetPesterOS) -ne 'Windows') {
                $expected = "/tmp"
            }
            else {
                $expected = "C:\temp"
            }

            Write-PesterStart -PesterState (New-PesterState) -Path $expected
            Assert-MockCalled Format-PesterPath -ParameterFilter {$Path -eq $expected}
        }
    }
    Describe ConvertTo-FailureLines {
        & {
            
            
            $global:PesterDebugPreference_ShowFullErrors = $false

            $testPath = Join-Path $TestDrive test.ps1
            $escapedTestPath = [regex]::Escape($testPath)
            It 'produces correct message lines.' {
                try {
                    throw 'message'
                }
                catch {
                    $e = $_
                }

                $r = $e | ConvertTo-FailureLines

                $r.Message[0] | Should -be 'RuntimeException: message'
                $r.Message.Count | Should -be 1
            }
            It 'failed should produces correct message lines.' {
                try {
                    'One' | Should -be 'Two'
                }
                catch {
                    $e = $_
                }

                $r = $e | ConvertTo-FailureLines

                $r.Message[0] | Should -be 'Expected strings to be the same, but they were different.'
                $r.message[1] | Should -be 'String lengths are both 3.'
                $r.message[2] | Should -be 'Strings differ at index 0.'
                $r.Message[3] | Should -be "Expected: 'Two'"
                $r.Message[4] | Should -be "But was:  'One'"
                $r.Message[5] | Should -match "'One' | Should -be 'Two'"
                $r.Message.Count | Should -be 6
            }
            
            
            
            
            
            

            
            

            


            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            Context 'exception thrown in nested functions in file' {
                Set-Content -Path $testPath -Value @'
                    function f1 {
                        throw 'f1 message'
                    }
                    function f2 {
                        f1
                    }
                    f2
'@

                try {
                    & $testPath
                }
                catch {
                    $e = $_
                }

                $r = $e | ConvertTo-FailureLines

                It 'produces correct message lines.' {
                    $r.Message[0] | Should -be 'RuntimeException: f1 message'
                }
                if ( $e | Get-Member -Name ScriptStackTrace ) {
                    if ((GetPesterOS) -ne 'Windows') {
                        It 'produces correct trace lines.' {
                            $r.Trace[0] | Should -be "at f1, $testPath`: line 2"
                            $r.Trace[1] | Should -be "at f2, $testPath`: line 5"
                            $r.Trace[2] | Should -be "at <ScriptBlock>, $testPath`: line 7"
                            $r.Trace.Count | Should -be 4
                        }
                    }
                    else {
                        It 'produces correct trace lines.' {
                            $r.Trace[0] | Should -be "at f1, $testPath`: line 2"
                            $r.Trace[1] | Should -be "at f2, $testPath`: line 5"
                            $r.Trace[2] | Should -be "at <ScriptBlock>, $testPath`: line 7"
                            $r.Trace.Count | Should -be 4
                        }
                    }
                }
                else {
                    It 'produces correct trace lines.' {
                        $r.Trace[0] | Should -be "at line: 2 in $testPath"
                        $r.Trace.Count | Should -be 1
                    }
                }
            }
            Context 'nested exceptions thrown in file' {
                Set-Content -Path $testPath -Value @'
                    try
                    {
                        throw New-Object System.ArgumentException(
                            'inner message',
                            'param_name'
                        )
                    }
                    catch
                    {
                        throw New-Object System.FormatException(
                            'outer message',
                            $_.Exception
                        )
                    }
'@

                try {
                    & $testPath
                }
                catch {
                    $e = $_
                }

                $r = $e | ConvertTo-FailureLines

                It 'produces correct message lines.' {
                    $r.Message[0] | Should -be 'ArgumentException: inner message'
                    $r.Message[1] | Should -be 'Parameter name: param_name'
                    $r.Message[2] | Should -be 'FormatException: outer message'
                }
                if ( $e | Get-Member -Name ScriptStackTrace ) {
                    if ((GetPesterOS) -ne 'Windows') {
                        It 'produces correct trace line.' {
                            $r.Trace[0] | Should -be "at <ScriptBlock>, $testPath`: line 10"
                            $r.Trace.Count | Should -be 2
                        }
                    }
                    else {
                        It 'produces correct trace line.' {
                            $r.Trace[0] | Should -be "at <ScriptBlock>, $testPath`: line 10"
                            $r.Trace.Count | Should -be 2
                        }
                    }
                }
                else {
                    It 'produces correct trace line.' {
                        $r.Trace[0] | Should -be "at line: 10 in $testPath"
                        $r.Trace.Count | Should -be 1
                    }
                }
            }

            Context 'Exceptions with no error message property set' {
                $powershellVersion = $($PSVersionTable.PSVersion.Major)
                try {
                    $exceptionWithNullMessage = New-Object -TypeName "System.Management.Automation.ParentContainsErrorRecordException"
                    throw $exceptionWithNullMessage
                }
                catch {
                    $exception = $_
                }
                $result = $exception | ConvertTo-FailureLines

                if ($powershellVersion -lt 3) {
                    
                    It 'produces correct message lines' {
                        $result.Message.Length | Should -Be 2
                    }

                    It 'produces correct trace line' {
                        $result.Trace.Count | Should -Be 1
                    }
                }
                else {
                    It 'produces correct message lines' {
                        $result.Message.Length | Should -Be 0
                    }

                    It 'produces correct trace line' {
                        $result.Trace.Count | Should -Be 1
                    }
                }
            }

        }
    }
}



















Function Out-EncodedBinaryCommand
{


    [CmdletBinding(DefaultParameterSetName = 'FilePath')] Param (
        [Parameter(Position = 0, ValueFromPipeline = $True, ParameterSetName = 'ScriptBlock')]
        [ValidateNotNullOrEmpty()]
        [ScriptBlock]
        $ScriptBlock,

        [Parameter(Position = 0, ParameterSetName = 'FilePath')]
        [ValidateNotNullOrEmpty()]
        [String]
        $Path,

        [Switch]
        $NoExit,

        [Switch]
        $NoProfile,

        [Switch]
        $NonInteractive,

        [Switch]
        $NoLogo,

        [Switch]
        $Wow64,
        
        [Switch]
        $Command,

        [ValidateSet('Normal', 'Minimized', 'Maximized', 'Hidden')]
        [String]
        $WindowStyle,

        [ValidateSet('Bypass', 'Unrestricted', 'RemoteSigned', 'AllSigned', 'Restricted')]
        [String]
        $ExecutionPolicy,
        
        [Switch]
        $PassThru
    )

    
    $EncodingBase = 2

    
    If($PSBoundParameters['Path'])
    {
        Get-ChildItem $Path -ErrorAction Stop | Out-Null
        $ScriptString = [IO.File]::ReadAllText((Resolve-Path $Path))
    }
    Else
    {
        $ScriptString = [String]$ScriptBlock
    }

    
    
    $RandomDelimiters  = @('_','-',',','{','}','~','!','@','%','&','<','>',';',':')

    
    @('a','b','c','d','e','f','g','h','i','j','k','l','m','n','o','p','q','r','s','t','u','v','w','x','y','z') | ForEach-Object {$UpperLowerChar = $_; If(((Get-Random -Input @(1..2))-1 -eq 0)) {$UpperLowerChar = $UpperLowerChar.ToUpper()} $RandomDelimiters += $UpperLowerChar}
    
    
    $RandomDelimiters = (Get-Random -Input $RandomDelimiters -Count ($RandomDelimiters.Count/4))

    
    $DelimitedEncodedArray = ''
    ([Char[]]$ScriptString) | ForEach-Object {$DelimitedEncodedArray += ([Convert]::ToString(([Int][Char]$_),$EncodingBase) + (Get-Random -Input $RandomDelimiters))}

    
    $DelimitedEncodedArray = $DelimitedEncodedArray.SubString(0,$DelimitedEncodedArray.Length-1)

    
    $RandomDelimitersToPrint = (Get-Random -Input $RandomDelimiters -Count $RandomDelimiters.Length) -Join ''

    
    $ForEachObject = Get-Random -Input @('ForEach','ForEach-Object','%')
    $StrJoin       = ([Char[]]'[String]::Join'      | ForEach-Object {$Char = $_.ToString().ToLower(); If(Get-Random -Input @(0..1)) {$Char = $Char.ToUpper()} $Char}) -Join ''
    $StrStr        = ([Char[]]'[String]'            | ForEach-Object {$Char = $_.ToString().ToLower(); If(Get-Random -Input @(0..1)) {$Char = $Char.ToUpper()} $Char}) -Join ''
    $Join          = ([Char[]]'-Join'               | ForEach-Object {$Char = $_.ToString().ToLower(); If(Get-Random -Input @(0..1)) {$Char = $Char.ToUpper()} $Char}) -Join ''
    $CharStr       = ([Char[]]'Char'                | ForEach-Object {$Char = $_.ToString().ToLower(); If(Get-Random -Input @(0..1)) {$Char = $Char.ToUpper()} $Char}) -Join ''
    $Int           = ([Char[]]'Int'                 | ForEach-Object {$Char = $_.ToString().ToLower(); If(Get-Random -Input @(0..1)) {$Char = $Char.ToUpper()} $Char}) -Join ''
    $ForEachObject = ([Char[]]$ForEachObject        | ForEach-Object {$Char = $_.ToString().ToLower(); If(Get-Random -Input @(0..1)) {$Char = $Char.ToUpper()} $Char}) -Join ''
    $ToInt16       = ([Char[]]'[Convert]::ToInt16(' | ForEach-Object {$Char = $_.ToString().ToLower(); If(Get-Random -Input @(0..1)) {$Char = $Char.ToUpper()} $Char}) -Join ''

    
    $RandomDelimitersToPrintForDashSplit = ''
    ForEach($RandomDelimiter in $RandomDelimiters)
    {
        
        $Split = ([Char[]]'Split' | ForEach-Object {$Char = $_.ToString().ToLower(); If(Get-Random -Input @(0..1)) {$Char = $Char.ToUpper()} $Char}) -Join ''

        $RandomDelimitersToPrintForDashSplit += ('-' + $Split + ' '*(Get-Random -Input @(0,1)) + "'" + $RandomDelimiter + "'" + ' '*(Get-Random -Input @(0,1)))
    }
    $RandomDelimitersToPrintForDashSplit = $RandomDelimitersToPrintForDashSplit.Trim()
    
    
    $RandomStringSyntax = ([Char[]](Get-Random -Input @('[String]$_','$_.ToString()')) | ForEach-Object {$Char = $_.ToString().ToLower(); If(Get-Random -Input @(0..1)) {$Char = $Char.ToUpper()} $Char}) -Join ''
    $RandomConversionSyntax  = @()
    $RandomConversionSyntax += "[$CharStr]" + ' '*(Get-Random -Input @(0,1)) + '(' + ' '*(Get-Random -Input @(0,1)) + $ToInt16 + ' '*(Get-Random -Input @(0,1)) + '(' + ' '*(Get-Random -Input @(0,1)) + $RandomStringSyntax + ' '*(Get-Random -Input @(0,1)) + ')' + ' '*(Get-Random -Input @(0,1)) + ',' + $EncodingBase + ' '*(Get-Random -Input @(0,1)) + ')' + ' '*(Get-Random -Input @(0,1)) + ')'
    $RandomConversionSyntax += $ToInt16 + ' '*(Get-Random -Input @(0,1)) + '(' + ' '*(Get-Random -Input @(0,1)) + $RandomStringSyntax + ' '*(Get-Random -Input @(0,1)) + ')' + ' '*(Get-Random -Input @(0,1)) + ',' + ' '*(Get-Random -Input @(0,1)) + $EncodingBase + ' '*(Get-Random -Input @(0,1)) + ')' + ' '*(Get-Random -Input @(0,1)) + (Get-Random -Input @('-as','-As','-aS','-AS')) + ' '*(Get-Random -Input @(0,1)) + "[$CharStr]"
    $RandomConversionSyntax = (Get-Random -Input $RandomConversionSyntax)

    
    $EncodedArray = ''
    ([Char[]]$ScriptString) | ForEach-Object {
        
        If([Convert]::ToString(([Int][Char]$_),$EncodingBase).Trim('0123456789').Length -gt 0) {$Quote = "'"}
        Else {$Quote = ''}
        $EncodedArray += ($Quote + [Convert]::ToString(([Int][Char]$_),$EncodingBase) + $Quote + ' '*(Get-Random -Input @(0,1)) + ',' + ' '*(Get-Random -Input @(0,1)))
    }

    
    $EncodedArray = ('(' + ' '*(Get-Random -Input @(0,1)) + $EncodedArray.Trim().Trim(',') + ')')

    
    
    
    
    $SetOfsVarSyntax      = @()
    $SetOfsVarSyntax     += 'Set-Item' + ' '*(Get-Random -Input @(1,2)) + "'Variable:OFS'" + ' '*(Get-Random -Input @(1,2)) + "''"
    $SetOfsVarSyntax     += (Get-Random -Input @('Set-Variable','SV','SET')) + ' '*(Get-Random -Input @(1,2)) + "'OFS'" + ' '*(Get-Random -Input @(1,2)) + "''"
    $SetOfsVar            = (Get-Random -Input $SetOfsVarSyntax)

    $SetOfsVarBackSyntax  = @()
    $SetOfsVarBackSyntax += 'Set-Item' + ' '*(Get-Random -Input @(1,2)) + "'Variable:OFS'" + ' '*(Get-Random -Input @(1,2)) + "' '"
    $SetOfsVarBackSyntax += (Get-Random -Input @('Set-Variable','SV','SET')) + ' '*(Get-Random -Input @(1,2)) + "'OFS'" + ' '*(Get-Random -Input @(1,2)) + "' '"
    $SetOfsVarBack        = (Get-Random -Input $SetOfsVarBackSyntax)

    
    $SetOfsVar            = ([Char[]]$SetOfsVar     | ForEach-Object {$Char = $_.ToString().ToLower(); If(Get-Random -Input @(0..1)) {$Char = $Char.ToUpper()} $Char}) -Join ''
    $SetOfsVarBack        = ([Char[]]$SetOfsVarBack | ForEach-Object {$Char = $_.ToString().ToLower(); If(Get-Random -Input @(0..1)) {$Char = $Char.ToUpper()} $Char}) -Join ''

    
    $BaseScriptArray  = @()
    $BaseScriptArray += '(' + ' '*(Get-Random -Input @(0,1)) + "'" + $DelimitedEncodedArray + "'." + $Split + "(" + ' '*(Get-Random -Input @(0,1)) + "'" + $RandomDelimitersToPrint + "'" + ' '*(Get-Random -Input @(0,1)) + ')' + ' '*(Get-Random -Input @(0,1)) + '|' + ' '*(Get-Random -Input @(0,1)) + $ForEachObject + ' '*(Get-Random -Input @(0,1)) + '{' + ' '*(Get-Random -Input @(0,1)) + '(' + ' '*(Get-Random -Input @(0,1)) + $RandomConversionSyntax + ')' +  ' '*(Get-Random -Input @(0,1)) + '}' + ' '*(Get-Random -Input @(0,1)) + ')'
    $BaseScriptArray += '(' + ' '*(Get-Random -Input @(0,1)) + "'" + $DelimitedEncodedArray + "'" + ' '*(Get-Random -Input @(0,1)) + $RandomDelimitersToPrintForDashSplit + ' '*(Get-Random -Input @(0,1)) + '|' + ' '*(Get-Random -Input @(0,1)) + $ForEachObject + ' '*(Get-Random -Input @(0,1)) + '{' + ' '*(Get-Random -Input @(0,1)) + '(' + ' '*(Get-Random -Input @(0,1)) + $RandomConversionSyntax + ')' +  ' '*(Get-Random -Input @(0,1)) + '}' + ' '*(Get-Random -Input @(0,1)) + ')'
    $BaseScriptArray += '(' + ' '*(Get-Random -Input @(0,1)) + $EncodedArray + ' '*(Get-Random -Input @(0,1)) + '|' + ' '*(Get-Random -Input @(0,1)) + $ForEachObject + ' '*(Get-Random -Input @(0,1)) + '{' + ' '*(Get-Random -Input @(0,1)) + '(' + ' '*(Get-Random -Input @(0,1)) + $RandomConversionSyntax + ')' +  ' '*(Get-Random -Input @(0,1)) + '}' + ' '*(Get-Random -Input @(0,1)) + ')'
    
    
    $NewScriptArray   = @()
    $NewScriptArray  += (Get-Random -Input $BaseScriptArray) + ' '*(Get-Random -Input @(0,1)) + $Join + ' '*(Get-Random -Input @(0,1)) + "''"
    $NewScriptArray  += $Join + ' '*(Get-Random -Input @(0,1)) + (Get-Random -Input $BaseScriptArray)
    $NewScriptArray  += $StrJoin + '(' + ' '*(Get-Random -Input @(0,1)) + "''" + ' '*(Get-Random -Input @(0,1)) + ',' + ' '*(Get-Random -Input @(0,1)) + (Get-Random -Input $BaseScriptArray) + ' '*(Get-Random -Input @(0,1)) + ')'
    $NewScriptArray  += '"' + ' '*(Get-Random -Input @(0,1)) + '$(' + ' '*(Get-Random -Input @(0,1)) + $SetOfsVar + ' '*(Get-Random -Input @(0,1)) + ')' + ' '*(Get-Random -Input @(0,1)) + '"' + ' '*(Get-Random -Input @(0,1)) + '+' + ' '*(Get-Random -Input @(0,1)) + $StrStr + (Get-Random -Input $BaseScriptArray) + ' '*(Get-Random -Input @(0,1)) + '+' + '"' + ' '*(Get-Random -Input @(0,1)) + '$(' + ' '*(Get-Random -Input @(0,1)) + $SetOfsVarBack + ' '*(Get-Random -Input @(0,1)) + ')' + ' '*(Get-Random -Input @(0,1)) + '"'

    
    $NewScript = (Get-Random -Input $NewScriptArray)

    
    
    $InvokeExpressionSyntax  = @()
    $InvokeExpressionSyntax += (Get-Random -Input @('IEX','Invoke-Expression'))
    
    
    
    $InvocationOperator = (Get-Random -Input @('.','&')) + ' '*(Get-Random -Input @(0,1))
    $InvokeExpressionSyntax += $InvocationOperator + "( `$ShellId[1]+`$ShellId[13]+'x')"
    $InvokeExpressionSyntax += $InvocationOperator + "( `$PSHome[" + (Get-Random -Input @(4,21)) + "]+`$PSHome[" + (Get-Random -Input @(30,34)) + "]+'x')"
    $InvokeExpressionSyntax += $InvocationOperator + "( `$env:Public[13]+`$env:Public[5]+'x')"
    $InvokeExpressionSyntax += $InvocationOperator + "( `$env:ComSpec[4," + (Get-Random -Input @(15,24,26)) + ",25]-Join'')"
    $InvokeExpressionSyntax += $InvocationOperator + "((" + (Get-Random -Input @('Get-Variable','GV','Variable')) + " '*mdr*').Name[3,11,2]-Join'')"
    $InvokeExpressionSyntax += $InvocationOperator + "( " + (Get-Random -Input @('$VerbosePreference.ToString()','([String]$VerbosePreference)')) + "[1,3]+'x'-Join'')"

    
    $InvokeExpression = (Get-Random -Input $InvokeExpressionSyntax)

    
    $InvokeExpression = ([Char[]]$InvokeExpression | ForEach-Object {$Char = $_.ToString().ToLower(); If(Get-Random -Input @(0..1)) {$Char = $Char.ToUpper()} $Char}) -Join ''
    
    
    $InvokeOptions  = @()
    $InvokeOptions += ' '*(Get-Random -Input @(0,1)) + $InvokeExpression + ' '*(Get-Random -Input @(0,1)) + '(' + ' '*(Get-Random -Input @(0,1)) + $NewScript + ' '*(Get-Random -Input @(0,1)) + ')' + ' '*(Get-Random -Input @(0,1))
    $InvokeOptions += ' '*(Get-Random -Input @(0,1)) + $NewScript + ' '*(Get-Random -Input @(0,1)) + '|' + ' '*(Get-Random -Input @(0,1)) + $InvokeExpression

    $NewScript = (Get-Random -Input $InvokeOptions)

    
    If(!$PSBoundParameters['PassThru'])
    {
        
        $PowerShellFlags = @()

        
        
        $CommandlineOptions = New-Object String[](0)
        If($PSBoundParameters['NoExit'])
        {
          $FullArgument = "-NoExit";
          $CommandlineOptions += $FullArgument.SubString(0,(Get-Random -Minimum 4 -Maximum ($FullArgument.Length+1)))
        }
        If($PSBoundParameters['NoProfile'])
        {
          $FullArgument = "-NoProfile";
          $CommandlineOptions += $FullArgument.SubString(0,(Get-Random -Minimum 4 -Maximum ($FullArgument.Length+1)))
        }
        If($PSBoundParameters['NonInteractive'])
        {
          $FullArgument = "-NonInteractive";
          $CommandlineOptions += $FullArgument.SubString(0,(Get-Random -Minimum 5 -Maximum ($FullArgument.Length+1)))
        }
        If($PSBoundParameters['NoLogo'])
        {
          $FullArgument = "-NoLogo";
          $CommandlineOptions += $FullArgument.SubString(0,(Get-Random -Minimum 4 -Maximum ($FullArgument.Length+1)))
        }
        If($PSBoundParameters['WindowStyle'] -OR $WindowsStyle)
        {
            $FullArgument = "-WindowStyle"
            If($WindowsStyle) {$ArgumentValue = $WindowsStyle}
            Else {$ArgumentValue = $PSBoundParameters['WindowStyle']}

            
            Switch($ArgumentValue.ToLower())
            {
                'normal'    {If(Get-Random -Input @(0..1)) {$ArgumentValue = (Get-Random -Input @('0','n','no','nor','norm','norma'))}}
                'hidden'    {If(Get-Random -Input @(0..1)) {$ArgumentValue = (Get-Random -Input @('1','h','hi','hid','hidd','hidde'))}}
                'minimized' {If(Get-Random -Input @(0..1)) {$ArgumentValue = (Get-Random -Input @('2','mi','min','mini','minim','minimi','minimiz','minimize'))}}
                'maximized' {If(Get-Random -Input @(0..1)) {$ArgumentValue = (Get-Random -Input @('3','ma','max','maxi','maxim','maximi','maximiz','maximize'))}}
                default {Write-Error "An invalid `$ArgumentValue value ($ArgumentValue) was passed to switch block for Out-PowerShellLauncher."; Exit;}
            }

            $PowerShellFlags += $FullArgument.SubString(0,(Get-Random -Minimum 2 -Maximum ($FullArgument.Length+1))) + ' '*(Get-Random -Minimum 1 -Maximum 3) + $ArgumentValue
        }
        If($PSBoundParameters['ExecutionPolicy'] -OR $ExecutionPolicy)
        {
            $FullArgument = "-ExecutionPolicy"
            If($ExecutionPolicy) {$ArgumentValue = $ExecutionPolicy}
            Else {$ArgumentValue = $PSBoundParameters['ExecutionPolicy']}
            
            $ExecutionPolicyFlags = @()
            $ExecutionPolicyFlags += '-EP'
            For($Index=3; $Index -le $FullArgument.Length; $Index++)
            {
                $ExecutionPolicyFlags += $FullArgument.SubString(0,$Index)
            }
            $ExecutionPolicyFlag = Get-Random -Input $ExecutionPolicyFlags
            $PowerShellFlags += $ExecutionPolicyFlag + ' '*(Get-Random -Minimum 1 -Maximum 3) + $ArgumentValue
        }
        
        
        
        If($CommandlineOptions.Count -gt 1)
        {
            $CommandlineOptions = Get-Random -InputObject $CommandlineOptions -Count $CommandlineOptions.Count
        }

        
        If($PSBoundParameters['Command'])
        {
            $FullArgument = "-Command"
            $CommandlineOptions += $FullArgument.SubString(0,(Get-Random -Minimum 2 -Maximum ($FullArgument.Length+1)))
        }

        
        For($i=0; $i -lt $PowerShellFlags.Count; $i++)
        {
            $PowerShellFlags[$i] = ([Char[]]$PowerShellFlags[$i] | ForEach-Object {$Char = $_.ToString().ToLower(); If(Get-Random -Input @(0..1)) {$Char = $Char.ToUpper()} $Char}) -Join ''
        }

        
        $CommandlineOptions = ($CommandlineOptions | ForEach-Object {$_ + " "*(Get-Random -Minimum 1 -Maximum 3)}) -Join ''
        $CommandlineOptions = " "*(Get-Random -Minimum 0 -Maximum 3) + $CommandlineOptions + " "*(Get-Random -Minimum 0 -Maximum 3)

        
        If($PSBoundParameters['Wow64'])
        {
            $CommandLineOutput = "C:\WINDOWS\SysWOW64\WindowsPowerShell\v1.0\powershell.exe $($CommandlineOptions) `"$NewScript`""
        }
        Else
        {
            
            
            $CommandLineOutput = "powershell $($CommandlineOptions) `"$NewScript`""
        }

        
        $CmdMaxLength = 8190
        If($CommandLineOutput.Length -gt $CmdMaxLength)
        {
            Write-Warning "This command exceeds the cmd.exe maximum allowed length of $CmdMaxLength characters! Its length is $($CmdLineOutput.Length) characters."
        }
        
        $NewScript = $CommandLineOutput
    }

    Return $NewScript
}