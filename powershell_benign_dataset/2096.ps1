

$ProgressPreference = "SilentlyContinue"

Describe 'get-help HelpFunc1' -Tags "Feature" {
    BeforeAll {
    function TestHelpError {
        [CmdletBinding()]
        param(
        $x,
        [System.Management.Automation.ErrorRecord[]]$e,
        [string] $expectedError
        )
        It 'Help result should be $null' { $x | Should -BeNullOrEmpty }
        It '$e.Count' { $e.Count | Should -BeGreaterThan 0 }
        It 'FullyQualifiedErrorId' { $e[0].FullyQualifiedErrorId | Should -BeExactly $expectedError }
    }

    function TestHelpFunc1 {
        [CmdletBinding()]
        param( $x )
        It '$x should not be $null' { $x | Should -Not -BeNullOrEmpty }
        It '$x.Synopsis' { $x.Synopsis | Should -BeExactly "A relatively useless function." }
        It '$x.Description' { $x.Description[0].Text | Should -BeExactly "A description`n`n    with indented text and a blank line." }
        It '$x.alertSet.alert' { $x.alertSet.alert[0].Text | Should -BeExactly "This function is mostly harmless." }
        It '$x.relatedLinks.navigationLink[0].uri' {  $x.relatedLinks.navigationLink[0].uri | Should -BeExactly "https://blogs.msdn.com/powershell" }
        It '$x.relatedLinks.navigationLink[1].linkText' { $x.relatedLinks.navigationLink[1].linkText | Should -BeExactly "other commands" }
        It '$x.examples.example.code' { $x.examples.example.code | Should -BeExactly "If you need an example, you're hopeless." }
        It '$x.inputTypes.inputType.type.name' { $x.inputTypes.inputType.type.name | Should -BeExactly "Anything you like." }
        It '$x.returnValues.returnValue.type.name' { $x.returnValues.returnValue.type.name | Should -BeExactly "Nothing." }
        It '$x.Component' { $x.Component | Should -BeExactly "Something" }
        It '$x.Role' { $x.Role | Should -BeExactly "CrazyUser" }
        It '$x.Functionality' { $x.Functionality | Should -BeExactly "Useless" }
        }

        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        function helpFunc1 {}

        Set-Item function:dynamicHelpFunc1 -Value {
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            

            process { }
        }
    }

    Context 'Get-Help helpFunc1' {
        $x = get-help helpFunc1
        TestHelpFunc1 $x
    }

    Context 'Get-Help dynamicHelpFunc1' {
        $x = get-help dynamicHelpFunc1
        TestHelpFunc1 $x
    }

    Context 'get-help helpFunc1 -component blah' {
        $x = get-help helpFunc1 -component blah -ErrorAction SilentlyContinue -ErrorVariable e
        TestHelpError $x $e 'HelpNotFound,Microsoft.PowerShell.Commands.GetHelpCommand'
    }

    Context 'get-help helpFunc1 -component Something' {
        $x = get-help helpFunc1 -component Something -ErrorAction SilentlyContinue -ErrorVariable e
        TestHelpFunc1 $x
        It '$e should be empty' { $e.Count | Should -Be 0 }
    }

    Context 'get-help helpFunc1 -role blah' {
        $x = get-help helpFunc1 -component blah -ErrorAction SilentlyContinue -ErrorVariable e
        TestHelpError $x $e 'HelpNotFound,Microsoft.PowerShell.Commands.GetHelpCommand'
    }

    Context 'get-help helpFunc1 -role CrazyUser' {
        $x = get-help helpFunc1 -role CrazyUser -ErrorAction SilentlyContinue -ErrorVariable e
        TestHelpFunc1 $x
        It '$e should be empty' { $e.Count | Should -Be 0 }
    }

    Context '$x = get-help helpFunc1 -functionality blah' {
        $x = get-help helpFunc1 -functionality blah -ErrorAction SilentlyContinue -ErrorVariable e
        TestHelpError $x $e 'HelpNotFound,Microsoft.PowerShell.Commands.GetHelpCommand'
    }

    Context '$x = get-help helpFunc1 -functionality Useless' {
        $x = get-help helpFunc1 -functionality Useless -ErrorAction SilentlyContinue -ErrorVariable e
        TestHelpFunc1 $x
        It '$e should be empty' { $e.Count | Should -Be 0 }
    }
}

