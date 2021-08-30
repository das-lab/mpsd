


















Function Invoke-Obfuscation
{


    [CmdletBinding(DefaultParameterSetName = 'ScriptBlock')] Param (
        [Parameter(Position = 0, ValueFromPipeline = $True, ParameterSetName = 'ScriptBlock')]
        [ValidateNotNullOrEmpty()]
        [ScriptBlock]
        $ScriptBlock,

        [Parameter(Position = 0, ParameterSetName = 'ScriptBlock')]
        [ValidateNotNullOrEmpty()]
        [String]
        $ScriptPath,
        
        [String]
        $Command,
        
        [Switch]
        $NoExit,
        
        [Switch]
        $Quiet
    )

    
    $Script:CliCommands       = @()
    $Script:CompoundCommand   = @()
    $Script:QuietWasSpecified = $FALSE
    $CliWasSpecified          = $FALSE
    $NoExitWasSpecified       = $FALSE

    
    If($PSBoundParameters['ScriptBlock'])
    {
        $Script:CliCommands += ('set scriptblock ' + [String]$ScriptBlock)
    }
    If($PSBoundParameters['ScriptPath'])
    {
        $Script:CliCommands += ('set scriptpath ' + $ScriptPath)
    }

    
    If($PSBoundParameters['Command'])
    {
        $Script:CliCommands += $Command.Split(',')
        $CliWasSpecified = $TRUE

        If($PSBoundParameters['NoExit'])
        {
            $NoExitWasSpecified = $TRUE
        }

        If($PSBoundParameters['Quiet'])
        {
            
            Function Write-Host {}
            Function Start-Sleep {}
            $Script:QuietWasSpecified = $TRUE
        }
    }

    
    
    

    
    
    $Script:ScriptPath   = ''
    $Script:ScriptBlock  = ''
    $Script:CliSyntax         = @()
    $Script:ExecutionCommands = @()
    $Script:ObfuscatedCommand = ''
    $Script:ObfuscatedCommandHistory = @()
    $Script:ObfuscationLength = ''
    $Script:OptionsMenu =   @()
    $Script:OptionsMenu += , @('ScriptPath '       , $Script:ScriptPath       , $TRUE)
    $Script:OptionsMenu += , @('ScriptBlock'       , $Script:ScriptBlock      , $TRUE)
    $Script:OptionsMenu += , @('CommandLineSyntax' , $Script:CliSyntax        , $FALSE)
    $Script:OptionsMenu += , @('ExecutionCommands' , $Script:ExecutionCommands, $FALSE)
    $Script:OptionsMenu += , @('ObfuscatedCommand' , $Script:ObfuscatedCommand, $FALSE)
    $Script:OptionsMenu += , @('ObfuscationLength' , $Script:ObfuscatedCommand, $FALSE)
    
    $SettableInputOptions = @()
    ForEach($Option in $Script:OptionsMenu)
    {
        If($Option[2]) {$SettableInputOptions += ([String]$Option[0]).ToLower().Trim()}
    }

    
    $Script:LauncherApplied = $FALSE

    
    If(!(Get-Module Invoke-Obfuscation | Where-Object {$_.ModuleType -eq 'Manifest'}))
    {
        $PathTopsd1 = "$ScriptDir\Invoke-Obfuscation.psd1"
        If($PathTopsd1.Contains(' ')) {$PathTopsd1 = '"' + $PathTopsd1 + '"'}
        Write-Host "`n`nERROR: Invoke-Obfuscation module is not loaded. You must run:" -ForegroundColor Red
        Write-Host "       Import-Module $PathTopsd1`n`n" -ForegroundColor Yellow
        Exit
    }

    
    $CmdMaxLength = 8190
    
    
    $LineSpacing = '[*] '
    
    
    $MenuLevel =   @()
    $MenuLevel+= , @($LineSpacing, 'TOKEN'    , 'Obfuscate PowerShell command <Tokens>')
    $MenuLevel+= , @($LineSpacing, 'STRING'   , 'Obfuscate entire command as a <String>')
    $MenuLevel+= , @($LineSpacing, 'ENCODING' , 'Obfuscate entire command via <Encoding>')
    $MenuLevel+= , @($LineSpacing, 'LAUNCHER' , 'Obfuscate command args w/<Launcher> techniques (run once at end)')
    
    
    $MenuLevel_Token                 =   @()
    $MenuLevel_Token                += , @($LineSpacing, 'STRING'     , 'Obfuscate <String> tokens (suggested to run first)')
    $MenuLevel_Token                += , @($LineSpacing, 'COMMAND'    , 'Obfuscate <Command> tokens')
    $MenuLevel_Token                += , @($LineSpacing, 'ARGUMENT'   , 'Obfuscate <Argument> tokens')
    $MenuLevel_Token                += , @($LineSpacing, 'MEMBER'     , 'Obfuscate <Member> tokens')
    $MenuLevel_Token                += , @($LineSpacing, 'VARIABLE'   , 'Obfuscate <Variable> tokens')
    $MenuLevel_Token                += , @($LineSpacing, 'TYPE  '     , 'Obfuscate <Type> tokens')
    $MenuLevel_Token                += , @($LineSpacing, 'COMMENT'    , 'Remove all <Comment> tokens')
    $MenuLevel_Token                += , @($LineSpacing, 'WHITESPACE' , 'Insert random <Whitespace> (suggested to run last)')
    $MenuLevel_Token                += , @($LineSpacing, 'ALL   '     , 'Select <All> choices from above (random order)')
    
    $MenuLevel_Token_String          =   @()
    $MenuLevel_Token_String         += , @($LineSpacing, '1' , "Concatenate --> e.g. <('co'+'ffe'+'e')>"                           , @('Out-ObfuscatedTokenCommand', 'String', 1))
    $MenuLevel_Token_String         += , @($LineSpacing, '2' , "Reorder     --> e.g. <('{1}{0}'-f'ffee','co')>"                    , @('Out-ObfuscatedTokenCommand', 'String', 2))
    
    $MenuLevel_Token_Command         =   @()
    $MenuLevel_Token_Command        += , @($LineSpacing, '1' , 'Ticks                   --> e.g. <Ne`w-O`Bject>'                   , @('Out-ObfuscatedTokenCommand', 'Command', 1))
    $MenuLevel_Token_Command        += , @($LineSpacing, '2' , "Splatting + Concatenate --> e.g. <&('Ne'+'w-Ob'+'ject')>"          , @('Out-ObfuscatedTokenCommand', 'Command', 2))
    $MenuLevel_Token_Command        += , @($LineSpacing, '3' , "Splatting + Reorder     --> e.g. <&('{1}{0}'-f'bject','New-O')>"   , @('Out-ObfuscatedTokenCommand', 'Command', 3))
    
    $MenuLevel_Token_Argument        =   @()
    $MenuLevel_Token_Argument       += , @($LineSpacing, '1' , 'Random Case --> e.g. <nEt.weBclIenT>'                              , @('Out-ObfuscatedTokenCommand', 'CommandArgument', 1))
    $MenuLevel_Token_Argument       += , @($LineSpacing, '2' , 'Ticks       --> e.g. <nE`T.we`Bc`lIe`NT>'                          , @('Out-ObfuscatedTokenCommand', 'CommandArgument', 2))
    $MenuLevel_Token_Argument       += , @($LineSpacing, '3' , "Concatenate --> e.g. <('Ne'+'t.We'+'bClient')>"                    , @('Out-ObfuscatedTokenCommand', 'CommandArgument', 3))
    $MenuLevel_Token_Argument       += , @($LineSpacing, '4' , "Reorder     --> e.g. <('{1}{0}'-f'bClient','Net.We')>"             , @('Out-ObfuscatedTokenCommand', 'CommandArgument', 4))
    
    $MenuLevel_Token_Member          =   @()
    $MenuLevel_Token_Member         += , @($LineSpacing, '1' , 'Random Case --> e.g. <dOwnLoAdsTRing>'                             , @('Out-ObfuscatedTokenCommand', 'Member', 1))
    $MenuLevel_Token_Member         += , @($LineSpacing, '2' , 'Ticks       --> e.g. <d`Ow`NLoAd`STRin`g>'                         , @('Out-ObfuscatedTokenCommand', 'Member', 2))
    $MenuLevel_Token_Member         += , @($LineSpacing, '3' , "Concatenate --> e.g. <('dOwnLo'+'AdsT'+'Ring').Invoke()>"          , @('Out-ObfuscatedTokenCommand', 'Member', 3))
    $MenuLevel_Token_Member         += , @($LineSpacing, '4' , "Reorder     --> e.g. <('{1}{0}'-f'dString','Downloa').Invoke()>"   , @('Out-ObfuscatedTokenCommand', 'Member', 4))
    
    $MenuLevel_Token_Variable        =   @()
    $MenuLevel_Token_Variable       += , @($LineSpacing, '1' , 'Random Case + {} + Ticks --> e.g. <${c`hEm`eX}>'                   , @('Out-ObfuscatedTokenCommand', 'Variable', 1))
    
    $MenuLevel_Token_Type            =   @()
    $MenuLevel_Token_Type           += , @($LineSpacing, '1' , "Type Cast + Concatenate --> e.g. <[Type]('Con'+'sole')>"           , @('Out-ObfuscatedTokenCommand', 'Type', 1))
    $MenuLevel_Token_Type           += , @($LineSpacing, '2' , "Type Cast + Reordered   --> e.g. <[Type]('{1}{0}'-f'sole','Con')>" , @('Out-ObfuscatedTokenCommand', 'Type', 2))
    
    $MenuLevel_Token_Whitespace      =   @()
    $MenuLevel_Token_Whitespace     += , @($LineSpacing, '1' , "`tRandom Whitespace --> e.g. <.( 'Ne'  +'w-Ob' +  'ject')>"        , @('Out-ObfuscatedTokenCommand', 'RandomWhitespace', 1))
    
    $MenuLevel_Token_Comment         =   @()
    $MenuLevel_Token_Comment        += , @($LineSpacing, '1' , "Remove Comments   --> e.g. self-explanatory"                       , @('Out-ObfuscatedTokenCommand', 'Comment', 1))

    $MenuLevel_Token_All             =   @()
    $MenuLevel_Token_All            += , @($LineSpacing, '1' , "`tExecute <ALL> Token obfuscation techniques (random order)"       , @('Out-ObfuscatedTokenCommandAll', '', ''))
    
    
    $MenuLevel_String                =   @()
    $MenuLevel_String               += , @($LineSpacing, '1' , '<Concatenate> entire command'                                      , @('Out-ObfuscatedStringCommand', '', 1))
    $MenuLevel_String               += , @($LineSpacing, '2' , '<Reorder> entire command after concatenating'                      , @('Out-ObfuscatedStringCommand', '', 2))
    $MenuLevel_String               += , @($LineSpacing, '3' , '<Reverse> entire command after concatenating'                      , @('Out-ObfuscatedStringCommand', '', 3))

    
    $MenuLevel_Encoding              =   @()
    $MenuLevel_Encoding             += , @($LineSpacing, '1' , "`tEncode entire command as <ASCII>"                                , @('Out-EncodedAsciiCommand'           , '', ''))
    $MenuLevel_Encoding             += , @($LineSpacing, '2' , "`tEncode entire command as <Hex>"                                  , @('Out-EncodedHexCommand'             , '', ''))
    $MenuLevel_Encoding             += , @($LineSpacing, '3' , "`tEncode entire command as <Octal>"                                , @('Out-EncodedOctalCommand'           , '', ''))
    $MenuLevel_Encoding             += , @($LineSpacing, '4' , "`tEncode entire command as <Binary>"                               , @('Out-EncodedBinaryCommand'          , '', ''))
    $MenuLevel_Encoding             += , @($LineSpacing, '5' , "`tEncrypt entire command as <SecureString> (AES)"                  , @('Out-SecureStringCommand'           , '', ''))
    $MenuLevel_Encoding             += , @($LineSpacing, '6' , "`tEncode entire command as <BXOR>"                                 , @('Out-EncodedBXORCommand'            , '', ''))
    $MenuLevel_Encoding             += , @($LineSpacing, '7' , "`tEncode entire command as <Special Characters>"                   , @('Out-EncodedSpecialCharOnlyCommand' , '', ''))
    $MenuLevel_Encoding             += , @($LineSpacing, '8' , "`tEncode entire command as <Whitespace>"                           , @('Out-EncodedWhitespaceCommand'      , '', ''))

    
    $MenuLevel_Launcher              =   @()
    $MenuLevel_Launcher             += , @($LineSpacing, 'PS'            , "`t<PowerShell>")
    $MenuLevel_Launcher             += , @($LineSpacing, 'CMD'           , '<Cmd> + PowerShell')
    $MenuLevel_Launcher             += , @($LineSpacing, 'WMIC'          , '<Wmic> + PowerShell')
    $MenuLevel_Launcher             += , @($LineSpacing, 'RUNDLL'        , '<Rundll32> + PowerShell')
    $MenuLevel_Launcher             += , @($LineSpacing, 'VAR+'          , 'Cmd + set <Var> && PowerShell iex <Var>')
    $MenuLevel_Launcher             += , @($LineSpacing, 'STDIN+'        , 'Cmd + <Echo> | PowerShell - (stdin)')
    $MenuLevel_Launcher             += , @($LineSpacing, 'CLIP+'         , 'Cmd + <Echo> | Clip && PowerShell iex <clipboard>')
    $MenuLevel_Launcher             += , @($LineSpacing, 'VAR++'         , 'Cmd + set <Var> && Cmd && PowerShell iex <Var>')
    $MenuLevel_Launcher             += , @($LineSpacing, 'STDIN++'       , 'Cmd + set <Var> && Cmd <Echo> | PowerShell - (stdin)')
    $MenuLevel_Launcher             += , @($LineSpacing, 'CLIP++'        , 'Cmd + <Echo> | Clip && Cmd && PowerShell iex <clipboard>')
    $MenuLevel_Launcher             += , @($LineSpacing, 'RUNDLL++'      , 'Cmd + set Var && <Rundll32> && PowerShell iex Var')
    $MenuLevel_Launcher             += , @($LineSpacing, 'MSHTA++'       , 'Cmd + set Var && <Mshta> && PowerShell iex Var')

    $MenuLevel_Launcher_PS           =   @()
    $MenuLevel_Launcher_PS          += , @("Enter string of numbers with all desired flags to pass to function. (e.g. 23459)`n", ''  , ''   , @('', '', ''))
    $MenuLevel_Launcher_PS          += , @($LineSpacing, '0' , 'NO EXECUTION FLAGS'                                          , @('Out-PowerShellLauncher', '', '1'))
    $MenuLevel_Launcher_PS          += , @($LineSpacing, '1' , '-NoExit'                                                     , @('Out-PowerShellLauncher', '', '1'))
    $MenuLevel_Launcher_PS          += , @($LineSpacing, '2' , '-NonInteractive'                                             , @('Out-PowerShellLauncher', '', '1'))
    $MenuLevel_Launcher_PS          += , @($LineSpacing, '3' , '-NoLogo'                                                     , @('Out-PowerShellLauncher', '', '1'))
    $MenuLevel_Launcher_PS          += , @($LineSpacing, '4' , '-NoProfile'                                                  , @('Out-PowerShellLauncher', '', '1'))
    $MenuLevel_Launcher_PS          += , @($LineSpacing, '5' , '-Command'                                                    , @('Out-PowerShellLauncher', '', '1'))
    $MenuLevel_Launcher_PS          += , @($LineSpacing, '6' , '-WindowStyle Hidden'                                         , @('Out-PowerShellLauncher', '', '1'))
    $MenuLevel_Launcher_PS          += , @($LineSpacing, '7' , '-ExecutionPolicy Bypass'                                     , @('Out-PowerShellLauncher', '', '1'))
    $MenuLevel_Launcher_PS          += , @($LineSpacing, '8' , '-Wow64 (to path 32-bit powershell.exe)'                      , @('Out-PowerShellLauncher', '', '1'))

    $MenuLevel_Launcher_CMD          =   @()
    $MenuLevel_Launcher_CMD         += , @("Enter string of numbers with all desired flags to pass to function. (e.g. 23459)`n", ''  , ''   , @('', '', ''))
    $MenuLevel_Launcher_CMD         += , @($LineSpacing, '0' , 'NO EXECUTION FLAGS'                                          , @('Out-PowerShellLauncher', '', '2'))
    $MenuLevel_Launcher_CMD         += , @($LineSpacing, '1' , '-NoExit'                                                     , @('Out-PowerShellLauncher', '', '2'))
    $MenuLevel_Launcher_CMD         += , @($LineSpacing, '2' , '-NonInteractive'                                             , @('Out-PowerShellLauncher', '', '2'))
    $MenuLevel_Launcher_CMD         += , @($LineSpacing, '3' , '-NoLogo'                                                     , @('Out-PowerShellLauncher', '', '2'))
    $MenuLevel_Launcher_CMD         += , @($LineSpacing, '4' , '-NoProfile'                                                  , @('Out-PowerShellLauncher', '', '2'))
    $MenuLevel_Launcher_CMD         += , @($LineSpacing, '5' , '-Command'                                                    , @('Out-PowerShellLauncher', '', '2'))
    $MenuLevel_Launcher_CMD         += , @($LineSpacing, '6' , '-WindowStyle Hidden'                                         , @('Out-PowerShellLauncher', '', '2'))
    $MenuLevel_Launcher_CMD         += , @($LineSpacing, '7' , '-ExecutionPolicy Bypass'                                     , @('Out-PowerShellLauncher', '', '2'))
    $MenuLevel_Launcher_CMD         += , @($LineSpacing, '8' , '-Wow64 (to path 32-bit powershell.exe)'                      , @('Out-PowerShellLauncher', '', '2'))

    $MenuLevel_Launcher_WMIC         =   @()
    $MenuLevel_Launcher_WMIC        += , @("Enter string of numbers with all desired flags to pass to function. (e.g. 23459)`n", ''  , ''   , @('', '', ''))
    $MenuLevel_Launcher_WMIC        += , @($LineSpacing, '0' , 'NO EXECUTION FLAGS'                                          , @('Out-PowerShellLauncher', '', '3'))
    $MenuLevel_Launcher_WMIC        += , @($LineSpacing, '1' , '-NoExit'                                                     , @('Out-PowerShellLauncher', '', '3'))
    $MenuLevel_Launcher_WMIC        += , @($LineSpacing, '2' , '-NonInteractive'                                             , @('Out-PowerShellLauncher', '', '3'))
    $MenuLevel_Launcher_WMIC        += , @($LineSpacing, '3' , '-NoLogo'                                                     , @('Out-PowerShellLauncher', '', '3'))
    $MenuLevel_Launcher_WMIC        += , @($LineSpacing, '4' , '-NoProfile'                                                  , @('Out-PowerShellLauncher', '', '3'))
    $MenuLevel_Launcher_WMIC        += , @($LineSpacing, '5' , '-Command'                                                    , @('Out-PowerShellLauncher', '', '3'))
    $MenuLevel_Launcher_WMIC        += , @($LineSpacing, '6' , '-WindowStyle Hidden'                                         , @('Out-PowerShellLauncher', '', '3'))
    $MenuLevel_Launcher_WMIC        += , @($LineSpacing, '7' , '-ExecutionPolicy Bypass'                                     , @('Out-PowerShellLauncher', '', '3'))
    $MenuLevel_Launcher_WMIC        += , @($LineSpacing, '8' , '-Wow64 (to path 32-bit powershell.exe)'                      , @('Out-PowerShellLauncher', '', '3'))

    $MenuLevel_Launcher_RUNDLL       =   @()
    $MenuLevel_Launcher_RUNDLL      += , @("Enter string of numbers with all desired flags to pass to function. (e.g. 23459)`n", ''  , ''   , @('', '', ''))
    $MenuLevel_Launcher_RUNDLL      += , @($LineSpacing, '0' , 'NO EXECUTION FLAGS'                                          , @('Out-PowerShellLauncher', '', '4'))
    $MenuLevel_Launcher_RUNDLL      += , @($LineSpacing, '1' , '-NoExit'                                                     , @('Out-PowerShellLauncher', '', '4'))
    $MenuLevel_Launcher_RUNDLL      += , @($LineSpacing, '2' , '-NonInteractive'                                             , @('Out-PowerShellLauncher', '', '4'))
    $MenuLevel_Launcher_RUNDLL      += , @($LineSpacing, '3' , '-NoLogo'                                                     , @('Out-PowerShellLauncher', '', '4'))
    $MenuLevel_Launcher_RUNDLL      += , @($LineSpacing, '4' , '-NoProfile'                                                  , @('Out-PowerShellLauncher', '', '4'))
    $MenuLevel_Launcher_RUNDLL      += , @($LineSpacing, '5' , '-Command'                                                    , @('Out-PowerShellLauncher', '', '4'))
    $MenuLevel_Launcher_RUNDLL      += , @($LineSpacing, '6' , '-WindowStyle Hidden'                                         , @('Out-PowerShellLauncher', '', '4'))
    $MenuLevel_Launcher_RUNDLL      += , @($LineSpacing, '7' , '-ExecutionPolicy Bypass'                                     , @('Out-PowerShellLauncher', '', '4'))
    $MenuLevel_Launcher_RUNDLL      += , @($LineSpacing, '8' , '-Wow64 (to path 32-bit powershell.exe)'                      , @('Out-PowerShellLauncher', '', '4'))

    ${MenuLevel_Launcher_VAR+}       =   @()
    ${MenuLevel_Launcher_VAR+}      += , @("Enter string of numbers with all desired flags to pass to function. (e.g. 23459)`n", ''  , ''   , @('', '', ''))
    ${MenuLevel_Launcher_VAR+}      += , @($LineSpacing, '0' , 'NO EXECUTION FLAGS'                                          , @('Out-PowerShellLauncher', '', '5'))
    ${MenuLevel_Launcher_VAR+}      += , @($LineSpacing, '1' , '-NoExit'                                                     , @('Out-PowerShellLauncher', '', '5'))
    ${MenuLevel_Launcher_VAR+}      += , @($LineSpacing, '2' , '-NonInteractive'                                             , @('Out-PowerShellLauncher', '', '5'))
    ${MenuLevel_Launcher_VAR+}      += , @($LineSpacing, '3' , '-NoLogo'                                                     , @('Out-PowerShellLauncher', '', '5'))
    ${MenuLevel_Launcher_VAR+}      += , @($LineSpacing, '4' , '-NoProfile'                                                  , @('Out-PowerShellLauncher', '', '5'))
    ${MenuLevel_Launcher_VAR+}      += , @($LineSpacing, '5' , '-Command'                                                    , @('Out-PowerShellLauncher', '', '5'))
    ${MenuLevel_Launcher_VAR+}      += , @($LineSpacing, '6' , '-WindowStyle Hidden'                                         , @('Out-PowerShellLauncher', '', '5'))
    ${MenuLevel_Launcher_VAR+}      += , @($LineSpacing, '7' , '-ExecutionPolicy Bypass'                                     , @('Out-PowerShellLauncher', '', '5'))
    ${MenuLevel_Launcher_VAR+}      += , @($LineSpacing, '8' , '-Wow64 (to path 32-bit powershell.exe)'                      , @('Out-PowerShellLauncher', '', '5'))

    ${MenuLevel_Launcher_STDIN+}     =   @()
    ${MenuLevel_Launcher_STDIN+}    += , @("Enter string of numbers with all desired flags to pass to function. (e.g. 23459)`n", ''  , ''   , @('', '', ''))
    ${MenuLevel_Launcher_STDIN+}    += , @($LineSpacing, '0' , 'NO EXECUTION FLAGS'                                          , @('Out-PowerShellLauncher', '', '6'))
    ${MenuLevel_Launcher_STDIN+}    += , @($LineSpacing, '1' , '-NoExit'                                                     , @('Out-PowerShellLauncher', '', '6'))
    ${MenuLevel_Launcher_STDIN+}    += , @($LineSpacing, '2' , '-NonInteractive'                                             , @('Out-PowerShellLauncher', '', '6'))
    ${MenuLevel_Launcher_STDIN+}    += , @($LineSpacing, '3' , '-NoLogo'                                                     , @('Out-PowerShellLauncher', '', '6'))
    ${MenuLevel_Launcher_STDIN+}    += , @($LineSpacing, '4' , '-NoProfile'                                                  , @('Out-PowerShellLauncher', '', '6'))
    ${MenuLevel_Launcher_STDIN+}    += , @($LineSpacing, '5' , '-Command'                                                    , @('Out-PowerShellLauncher', '', '6'))
    ${MenuLevel_Launcher_STDIN+}    += , @($LineSpacing, '6' , '-WindowStyle Hidden'                                         , @('Out-PowerShellLauncher', '', '6'))
    ${MenuLevel_Launcher_STDIN+}    += , @($LineSpacing, '7' , '-ExecutionPolicy Bypass'                                     , @('Out-PowerShellLauncher', '', '6'))
    ${MenuLevel_Launcher_STDIN+}    += , @($LineSpacing, '8' , '-Wow64 (to path 32-bit powershell.exe)'                      , @('Out-PowerShellLauncher', '', '6'))
    
    ${MenuLevel_Launcher_CLIP+}      =   @()
    ${MenuLevel_Launcher_CLIP+}     += , @("Enter string of numbers with all desired flags to pass to function. (e.g. 23459)`n", ''  , ''   , @('', '', ''))
    ${MenuLevel_Launcher_CLIP+}     += , @($LineSpacing, '0' , 'NO EXECUTION FLAGS'                                          , @('Out-PowerShellLauncher', '', '7'))
    ${MenuLevel_Launcher_CLIP+}     += , @($LineSpacing, '1' , '-NoExit'                                                     , @('Out-PowerShellLauncher', '', '7'))
    ${MenuLevel_Launcher_CLIP+}     += , @($LineSpacing, '2' , '-NonInteractive'                                             , @('Out-PowerShellLauncher', '', '7'))
    ${MenuLevel_Launcher_CLIP+}     += , @($LineSpacing, '3' , '-NoLogo'                                                     , @('Out-PowerShellLauncher', '', '7'))
    ${MenuLevel_Launcher_CLIP+}     += , @($LineSpacing, '4' , '-NoProfile'                                                  , @('Out-PowerShellLauncher', '', '7'))
    ${MenuLevel_Launcher_CLIP+}     += , @($LineSpacing, '5' , '-Command'                                                    , @('Out-PowerShellLauncher', '', '7'))
    ${MenuLevel_Launcher_CLIP+}     += , @($LineSpacing, '6' , '-WindowStyle Hidden'                                         , @('Out-PowerShellLauncher', '', '7'))
    ${MenuLevel_Launcher_CLIP+}     += , @($LineSpacing, '7' , '-ExecutionPolicy Bypass'                                     , @('Out-PowerShellLauncher', '', '7'))
    ${MenuLevel_Launcher_CLIP+}     += , @($LineSpacing, '8' , '-Wow64 (to path 32-bit powershell.exe)'                      , @('Out-PowerShellLauncher', '', '7'))
    
    ${MenuLevel_Launcher_VAR++}      =   @()
    ${MenuLevel_Launcher_VAR++}     += , @("Enter string of numbers with all desired flags to pass to function. (e.g. 23459)`n", ''  , ''   , @('', '', ''))
    ${MenuLevel_Launcher_VAR++}     += , @($LineSpacing, '0' , 'NO EXECUTION FLAGS'                                          , @('Out-PowerShellLauncher', '', '8'))
    ${MenuLevel_Launcher_VAR++}     += , @($LineSpacing, '1' , '-NoExit'                                                     , @('Out-PowerShellLauncher', '', '8'))
    ${MenuLevel_Launcher_VAR++}     += , @($LineSpacing, '2' , '-NonInteractive'                                             , @('Out-PowerShellLauncher', '', '8'))
    ${MenuLevel_Launcher_VAR++}     += , @($LineSpacing, '3' , '-NoLogo'                                                     , @('Out-PowerShellLauncher', '', '8'))
    ${MenuLevel_Launcher_VAR++}     += , @($LineSpacing, '4' , '-NoProfile'                                                  , @('Out-PowerShellLauncher', '', '8'))
    ${MenuLevel_Launcher_VAR++}     += , @($LineSpacing, '5' , '-Command'                                                    , @('Out-PowerShellLauncher', '', '8'))
    ${MenuLevel_Launcher_VAR++}     += , @($LineSpacing, '6' , '-WindowStyle Hidden'                                         , @('Out-PowerShellLauncher', '', '8'))
    ${MenuLevel_Launcher_VAR++}     += , @($LineSpacing, '7' , '-ExecutionPolicy Bypass'                                     , @('Out-PowerShellLauncher', '', '8'))
    ${MenuLevel_Launcher_VAR++}     += , @($LineSpacing, '8' , '-Wow64 (to path 32-bit powershell.exe)'                      , @('Out-PowerShellLauncher', '', '8'))

    ${MenuLevel_Launcher_STDIN++}    =   @()
    ${MenuLevel_Launcher_STDIN++}   += , @("Enter string of numbers with all desired flags to pass to function. (e.g. 23459)`n", ''  , ''   , @('', '', ''))
    ${MenuLevel_Launcher_STDIN++}   += , @($LineSpacing, '0' , "`tNO EXECUTION FLAGS"                                        , @('Out-PowerShellLauncher', '', '9'))
    ${MenuLevel_Launcher_STDIN++}   += , @($LineSpacing, '1' , "`t-NoExit"                                                   , @('Out-PowerShellLauncher', '', '9'))
    ${MenuLevel_Launcher_STDIN++}   += , @($LineSpacing, '2' , "`t-NonInteractive"                                           , @('Out-PowerShellLauncher', '', '9'))
    ${MenuLevel_Launcher_STDIN++}   += , @($LineSpacing, '3' , "`t-NoLogo"                                                   , @('Out-PowerShellLauncher', '', '9'))
    ${MenuLevel_Launcher_STDIN++}   += , @($LineSpacing, '4' , "`t-NoProfile"                                                , @('Out-PowerShellLauncher', '', '9'))
    ${MenuLevel_Launcher_STDIN++}   += , @($LineSpacing, '5' , "`t-Command"                                                  , @('Out-PowerShellLauncher', '', '9'))
    ${MenuLevel_Launcher_STDIN++}   += , @($LineSpacing, '6' , "`t-WindowStyle Hidden"                                       , @('Out-PowerShellLauncher', '', '9'))
    ${MenuLevel_Launcher_STDIN++}   += , @($LineSpacing, '7' , "`t-ExecutionPolicy Bypass"                                   , @('Out-PowerShellLauncher', '', '9'))
    ${MenuLevel_Launcher_STDIN++}   += , @($LineSpacing, '8' , "`t-Wow64 (to path 32-bit powershell.exe)"                    , @('Out-PowerShellLauncher', '', '9'))

    ${MenuLevel_Launcher_CLIP++}     =   @()
    ${MenuLevel_Launcher_CLIP++}    += , @("Enter string of numbers with all desired flags to pass to function. (e.g. 23459)`n", ''  , ''   , @('', '', ''))
    ${MenuLevel_Launcher_CLIP++}    += , @($LineSpacing, '0' , 'NO EXECUTION FLAGS'                                          , @('Out-PowerShellLauncher', '', '10'))
    ${MenuLevel_Launcher_CLIP++}    += , @($LineSpacing, '1' , '-NoExit'                                                     , @('Out-PowerShellLauncher', '', '10'))
    ${MenuLevel_Launcher_CLIP++}    += , @($LineSpacing, '2' , '-NonInteractive'                                             , @('Out-PowerShellLauncher', '', '10'))
    ${MenuLevel_Launcher_CLIP++}    += , @($LineSpacing, '3' , '-NoLogo'                                                     , @('Out-PowerShellLauncher', '', '10'))
    ${MenuLevel_Launcher_CLIP++}    += , @($LineSpacing, '4' , '-NoProfile'                                                  , @('Out-PowerShellLauncher', '', '10'))
    ${MenuLevel_Launcher_CLIP++}    += , @($LineSpacing, '5' , '-Command'                                                    , @('Out-PowerShellLauncher', '', '10'))
    ${MenuLevel_Launcher_CLIP++}    += , @($LineSpacing, '6' , '-WindowStyle Hidden'                                         , @('Out-PowerShellLauncher', '', '10'))
    ${MenuLevel_Launcher_CLIP++}    += , @($LineSpacing, '7' , '-ExecutionPolicy Bypass'                                     , @('Out-PowerShellLauncher', '', '10'))
    ${MenuLevel_Launcher_CLIP++}    += , @($LineSpacing, '8' , '-Wow64 (to path 32-bit powershell.exe)'                      , @('Out-PowerShellLauncher', '', '10'))

    ${MenuLevel_Launcher_RUNDLL++}   =   @()
    ${MenuLevel_Launcher_RUNDLL++}  += , @("Enter string of numbers with all desired flags to pass to function. (e.g. 23459)`n", ''  , ''   , @('', '', ''))
    ${MenuLevel_Launcher_RUNDLL++}  += , @($LineSpacing, '0' , 'NO EXECUTION FLAGS'                                          , @('Out-PowerShellLauncher', '', '11'))
    ${MenuLevel_Launcher_RUNDLL++}  += , @($LineSpacing, '1' , '-NoExit'                                                     , @('Out-PowerShellLauncher', '', '11'))
    ${MenuLevel_Launcher_RUNDLL++}  += , @($LineSpacing, '2' , '-NonInteractive'                                             , @('Out-PowerShellLauncher', '', '11'))
    ${MenuLevel_Launcher_RUNDLL++}  += , @($LineSpacing, '3' , '-NoLogo'                                                     , @('Out-PowerShellLauncher', '', '11'))
    ${MenuLevel_Launcher_RUNDLL++}  += , @($LineSpacing, '4' , '-NoProfile'                                                  , @('Out-PowerShellLauncher', '', '11'))
    ${MenuLevel_Launcher_RUNDLL++}  += , @($LineSpacing, '5' , '-Command'                                                    , @('Out-PowerShellLauncher', '', '11'))
    ${MenuLevel_Launcher_RUNDLL++}  += , @($LineSpacing, '6' , '-WindowStyle Hidden'                                         , @('Out-PowerShellLauncher', '', '11'))
    ${MenuLevel_Launcher_RUNDLL++}  += , @($LineSpacing, '7' , '-ExecutionPolicy Bypass'                                     , @('Out-PowerShellLauncher', '', '11'))
    ${MenuLevel_Launcher_RUNDLL++}  += , @($LineSpacing, '8' , '-Wow64 (to path 32-bit powershell.exe)'                      , @('Out-PowerShellLauncher', '', '11'))

    ${MenuLevel_Launcher_MSHTA++}    =   @()
    ${MenuLevel_Launcher_MSHTA++}   += , @("Enter string of numbers with all desired flags to pass to function. (e.g. 23459)`n", ''  , ''   , @('', '', ''))
    ${MenuLevel_Launcher_MSHTA++}   += , @($LineSpacing, '0' , 'NO EXECUTION FLAGS'                                          , @('Out-PowerShellLauncher', '', '12'))
    ${MenuLevel_Launcher_MSHTA++}   += , @($LineSpacing, '1' , '-NoExit'                                                     , @('Out-PowerShellLauncher', '', '12'))
    ${MenuLevel_Launcher_MSHTA++}   += , @($LineSpacing, '2' , '-NonInteractive'                                             , @('Out-PowerShellLauncher', '', '12'))
    ${MenuLevel_Launcher_MSHTA++}   += , @($LineSpacing, '3' , '-NoLogo'                                                     , @('Out-PowerShellLauncher', '', '12'))
    ${MenuLevel_Launcher_MSHTA++}   += , @($LineSpacing, '4' , '-NoProfile'                                                  , @('Out-PowerShellLauncher', '', '12'))
    ${MenuLevel_Launcher_MSHTA++}   += , @($LineSpacing, '5' , '-Command'                                                    , @('Out-PowerShellLauncher', '', '12'))
    ${MenuLevel_Launcher_MSHTA++}   += , @($LineSpacing, '6' , '-WindowStyle Hidden'                                         , @('Out-PowerShellLauncher', '', '12'))
    ${MenuLevel_Launcher_MSHTA++}   += , @($LineSpacing, '7' , '-ExecutionPolicy Bypass'                                     , @('Out-PowerShellLauncher', '', '12'))
    ${MenuLevel_Launcher_MSHTA++}   += , @($LineSpacing, '8' , '-Wow64 (to path 32-bit powershell.exe)'                      , @('Out-PowerShellLauncher', '', '12'))

    
    $TutorialInputOptions         = @(@('tutorial')                            , "<Tutorial> of how to use this tool        `t  " )
    $MenuInputOptionsShowHelp     = @(@('help','get-help','?','-?','/?','menu'), "Show this <Help> Menu                     `t  " )
    $MenuInputOptionsShowOptions  = @(@('show options','show','options')       , "<Show options> for payload to obfuscate   `t  " )
    $ClearScreenInputOptions      = @(@('clear','clear-host','cls')            , "<Clear> screen                            `t  " )
    $CopyToClipboardInputOptions  = @(@('copy','clip','clipboard')             , "<Copy> ObfuscatedCommand to clipboard     `t  " )
    $OutputToDiskInputOptions     = @(@('out')                                 , "Write ObfuscatedCommand <Out> to disk     `t  " )
    $ExecutionInputOptions        = @(@('exec','execute','test','run')         , "<Execute> ObfuscatedCommand locally       `t  " )
    $ResetObfuscationInputOptions = @(@('reset')                               , "<Reset> ALL obfuscation for ObfuscatedCommand  ")
    $UndoObfuscationInputOptions  = @(@('undo')                                , "<Undo> LAST obfuscation for ObfuscatedCommand  ")
    $BackCommandInputOptions      = @(@('back','cd ..')                        , "Go <Back> to previous obfuscation menu    `t  " )
    $ExitCommandInputOptions      = @(@('quit','exit')                         , "<Quit> Invoke-Obfuscation                 `t  " )
    $HomeMenuInputOptions         = @(@('home','main')                         , "Return to <Home> Menu                     `t  " )
    
    
    
    
    $AllAvailableInputOptionsLists   = @()
    $AllAvailableInputOptionsLists  += , $TutorialInputOptions
    $AllAvailableInputOptionsLists  += , $MenuInputOptionsShowHelp
    $AllAvailableInputOptionsLists  += , $MenuInputOptionsShowOptions
    $AllAvailableInputOptionsLists  += , $ClearScreenInputOptions
    $AllAvailableInputOptionsLists  += , $ExecutionInputOptions
    $AllAvailableInputOptionsLists  += , $CopyToClipboardInputOptions
    $AllAvailableInputOptionsLists  += , $OutputToDiskInputOptions
    $AllAvailableInputOptionsLists  += , $ResetObfuscationInputOptions
    $AllAvailableInputOptionsLists  += , $UndoObfuscationInputOptions
    $AllAvailableInputOptionsLists  += , $BackCommandInputOptions    
    $AllAvailableInputOptionsLists  += , $ExitCommandInputOptions
    $AllAvailableInputOptionsLists  += , $HomeMenuInputOptions
    
    

    
    $ExitInputOptions = $ExitCommandInputOptions[0]
    $MenuInputOptions = $BackCommandInputOptions[0]
    
    
    Show-AsciiArt
    Start-Sleep -Seconds 2
    
    
    Show-HelpMenu
    
    
    
    $UserResponse = ''
    While($ExitInputOptions -NotContains ([String]$UserResponse).ToLower())
    {
        $UserResponse = ([String]$UserResponse).Trim()

        If($HomeMenuInputOptions[0] -Contains ([String]$UserResponse).ToLower())
        {
            $UserResponse = ''
        }

        
        If(Test-Path ('Variable:' + "MenuLevel$UserResponse"))
        {
            $UserResponse = Show-Menu (Get-Variable "MenuLevel$UserResponse").Value $UserResponse $Script:OptionsMenu
        }
        Else
        {
            Write-Error "The variable MenuLevel$UserResponse does not exist."
            $UserResponse = 'quit'
        }
        
        If(($UserResponse -eq 'quit') -AND $CliWasSpecified -AND !$NoExitWasSpecified)
        {
            Write-Output $Script:ObfuscatedCommand.Trim("`n")
            $UserInput = 'quit'
        }
    }
}



