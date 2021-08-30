
[CmdletBinding()]
Param (
	[switch]
	$SkipTest,
	
	[string[]]
	$CommandPath = @("$PSScriptRoot\..\..\functions", "$PSScriptRoot\..\..\internal\functions"),
	
	[string]
	$ModuleName = "PSFramework",
	
	[string]
	$ExceptionsFile = "$PSScriptRoot\Help.Exceptions.ps1"
)
if ($SkipTest) { return }
. $ExceptionsFile

$includedNames = (Get-ChildItem $CommandPath -Recurse -File | Where-Object Name -like "*.ps1").BaseName
$commands = Get-Command -Module (Get-Module $ModuleName) -CommandType Cmdlet, Function, Workflow | Where-Object Name -in $includedNames
$ExportedCommands = ((Get-Module $ModuleName -ListAvailable).ExportedCommands).Keys




foreach ($command in $commands) {
    $commandName = $command.Name
	$HelpUri = "https://psframework.org/documentation/commands/PSFramework/$commandName"
    
    if ($global:FunctionHelpTestExceptions -contains $commandName) { continue }
    
    
    $Help = Get-Help $commandName -ErrorAction SilentlyContinue
    $testhelperrors = 0
    $testhelpall = 0
    Describe "Test help for $commandName" {
		
		$testhelpall += 1
		if (($command.HelpUri -notlike $HelpUri) -and ($ExportedCommands -contains $commandName)) {
			
			It "should contain a proper helpuri" {
				$Command.HelpUri | Should Be $HelpUri
			}
			$testhelperrors += 1
		}
		
        $testhelpall += 1
        if ($Help.Synopsis -like '*`[`<CommonParameters`>`]*') {
            
            It "should not be auto-generated" {
                $Help.Synopsis | Should -Not -BeLike '*`[`<CommonParameters`>`]*'
            }
            $testhelperrors += 1
        }
        
        $testhelpall += 1
        if ([String]::IsNullOrEmpty($Help.Description.Text)) {
            
            It "gets description for $commandName" {
                $Help.Description | Should -Not -BeNullOrEmpty
            }
            $testhelperrors += 1
        }
        
        $testhelpall += 1
        if ([String]::IsNullOrEmpty(($Help.Examples.Example | Select-Object -First 1).Code)) {
            
            It "gets example code from $commandName" {
                ($Help.Examples.Example | Select-Object -First 1).Code | Should -Not -BeNullOrEmpty
            }
            $testhelperrors += 1
        }
        
        $testhelpall += 1
        if ([String]::IsNullOrEmpty(($Help.Examples.Example.Remarks | Select-Object -First 1).Text)) {
            
            It "gets example help from $commandName" {
                ($Help.Examples.Example.Remarks | Select-Object -First 1).Text | Should -Not -BeNullOrEmpty
            }
            $testhelperrors += 1
        }
        
        if ($testhelperrors -eq 0) {
            It "Ran silently $testhelpall tests" {
                $testhelperrors | Should -be 0
            }
        }
        
        $testparamsall = 0
        $testparamserrors = 0
        Context "Test parameter help for $commandName" {
            
            $Common = 'Debug', 'ErrorAction', 'ErrorVariable', 'InformationAction', 'InformationVariable', 'OutBuffer', 'OutVariable',
            'PipelineVariable', 'Verbose', 'WarningAction', 'WarningVariable'
            
            $parameters = $command.ParameterSets.Parameters | Sort-Object -Property Name -Unique | Where-Object Name -notin $common
            $parameterNames = $parameters.Name
            $HelpParameterNames = $Help.Parameters.Parameter.Name | Sort-Object -Unique
            foreach ($parameter in $parameters) {
                $parameterName = $parameter.Name
                $parameterHelp = $Help.parameters.parameter | Where-Object Name -EQ $parameterName
                
                $testparamsall += 1
                if ([String]::IsNullOrEmpty($parameterHelp.Description.Text)) {
                    
                    It "gets help for parameter: $parameterName : in $commandName" {
                        $parameterHelp.Description.Text | Should -Not -BeNullOrEmpty
                    }
                    $testparamserrors += 1
                }
                
                $testparamsall += 1
                $codeMandatory = $parameter.IsMandatory.toString()
                if ($parameterHelp.Required -ne $codeMandatory) {
                    
                    It "help for $parameterName parameter in $commandName has correct Mandatory value" {
                        $parameterHelp.Required | Should -Be $codeMandatory
                    }
                    $testparamserrors += 1
                }
                
                if ($HelpTestSkipParameterType[$commandName] -contains $parameterName) { continue }
                
                $codeType = $parameter.ParameterType.Name
                
                $testparamsall += 1
                if ($parameter.ParameterType.IsEnum) {
                    
                    $names = $parameter.ParameterType::GetNames($parameter.ParameterType)
                    if ($parameterHelp.parameterValueGroup.parameterValue -ne $names) {
                        
                        It "help for $commandName has correct parameter type for $parameterName" {
                            $parameterHelp.parameterValueGroup.parameterValue | Should -be $names
                        }
                        $testparamserrors += 1
                    }
                }
                elseif ($parameter.ParameterType.FullName -in $HelpTestEnumeratedArrays) {
                    
                    $names = [Enum]::GetNames($parameter.ParameterType.DeclaredMembers[0].ReturnType)
                    if ($parameterHelp.parameterValueGroup.parameterValue -ne $names) {
                        
                        It "help for $commandName has correct parameter type for $parameterName" {
                            $parameterHelp.parameterValueGroup.parameterValue | Should -be $names
                        }
                        $testparamserrors += 1
                    }
                }
                else {
                    
                    $helpType = if ($parameterHelp.parameterValue) { $parameterHelp.parameterValue.Trim() }
                    if ($helpType -ne $codeType) {
                        
                        It "help for $commandName has correct parameter type for $parameterName" {
                            $helpType | Should -be $codeType
                        }
                        $testparamserrors += 1
                    }
                }
            }
            foreach ($helpParm in $HelpParameterNames) {
                $testparamsall += 1
                if ($helpParm -notin $parameterNames) {
                    
                    It "finds help parameter in code: $helpParm" {
                        $helpParm -in $parameterNames | Should -Be $true
                    }
                    $testparamserrors += 1
                }
            }
            if ($testparamserrors -eq 0) {
                It "Ran silently $testparamsall tests" {
                    $testparamserrors | Should -be 0
                }
            }
        }
    }
}