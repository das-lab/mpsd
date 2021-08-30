
class CommandParser {
    [ParsedCommand] static Parse([Message]$Message) {

        $commandString = [string]::Empty
        if (-not [string]::IsNullOrEmpty($Message.Text)) {
            $commandString = $Message.Text.Trim()
        }

        
        $cmdArray = $commandString.Split(' ')
        $command = $cmdArray[0]
        if ($cmdArray.Count -gt 1) {
            $commandArgs = $cmdArray[1..($cmdArray.length-1)] -join ' '
        } else {
            $commandArgs = [string]::Empty
        }

        
        if ($command -notlike '*://*') {
            $arrCmdStr = $command.Split(':')
        } else {
            $arrCmdStr = @($command)
        }

        
        $version = $null
        if ($arrCmdStr[1] -as [Version]) {
            $version = $arrCmdStr[1]
        } elseif ($arrCmdStr[2] -as [Version]) {
            $version = $arrCmdStr[2]
        }

        
        
        $plugin = [string]::Empty
        if ($Message.Type -eq [MessageType]::Message -and $Message.SubType -eq [MessageSubtype]::None ) {
            $plugin = $arrCmdStr[0]
        }
        if ($arrCmdStr[1] -as [Version]) {
            $command = $arrCmdStr[0]
            $plugin = $null
        } else {
            $command = $arrCmdStr[1]
            if (-not $command) {
                $command = $plugin
                $plugin = $null
            }
        }

        
        $parsedCommand = [ParsedCommand]::new()
        $parsedCommand.CommandString = $commandString
        $parsedCommand.Plugin = $plugin
        $parsedCommand.Command = $command
        $parsedCommand.OriginalMessage = $Message
        $parsedCommand.Time = $Message.Time
        if ($version)          { $parsedCommand.Version  = $version }
        if ($Message.To)       { $parsedCommand.To       = $Message.To }
        if ($Message.ToName)   { $parsedCommand.ToName   = $Message.ToName }
        if ($Message.From)     { $parsedCommand.From     = $Message.From }
        if ($Message.FromName) { $parsedCommand.FromName = $Message.FromName }

        
        try {
            $positionalParams = @()
            $namedParams = @{}

            if (-not [string]::IsNullOrEmpty($commandArgs)) {

                
                
                $astCmdStr = "fake-command $commandArgs" -Replace '(\s--([a-zA-Z0-9])*?)', ' -$2'
                $ast = [System.Management.Automation.Language.Parser]::ParseInput($astCmdStr, [ref]$null, [ref]$null)
                $commandAST = $ast.FindAll({$args[0] -as [System.Management.Automation.Language.CommandAst]},$false)

                for ($x = 1; $x -lt $commandAST.CommandElements.Count; $x++) {
                    $element = $commandAST.CommandElements[$x]

                    
                    
                    if ($element -is [System.Management.Automation.Language.CommandParameterAst]) {

                        $paramName = $element.ParameterName
                        $paramValues = @()
                        $y = 1

                        
                        
                        if ((-not $commandAST.CommandElements[$x+1]) -or ($commandAST.CommandElements[$x+1] -is [System.Management.Automation.Language.CommandParameterAst])) {
                            $paramValues = $true
                        } else {
                            
                            
                            do {
                                $elementValue = $commandAST.CommandElements[$x+$y]

                                if ($elementValue -is [System.Management.Automation.Language.VariableExpressionAst]) {
                                    
                                    
                                    $paramValues += $elementValue.Extent.Text
                                } else {
                                    if ($elementValue.Value) {
                                       $paramValues += $elementValue.Value
                                    } else {
                                        $paramValues += $elementValue.SafeGetValue()
                                    }
                                }
                                $y++
                            } until ((-not $commandAST.CommandElements[$x+$y]) -or $commandAST.CommandElements[$x+$y] -is [System.Management.Automation.Language.CommandParameterAst])
                        }

                        if ($paramValues.Count -eq 1) {
                            $paramValues = $paramValues[0]
                        }
                        $namedParams.Add($paramName, $paramValues)
                        $x += $y-1
                    } else {
                        
                        if ($element -is [System.Management.Automation.Language.VariableExpressionAst]) {
                            $positionalParams += $element.Extent.Text
                        } else {
                            if ($element.Value) {
                                $positionalParams += $element.Value
                            } else {
                                $positionalParams += $element.SafeGetValue()
                            }
                        }
                    }
                }
            }

            $parsedCommand.NamedParameters = $namedParams
            $parsedCommand.PositionalParameters = $positionalParams
        } catch {
            Write-Error -Message "Error parsing command [$CommandString]: $_"
        }

        return $parsedCommand
    }
}