Describe 'get-help file' -Tags "CI" {
    BeforeAll {
        try {
            $tmpfile = [IO.Path]::ChangeExtension([IO.Path]::GetTempFileName(), "ps1")
        } catch {
            return
        }
    }

    AfterAll {
        remove-item $tmpfile -Force -ErrorAction silentlycontinue
    }

    Context 'get-help file1' {

        @'
    
    
    function foo
    {
    }

    get-help foo
'@ > $tmpfile

        $x = get-help $tmpfile
        It '$x should not be $null' { $x | Should -Not -BeNullOrEmpty }
        $x = & $tmpfile
        It '$x.Synopsis' { $x.Synopsis | Should -BeExactly 'Function help, not script help' }
    }

    Context 'get-help file2' {

	    
        @'
        
        


        function foo
        {
        }

        get-help foo
'@ > $tmpfile

        $x = get-help $tmpfile
        It '$x.Synopsis' { $x.Synopsis | Should -BeExactly 'Script help, not function help' }
        $x = & $tmpfile
        It '$x should not be $null' { $x | Should -Not -BeNullOrEmpty }
    }
}

Describe 'get-help other tests' -Tags "CI" {
    BeforeAll {
        try {
            $tempFile = [IO.Path]::ChangeExtension([IO.Path]::GetTempFileName(), "ps1")
        } catch {
            return
        }
    }

    AfterAll {
        remove-item $tempFile -Force -ErrorAction silentlycontinue
    }

    Context 'get-help missingHelp' {
        

        


        function missingHelp { param($abc) }
            $x = get-help missingHelp
            It '$x should not be $null' { $x | Should -Not -BeNullOrEmpty }
            It '$x.Synopsis' { $x.Synopsis.Trim() | Should -BeExactly 'missingHelp [[-abc] <Object>]' }
        }

    Context 'get-help helpFunc2' {

    

    function helpFunc2 { param($abc) }

        $x = get-help helpFunc2
        It '$x should not be $null' { $x | Should -Not -BeNullOrEmpty }
        It '$x.Synopsis' { $x.Synopsis.Trim() | Should -BeExactly 'This help block goes on helpFunc2' }
    }

    Context 'get-help file and get-help helpFunc2' {
        $script = @"
            

            
            function helpFunc2 {}

            get-help helpFunc2
"@

        Set-Content $tempFile $script
        $x = get-help $tempFile
        It '$x.Synopsis' { $x.Synopsis | Should -BeExactly "This is script help" }

        $x = & $tempFile
        It '$x.Synopsis' { $x.Synopsis | Should -BeExactly "This is function help for helpFunc2" }
    }

    Context 'get-help file and get-help helpFunc2' {
    $script = @"
        
        
        
        

        
        
        
        
        function helpFunc2 {}

        get-help helpFunc2
"@

        Set-Content $tempFile $script
        $x = get-help $tempFile
        It $x.Synopsis { $x.Synopsis | Should -BeExactly "This is script help" }

        $x = & $tempFile
        It $x.Synopsis { $x.Synopsis | Should -BeExactly "This is function help for helpFunc2" }
    }

    Context 'get-help psuedo file' {

    $script = @'
        
        
        
        
        

        

        
        
        
        
        [CmdletBinding(DefaultParameterSetName="Live")]
        param(
        [Parameter(
	        ParameterSetName="Live",
	        Mandatory=$true)]
        $live,
        [Parameter(
	        ParameterSetName="Test",
	        Mandatory=$true)]
        $test)
'@

        Set-Content $tempFile $script
        $x = get-help $tempFile

        It '$x.Synopsis' { $x.Synopsis | Should -BeExactly "Changes Admin passwords across all KDE servers." }
        It '$x.parameters.parameter[0].required' { $x.parameters.parameter[0].required | Should -BeTrue}
        It '$x.syntax.syntaxItem[0].parameter.required' { $x.syntax.syntaxItem[0].parameter.required | Should -BeTrue}
        It '$x.syntax.syntaxItem[0].parameter.parameterValue.required' { $x.syntax.syntaxItem[0].parameter.parameterValue.required | Should -BeTrue}
        It 'Common parameters should not be appear in the syntax' { $x.Syntax -like "*verbose*" | Should -BeFalse }
        It 'Common parameters should not be in syntax maml' {@($x.syntax.syntaxItem[0].parameter).Count | Should -Be 1}
        It 'Common parameters should also not appear in parameters maml' { $x.parameters.parameter.Count | Should -Be 2}
    }

    It 'helpFunc3 -?' {

        

        function helpFunc3()
        {
        
        
        
        
        
        
        
        }

        $x = helpFunc3 -?
        $x.Synopsis | Should -BeExactly "A synopsis of helpFunc3."
    }

    It 'get-help helpFunc4' {

        
        function helpFunc4()
        {
        }

        $x = get-help helpFunc4
        $x.Synopsis | Should -BeExactly ""
    }

    Context 'get-help helpFunc5' {

        function helpFunc5
        {
            
        }
        $x = get-help helpFunc5
        It '$x should not be $null' { $x | Should -Not -BeNullOrEmpty }
        It '$x.Synopsis' { $x.Synopsis | Should -BeExactly "A useless function, really." }
    }

    Context 'get-help helpFunc6 script help xml' {
        function helpFunc6
        {
            
        }
        if ($PSUICulture -ieq "en-us")
        {
            $x = get-help helpFunc6
            It '$x should not be $null' { $x | Should -Not -BeNullOrEmpty }
            It '$x.Synopsis' { $x.Synopsis | Should -BeExactly "Useless.  Really, trust me on this one." }
        }
    }

    Context 'get-help helpFunc6 script help xml' {
        function helpFunc6
        {
            
        }
        if ($PSUICulture -ieq "en-us")
        {
            $x = get-help helpFunc6
            It '$x should not be $null' { $x | Should -Not -BeNullOrEmpty }
            It '$x.Synopsis' { $x.Synopsis | Should -BeExactly "Useless in newbase.  Really, trust me on this one." }
        }
    }

    Context 'get-help helpFunc7' {

        function helpFunc7
        {
            
            
        }
        $x = Get-Help helpFunc7
        It '$x.Name' { $x.Name | Should -BeExactly 'Get-Help' }
        It '$x.Category' { $x.Category | Should -BeExactly 'Cmdlet' }

        
        if ($null -ne (get-command -type Function help))
        {
            if ((get-content function:help) -Match "FORWARDHELP")
            {
                $x = Get-Help help
                It '$x.Name' { $x.Name | Should -BeExactly 'Get-Help' }
                It '$x.Category' { $x.Category | Should -BeExactly 'Cmdlet' }
            }
        }
    }

    Context 'get-help helpFunc8' {

        function func8
        {
            
            
            function helpFunc8
            {
            }
            get-help helpFunc8
        }

        $x = Get-Help func8
        It '$x should not be $null' { $x | Should -Not -BeNullOrEmpty }

        $x = func8
        It '$x.Synopsis' { $x.Synopsis | Should -BeExactly 'Help on helpFunc8, not func8' }
    }

    Context 'get-help helpFunc9' {
        function helpFunc9
        {
            
            
            param($x)

            function func9
            {
            }
            get-help func9
        }
        $x = Get-Help helpFunc9
        It 'help is on the outer functon' { $x.Synopsis | Should -BeExactly 'Help on helpFunc9, not func9' }
        $x = helpFunc9
        It '$x should not be $null' { $x | Should -Not -BeNullOrEmpty }
    }

    It 'get-help helpFunc10' {
        
        
        
        
        function helpFunc10
        {
        }

        $x = get-help helpFunc10
        $x.Synopsis | Should -BeExactly 'Help on helpFunc10'
    }

    Context 'get-help helpFunc11' {
        function helpFunc11
        {
        
        
        

            param(

                

                 [parameter()]    [string]
                $abc,

                [string]
                
                $def,

                [parameter()]
                
                $ghi,

                

                $jkl,

                $mno,
                [int]$pqr

                )
        }

        $x = get-help helpFunc11 -det
        $x.Parameters.parameter | ForEach-Object {
        It '$_.description' { $_.description[0].text | Should -Match "^$($_.Name)\s+help" }
        }
    }

    Context 'get-help helpFunc12' {
        
        function helpFunc12 {
            Param ([Parameter(Mandatory=$true)][String]$Name,
                   [string]$Extension = "txt",
                   $NoType,
                   [switch]$ASwitch,
                   [System.Management.Automation.CommandTypes]$AnEnum)
            $name = $name + "." + $extension
            $name

        
        }
        $x = get-help helpFunc12
        It '$x.syntax' { ($x.syntax | Out-String -width 250) | Should -Match "helpFunc12 \[-Name] <String> \[\[-Extension] <String>] \[\[-NoType] <Object>] \[-ASwitch] \[\[-AnEnum] \{Alias.*All}] \[<CommonParameters>]" }
        It '$x.syntax.syntaxItem.parameter[3].position' { $x.syntax.syntaxItem.parameter[3].position | Should -BeExactly 'named' }
        It '$x.syntax.syntaxItem.parameter[3].parameterValue' { $x.syntax.syntaxItem.parameter[3].parameterValue | Should -BeNullOrEmpty }
        It '$x.parameters.parameter[3].parameterValue' { $x.parameters.parameter[3].parameterValue | Should -Not -BeNullOrEmpty }
        It '$x.syntax.syntaxItem.parameter[4].parameterValueGroup' { $x.syntax.syntaxItem.parameter[4].parameterValueGroup | Should -Not -BeNullOrEmpty }
        It '$x.parameters.parameter[4].parameterValueGroup' { $x.parameters.parameter[4].parameterValueGroup | Should -Not -BeNullOrEmpty }
        It '$x.examples.example[0].introduction[0].text' { $x.examples.example[0].introduction[0].text | Should -BeExactly 'PS>' }
        It '$x.examples.example[0].code' { $x.examples.example[0].code | Should -BeExactly 'helpFunc12 -Name foo' }
        It '$x.examples.example[0].remarks[0].text' { $x.examples.example[0].remarks[0].text | Should -BeExactly 'Adds .txt to foo' }
        It '$x.examples.example[0].remarks.length' { $x.examples.example[0].remarks.length | Should -Be 5 }
        It '$x.examples.example[1].introduction[0].text' { $x.examples.example[1].introduction[0].text | Should -BeExactly 'C:\PS>' }
        It '$x.examples.example[1].code' { $x.examples.example[1].code | Should -BeExactly 'helpFunc12 bar txt' }
        It '$x.examples.example[1].remarks[0].text' { $x.examples.example[1].remarks[0].text | Should -BeExactly 'Adds .txt to bar' }
        It '$x.examples.example[1].remarks.length' { $x.examples.example[1].remarks.length | Should -Be 5 }
    }

    Context 'get-help helpFunc12' {
        function helpFunc13
        {
        
            param(
                [SupportsWildcards()]
                $p1,
                $p2 = 42,
                [PSDefaultValue(Help="parameter is mandatory")]
                $p3 = $(throw "parameter p3 is not specified")
            )
        }

        $x = get-help helpFunc13

        It '$x.Parameters.parameter[0].globbing' { $x.Parameters.parameter[0].globbing | Should -BeExactly 'true' }
        It '$x.Parameters.parameter[1].defaultValue' { $x.Parameters.parameter[1].defaultValue | Should -BeExactly '42' }
        It '$x.Parameters.parameter[2].defaultValue' { $x.Parameters.parameter[2].defaultValue | Should -BeExactly 'parameter is mandatory' }
    }

    Context 'get-help -Examples prompt string should have trailing space' {
        function foo {
            
              param()
        }

        It 'prompt should be exactly "PS > " with trailing space' {
            (Get-Help foo -Examples).examples.example.introduction.Text | Should -BeExactly "PS > "
        }
    }
}