$ScriptDir = [System.IO.Path]::GetDirectoryName($myInvocation.MyCommand.Definition) 


Function Show-Menu
{


    Param(
        [Parameter(ValueFromPipeline = $true)]
        [ValidateNotNullOrEmpty()]
        [Object[]]
        $Menu,

        [String]
        $MenuName,

        [Object[]]
        $Script:OptionsMenu
    )

    
    $AcceptableInput = @()
    $SelectionContainsCommand = $FALSE
    ForEach($Line in $Menu)
    {
        
        If($Line.Count -eq 4)
        {
            $SelectionContainsCommand = $TRUE
        }
        $AcceptableInput += ($Line[1]).Trim(' ')
    }

    $UserInput = $NULL
    
    While($AcceptableInput -NotContains $UserInput)
    {
        
        Write-Host "`n"
        $BreadCrumb = $MenuName.Trim('_')
        If($BreadCrumb.Length -gt 1)
        {
            If($BreadCrumb.ToLower() -eq 'show options')
            {
                $BreadCrumb = 'Show Options'
            }
            If($MenuName -ne '')
            {
                
                $BreadCrumbOCD  =   @()
                $BreadCrumbOCD += , @('ps'      ,'PS')
                $BreadCrumbOCD += , @('cmd'     ,'Cmd')
                $BreadCrumbOCD += , @('wmic'    ,'Wmic')
                $BreadCrumbOCD += , @('rundll'  ,'RunDll')
                $BreadCrumbOCD += , @('var+'    ,'Var+')
                $BreadCrumbOCD += , @('stdin+'  ,'StdIn+')
                $BreadCrumbOCD += , @('clip+'   ,'Clip+')
                $BreadCrumbOCD += , @('var++'   ,'Var++')
                $BreadCrumbOCD += , @('stdin++' ,'StdIn++')
                $BreadCrumbOCD += , @('clip++'  ,'Clip++')
                $BreadCrumbOCD += , @('rundll++','RunDll++')
                $BreadCrumbOCD += , @('mshta++' ,'Mshta++')

                $BreadCrumbArray = @()
                ForEach($Crumb in $BreadCrumb.Split('_'))
                {
                    
                    $StillLookingForSubstitution = $TRUE
                    ForEach($Substitution in $BreadCrumbOCD)
                    {
                        If($Crumb.ToLower() -eq $Substitution[0])
                        {
                            $BreadCrumbArray += $Substitution[1]
                            $StillLookingForSubstitution = $FALSE
                        }
                    }

                    
                    If($StillLookingForSubstitution)
                    {
                        $BreadCrumbArray += $Crumb.SubString(0,1).ToUpper() + $Crumb.SubString(1).ToLower()

                        
                        If(($BreadCrumb.Split('_').Count -eq 2) -AND ($BreadCrumb.StartsWith('Launcher_')) -AND ($Crumb -ne 'Launcher'))
                        {
                            Write-Warning "No substituion pair was found for `$Crumb=$Crumb in `$BreadCrumb=$BreadCrumb. Add this `$Crumb substitution pair to `$BreadCrumbOCD array in Invoke-Obfuscation."
                        }
                    }
                }
                $BreadCrumb = $BreadCrumbArray -Join '\'
            }
            $BreadCrumb = '\' + $BreadCrumb
        }
        
        
        $FirstLine = "Choose one of the below "
        If($BreadCrumb -ne '')
        {
            $FirstLine = $FirstLine + $BreadCrumb.Trim('\') + ' '
        }
        Write-Host "$FirstLine" -NoNewLine
        
        
        If($SelectionContainsCommand)
        {
            Write-Host "options" -NoNewLine -ForegroundColor Green
            Write-Host " to" -NoNewLine
            Write-Host " APPLY" -NoNewLine -ForegroundColor Green
            Write-Host " to current payload" -NoNewLine
        }
        Else
        {
            Write-Host "options" -NoNewLine -ForegroundColor Yellow
        }
        Write-Host ":`n"
    
        ForEach($Line in $Menu)
        {
            $LineSpace  = $Line[0]
            $LineOption = $Line[1]
            $LineValue  = $Line[2]
            Write-Host $LineSpace -NoNewLine

            
            If(($BreadCrumb -ne '') -AND ($LineSpace.StartsWith('[')))
            {
                Write-Host ($BreadCrumb.ToUpper().Trim('\') + '\') -NoNewLine
            }
            
            
            If($SelectionContainsCommand)
            {
                Write-Host $LineOption -NoNewLine -ForegroundColor Green
            }
            Else
            {
                Write-Host $LineOption -NoNewLine -ForegroundColor Yellow
            }
            
            
            If($LineValue.Contains('<') -AND $LineValue.Contains('>'))
            {
                $FirstPart  = $LineValue.SubString(0,$LineValue.IndexOf('<'))
                $MiddlePart = $LineValue.SubString($FirstPart.Length+1)
                $MiddlePart = $MiddlePart.SubString(0,$MiddlePart.IndexOf('>'))
                $LastPart   = $LineValue.SubString($FirstPart.Length+$MiddlePart.Length+2)
                Write-Host "`t$FirstPart" -NoNewLine
                Write-Host $MiddlePart -NoNewLine -ForegroundColor Cyan

                
                If($LastPart.Contains('<') -AND $LastPart.Contains('>'))
                {
                    $LineValue  = $LastPart
                    $FirstPart  = $LineValue.SubString(0,$LineValue.IndexOf('<'))
                    $MiddlePart = $LineValue.SubString($FirstPart.Length+1)
                    $MiddlePart = $MiddlePart.SubString(0,$MiddlePart.IndexOf('>'))
                    $LastPart   = $LineValue.SubString($FirstPart.Length+$MiddlePart.Length+2)
                    Write-Host "$FirstPart" -NoNewLine
                    Write-Host $MiddlePart -NoNewLine -ForegroundColor Cyan
                }

                Write-Host $LastPart
            }
            Else
            {
                Write-Host "`t$LineValue"
            }
        }
        
        
        Write-Host ''
        If($UserInput -ne '') {Write-Host ''}
        $UserInput = ''
        
        While(($UserInput -eq '') -AND ($Script:CompoundCommand.Count -eq 0))
        {
            
            Write-Host "Invoke-Obfuscation$BreadCrumb> " -NoNewLine -ForegroundColor Magenta

            
            If(($Script:CliCommands.Count -gt 0) -OR ($Script:CliCommands -ne $NULL))
            {
                If($Script:CliCommands.GetType().Name -eq 'String')
                {
                    $NextCliCommand = $Script:CliCommands.Trim()
                    $Script:CliCommands = @()
                }
                Else
                {
                    $NextCliCommand = ([String]$Script:CliCommands[0]).Trim()
                    $Script:CliCommands = For($i=1; $i -lt $Script:CliCommands.Count; $i++) {$Script:CliCommands[$i]}
                }

                $UserInput = $NextCliCommand
            }
            Else
            {
                
                If($CliWasSpecified -AND ($Script:CliCommands.Count -lt 1) -AND ($Script:CompoundCommand.Count -lt 1) -AND ($Script:QuietWasSpecified -OR !$NoExitWasSpecified))
                {
                    If($Script:QuietWasSpecified)
                    {
                        
                        Remove-Item -Path Function:Write-Host
                        Remove-Item -Path Function:Start-Sleep

                        $Script:QuietWasSpecified = $FALSE

                        
                        $UserInput  = 'show options'
                        $BreadCrumb = 'Show Options'
                    }
                    
                    If(!$NoExitWasSpecified)
                    {
                        $UserInput = 'quit'
                    }
                }
                Else
                {
                    $UserInput = (Read-Host).Trim()
                }

                
                If(($Script:CliCommands.Count -eq 0) -AND !$UserInput.ToLower().StartsWith('set ') -AND $UserInput.Contains(','))
                {
                    $Script:CliCommands = $UserInput.Split(',')
                    
                    
                    $UserInput = ''
                }
            }
        }

        
        $UserInput = $UserInput.Trim('/\')

        
        
        If((($MenuLevel | ForEach-Object {$_[1].Trim()}) -Contains $UserInput.Split('/\')[0]) -AND !(('string' -Contains $UserInput.Split('/\')[0]) -AND ($MenuName -eq '_token')) -AND ($MenuName -ne ''))
        {
            $UserInput = 'home/' + $UserInput.Trim()
        }

        
        
        If(($Script:CompoundCommand.Count -eq 0) -AND !$UserInput.ToLower().StartsWith('set ') -AND !$UserInput.ToLower().StartsWith('out ') -AND ($UserInput.Contains('\') -OR $UserInput.Contains('/')))
        {
            $Script:CompoundCommand = $UserInput.Split('/\')
        }

        
        
        If($Script:CompoundCommand.Count -gt 0)
        {
            $UserInput = ''
            While(($UserInput -eq '') -AND ($Script:CompoundCommand.Count -gt 0))
            {
                
                If($Script:CompoundCommand.GetType().Name -eq 'String')
                {
                    $NextCompoundCommand = $Script:CompoundCommand.Trim()
                    $Script:CompoundCommand = @()
                }
                Else
                {
                    
                    
                    $NextCompoundCommand = ([String]$Script:CompoundCommand[0]).Trim()
                    
                    
                    $Temp = $Script:CompoundCommand
                    $Script:CompoundCommand = @()
                    For($i=1; $i -lt $Temp.Count; $i++)
                    {
                        $Script:CompoundCommand += $Temp[$i]
                    }
                }
                $UserInput = $NextCompoundCommand
            }
        }

        
        
        $TempUserInput = $UserInput.ToLower()
        @(97..122) | ForEach-Object {$TempUserInput = $TempUserInput.Replace([String]([Char]$_),'')}
        @(0..9)    | ForEach-Object {$TempUserInput = $TempUserInput.Replace($_,'')}
        $TempUserInput = $TempUserInput.Replace(' ','').Replace('+','').Replace('

        If(($TempUserInput.Length -gt 0) -AND !($UserInput.Trim().ToLower().StartsWith('set ')) -AND !($UserInput.Trim().ToLower().StartsWith('out ')))
        {
            
            $UserInput = $UserInput.Replace('.*','_____').Replace('*','.*').Replace('_____','.*')

            
            If(!$UserInput.Trim().StartsWith('^') -AND !$UserInput.Trim().StartsWith('.*'))
            {
                $UserInput = '^' + $UserInput
            }
            If(!$UserInput.Trim().EndsWith('$') -AND !$UserInput.Trim().EndsWith('.*'))
            {
                $UserInput = $UserInput + '$'
            }

            
            Try
            {
                $MenuFiltered = ($Menu | Where-Object {($_[1].Trim() -Match $UserInput) -AND ($_[1].Trim().Length -gt 0)} | ForEach-Object {$_[1].Trim()})
            }
            Catch
            {
                
                
                Write-Host "`n`nERROR:" -NoNewLine -ForegroundColor Red
                Write-Host ' The current Regular Expression caused the following error:'
                write-host "       $_" -ForegroundColor Red
            }

            
            If($MenuFiltered -ne $NULL)
            {
                
                $UserInput = (Get-Random -Input $MenuFiltered).Trim()

                
                If($MenuFiltered.Count -gt 1)
                {
                    
                    If($SelectionContainsCommand)
                    {
                        $ColorToOutput = 'Green'
                    }
                    Else
                    {
                        $ColorToOutput = 'Yellow'
                    }

                    Write-Host "`n`nRandomly selected " -NoNewline
                    Write-Host $UserInput -NoNewline -ForegroundColor $ColorToOutput
                    write-host " from the following filtered options: " -NoNewline

                    For($i=0; $i -lt $MenuFiltered.Count-1; $i++)
                    {
                        Write-Host $MenuFiltered[$i].Trim() -NoNewLine -ForegroundColor $ColorToOutput
                        Write-Host ', ' -NoNewLine
                    }
                    Write-Host $MenuFiltered[$MenuFiltered.Count-1].Trim() -NoNewLine -ForegroundColor $ColorToOutput
                }
            }
        }

        
        $OverrideAcceptableInput = $FALSE
        $MenusWithMultiSelectNumbers = @('\Launcher')
        If(($UserInput.Trim(' 0123456789').Length -eq 0) -AND $BreadCrumb.Contains('\') -AND ($MenusWithMultiSelectNumbers -Contains $BreadCrumb.SubString(0,$BreadCrumb.LastIndexOf('\'))))
        {
            $OverrideAcceptableInput = $TRUE
        }
        
        If($ExitInputOptions -Contains $UserInput.ToLower())
        {
            Return $ExitInputOptions[0]
        }
        ElseIf($MenuInputOptions -Contains $UserInput.ToLower())
        {
            
            If($BreadCrumb.Contains('\')) {$UserInput = $BreadCrumb.SubString(0,$BreadCrumb.LastIndexOf('\')).Replace('\','_')}
            Else {$UserInput = ''}

            Return $UserInput.ToLower()
        }
        ElseIf($HomeMenuInputOptions[0] -Contains $UserInput.ToLower())
        {
            Return $UserInput.ToLower()
        }
        ElseIf($UserInput.ToLower().StartsWith('set '))
        {
            
            $UserInputOptionName  = $NULL
            $UserInputOptionValue = $NULL
            $HasError = $FALSE
    
            $UserInputMinusSet = $UserInput.SubString(4).Trim()
            If($UserInputMinusSet.IndexOf(' ') -eq -1)
            {
                $HasError = $TRUE
                $UserInputOptionName  = $UserInputMinusSet.Trim()
            }
            Else
            {
                $UserInputOptionName  = $UserInputMinusSet.SubString(0,$UserInputMinusSet.IndexOf(' ')).Trim().ToLower()
                $UserInputOptionValue = $UserInputMinusSet.SubString($UserInputMinusSet.IndexOf(' ')).Trim()
            }

            
            If($SettableInputOptions -Contains $UserInputOptionName)
            {
                
                If($UserInputOptionValue.Length -eq 0) {$UserInputOptionName = 'emptyvalue'}
                Switch($UserInputOptionName.ToLower())
                {
                    'scriptpath' {
                        If($UserInputOptionValue -AND ((Test-Path $UserInputOptionValue) -OR ($UserInputOptionValue -Match '(http|https)://')))
                        {
                            
                            $Script:ScriptBlock = ''
                        
                            
                            If($UserInputOptionValue -Match '(http|https)://')
                            {
                                
                            
                                
                                $Script:ScriptBlock = (New-Object Net.WebClient).DownloadString($UserInputOptionValue)
                            
                                
                                $Script:ScriptPath                = $UserInputOptionValue
                                $Script:ObfuscatedCommand         = $Script:ScriptBlock
                                $Script:ObfuscatedCommandHistory  = @()
                                $Script:ObfuscatedCommandHistory += $Script:ScriptBlock
                                $Script:CliSyntax                 = @()
                                $Script:ExecutionCommands         = @()
                                $Script:LauncherApplied           = $FALSE
                            
                                Write-Host "`n`nSuccessfully set ScriptPath (as URL):" -ForegroundColor Cyan
                                Write-Host $Script:ScriptPath -ForegroundColor Magenta
                            }
                            ElseIf ((Get-Item $UserInputOptionValue) -is [System.IO.DirectoryInfo])
                            {
                                
                                Write-Host "`n`nERROR:" -NoNewLine -ForegroundColor Red
                                Write-Host ' Path is a directory instead of a file (' -NoNewLine
                                Write-Host "$UserInputOptionValue" -NoNewLine -ForegroundColor Cyan
                                Write-Host ").`n" -NoNewLine
                            }
                            Else
                            {
                                
                                Get-ChildItem $UserInputOptionValue -ErrorAction Stop | Out-Null
                                $Script:ScriptBlock = [IO.File]::ReadAllText((Resolve-Path $UserInputOptionValue))
                        
                                
                                $Script:ScriptPath                = $UserInputOptionValue
                                $Script:ObfuscatedCommand         = $Script:ScriptBlock
                                $Script:ObfuscatedCommandHistory  = @()
                                $Script:ObfuscatedCommandHistory += $Script:ScriptBlock
                                $Script:CliSyntax                 = @()
                                $Script:ExecutionCommands         = @()
                                $Script:LauncherApplied           = $FALSE
                            
                                Write-Host "`n`nSuccessfully set ScriptPath:" -ForegroundColor Cyan
                                Write-Host $Script:ScriptPath -ForegroundColor Magenta
                            }
                        }
                        Else
                        {
                            
                            Write-Host "`n`nERROR:" -NoNewLine -ForegroundColor Red
                            Write-Host ' Path not found (' -NoNewLine
                            Write-Host "$UserInputOptionValue" -NoNewLine -ForegroundColor Cyan
                            Write-Host ").`n" -NoNewLine
                        }
                    }
                    'scriptblock' {
                        
                        ForEach($Char in @(@('{','}'),@('"','"'),@("'","'")))
                        {
                            While($UserInputOptionValue.StartsWith($Char[0]) -AND $UserInputOptionValue.EndsWith($Char[1]))
                            {
                                $UserInputOptionValue = $UserInputOptionValue.SubString(1,$UserInputOptionValue.Length-2).Trim()
                            }
                        }

                        
                        If($UserInputOptionValue -Match 'powershell(.exe | )\s*-(e |ec |en |enc |enco |encod |encode)\s*["'']*[a-z=]')
                        {
                            
                            $EncodedCommand = $UserInputOptionValue.SubString($UserInputOptionValue.ToLower().IndexOf(' -e')+3)
                            $EncodedCommand = $EncodedCommand.SubString($EncodedCommand.IndexOf(' ')).Trim(" '`"")

                            
                            $UserInputOptionValue = [System.Text.Encoding]::Unicode.GetString([System.Convert]::FromBase64String($EncodedCommand))
                        }

                        
                        $Script:ScriptPath                = 'N/A'
                        $Script:ScriptBlock               = $UserInputOptionValue
                        $Script:ObfuscatedCommand         = $UserInputOptionValue
                        $Script:ObfuscatedCommandHistory  = @()
                        $Script:ObfuscatedCommandHistory += $UserInputOptionValue
                        $Script:CliSyntax                 = @()
                        $Script:ExecutionCommands         = @()
                        $Script:LauncherApplied           = $FALSE
                    
                        Write-Host "`n`nSuccessfully set ScriptBlock:" -ForegroundColor Cyan
                        Write-Host $Script:ScriptBlock -ForegroundColor Magenta
                    }
                    'emptyvalue' {
                        
                        $HasError = $TRUE
                        Write-Host "`n`nERROR:" -NoNewLine -ForegroundColor Red
                        Write-Host ' No value was entered after' -NoNewLine
                        Write-Host ' SCRIPTBLOCK/SCRIPTPATH' -NoNewLine -ForegroundColor Cyan
                        Write-Host '.' -NoNewLine
                    }
                    default {Write-Error "An invalid OPTIONNAME ($UserInputOptionName) was passed to switch block."; Exit}
                }
            }
            Else
            {
                $HasError = $TRUE
                Write-Host "`n`nERROR:" -NoNewLine -ForegroundColor Red
                Write-Host ' OPTIONNAME' -NoNewLine
                Write-Host " $UserInputOptionName" -NoNewLine -ForegroundColor Cyan
                Write-Host " is not a settable option." -NoNewLine
            }
    
            If($HasError)
            {
                Write-Host "`n       Correct syntax is" -NoNewLine
                Write-Host ' SET OPTIONNAME VALUE' -NoNewLine -ForegroundColor Green
                Write-Host '.' -NoNewLine
        
                Write-Host "`n       Enter" -NoNewLine
                Write-Host ' SHOW OPTIONS' -NoNewLine -ForegroundColor Yellow
                Write-Host ' for more details.'
            }
        }
        ElseIf(($AcceptableInput -Contains $UserInput) -OR ($OverrideAcceptableInput))
        {
            
            
            

            
            $UserInput = $BreadCrumb.Trim('\').Replace('\','_') + '_' + $UserInput
            If($BreadCrumb.StartsWith('\')) {$UserInput = '_' + $UserInput}

            
            If($SelectionContainsCommand)
            {
                
                If($Script:ObfuscatedCommand -ne $NULL)
                {
                    
                    ForEach($Line in $Menu)
                    {
                        If($Line[1].Trim(' ') -eq $UserInput.SubString($UserInput.LastIndexOf('_')+1)) {$CommandToExec = $Line[3]; Continue}
                    }

                    If(!$OverrideAcceptableInput)
                    {
                        
                        $Function = $CommandToExec[0]
                        $Token    = $CommandToExec[1]
                        $ObfLevel = $CommandToExec[2]
                    }
                    Else
                    {
                        
                        Switch($BreadCrumb.ToLower())
                        {
                            '\launcher\ps'       {$Function = 'Out-PowerShellLauncher'; $ObfLevel = 1}
                            '\launcher\cmd'      {$Function = 'Out-PowerShellLauncher'; $ObfLevel = 2}
                            '\launcher\wmic'     {$Function = 'Out-PowerShellLauncher'; $ObfLevel = 3}
                            '\launcher\rundll'   {$Function = 'Out-PowerShellLauncher'; $ObfLevel = 4}
                            '\launcher\var+'     {$Function = 'Out-PowerShellLauncher'; $ObfLevel = 5}
                            '\launcher\stdin+'   {$Function = 'Out-PowerShellLauncher'; $ObfLevel = 6}
                            '\launcher\clip+'    {$Function = 'Out-PowerShellLauncher'; $ObfLevel = 7}
                            '\launcher\var++'    {$Function = 'Out-PowerShellLauncher'; $ObfLevel = 8}
                            '\launcher\stdin++'  {$Function = 'Out-PowerShellLauncher'; $ObfLevel = 9}
                            '\launcher\clip++'   {$Function = 'Out-PowerShellLauncher'; $ObfLevel = 10}
                            '\launcher\rundll++' {$Function = 'Out-PowerShellLauncher'; $ObfLevel = 11}
                            '\launcher\mshta++'  {$Function = 'Out-PowerShellLauncher'; $ObfLevel = 12}
                            default {Write-Error "An invalid value ($($BreadCrumb.ToLower())) was passed to switch block for setting `$Function when `$OverrideAcceptableInput -eq `$TRUE."; Exit}
                        }
                        
                        $ObfLevel = $Menu[1][3][2]
                        $Token = $UserInput.SubString($UserInput.LastIndexOf('_')+1)
                    }

                    
                    If(!($Script:LauncherApplied))
                    {
                        $ObfCommandScriptBlock = $ExecutionContext.InvokeCommand.NewScriptBlock($Script:ObfuscatedCommand)
                    }
                    
                    
                    If($Script:ObfuscatedCommand -eq '')
                    {
                        Write-Host "`n`nERROR:" -NoNewLine -ForegroundColor Red
                        Write-Host " Cannot execute obfuscation commands without setting ScriptPath or ScriptBlock values in SHOW OPTIONS menu. Set these by executing" -NoNewLine
                        Write-Host ' SET SCRIPTBLOCK script_block_or_command' -NoNewLine -ForegroundColor Green
                        Write-Host ' or' -NoNewLine
                        Write-Host ' SET SCRIPTPATH path_to_script_or_URL' -NoNewLine -ForegroundColor Green
                        Write-Host '.'
                        Continue
                    }

                    
                    $ObfuscatedCommandBefore = $Script:ObfuscatedCommand
                    $CmdToPrint = $NULL

                    If($Script:LauncherApplied)
                    {
                        If($Function -eq 'Out-PowerShellLauncher')
                        {
                            $ErrorMessage = ' You have already applied a launcher to ObfuscatedCommand.'
                        }
                        Else
                        {
                            $ErrorMessage = ' You cannot obfuscate after applying a Launcher to ObfuscatedCommand.'
                        }

                        Write-Host "`n`nERROR:" -NoNewLine -ForegroundColor Red
                        Write-Host $ErrorMessage -NoNewLine
                        Write-Host "`n       Enter" -NoNewLine
                        Write-Host ' UNDO' -NoNewLine -ForegroundColor Yellow
                        Write-Host " to remove the launcher from ObfuscatedCommand.`n" -NoNewLine
                    }
                    Else
                    {
                        
                        Switch($Function)
                        {
                            'Out-ObfuscatedTokenCommand'        {
                                $Script:ObfuscatedCommand = Out-ObfuscatedTokenCommand        -ScriptBlock $ObfCommandScriptBlock $Token $ObfLevel
                                $CmdToPrint = @("Out-ObfuscatedTokenCommand -ScriptBlock "," '$Token' $ObfLevel")
                            }
                            'Out-ObfuscatedTokenCommandAll'     {
                                $Script:ObfuscatedCommand = Out-ObfuscatedTokenCommand        -ScriptBlock $ObfCommandScriptBlock
                                $CmdToPrint = @("Out-ObfuscatedTokenCommand -ScriptBlock ","")
                            }
                            'Out-ObfuscatedStringCommand'       {
                                $Script:ObfuscatedCommand = Out-ObfuscatedStringCommand       -ScriptBlock $ObfCommandScriptBlock $ObfLevel
                                $CmdToPrint = @("Out-ObfuscatedStringCommand -ScriptBlock "," $ObfLevel")
                            }
                            'Out-EncodedAsciiCommand'           {
                                $Script:ObfuscatedCommand = Out-EncodedAsciiCommand           -ScriptBlock $ObfCommandScriptBlock -PassThru
                                $CmdToPrint = @("Out-EncodedAsciiCommand -ScriptBlock "," -PassThru")
                            }
                            'Out-EncodedHexCommand'             {
                                $Script:ObfuscatedCommand = Out-EncodedHexCommand             -ScriptBlock $ObfCommandScriptBlock -PassThru
                                $CmdToPrint = @("Out-EncodedHexCommand -ScriptBlock "," -PassThru")
                            }
                            'Out-EncodedOctalCommand'           {
                                $Script:ObfuscatedCommand = Out-EncodedOctalCommand           -ScriptBlock $ObfCommandScriptBlock -PassThru
                                $CmdToPrint = @("Out-EncodedOctalCommand -ScriptBlock "," -PassThru")
                            }
                            'Out-EncodedBinaryCommand'          {
                                $Script:ObfuscatedCommand = Out-EncodedBinaryCommand          -ScriptBlock $ObfCommandScriptBlock -PassThru
                                $CmdToPrint = @("Out-EncodedBinaryCommand -ScriptBlock "," -PassThru")
                            }
                            'Out-SecureStringCommand'           {
                                $Script:ObfuscatedCommand = Out-SecureStringCommand           -ScriptBlock $ObfCommandScriptBlock -PassThru
                                $CmdToPrint = @("Out-SecureStringCommand -ScriptBlock "," -PassThru")
                            }
                            'Out-EncodedBXORCommand'            {
                                $Script:ObfuscatedCommand = Out-EncodedBXORCommand            -ScriptBlock $ObfCommandScriptBlock -PassThru
                                $CmdToPrint = @("Out-EncodedBXORCommand -ScriptBlock "," -PassThru")
                            }
                            'Out-EncodedSpecialCharOnlyCommand' {
                                $Script:ObfuscatedCommand = Out-EncodedSpecialCharOnlyCommand -ScriptBlock $ObfCommandScriptBlock -PassThru
                                $CmdToPrint = @("Out-EncodedSpecialCharOnlyCommand -ScriptBlock "," -PassThru")
                            }
                            'Out-EncodedWhitespaceCommand' {
                                $Script:ObfuscatedCommand = Out-EncodedWhitespaceCommand      -ScriptBlock $ObfCommandScriptBlock -PassThru
                                $CmdToPrint = @("Out-EncodedWhitespaceCommand -ScriptBlock "," -PassThru")
                            }
                            'Out-PowerShellLauncher'            {
                                
                                $SwitchesAsStringArray = [char[]]$Token | Sort-Object -Unique | Where-Object {$_ -ne ' '}
                                
                                If($SwitchesAsStringArray -Contains '0')
                                {
                                    $CmdToPrint = @("Out-PowerShellLauncher -ScriptBlock "," $ObfLevel")
                                }
                                Else
                                {
                                    $HasWindowStyle = $FALSE
                                    $SwitchesToPrint = @()
                                    ForEach($Value in $SwitchesAsStringArray)
                                    {
                                        Switch($Value)
                                        {
                                            1 {$SwitchesToPrint += '-NoExit'}
                                            2 {$SwitchesToPrint += '-NonInteractive'}
                                            3 {$SwitchesToPrint += '-NoLogo'}
                                            4 {$SwitchesToPrint += '-NoProfile'}
                                            5 {$SwitchesToPrint += '-Command'}
                                            6 {If(!$HasWindowStyle) {$SwitchesToPrint += '-WindowStyle Hidden'; $HasWindowStyle = $TRUE}}
                                            7 {$SwitchesToPrint += '-ExecutionPolicy Bypass'}
                                            8 {$SwitchesToPrint += '-Wow64'}
                                            default {Write-Error "An invalid `$SwitchesAsString value ($Value) was passed to switch block."; Exit;}
                                        }
                                    }
                                    $SwitchesToPrint =  $SwitchesToPrint -Join ' '
                                    $CmdToPrint = @("Out-PowerShellLauncher -ScriptBlock "," $SwitchesToPrint $ObfLevel")
                                }
                                
                                $Script:ObfuscatedCommand = Out-PowerShellLauncher -ScriptBlock $ObfCommandScriptBlock -SwitchesAsString $Token $ObfLevel
                                
                                
                                If($ObfuscatedCommandBefore -ne $Script:ObfuscatedCommand)
                                {
                                    $Script:LauncherApplied = $TRUE
                                }
                            }
                            default {Write-Error "An invalid `$Function value ($Function) was passed to switch block."; Exit;}
                        }

                        If(($Script:ObfuscatedCommand -ceq $ObfuscatedCommandBefore) -AND ($MenuName.StartsWith('_Token_')))
                        {
                            Write-Host "`nWARNING:" -NoNewLine -ForegroundColor Red
                            Write-Host " There were not any" -NoNewLine
                            If($BreadCrumb.SubString($BreadCrumb.LastIndexOf('\')+1).ToLower() -ne 'all') {Write-Host " $($BreadCrumb.SubString($BreadCrumb.LastIndexOf('\')+1))" -NoNewLine -ForegroundColor Yellow}
                            Write-Host " tokens to further obfuscate, so nothing changed."
                        }
                        Else
                        {
                            
                            $Script:ObfuscatedCommandHistory += , $Script:ObfuscatedCommand
    
                            
                            $CliSyntaxCurrentCommand = $UserInput.Trim('_ ').Replace('_','\')
    
                            
                            $Script:CliSyntax += $CliSyntaxCurrentCommand

                            
                            $Script:ExecutionCommands += ($CmdToPrint[0] + '$ScriptBlock' + $CmdToPrint[1])

                            
                            Write-Host "`nExecuted:`t"
                            Write-Host "  CLI:  " -NoNewline
                            Write-Host $CliSyntaxCurrentCommand -ForegroundColor Cyan
                            Write-Host "  FULL: " -NoNewline
                            Write-Host $CmdToPrint[0] -NoNewLine -ForegroundColor Cyan
                            Write-Host '$ScriptBlock' -NoNewLine -ForegroundColor Magenta
                            Write-Host $CmdToPrint[1] -ForegroundColor Cyan

                            
                            Write-Host "`nResult:`t"
                            Out-ScriptContents $Script:ObfuscatedCommand -PrintWarning
                        }
                    }
                }
            }
            Else
            {
                Return $UserInput
            }
        }
        Else
        {
            If    ($MenuInputOptionsShowHelp[0]     -Contains $UserInput) {Show-HelpMenu}
            ElseIf($MenuInputOptionsShowOptions[0]  -Contains $UserInput) {Show-OptionsMenu}
            ElseIf($TutorialInputOptions[0]         -Contains $UserInput) {Show-Tutorial}
            ElseIf($ClearScreenInputOptions[0]      -Contains $UserInput) {Clear-Host}
            
            
            ElseIf($ResetObfuscationInputOptions[0] -Contains $UserInput)
            {
                If(($Script:ObfuscatedCommand -ne $NULL) -AND ($Script:ObfuscatedCommand.Length -eq 0))
                {
                    Write-Host "`n`nWARNING:" -NoNewLine -ForegroundColor Red
                    Write-Host " ObfuscatedCommand has not been set. There is nothing to reset."
                }
                ElseIf($Script:ObfuscatedCommand -ceq $Script:ScriptBlock)
                {
                    Write-Host "`n`nWARNING:" -NoNewLine -ForegroundColor Red
                    Write-Host " No obfuscation has been applied to ObfuscatedCommand. There is nothing to reset."
                }
                Else
                {
                    $Script:LauncherApplied = $FALSE
                    $Script:ObfuscatedCommand = $Script:ScriptBlock
                    $Script:ObfuscatedCommandHistory = @($Script:ScriptBlock)
                    $Script:CliSyntax         = @()
                    $Script:ExecutionCommands = @()
                    
                    Write-Host "`n`nSuccessfully reset ObfuscatedCommand." -ForegroundColor Cyan
                }
            }
            ElseIf($UndoObfuscationInputOptions[0] -Contains $UserInput)
            {
                If(($Script:ObfuscatedCommand -ne $NULL) -AND ($Script:ObfuscatedCommand.Length -eq 0))
                {
                    Write-Host "`n`nWARNING:" -NoNewLine -ForegroundColor Red
                    Write-Host " ObfuscatedCommand has not been set. There is nothing to undo."
                }
                ElseIf($Script:ObfuscatedCommand -ceq $Script:ScriptBlock)
                {
                    Write-Host "`n`nWARNING:" -NoNewLine -ForegroundColor Red
                    Write-Host " No obfuscation has been applied to ObfuscatedCommand. There is nothing to undo."
                }
                Else
                {
                    
                    $Script:ObfuscatedCommand = $Script:ObfuscatedCommandHistory[$Script:ObfuscatedCommandHistory.Count-2]

                    
                    $Temp = $Script:ObfuscatedCommandHistory
                    $Script:ObfuscatedCommandHistory = @()
                    For($i=0; $i -lt $Temp.Count-1; $i++)
                    {
                        $Script:ObfuscatedCommandHistory += $Temp[$i]
                    }

                    
                    $CliSyntaxCount = $Script:CliSyntax.Count
                    While(($Script:CliSyntax[$CliSyntaxCount-1] -Match '^(clip|out )') -AND ($CliSyntaxCount -gt 0))
                    {
                        $CliSyntaxCount--
                    }
                    $Temp = $Script:CliSyntax
                    $Script:CliSyntax = @()
                    For($i=0; $i -lt $CliSyntaxCount-1; $i++)
                    {
                        $Script:CliSyntax += $Temp[$i]
                    }

                    
                    $Temp = $Script:ExecutionCommands
                    $Script:ExecutionCommands = @()
                    For($i=0; $i -lt $Temp.Count-1; $i++)
                    {
                        $Script:ExecutionCommands += $Temp[$i]
                    }

                    
                    If($Script:LauncherApplied)
                    {
                        $Script:LauncherApplied = $FALSE
                        Write-Host "`n`nSuccessfully removed launcher from ObfuscatedCommand." -ForegroundColor Cyan
                    }
                    Else
                    {
                        Write-Host "`n`nSuccessfully removed last obfuscation from ObfuscatedCommand." -ForegroundColor Cyan
                    }
                }
            }
            ElseIf(($OutputToDiskInputOptions[0] -Contains $UserInput) -OR ($OutputToDiskInputOptions[0] -Contains $UserInput.Trim().Split(' ')[0]))
            {
                If(($Script:ObfuscatedCommand -ne '') -AND ($Script:ObfuscatedCommand -ceq $Script:ScriptBlock))
                {
                    Write-Host "`n`nWARNING:" -NoNewLine -ForegroundColor Red
                    Write-Host " You haven't applied any obfuscation.`n         Just enter" -NoNewLine
                    Write-Host " SHOW OPTIONS" -NoNewLine -ForegroundColor Yellow
                    Write-Host " and look at ObfuscatedCommand."
                }
                ElseIf($Script:ObfuscatedCommand -ne '')
                {
                    
                    If($UserInput.Trim().Split(' ').Count -gt 1)
                    {
                        
                        $UserInputOutputFilePath = $UserInput.Trim().SubString(4).Trim()
                        Write-Host ''
                    }
                    Else
                    {
                        
                        $UserInputOutputFilePath = Read-Host "`n`nEnter path for output file (or leave blank for default)"
                    }                    
                    
                    If($UserInputOutputFilePath.Trim() -eq '')
                    {
                        
                        $OutputFilePath = "$ScriptDir\Obfuscated_Command.txt"
                    }
                    ElseIf(!($UserInputOutputFilePath.Contains('\')) -AND !($UserInputOutputFilePath.Contains('/')))
                    {
                        
                        $OutputFilePath = "$ScriptDir\$($UserInputOutputFilePath.Trim())"
                    }
                    Else
                    {
                        
                        $OutputFilePath = $UserInputOutputFilePath
                    }
                    
                    
                    Write-Output $Script:ObfuscatedCommand > $OutputFilePath

                    If($Script:LauncherApplied -AND (Test-Path $OutputFilePath))
                    {
                        $Script:CliSyntax += "out $OutputFilePath"
                        Write-Host "`nSuccessfully output ObfuscatedCommand to" -NoNewLine -ForegroundColor Cyan
                        Write-Host " $OutputFilePath" -NoNewLine -ForegroundColor Yellow
                        Write-Host ".`nA Launcher has been applied so this script cannot be run as a standalone .ps1 file." -ForegroundColor Cyan
                        If($Env:windir) { C:\Windows\Notepad.exe $OutputFilePath }
                    }
                    ElseIf(!$Script:LauncherApplied -AND (Test-Path $OutputFilePath))
                    {
                        $Script:CliSyntax += "out $OutputFilePath"
                        Write-Host "`nSuccessfully output ObfuscatedCommand to" -NoNewLine -ForegroundColor Cyan
                        Write-Host " $OutputFilePath" -NoNewLine -ForegroundColor Yellow
                        Write-Host "." -ForegroundColor Cyan
                        If($Env:windir) { C:\Windows\Notepad.exe $OutputFilePath }
                    }
                    Else
                    {
                        Write-Host "`nERROR: Unable to write ObfuscatedCommand out to" -NoNewLine -ForegroundColor Red
                        Write-Host " $OutputFilePath" -NoNewLine -ForegroundColor Yellow
                    }
                }
                ElseIf($Script:ObfuscatedCommand -eq '')
                {
                    Write-Host "`n`nERROR:" -NoNewLine -ForegroundColor Red
                    Write-Host " There isn't anything to write out to disk.`n       Just enter" -NoNewLine
                    Write-Host " SHOW OPTIONS" -NoNewLine -ForegroundColor Yellow
                    Write-Host " and look at ObfuscatedCommand."
                }
            }
            ElseIf($CopyToClipboardInputOptions[0] -Contains $UserInput)
            {
                If(($Script:ObfuscatedCommand -ne '') -AND ($Script:ObfuscatedCommand -ceq $Script:ScriptBlock))
                {
                    Write-Host "`n`nWARNING:" -NoNewLine -ForegroundColor Red
                    Write-Host " You haven't applied any obfuscation.`n         Just enter" -NoNewLine
                    Write-Host " SHOW OPTIONS" -NoNewLine -ForegroundColor Yellow
                    Write-Host " and look at ObfuscatedCommand."
                }
                ElseIf($Script:ObfuscatedCommand -ne '')
                {
                    
                    
                    Try
                    {
                        $Null = [Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms")
                        [Windows.Forms.Clipboard]::SetText($Script:ObfuscatedCommand)

                        If($Script:LauncherApplied)
                        {
                            Write-Host "`n`nSuccessfully copied ObfuscatedCommand to clipboard." -ForegroundColor Cyan
                        }
                        Else
                        {
                            Write-Host "`n`nSuccessfully copied ObfuscatedCommand to clipboard.`nNo Launcher has been applied, so command can only be pasted into powershell.exe." -ForegroundColor Cyan
                        }
                    }
                    Catch
                    {
                        $ErrorMessage = "Clipboard functionality will not work in PowerShell version $($PsVersionTable.PsVersion.Major) unless you add -STA (Single-Threaded Apartment) execution flag to powershell.exe."

                        If((Get-Command Write-Host).CommandType -ne 'Cmdlet')
                        {
                            
                            . ((Get-Command Write-Host)  | Where-Object {$_.CommandType -eq 'Cmdlet'}) "`n`nWARNING: " -NoNewLine -ForegroundColor Red
                            . ((Get-Command Write-Host)  | Where-Object {$_.CommandType -eq 'Cmdlet'}) $ErrorMessage -NoNewLine

                            . ((Get-Command Start-Sleep) | Where-Object {$_.CommandType -eq 'Cmdlet'}) 2
                        }
                        Else
                        {
                            Write-Host "`n`nWARNING: " -NoNewLine -ForegroundColor Red
                            Write-Host $ErrorMessage

                            If($Script:CliSyntax -gt 0) {Start-Sleep 2}
                        }
                    }
                    
                    $Script:CliSyntax += 'clip'
                }
                ElseIf($Script:ObfuscatedCommand -eq '')
                {
                    Write-Host "`n`nERROR:" -NoNewLine -ForegroundColor Red
                    Write-Host " There isn't anything to copy to your clipboard.`n       Just enter" -NoNewLine
                    Write-Host " SHOW OPTIONS" -NoNewLine -ForegroundColor Yellow
                    Write-Host " and look at ObfuscatedCommand." -NoNewLine
                }
                
            }
            ElseIf($ExecutionInputOptions[0] -Contains $UserInput)
            {
                If($Script:LauncherApplied)
                {
                    Write-Host "`n`nERROR:" -NoNewLine -ForegroundColor Red
                    Write-Host " Cannot execute because you have applied a Launcher.`n       Enter" -NoNewLine
                    Write-Host " COPY" -NoNewLine -ForeGroundColor Yellow
                    Write-Host "/" -NoNewLine
                    Write-Host "CLIP" -NoNewLine -ForeGroundColor Yellow
                    Write-Host " and paste into cmd.exe.`n       Or enter" -NoNewLine
                    Write-Host " UNDO" -NoNewLine -ForeGroundColor Yellow
                    Write-Host " to remove the Launcher from ObfuscatedCommand."
                }
                ElseIf($Script:ObfuscatedCommand -ne '')
                {
                    If($Script:ObfuscatedCommand -ceq $Script:ScriptBlock) {Write-Host "`n`nInvoking (though you haven't obfuscated anything yet):"}
                    Else {Write-Host "`n`nInvoking:"}
                    
                    Out-ScriptContents $Script:ObfuscatedCommand
                    Write-Host ''
                    $null = Invoke-Expression $Script:ObfuscatedCommand
                }
                Else {
                    Write-Host "`n`nERROR:" -NoNewLine -ForegroundColor Red
                    Write-Host " Cannot execute because you have not set ScriptPath or ScriptBlock.`n       Enter" -NoNewline
                    Write-Host " SHOW OPTIONS" -NoNewLine -ForegroundColor Yellow
                    Write-Host " to set ScriptPath or ScriptBlock."
                }
            }
            Else
            {
                Write-Host "`n`nERROR:" -NoNewLine -ForegroundColor Red
                Write-Host " You entered an invalid option. Enter" -NoNewLine
                Write-Host " HELP" -NoNewLine -ForegroundColor Yellow
                Write-Host " for more information."

                
                If($Script:CompoundCommand.Count -gt 0)
                {
                    $Script:CompoundCommand = @()
                }

                
                If($AcceptableInput.Count -gt 1)
                {
                    $Message = 'Valid options for current menu include:'
                }
                Else
                {
                    $Message = 'Valid option for current menu includes:'
                }
                Write-Host "       $Message " -NoNewLine

                $Counter=0
                ForEach($AcceptableOption in $AcceptableInput)
                {
                    $Counter++

                    
                    If($SelectionContainsCommand)
                    {
                        $ColorToOutput = 'Green'
                    }
                    Else
                    {
                        $ColorToOutput = 'Yellow'
                    }

                    Write-Host $AcceptableOption -NoNewLine -ForegroundColor $ColorToOutput
                    If(($Counter -lt $AcceptableInput.Length) -AND ($AcceptableOption.Length -gt 0))
                    {
                        Write-Host ', ' -NoNewLine
                    }
                }
                Write-Host ''
            }
        }
    }
    
    Return $UserInput.ToLower()
}


Function Show-OptionsMenu
{


    
    $Counter = 0
    ForEach($Line in $Script:OptionsMenu)
    {
        If($Line[0].ToLower().Trim() -eq 'scriptpath')            {$Script:OptionsMenu[$Counter][1] = $Script:ScriptPath}
        If($Line[0].ToLower().Trim() -eq 'scriptblock')           {$Script:OptionsMenu[$Counter][1] = $Script:ScriptBlock}
        If($Line[0].ToLower().Trim() -eq 'commandlinesyntax')     {$Script:OptionsMenu[$Counter][1] = $Script:CliSyntax}
        If($Line[0].ToLower().Trim() -eq 'executioncommands')     {$Script:OptionsMenu[$Counter][1] = $Script:ExecutionCommands}
        If($Line[0].ToLower().Trim() -eq 'obfuscatedcommand')
        {
            
            If($Script:ObfuscatedCommand -cne $Script:ScriptBlock) {$Script:OptionsMenu[$Counter][1] = $Script:ObfuscatedCommand}
            Else {$Script:OptionsMenu[$Counter][1] = ''}
        }
        If($Line[0].ToLower().Trim() -eq 'obfuscationlength')
        {
            
            If(($Script:ObfuscatedCommand.Length -gt 0) -AND ($Script:ObfuscatedCommand -cne $Script:ScriptBlock)) {$Script:OptionsMenu[$Counter][1] = $Script:ObfuscatedCommand.Length}
            Else {$Script:OptionsMenu[$Counter][1] = ''}
        }

        $Counter++
    }
    
    
    Write-Host "`n`nSHOW OPTIONS" -NoNewLine -ForegroundColor Cyan
    Write-Host " ::" -NoNewLine
    Write-Host " Yellow" -NoNewLine -ForegroundColor Yellow
    Write-Host " options can be set by entering" -NoNewLine
    Write-Host " SET OPTIONNAME VALUE" -NoNewLine -ForegroundColor Green
    Write-Host ".`n"
    ForEach($Option in $Script:OptionsMenu)
    {
        $OptionTitle = $Option[0]
        $OptionValue = $Option[1]
        $CanSetValue = $Option[2]
      
        Write-Host $LineSpacing -NoNewLine
        
        
        If($CanSetValue) {Write-Host $OptionTitle -NoNewLine -ForegroundColor Yellow}
        Else {Write-Host $OptionTitle -NoNewLine}
        Write-Host ": " -NoNewLine
        
        
        If($OptionTitle -eq 'ObfuscationLength')
        {
            Write-Host $OptionValue -ForegroundColor Cyan
        }
        ElseIf($OptionTitle -eq 'ScriptBlock')
        {
            Out-ScriptContents $OptionValue
        }
        ElseIf($OptionTitle -eq 'CommandLineSyntax')
        {
            
            $SetSyntax = ''
            If(($Script:ScriptPath.Length -gt 0) -AND ($Script:ScriptPath -ne 'N/A'))
            {
                $SetSyntax = " -ScriptPath '$Script:ScriptPath'"
            }
            ElseIf(($Script:ScriptBlock.Length -gt 0) -AND ($Script:ScriptPath -eq 'N/A'))
            {
                $SetSyntax = " -ScriptBlock {$Script:ScriptBlock}"
            }

            $CommandSyntax = ''
            If($OptionValue.Count -gt 0)
            {
                $CommandSyntax = " -Command '" + ($OptionValue -Join ',') + "' -Quiet"
            }

            If(($SetSyntax -ne '') -OR ($CommandSyntax -ne ''))
            {
                $CliSyntaxToOutput = "Invoke-Obfuscation" + $SetSyntax + $CommandSyntax
                Write-Host $CliSyntaxToOutput -ForegroundColor Cyan
            }
            Else
            {
                Write-Host ''
            }
        }
        ElseIf($OptionTitle -eq 'ExecutionCommands')
        {
            
            If($OptionValue.Count -gt 0) {Write-Host ''}
            $Counter = 0
            ForEach($ExecutionCommand in $OptionValue)
            {
                $Counter++
                If($ExecutionCommand.Length -eq 0) {Write-Host ''; Continue}
            
                $ExecutionCommand = $ExecutionCommand.Replace('$ScriptBlock','~').Split('~')
                Write-Host "    $($ExecutionCommand[0])" -NoNewLine -ForegroundColor Cyan
                Write-Host '$ScriptBlock' -NoNewLine -ForegroundColor Magenta
                
                
                If(($OptionValue.Count -gt 0) -AND ($Counter -lt $OptionValue.Count))
                {
                    Write-Host $ExecutionCommand[1] -ForegroundColor Cyan
                }
                Else
                {
                    Write-Host $ExecutionCommand[1] -NoNewLine -ForegroundColor Cyan
                }

            }
            Write-Host ''
        }
        ElseIf($OptionTitle -eq 'ObfuscatedCommand')
        {
            Out-ScriptContents $OptionValue
        }
        Else
        {
            Write-Host $OptionValue -ForegroundColor Magenta
        }
    }
    
}


Function Show-HelpMenu
{


    
    Write-Host "`n`nHELP MENU" -NoNewLine -ForegroundColor Cyan
    Write-Host " :: Available" -NoNewLine
    Write-Host " options" -NoNewLine -ForegroundColor Yellow
    Write-Host " shown below:`n"
    ForEach($InputOptionsList in $AllAvailableInputOptionsLists)
    {
        $InputOptionsCommands    = $InputOptionsList[0]
        $InputOptionsDescription = $InputOptionsList[1]

        
        If($InputOptionsDescription.Contains('<') -AND $InputOptionsDescription.Contains('>'))
        {
            $FirstPart  = $InputOptionsDescription.SubString(0,$InputOptionsDescription.IndexOf('<'))
            $MiddlePart = $InputOptionsDescription.SubString($FirstPart.Length+1)
            $MiddlePart = $MiddlePart.SubString(0,$MiddlePart.IndexOf('>'))
            $LastPart   = $InputOptionsDescription.SubString($FirstPart.Length+$MiddlePart.Length+2)
            Write-Host "$LineSpacing $FirstPart" -NoNewLine
            Write-Host $MiddlePart -NoNewLine -ForegroundColor Cyan
            Write-Host $LastPart -NoNewLine
        }
        Else
        {
            Write-Host "$LineSpacing $InputOptionsDescription" -NoNewLine
        }
        
        $Counter = 0
        ForEach($Command in $InputOptionsCommands)
        {
            $Counter++
            Write-Host $Command.ToUpper() -NoNewLine -ForegroundColor Yellow
            If($Counter -lt $InputOptionsCommands.Count) {Write-Host ',' -NoNewLine}
        }
        Write-Host ''
    }
}


Function Show-Tutorial
{


    Write-Host "`n`nTUTORIAL" -NoNewLine -ForegroundColor Cyan
    Write-Host " :: Here is a quick tutorial showing you how to get your obfuscation on:"
    
    Write-Host "`n1) " -NoNewLine -ForegroundColor Cyan
    Write-Host "Load a scriptblock (SET SCRIPTBLOCK) or a script path/URL (SET SCRIPTPATH)."
    Write-Host "   SET SCRIPTBLOCK Write-Host 'This is my test command' -ForegroundColor Green" -ForegroundColor Green
    
    Write-Host "`n2) " -NoNewLine -ForegroundColor Cyan
    Write-Host "Navigate through the obfuscation menus where the options are in" -NoNewLine
    Write-Host " YELLOW" -NoNewLine -ForegroundColor Yellow
    Write-Host "."
    Write-Host "   GREEN" -NoNewLine -ForegroundColor Green
    Write-Host " options apply obfuscation."
    Write-Host "   Enter" -NoNewLine
    Write-Host " BACK" -NoNewLine -ForegroundColor Yellow
    Write-Host "/" -NoNewLine
    Write-Host "CD .." -NoNewLine -ForegroundColor Yellow
    Write-Host " to go to previous menu and" -NoNewLine
    Write-Host " HOME" -NoNewline -ForegroundColor Yellow
    Write-Host "/" -NoNewline
    Write-Host "MAIN" -NoNewline -ForegroundColor Yellow
    Write-Host " to go to home menu.`n   E.g. Enter" -NoNewLine
    Write-Host " ENCODING" -NoNewLine -ForegroundColor Yellow
    Write-Host " & then" -NoNewLine
    Write-Host " 5" -NoNewLine -ForegroundColor Green
    Write-Host " to apply SecureString obfuscation."
    
    Write-Host "`n3) " -NoNewLine -ForegroundColor Cyan
    Write-Host "Enter" -NoNewLine
    Write-Host " TEST" -NoNewLine -ForegroundColor Yellow
    Write-Host "/" -NoNewLine
    Write-Host "EXEC" -NoNewLine -ForegroundColor Yellow
    Write-Host " to test the obfuscated command locally.`n   Enter" -NoNewLine
    Write-Host " SHOW" -NoNewLine -ForegroundColor Yellow
    Write-Host " to see the currently obfuscated command."
    
    Write-Host "`n4) " -NoNewLine -ForegroundColor Cyan
    Write-Host "Enter" -NoNewLine
    Write-Host " COPY" -NoNewLine -ForegroundColor Yellow
    Write-Host "/" -NoNewLine
    Write-Host "CLIP" -NoNewLine -ForegroundColor Yellow
    Write-Host " to copy obfuscated command out to your clipboard."
    Write-Host "   Enter" -NoNewLine
    Write-Host " OUT" -NoNewLine -ForegroundColor Yellow
    Write-Host " to write obfuscated command out to disk."
    
    Write-Host "`n5) " -NoNewLine -ForegroundColor Cyan
    Write-Host "Enter" -NoNewLine
    Write-Host " RESET" -NoNewLine -ForegroundColor Yellow
    Write-Host " to remove all obfuscation and start over.`n   Enter" -NoNewLine
    Write-Host " UNDO" -NoNewLine -ForegroundColor Yellow
    Write-Host " to undo last obfuscation.`n   Enter" -NoNewLine
    Write-Host " HELP" -NoNewLine -ForegroundColor Yellow
    Write-Host "/" -NoNewLine
    Write-Host "?" -NoNewLine -ForegroundColor Yellow
    Write-Host " for help menu."
    
    Write-Host "`nAnd finally the obligatory `"Don't use this for evil, please`"" -NoNewLine -ForegroundColor Cyan
    Write-Host " :)" -ForegroundColor Green
}


Function Out-ScriptContents
{


    Param(
        [Parameter(ValueFromPipeline = $true)]
        [String]
        $ScriptContents,

        [Switch]
        $PrintWarning
    )

    If($ScriptContents.Length -gt $CmdMaxLength)
    {
        
        $RedactedPrintLength = $CmdMaxLength/5
        
        
        $CmdLineWidth = (Get-Host).UI.RawUI.BufferSize.Width
        $RedactionMessage = "<REDACTED: ObfuscatedLength = $($ScriptContents.Length)>"
        $CenteredRedactionMessageStartIndex = (($CmdLineWidth-$RedactionMessage.Length)/2) - "[*] ObfuscatedCommand: ".Length
        $CurrentRedactionMessageStartIndex = ($RedactedPrintLength % $CmdLineWidth)
        
        If($CurrentRedactionMessageStartIndex -gt $CenteredRedactionMessageStartIndex)
        {
            $RedactedPrintLength = $RedactedPrintLength-($CurrentRedactionMessageStartIndex-$CenteredRedactionMessageStartIndex)
        }
        Else
        {
            $RedactedPrintLength = $RedactedPrintLength+($CenteredRedactionMessageStartIndex-$CurrentRedactionMessageStartIndex)
        }
    
        Write-Host $ScriptContents.SubString(0,$RedactedPrintLength) -NoNewLine -ForegroundColor Magenta
        Write-Host $RedactionMessage -NoNewLine -ForegroundColor Yellow
        Write-Host $ScriptContents.SubString($ScriptContents.Length-$RedactedPrintLength) -ForegroundColor Magenta
    }
    Else
    {
        Write-Host $ScriptContents -ForegroundColor Magenta
    }

    
    If($ScriptContents.Length -gt $CmdMaxLength)
    {
        If($PSBoundParameters['PrintWarning'])
        {
            Write-Host "`nWARNING: This command exceeds the cmd.exe maximum length of $CmdMaxLength." -ForegroundColor Red
            Write-Host "         Its length is" -NoNewLine -ForegroundColor Red
            Write-Host " $($ScriptContents.Length)" -NoNewLine -ForegroundColor Yellow
            Write-Host " characters." -ForegroundColor Red
        }
    }
}          


Function Show-AsciiArt
{

    [CmdletBinding()] Param (
        [Parameter(Position = 0)]
        [ValidateNotNullOrEmpty()]
        [Switch]
        $Random
    )

    
    $Spacing = "`t"
    $InvokeObfuscationAscii  = @()
    $InvokeObfuscationAscii += $Spacing + '    ____                 __                              '
    $InvokeObfuscationAscii += $Spacing + '   /  _/___ _   ______  / /_____                         '
    $InvokeObfuscationAscii += $Spacing + '   / // __ \ | / / __ \/ //_/ _ \______                  '
    $InvokeObfuscationAscii += $Spacing + ' _/ // / / / |/ / /_/ / ,< /  __/_____/                  '
    $InvokeObfuscationAscii += $Spacing + '/______ /__|_________/_/|_|\___/         __  _           '
    $InvokeObfuscationAscii += $Spacing + '  / __ \/ /_  / __/_  ________________ _/ /_(_)___  ____ '
    $InvokeObfuscationAscii += $Spacing + ' / / / / __ \/ /_/ / / / ___/ ___/ __ `/ __/ / __ \/ __ \'
    $InvokeObfuscationAscii += $Spacing + '/ /_/ / /_/ / __/ /_/ (__  ) /__/ /_/ / /_/ / /_/ / / / /'
    $InvokeObfuscationAscii += $Spacing + '\____/_.___/_/  \__,_/____/\___/\__,_/\__/_/\____/_/ /_/ '
    
    
    If(!$PSBoundParameters['Random'])
    {
        $ArrowAscii  = @()
        $ArrowAscii += '  |  '
        $ArrowAscii += '  |  '
        $ArrowAscii += ' \ / '
        $ArrowAscii += '  V  '

        
        Write-Host "`nIEX( ( '36{78Q55@32t61_91{99@104X97{114Q91-32t93}32t93}32t34@110m111@105}115X115-101m114_112@120@69-45{101@107X111m118m110-73Q124Q32X41Q57@51-93Q114_97_104t67t91{44V39Q112_81t109@39}101{99@97}108{112}101}82_45m32_32X52{51Q93m114@97-104{67t91t44t39V98t103V48t39-101}99}97V108}112t101_82_45{32@41X39{41_112t81_109_39m43{39-110t101@112{81t39X43@39t109_43t112_81Q109t101X39Q43m39}114Q71_112{81m109m39@43X39V32Q40}32m39_43_39{114-111m108t111t67{100m110{117Q39_43m39-111-114Q103_101t114@39m43-39{111t70-45}32m41}98{103V48V110Q98t103{48@39{43{39-43{32t98m103_48{111@105t98@103V48-39@43{39_32-32V43V32}32t98t103@48X116m97V99t98X103t48_39V43m39@43-39X43Q39_98@103@48}115V117V102Q98V79m45@98m39Q43{39X103_39X43Q39V48}43-39}43t39}98-103{48V101_107Q39t43X39_111X118X110V39X43}39t98_103{48@43}32_98{103}48{73{98-39@43t39m103_39}43{39{48Q32t39X43X39-32{40V32t41{39Q43V39m98X103{39_43V39{48-116{115Q79{39_43_39}98}103m48{39Q43t39X32X43{32_98@103-39@43m39X48_72-39_43t39V45m39t43Q39_101Q98}103_48-32_39Q43V39V32t39V43}39m43Q32V98X39Q43_39@103_48V39@43Q39@116X73t82V119m98-39{43_39}103Q48X40_46_32m39}40_40{34t59m91@65V114V114@97_121}93Q58Q58V82Q101Q118Q101{114}115_101m40_36_78m55@32t41t32-59{32}73{69V88m32{40t36V78t55}45Q74m111@105-110m32X39V39-32}41'.SpLiT( '{_Q-@t}mXV' ) |ForEach-Object { ([Int]`$_ -AS [Char]) } ) -Join'' )" -ForegroundColor Cyan
        Start-Sleep -Milliseconds 650
        ForEach($Line in $ArrowAscii) {Write-Host $Line -NoNewline; Write-Host $Line -NoNewline; Write-Host $Line -NoNewline; Write-Host $Line}
        Start-Sleep -Milliseconds 100
        
        Write-Host "`$N7 =[char[ ] ] `"noisserpxE-ekovnI| )93]rahC[,'pQm'ecalpeR-  43]rahC[,'bg0'ecalpeR- )')pQm'+'nepQ'+'m+pQme'+'rGpQm'+' ( '+'roloCdnu'+'orger'+'oF- )bg0nbg0'+'+ bg0oibg0'+'  +  bg0tacbg0'+'+'+'bg0sufbO-b'+'g'+'0+'+'bg0ek'+'ovn'+'bg0+ bg0Ib'+'g'+'0 '+' ( )'+'bg'+'0tsO'+'bg0'+' + bg'+'0H'+'-'+'ebg0 '+' '+'+ b'+'g0'+'tIRwb'+'g0(. '((`";[Array]::Reverse(`$N7 ) ; IEX (`$N7-Join '' )" -ForegroundColor Magenta
        Start-Sleep -Milliseconds 650
        ForEach($Line in $ArrowAscii) {Write-Host $Line -NoNewline; Write-Host $Line -NoNewline; Write-Host $Line}
        Start-Sleep -Milliseconds 100

        Write-Host ".(`"wRIt`" +  `"e-H`" + `"Ost`") (  `"I`" +`"nvoke`"+`"-Obfus`"+`"cat`"  +  `"io`" +`"n`") -ForegroundColor ( 'Gre'+'en')" -ForegroundColor Yellow
        Start-Sleep -Milliseconds 650
        ForEach($Line in $ArrowAscii) {Write-Host $Line -NoNewline;  Write-Host $Line}
        Start-Sleep -Milliseconds 100

        Write-Host "Write-Host `"Invoke-Obfuscation`" -ForegroundColor Green" -ForegroundColor White
        Start-Sleep -Milliseconds 650
        ForEach($Line in $ArrowAscii) {Write-Host $Line}
        Start-Sleep -Milliseconds 100
        
        
        Start-Sleep -Milliseconds 100
        ForEach($Char in [Char[]]'Invoke-Obfuscation')
        {
            Start-Sleep -Milliseconds (Get-Random -Input @(25..200))
            Write-Host $Char -NoNewline -ForegroundColor Green
        }
        
        Start-Sleep -Milliseconds 900
        Write-Host ""
        Start-Sleep -Milliseconds 300
        Write-Host

        
        $RandomColor = (Get-Random -Input @('Green','Cyan','Yellow'))
        ForEach($Line in $InvokeObfuscationAscii)
        {
            Write-Host $Line -ForegroundColor $RandomColor
        }
    }
    Else
    {
        

    }

    
    Write-Host ""
    Write-Host "`tTool    :: Invoke-Obfuscation" -ForegroundColor Magenta
    Write-Host "`tAuthor  :: Daniel Bohannon (DBO)" -ForegroundColor Magenta
    Write-Host "`tTwitter :: @danielhbohannon" -ForegroundColor Magenta
    Write-Host "`tBlog    :: http://danielbohannon.com" -ForegroundColor Magenta
    Write-Host "`tGithub  :: https://github.com/danielbohannon/Invoke-Obfuscation" -ForegroundColor Magenta
    Write-Host "`tVersion :: 1.8" -ForegroundColor Magenta
    Write-Host "`tLicense :: Apache License, Version 2.0" -ForegroundColor Magenta
    Write-Host "`tNotes   :: If(!`$Caffeinated) {Exit}" -ForegroundColor Magenta
}
