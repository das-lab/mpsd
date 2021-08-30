


$outputDir = Join-Path -Path $ENV:BHProjectPath -ChildPath 'out'
$outputModDir = Join-Path -Path $outputDir -ChildPath $env:BHProjectName
$manifest = Import-PowerShellDataFile -Path $env:BHPSModuleManifest
$outputModVerDir = Join-Path -Path $outputModDir -ChildPath $manifest.ModuleVersion





$commands = Get-Command -Module (Get-Module $env:BHProjectName) -CommandType Cmdlet, Function, Workflow  




foreach ($command in $commands) {
    $commandName = $command.Name

    
    $help = Get-Help $commandName -ErrorAction SilentlyContinue

    Describe "Test help for $commandName" {

        
        It 'should not be auto-generated' {
            $help.Synopsis | Should Not BeLike '*`[`<CommonParameters`>`]*'
        }

        
        It "gets description for $commandName" {
            $help.Description | Should Not BeNullOrEmpty
        }

        
        It "gets example code from $commandName" {
            ($help.Examples.Example | Select-Object -First 1).Code | Should Not BeNullOrEmpty
        }

        
        It "gets example help from $commandName" {
            ($help.Examples.Example.Remarks | Select-Object -First 1).Text | Should Not BeNullOrEmpty
        }

        Context "Test parameter help for $commandName" {

            $common = 'Debug', 'ErrorAction', 'ErrorVariable', 'InformationAction', 'InformationVariable', 'OutBuffer',
                'OutVariable', 'PipelineVariable', 'Verbose', 'WarningAction', 'WarningVariable', 'Confirm', 'Whatif'

            $parameters = $command.ParameterSets.Parameters |
                Sort-Object -Property Name -Unique |
                Where-Object { $_.Name -notin $common }
            $parameterNames = $parameters.Name

            
            $helpParameters = $help.Parameters.Parameter |
                Where-Object { $_.Name -notin $common } |
                Sort-Object -Property Name -Unique
            $helpParameterNames = $helpParameters.Name

            foreach ($parameter in $parameters) {
                $parameterName = $parameter.Name
                $parameterHelp = $help.parameters.parameter | Where-Object Name -EQ $parameterName

                
                It "gets help for parameter: $parameterName : in $commandName" {
                    $parameterHelp.Description.Text | Should Not BeNullOrEmpty
                }

                
                It "help for $parameterName parameter in $commandName has correct Mandatory value" {
                    $codeMandatory = $parameter.IsMandatory.toString()
                    $parameterHelp.Required | Should Be $codeMandatory
                }

                
                
                
                
                
                
                
            }

            foreach ($helpParm in $HelpParameterNames) {
                
                It "finds help parameter in code: $helpParm" {
                    $helpParm -in $parameterNames | Should Be $true
                }
            }
        }

        Context "Help Links should be Valid for $commandName" {
            $link = $help.relatedLinks.navigationLink.uri

            foreach ($link in $links) {
                if ($link) {
                    
                    it "[$link] should have 200 Status Code for $commandName" {
                        $Results = Invoke-WebRequest -Uri $link -UseBasicParsing
                        $Results.StatusCode | Should Be '200'
                    }
                }
            }
        }
    }
}
