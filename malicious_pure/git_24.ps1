


















Function Out-PowerShellLauncher
{


    [CmdletBinding(DefaultParameterSetName = 'ScriptBlock')] Param (
        [Parameter(Position = 0, ValueFromPipeline = $True, ParameterSetName = 'ScriptBlock')]
        [ValidateNotNullOrEmpty()]
        [ScriptBlock]
        $ScriptBlock,
        
        [Parameter(Position = 1)]
        [ValidateNotNullOrEmpty()]
        [ValidateSet(1,2,3,4,5,6,7,8,9,10,11,12)]
        [Int]
        $LaunchType,

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
        
        [Parameter(Position = 2)]
        [String]
        $SwitchesAsString
    )

    
    $ArgsDefenderWillSee = @()

    
    $ScriptString = [String]$ScriptBlock
    
    
    If($ScriptString.Contains([Char]13+[Char]10))
    {
        Write-Host ""
        Write-Warning "Current script content contains newline characters.`n         Applying a launcher will not work on the command line.`n         Apply ENCODING obfuscation before applying LAUNCHER."
        Start-Sleep 1
        Return $ScriptString
    }

    
    If($SwitchesAsString.Length -gt 0)
    {
        If(!($SwitchesAsString.Contains('0')))
        {
            $SwitchesAsString = ([Char[]]$SwitchesAsString | Sort-Object -Unique -Descending) -Join ' '
            ForEach($SwitchAsString in $SwitchesAsString.Split(' '))
            {
                Switch($SwitchAsString)
                {
                    '1' {$NoExit          = $TRUE}
                    '2' {$NonInteractive  = $TRUE}
                    '3' {$NoLogo          = $TRUE}
                    '4' {$NoProfile       = $TRUE}
                    '5' {$Command         = $TRUE}
                    '6' {$WindowsStyle    = 'Hidden'}
                    '7' {$ExecutionPolicy = 'Bypass'}
                    '8' {$Wow64           = $TRUE}
                    default {Write-Error "An invalid `$SwitchAsString value ($SwitchAsString) was passed to switch block for Out-PowerShellLauncher"; Exit;}
                }
            }
        }
    }

    
    $Tokens = [System.Management.Automation.PSParser]::Tokenize($ScriptString,[ref]$null)
    $CharsToEscape = @('&','|','<','>')
    For($i=$Tokens.Count-1; $i -ge 0; $i--)
    {
        $Token = $Tokens[$i]
        
        
        $PreTokenStr    = $ScriptString.SubString(0,$Token.Start)
        $ExtractedToken = $ScriptString.SubString($Token.Start,$Token.Length)
        $PostTokenStr   = $ScriptString.SubString($Token.Start+$Token.Length)
        
        
        
        If($Token.Type -eq 'String' -AND !($ExtractedToken.StartsWith("'") -AND $ExtractedToken.EndsWith("'")))
        {
            ForEach($Char in $CharsToEscape)
            {
                If($ExtractedToken.Contains($Char)) {$ExtractedToken = $ExtractedToken.Replace($Char,"^$Char")}
            }

            If($ExtractedToken.Contains('\')) {$ExtractedToken = $ExtractedToken.Replace('\','\\')}
            
            If($ExtractedToken.Contains('"')) {$ExtractedToken = '\"' + $ExtractedToken.SubString(1,$ExtractedToken.Length-1-1) + '\"'}
        }
        Else
        {
            
            If($ExtractedToken.Contains('^'))
            {
                $ExtractedTokenSplit = $ExtractedToken.Split('^')
                $ExtractedToken = ''
                For($j=0; $j -lt $ExtractedTokenSplit.Count; $j++)
                {
                    $ExtractedToken += $ExtractedTokenSplit[$j]
                    $FirstCharFollowingCaret = $ExtractedTokenSplit[$j+1]
                    If(!$FirstCharFollowingCaret -OR ($CharsToEscape -NotContains $FirstCharFollowingCaret.SubString(0,1)) -AND ($j -ne $ExtractedTokenSplit.Count-1))
                    {
                        $ExtractedToken += '^^^^'
                    }
                }
            }

            ForEach($Char in $CharsToEscape)
            {
                If($ExtractedToken.Contains($Char)) {$ExtractedToken = $ExtractedToken.Replace($Char,"^^^$Char")}
            }
        }
        
        
        $ScriptString = $PreTokenStr + $ExtractedToken + $PostTokenStr
    }
 
    
    
    $PowerShellFlags = New-Object String[](0)
    If($PSBoundParameters['NoExit'] -OR $NoExit)
    {
        $FullArgument = "-NoExit"
        $PowerShellFlags += $FullArgument.SubString(0,(Get-Random -Minimum 4 -Maximum ($FullArgument.Length+1)))
    }
    If($PSBoundParameters['NoProfile'] -OR $NoProfile)
    {
        $FullArgument = "-NoProfile"
        $PowerShellFlags += $FullArgument.SubString(0,(Get-Random -Minimum 4 -Maximum ($FullArgument.Length+1)))
    }
    If($PSBoundParameters['NonInteractive'] -OR $NonInteractive)
    {
        $FullArgument = "-NonInteractive"
        $PowerShellFlags += $FullArgument.SubString(0,(Get-Random -Minimum 5 -Maximum ($FullArgument.Length+1)))
    }
    If($PSBoundParameters['NoLogo'] -OR $NoLogo)
    {
        $FullArgument = "-NoLogo"
        $PowerShellFlags += $FullArgument.SubString(0,(Get-Random -Minimum 4 -Maximum ($FullArgument.Length+1)))
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

    
    
    If($PowerShellFlags.Count -gt 1)
    {
        $PowerShellFlags = Get-Random -InputObject $PowerShellFlags -Count $PowerShellFlags.Count
    }

    
    If($PSBoundParameters['Command'] -OR $Command)
    {
        $FullArgument = "-Command"
        $PowerShellFlags += $FullArgument.SubString(0,(Get-Random -Minimum 2 -Maximum ($FullArgument.Length+1)))
    }

    
    For($i=0; $i -lt $PowerShellFlags.Count; $i++)
    {
        $PowerShellFlags[$i] = ([Char[]]$PowerShellFlags[$i] | ForEach-Object {$Char = $_.ToString().ToLower(); If(Get-Random -Input @(0..1)) {$Char = $Char.ToUpper()} $Char}) -Join ''
    }

    
    
    $PowerShellFlagsArray = $PowerShellFlags
    $PowerShellFlags = ($PowerShellFlags | ForEach-Object {$_ + ' '*(Get-Random -Minimum 1 -Maximum 3)}) -Join ''
    $PowerShellFlags = ' '*(Get-Random -Minimum 1 -Maximum 3) + $PowerShellFlags + ' '*(Get-Random -Minimum 1 -Maximum 3)

    
    $WinPath      = "C:\WINDOWS"
    $System32Path = "C:\WINDOWS\system32"
    $PathToRunDll = Get-Random -Input @("$System32Path\rundll32"  , "$System32Path\rundll32.exe"  , "rundll32" , "rundll32.exe")
    $PathToMshta  = Get-Random -Input @("$System32Path\mshta"     , "$System32Path\mshta.exe"     , "mshta"    , "mshta.exe")
    $PathToCmd    = Get-Random -Input @("$System32Path\cmd"       , "$System32Path\cmd.exe"       , "cmd.exe"  , "cmd")
    $PathToClip   = Get-Random -Input @("$System32Path\clip"      , "$System32Path\clip.exe"      , "clip"     , "clip.exe")
    $PathToWmic   = Get-Random -Input @("$System32Path\WBEM\wmic" , "$System32Path\WBEM\wmic.exe" , "wmic"     , "wmic.exe")
    
    
    If($PathToCmd.Contains('\'))
    {
        $PathToCmd = $PathToCmd + ' '*(Get-Random -Minimum 2 -Maximum 4)
    }
    Else
    {
        $PathToCmd = $PathToCmd + ' '*(Get-Random -Minimum 0 -Maximum 4)
    }

    If($PSBoundParameters['Wow64'] -OR $Wow64)
    {
        $PathToPowerShell = "$WinPath\SysWOW64\WindowsPowerShell\v1.0\powershell.exe"
    }
    Else
    {
        
        
        $PathToPowerShell = "powershell"
    }

    
    $PowerShellFlags  = ([Char[]]$PowerShellFlags.ToLower()  | ForEach-Object {$Char = $_; If(Get-Random -Input (0..1)){$Char = $Char.ToString().ToUpper()} $Char}) -Join ''
    $PathToPowerShell = ([Char[]]$PathToPowerShell.ToLower() | ForEach-Object {$Char = $_; If(Get-Random -Input (0..1)){$Char = $Char.ToString().ToUpper()} $Char}) -Join ''
    $PathToRunDll     = ([Char[]]$PathToRunDll.ToLower()     | ForEach-Object {$Char = $_; If(Get-Random -Input (0..1)){$Char = $Char.ToString().ToUpper()} $Char}) -Join ''
    $PathToMshta      = ([Char[]]$PathToMshta.ToLower()      | ForEach-Object {$Char = $_; If(Get-Random -Input (0..1)){$Char = $Char.ToString().ToUpper()} $Char}) -Join ''
    $PathToCmd        = ([Char[]]$PathToCmd.ToLower()        | ForEach-Object {$Char = $_; If(Get-Random -Input (0..1)){$Char = $Char.ToString().ToUpper()} $Char}) -Join ''
    $PathToClip       = ([Char[]]$PathToClip.ToLower()       | ForEach-Object {$Char = $_; If(Get-Random -Input (0..1)){$Char = $Char.ToString().ToUpper()} $Char}) -Join ''
    $PathToWmic       = ([Char[]]$PathToWmic.ToLower()       | ForEach-Object {$Char = $_; If(Get-Random -Input (0..1)){$Char = $Char.ToString().ToUpper()} $Char}) -Join ''
    $SlashC           = ([Char[]]'/c'.ToLower()              | ForEach-Object {$Char = $_; If(Get-Random -Input (0..1)){$Char = $Char.ToString().ToUpper()} $Char}) -Join ''
    $Echo             = ([Char[]]'echo'.ToLower()            | ForEach-Object {$Char = $_; If(Get-Random -Input (0..1)){$Char = $Char.ToString().ToUpper()} $Char}) -Join ''

    
    $NumberOfDoubleQuotes = $ScriptString.Length-$ScriptString.Replace('"','').Length
    If($NumberOfDoubleQuotes%2 -eq 1)
    {
        Write-Host ""
        Write-Warning "This command contains an unbalanced number of double quotes ($NumberOfDoubleQuotes).`n         Try applying STRING or ENCODING obfuscation options first to encode the double quotes.`n"
        Start-Sleep 1
        Return $ScriptString
    }

    
    If($LaunchType -eq 0)
    {
        $LaunchType = Get-Random -Input @(3..12)
    }

    
    Switch($LaunchType)
    {
        1 {
              
              
              

              
              ForEach($Char in $CharsToEscape)
              {
                  If($ScriptString.Contains("^^^$Char")) {$ScriptString = $ScriptString.Replace("^^^$Char",$Char)}
              }
              If($ScriptString.Contains('^^^^'))
              {
                  $ScriptString = $ScriptString.Replace('^^^^','^')
              }

              
              $PSCmdSyntax = $PowerShellFlags + '"' + $ScriptString + '"'
    
              
              $ArgsDefenderWillSee += , @($PathToPowerShell, $PSCmdSyntax)

              $CmdLineOutput = $PathToPowerShell + $PSCmdSyntax
          }
        2 {
              
              
              

              
              ForEach($Char in $CharsToEscape)
              {
                  If($ScriptString.Contains("^^^$Char")) {$ScriptString = $ScriptString.Replace("^^^$Char",$Char)}
                  If($ScriptString.Contains("^$Char")) {$ScriptString = $ScriptString.Replace("^$Char","^^^$Char")}
              }
              If($ScriptString.Contains('^^^^'))
              {
                  $ScriptString = $ScriptString.Replace('^^^^','^')
              }

              
              $PSCmdSyntax = $PowerShellFlags + '"' + $ScriptString + '"'
              $CmdSyntax   = $SlashC + ' '*(Get-Random -Minimum 0 -Maximum 4) + $PathToPowerShell + $PSCmdSyntax
    
              
              $ArgsDefenderWillSee += , @($PathToCmd       , $CmdSyntax)
              $ArgsDefenderWillSee += , @($PathToPowerShell, $PSCmdSyntax)

              $CmdLineOutput = $PathToCmd + $CmdSyntax
          }
        3 {
              
              
              

              
              For($i=1; $i -le 12; $i++)
              {
                  $StringToReplace = '${' + ' '*$i + '}'
                  If($ScriptString.Contains($StringToReplace))
                  {
                      $ScriptString = $ScriptString.Replace($StringToReplace,$StringToReplace.Replace(' ','\ '))
                  }
              }

              
              ForEach($Char in $CharsToEscape)
              {
                  While($ScriptString.Contains('^' + $Char))
                  {
                      $ScriptString = $ScriptString.Replace(('^' + $Char),$Char)
                  }
              }
              If($ScriptString.Contains('^^^^'))
              {
                  $ScriptString = $ScriptString.Replace('^^^^','^')
              }

              
              If($ScriptString.Contains(','))
              {
                  
                  $SetVariables = ''

                  
                  If($ScriptString.Contains('$'))
                  {
                      $ScriptString = $ScriptString.Replace('$','`$')
                         
                      
                      If($ScriptString.Contains('``$'))
                      {
                          $ScriptString = $ScriptString.Replace('``$','```$')
                      }
                  }

                  
                  If($ScriptString.Contains('`"'))
                  {
                      $ScriptString = $ScriptString.Replace('`"','``"')
                  }

                  
                  If($ScriptString.Contains('"'))
                  {
                      
                      While($ScriptString.Contains('\"'))
                      {
                          $ScriptString = $ScriptString.Replace('\"','"')
                      }

                      
                      $CharCastDoubleQuote = ([Char[]](Get-Random -Input @('[String][Char]34','([Char]34).ToString()')) | ForEach-Object {$Char = $_; If(Get-Random -Input (0..1)){$Char = $Char.ToString().ToUpper()} $Char}) -Join ''
                      If($ScriptString.Length-$ScriptString.Replace('"','').Length -le 5)
                      {
                          
                          $SubstitutionSyntax  = ('\"' + ' '*(Get-Random -Minimum 0 -Maximum 3) + '+' + ' '*(Get-Random -Minimum 0 -Maximum 3) + $CharCastDoubleQuote + ' '*(Get-Random -Minimum 0 -Maximum 3) + '+' + ' '*(Get-Random -Minimum 0 -Maximum 3) + '\"')
                          $ScriptString        = $ScriptString.Replace('"',$SubstitutionSyntax).Replace('\"\"+','').Replace('\"\" +','').Replace('\"\"  +','').Replace('\"\"   +','')
                      }
                      Else
                      {
                          
                          
                          $CharsToRandomVarName  = @(0..9)
                          $CharsToRandomVarName += @('A','B','C','D','E','F','G','H','I','J','K','L','M','N','O','P','Q','R','S','T','U','V','W','X','Y','Z')

                          
                          $RandomVarLength = (Get-Random -Input @(1..2))
   
                          
                          If($CharsToRandomVarName.Count -lt $RandomVarLength) {$RandomVarLength = $CharsToRandomVarName.Count}
                          $RandomVarName = ((Get-Random -Input $CharsToRandomVarName -Count $RandomVarLength) -Join '').Replace(' ','')

                          
                          While($ScriptString.ToLower().Contains($RandomVarName.ToLower()))
                          {
                              $RandomVarName = ((Get-Random -Input $CharsToRandomVarName -Count $RandomVarLength) -Join '').Replace(' ','')
                              $RandomVarLength++
                          }

                          
                          $RandomVarNameMaybeConcatenated = $RandomVarName
                          If((Get-Random -Input @(0..1)) -eq 0)
                          {
                              $RandomVarNameMaybeConcatenated = '(' + (Out-ConcatenatedString $RandomVarName "'") + ')'
                          }

                          
                          $RandomVarSetSyntax  = @()
                          $RandomVarSetSyntax += '$' + $RandomVarName + ' '*(Get-Random @(0..2)) + '=' + ' '*(Get-Random @(0..2)) + $CharCastDoubleQuote
                          $RandomVarSetSyntax += (Get-Random -Input @('Set-Variable','SV','Set')) + ' '*(Get-Random @(1..2)) + $RandomVarNameMaybeConcatenated + ' '*(Get-Random @(1..2)) + '(' + ' '*(Get-Random @(0..2)) + $CharCastDoubleQuote + ' '*(Get-Random @(0..2)) + ')'
    
                          
                          $RandomVarSet = (Get-Random -Input $RandomVarSetSyntax)

                          
                          $SetVariables += $RandomVarSet + ' '*(Get-Random @(1..2)) + ';'
                          $ScriptString = $ScriptString.Replace('"',"`${$RandomVarName}")
                      }
                  }
                  
                  
                  $CharCastComma= ([Char[]](Get-Random -Input @('[String][Char]44','([Char]44).ToString()')) | ForEach-Object {$Char = $_; If(Get-Random -Input (0..1)){$Char = $Char.ToString().ToUpper()} $Char}) -Join ''
                  If($ScriptString.Length-$ScriptString.Replace(',','').Length -le 5)
                  {
                      
                      $SubstitutionSyntax  = ('\"' + ' '*(Get-Random -Minimum 0 -Maximum 3) + '+' + ' '*(Get-Random -Minimum 0 -Maximum 3) + $CharCastComma + ' '*(Get-Random -Minimum 0 -Maximum 3) + '+' + ' '*(Get-Random -Minimum 0 -Maximum 3) + '\"')
                      $ScriptString        = $ScriptString.Replace(',',$SubstitutionSyntax).Replace('\"\"+','').Replace('\"\" +','').Replace('\"\"  +','').Replace('\"\"   +','')
                  }
                  Else
                  {
                      
                      
                      $CharsToRandomVarName  = @(0..9)
                      $CharsToRandomVarName += @('A','B','C','D','E','F','G','H','I','J','K','L','M','N','O','P','Q','R','S','T','U','V','W','X','Y','Z')

                      
                      $RandomVarLength = (Get-Random -Input @(1..2))
   
                      
                      If($CharsToRandomVarName.Count -lt $RandomVarLength) {$RandomVarLength = $CharsToRandomVarName.Count}
                      $RandomVarName = ((Get-Random -Input $CharsToRandomVarName -Count $RandomVarLength) -Join '').Replace(' ','')

                      
                      While($ScriptString.ToLower().Contains($RandomVarName.ToLower()))
                      {
                          $RandomVarName = ((Get-Random -Input $CharsToRandomVarName -Count $RandomVarLength) -Join '').Replace(' ','')
                          $RandomVarLength++
                      }

                      
                      $RandomVarNameMaybeConcatenated = $RandomVarName
                      If((Get-Random -Input @(0..1)) -eq 0)
                      {
                          $RandomVarNameMaybeConcatenated = '(' + (Out-ConcatenatedString $RandomVarName "'") + ')'
                      }

                      
                      $RandomVarSetSyntax  = @()
                      $RandomVarSetSyntax += '$' + $RandomVarName + ' '*(Get-Random @(0..2)) + '=' + ' '*(Get-Random @(0..2)) + $CharCastComma
                      $RandomVarSetSyntax += (Get-Random -Input @('Set-Variable','SV','Set')) + ' '*(Get-Random @(1..2)) + $RandomVarNameMaybeConcatenated + ' '*(Get-Random @(1..2)) + '(' + ' '*(Get-Random @(0..2)) + $CharCastComma + ' '*(Get-Random @(0..2)) + ')'

                      
                      $RandomVarSet = (Get-Random -Input $RandomVarSetSyntax)

                      
                      $SetVariables += $RandomVarSet + ' '*(Get-Random @(1..2)) + ';'
                      $ScriptString = $ScriptString.Replace(',',"`${$RandomVarName}")
                  }

                  
                  $ScriptString =  '\"' + $ScriptString + '\"'

                  
                  
                  
                  $ScriptStringTemp = ','
                  While($ScriptStringTemp.Contains(','))
                  {
                      $ScriptStringTemp = Out-EncapsulatedInvokeExpression $ScriptString
                  }

                  
                  $ScriptString = $ScriptStringTemp

                  
                  $ScriptString = $SetVariables + $ScriptString
              }

              
              $WmicArguments = ([Char[]]'process call create' | ForEach-Object {$Char = $_; If(Get-Random -Input (0..1)){$Char = $Char.ToString().ToUpper()} $Char}) -Join ''

              
              $WmicArguments = (($WmicArguments.Split(' ') | ForEach-Object {$RandomQuotes = (Get-Random -Input @('"',"'",' ')); $RandomQuotes + $_ + $RandomQuotes + ' '*(Get-Random -Minimum 1 -Maximum 4)}) -Join '').Trim()

              
              If($ScriptString.Contains('\"'))
              {
                  $ScriptString = $ScriptString.Replace('\"','"\"')
              }

              
              $PSCmdSyntax   = $PowerShellFlags + $ScriptString
              $WmicCmdSyntax = ' '*(Get-Random -Minimum 1 -Maximum 4) + $WmicArguments + ' '*(Get-Random -Minimum 1 -Maximum 4) + '"' + $PathToPowerShell + $PSCmdSyntax + '"'
    
              
              
              $ArgsDefenderWillSee += , @("[Unrelated to WMIC.EXE execution] C:\WINDOWS\system32\wbem\wmiprvse.exe", " -secured -Embedding")
              $ArgsDefenderWillSee += , @($PathToPowerShell, $PSCmdSyntax)

              $CmdLineOutput = $PathToWmic + $WmicCmdSyntax
          }
        4 {
              
              
              

              

              
              ForEach($Char in $CharsToEscape)
              {
                  If($ScriptString.Contains("^^^$Char")) {$ScriptString = $ScriptString.Replace("^^^$Char","$Char")}
              }
              If($ScriptString.Contains('^^^^'))
              {
                  $ScriptString = $ScriptString.Replace('^^^^','^')
              }

              
              $Shell32Dll = ([Char[]]'SHELL32.DLL' | ForEach-Object {$Char = $_; If(Get-Random -Input (0..1)){$Char = $Char.ToString().ToUpper()} $Char}) -Join ''

              
              $ExecutionFlagsRunDllSyntax = ($PowerShellFlagsArray | Where-Object {$_.Trim().Length -gt 0} | ForEach-Object {'"' + ' '*(Get-Random -Minimum 0 -Maximum 3) + $_ + ' '*(Get-Random -Minimum 0 -Maximum 3) + '"' + ' '*(Get-Random -Minimum 1 -Maximum 4)}) -Join ''
 
              
              $PSCmdSyntax     = ' '*(Get-Random -Minimum 1 -Maximum 4) + $ExecutionFlagsRunDllSyntax + ' '*(Get-Random -Minimum 1 -Maximum 4) + "`"$ScriptString`""
              $RunDllCmdSyntax = ' '*(Get-Random -Minimum 1 -Maximum 4) + $Shell32Dll + (Get-Random -Input @(',',' ', ((Get-Random -Input @(',',',',',',' ',' ',' ') -Count (Get-Random -Input @(4..6)))-Join''))) + 'ShellExec_RunDLL' + ' '*(Get-Random -Minimum 1 -Maximum 4) + "`"$PathToPowerShell`"" + $PSCmdSyntax
    
              
              $ArgsDefenderWillSee += , @($PathToRunDll          , $RunDllCmdSyntax)
              $ArgsDefenderWillSee += , @("`"$PathToPowerShell`"", $PSCmdSyntax.Replace('^',''))

              $CmdLineOutput = $PathToRunDll + $RunDllCmdSyntax
          }
        5 {
              
              
              

              
              ForEach($Char in $CharsToEscape)
              {
                  If($ScriptString.Contains("^^^$Char")) {$ScriptString = $ScriptString.Replace("^^^$Char","^$Char")}
              }
              If($ScriptString.Contains('^^^^'))
              {
                  $ScriptString = $ScriptString.Replace('^^^^','^^')
              }
                        
              
              If($ScriptString.Contains('\"')) {$ScriptString = $ScriptString.Replace('\"','"')}

              
              
              $CharsForVarName = @('a','b','c','d','e','f','g','h','i','j','k','l','m','n','o','p','q','r','s','t','u','v','w','x','y','z')
              $VariableName = (Get-Random -Input $CharsForVarName -Count ($CharsForVarName.Count/(Get-Random -Input @(5..10)))) -Join ''
              $VariableName = ([Char[]]$VariableName.ToLower() | ForEach-Object {$Char = $_; If(Get-Random -Input (0..1)){$Char = $Char.ToString().ToUpper()} $Char}) -Join ''

              
              $InvokeVariableSyntax = Out-RandomInvokeRandomEnvironmentVariableSyntax $VariableName

              
              $SetSyntax = ([Char[]]'set' | ForEach-Object {$Char = $_; If(Get-Random -Input (0..1)){$Char = $Char.ToString().ToUpper()} $Char}) -Join ''
              $SetSyntax = $SetSyntax + ' '*(Get-Random -Minimum 2 -Maximum 4) + $VariableName + '='

              
              $SetSyntax = ([Char[]]$SetSyntax.ToLower() | ForEach-Object {$Char = $_; If(Get-Random -Input (0..1)){$Char = $Char.ToString().ToUpper()} $Char}) -Join ''

              
              $PSCmdSyntax = $PowerShellFlags + $InvokeVariableSyntax
              $CmdSyntax   = $SlashC + ' '*(Get-Random -Minimum 0 -Maximum 4) + '"' + $SetSyntax + $ScriptString + '&&' + ' '*(Get-Random -Minimum 0 -Maximum 4) + $PathToPowerShell + $PSCmdSyntax + '"'
    
              
              $ArgsDefenderWillSee += , @($PathToCmd       , $CmdSyntax)
              $ArgsDefenderWillSee += , @($PathToPowerShell, $PSCmdSyntax.Replace('^',''))

              $CmdLineOutput = $PathToCmd + $CmdSyntax
          }
        6 {
              
              
              

              
              If($ScriptString.Contains('\"')) {$ScriptString = $ScriptString.Replace('\"','"')}
             
              
              $PowerShellStdin = Out-RandomPowerShellStdInInvokeSyntax
              
              
              $PSCmdSyntax = $PowerShellFlags + $PowerShellStdin
              $CmdSyntax   = $SlashC + ' '*(Get-Random -Minimum 0 -Maximum 4) + '"'  + ' '*(Get-Random -Minimum 0 -Maximum 3) + $Echo + (Get-Random -Input ('/','\',' '*(Get-Random -Minimum 1 -Maximum 3))) + $ScriptString + ' '*(Get-Random -Minimum 1 -Maximum 3) + '|' + ' '*(Get-Random -Minimum 1 -Maximum 3) + $PathToPowerShell + $PSCmdSyntax + '"'
    
              
              $ArgsDefenderWillSee += , @($PathToCmd       , $CmdSyntax)
              $ArgsDefenderWillSee += , @($PathToPowerShell, $PSCmdSyntax.Replace('^',''))

              $CmdLineOutput = $PathToCmd + $CmdSyntax
          }
        7 {
              
              
              

              
              If($ScriptString.Contains('\"')) {$ScriptString = $ScriptString.Replace('\"','"')}
             
              
              $PowerShellClip = Out-RandomClipboardInvokeSyntax

              
              
              
              
              
              $CommandFlagValue = $NULL
              If($PSBoundParameters['Command'] -OR $Command)
              {
                  $UpperLimit = $PowerShellFlagsArray.Count-1
                  $CommandFlagValue = $PowerShellFlagsArray[$PowerShellFlagsArray.Count-1]
              }
              Else
              {
                  $UpperLimit = $PowerShellFlagsArray.Count
              }

              
              $PowerShellFlags = @()
              For($i=0; $i -lt $UpperLimit; $i++)
              {
                  $PowerShellFlags += $PowerShellFlagsArray[$i]
              }

              
              $PowerShellFlags += (Get-Random -Input @('-st','-sta'))
              
              
              
              If($PowerShellFlags.Count -gt 1)
              {
                  $PowerShellFlags = Get-Random -InputObject $PowerShellFlags -Count $PowerShellFlags.Count
              }

              
              If($CommandFlagValue)
              {
                  $PowerShellFlags += $CommandFlagValue
              }

              
              For($i=0; $i -lt $PowerShellFlags.Count; $i++)
              {
                  $PowerShellFlags[$i] = ([Char[]]$PowerShellFlags[$i] | ForEach-Object {$Char = $_.ToString().ToLower(); If(Get-Random -Input @(0..1)) {$Char = $Char.ToUpper()} $Char}) -Join ''
              }

              
              $PowerShellFlags = ($PowerShellFlags | ForEach-Object {$_ + ' '*(Get-Random -Minimum 1 -Maximum 3)}) -Join ''
              $PowerShellFlags = ' '*(Get-Random -Minimum 1 -Maximum 3) + $PowerShellFlags + ' '*(Get-Random -Minimum 1 -Maximum 3)

              
              $PSCmdSyntax = $PowerShellFlags + $PowerShellClip
              $CmdSyntax   = $SlashC + ' '*(Get-Random -Minimum 0 -Maximum 4) + '"'  + ' '*(Get-Random -Minimum 0 -Maximum 3) + $Echo + (Get-Random -Input ('/','\',' '*(Get-Random -Minimum 1 -Maximum 3))) + $ScriptString + ' '*(Get-Random -Minimum 0 -Maximum 2) + '|' + ' '*(Get-Random -Minimum 0 -Maximum 2) + $PathToClip + ' '*(Get-Random -Minimum 0 -Maximum 2) + '&&' + ' '*(Get-Random -Minimum 1 -Maximum 3) + $PathToPowerShell + $PSCmdSyntax + '"'
    
              
              $ArgsDefenderWillSee += , @($PathToCmd       , $CmdSyntax)
              $ArgsDefenderWillSee += , @($PathToPowerShell, $PSCmdSyntax.Replace('^',''))

              $CmdLineOutput = $PathToCmd + $CmdSyntax
          }
        8 {
              
              
              

              
              ForEach($Char in $CharsToEscape)
              {
                  If($ScriptString.Contains("^^^$Char")) {$ScriptString = $ScriptString.Replace("^^^$Char","^$Char")}
              }
              If($ScriptString.Contains('^^^^'))
              {
                  $ScriptString = $ScriptString.Replace('^^^^','^^')
              }

              
              If($ScriptString.Contains('\"')) {$ScriptString = $ScriptString.Replace('\"','"')}
              
              
              
              $CharsForVarName = @('a','b','c','d','e','f','g','h','i','j','k','l','m','n','o','p','q','r','s','t','u','v','w','x','y','z')
              $VariableName  = (Get-Random -Input $CharsForVarName -Count ($CharsForVarName.Count/(Get-Random -Input @(5..10)))) -Join ''
              $VariableName  = ([Char[]]$VariableName.ToLower() | ForEach-Object {$Char = $_; If(Get-Random -Input (0..1)){$Char = $Char.ToString().ToUpper()} $Char}) -Join ''
              $VariableName2 = (Get-Random -Input $CharsForVarName -Count ($CharsForVarName.Count/(Get-Random -Input @(5..10)))) -Join ''
              $VariableName2 = ([Char[]]$VariableName2.ToLower() | ForEach-Object {$Char = $_; If(Get-Random -Input (0..1)){$Char = $Char.ToString().ToUpper()} $Char}) -Join ''

              
              $SetSyntax  = ([Char[]]'set' | ForEach-Object {$Char = $_; If(Get-Random -Input (0..1)){$Char = $Char.ToString().ToUpper()} $Char}) -Join ''
              $SetSyntax  = $SetSyntax + ' '*(Get-Random -Minimum 2 -Maximum 4) + $VariableName + '='
              $SetSyntax2 = ([Char[]]'set' | ForEach-Object {$Char = $_; If(Get-Random -Input (0..1)){$Char = $Char.ToString().ToUpper()} $Char}) -Join ''
              $SetSyntax2 = $SetSyntax2 + ' '*(Get-Random -Minimum 2 -Maximum 4) + $VariableName2 + '='

              
              $SetSyntax     = ([Char[]]$SetSyntax.ToLower()     | ForEach-Object {$Char = $_; If(Get-Random -Input (0..1)){$Char = $Char.ToString().ToUpper()} $Char}) -Join ''
              $SetSyntax2    = ([Char[]]$SetSyntax2.ToLower()    | ForEach-Object {$Char = $_; If(Get-Random -Input (0..1)){$Char = $Char.ToString().ToUpper()} $Char}) -Join ''
              $VariableName  = ([Char[]]$VariableName.ToLower()  | ForEach-Object {$Char = $_; If(Get-Random -Input (0..1)){$Char = $Char.ToString().ToUpper()} $Char}) -Join ''
              $VariableName2 = ([Char[]]$VariableName2.ToLower() | ForEach-Object {$Char = $_; If(Get-Random -Input (0..1)){$Char = $Char.ToString().ToUpper()} $Char}) -Join ''
    
              
              $InvokeOption = Out-RandomInvokeRandomEnvironmentVariableSyntax $VariableName

              
              ForEach($Char in @('<','>','|','&'))
              {
                  If($InvokeOption.Contains("^$Char"))
                  {
                      $InvokeOption = $InvokeOption.Replace("^$Char","^^^$Char")
                  }
              }

              
              $PSCmdSyntax = $PowerShellFlags + ' '*(Get-Random -Minimum 1 -Maximum 3) + $InvokeOption
              $CmdSyntax2  = $SlashC + ' '*(Get-Random -Minimum 0 -Maximum 2) + "%$VariableName2%"
              $CmdSyntax   = $SlashC + ' '*(Get-Random -Minimum 0 -Maximum 4) + '"' + $SetSyntax + $ScriptString + '&&' + $SetSyntax2 + $PathToPowerShell + $PSCmdSyntax + '&&' + ' '*(Get-Random -Minimum 0 -Maximum 4) + $PathToCmd + $CmdSyntax2 + '"'
    
              
              $ArgsDefenderWillSee += , @($PathToCmd       , $CmdSyntax)
              $ArgsDefenderWillSee += , @($PathToCmd       , $CmdSyntax2)
              $ArgsDefenderWillSee += , @($PathToPowerShell, $PSCmdSyntax.Replace('^',''))

              $CmdLineOutput = $PathToCmd + $CmdSyntax
          }
        9 {
              
              
              
              
              
              If($ScriptString.Contains('\"')) {$ScriptString = $ScriptString.Replace('\"','"')}
              
              
              
              $CharsForVarName = @('a','b','c','d','e','f','g','h','i','j','k','l','m','n','o','p','q','r','s','t','u','v','w','x','y','z')
              $VariableName  = (Get-Random -Input $CharsForVarName -Count ($CharsForVarName.Count/(Get-Random -Input @(5..10)))) -Join ''
              $VariableName  = ([Char[]]$VariableName.ToLower() | ForEach-Object {$Char = $_; If(Get-Random -Input (0..1)){$Char = $Char.ToString().ToUpper()} $Char}) -Join ''
              $VariableName2 = (Get-Random -Input $CharsForVarName -Count ($CharsForVarName.Count/(Get-Random -Input @(5..10)))) -Join ''
              $VariableName2 = ([Char[]]$VariableName2.ToLower() | ForEach-Object {$Char = $_; If(Get-Random -Input (0..1)){$Char = $Char.ToString().ToUpper()} $Char}) -Join ''

              
              $SetSyntax  = ([Char[]]'set' | ForEach-Object {$Char = $_; If(Get-Random -Input (0..1)){$Char = $Char.ToString().ToUpper()} $Char}) -Join ''
              $SetSyntax  = $SetSyntax + ' '*(Get-Random -Minimum 2 -Maximum 4) + $VariableName + '='
              $SetSyntax2 = ([Char[]]'set' | ForEach-Object {$Char = $_; If(Get-Random -Input (0..1)){$Char = $Char.ToString().ToUpper()} $Char}) -Join ''
              $SetSyntax2 = $SetSyntax2 + ' '*(Get-Random -Minimum 2 -Maximum 4) + $VariableName2 + '='

              
              $ExecContextVariable  = @()
              $ExecContextVariable += '(' + (Get-Random -Input @('DIR','Get-ChildItem','GCI','ChildItem','LS','Get-Item','GI','Item')) + ' ' + 'variable:' + (Get-Random -Input @('Ex*xt','E*t','*xec*t','*ecu*t','*cut*t','*cuti*t','*uti*t','E*ext','E*xt','E*Cont*','E*onte*','E*tex*','ExecutionContext')) + ').Value'
              
              $ExecContextVariable = Get-Random -Input $ExecContextVariable

              
              $GetRandomVariableSyntax  = @()
              $GetRandomVariableSyntax += '(' + (Get-Random -Input @('DIR','Get-ChildItem','GCI','ChildItem','LS','Get-Item','GI','Item')) + ' ' + 'env:' + $VariableName + ').Value'
              $GetRandomVariableSyntax += ('(' + '[Environment]::GetEnvironmentVariable(' + "'$VariableName'" + ',' + "'Process'" + ')' + ')')
              
              $GetRandomVariableSyntax = Get-Random -Input $GetRandomVariableSyntax

              
              $InvokeOptions  = @()
              $InvokeOptions += (Get-Random -Input ('IEX','Invoke-Expression')) + ' '*(Get-Random -Minimum 1 -Maximum 3) + $GetRandomVariableSyntax
              $InvokeOptions += (Get-Random -Input @('$ExecutionContext','${ExecutionContext}',$ExecContextVariable)) + '.InvokeCommand.InvokeScript(' + ' '*(Get-Random -Minimum 0 -Maximum 3) + $GetRandomVariableSyntax + ' '*(Get-Random -Minimum 0 -Maximum 3) + ')'
              
              $InvokeOption = Get-Random -Input $InvokeOptions

              
              $SetSyntax            = ([Char[]]$SetSyntax.ToLower()            | ForEach-Object {$Char = $_; If(Get-Random -Input (0..1)){$Char = $Char.ToString().ToUpper()} $Char}) -Join ''
              $SetSyntax2           = ([Char[]]$SetSyntax2.ToLower()           | ForEach-Object {$Char = $_; If(Get-Random -Input (0..1)){$Char = $Char.ToString().ToUpper()} $Char}) -Join ''
              $VariableName         = ([Char[]]$VariableName.ToLower()         | ForEach-Object {$Char = $_; If(Get-Random -Input (0..1)){$Char = $Char.ToString().ToUpper()} $Char}) -Join ''
              $VariableName2        = ([Char[]]$VariableName2.ToLower()        | ForEach-Object {$Char = $_; If(Get-Random -Input (0..1)){$Char = $Char.ToString().ToUpper()} $Char}) -Join ''
              $InvokeOption         = ([Char[]]$InvokeOption.ToLower()         | ForEach-Object {$Char = $_; If(Get-Random -Input (0..1)){$Char = $Char.ToString().ToUpper()} $Char}) -Join ''
              $ExecContextVariable  = ([Char[]]$ExecContextVariable.ToLower()  | ForEach-Object {$Char = $_; If(Get-Random -Input (0..1)){$Char = $Char.ToString().ToUpper()} $Char}) -Join ''
              $GetRandomVariableSyntax = ([Char[]]$GetRandomVariableSyntax.ToLower() | ForEach-Object {$Char = $_; If(Get-Random -Input (0..1)){$Char = $Char.ToString().ToUpper()} $Char}) -Join ''

              
              $InvokeVariableSyntax = Out-RandomInvokeRandomEnvironmentVariableSyntax $VariableName

              
              $PowerShellStdin = Out-RandomPowerShellStdInInvokeSyntax
              
              
              ForEach($Char in $CharsToEscape)
              {
                  If($ScriptString.Contains("^^^$Char")) {$ScriptString = $ScriptString.Replace("^^^$Char","^$Char")}
    
                  If($PowerShellStdin.Contains("^$Char")) {$PowerShellStdin = $PowerShellStdin.Replace("^$Char","^^^$Char")}
              }
              If($ScriptString.Contains('^^^^'))
              {
                  $ScriptString = $ScriptString.Replace('^^^^','^^')
              }

              
              $PSCmdSyntax = $PowerShellFlags + ' '*(Get-Random -Minimum 1 -Maximum 3) + $PowerShellStdin + ' '*(Get-Random -Minimum 0 -Maximum 3)
              $CmdSyntax2  = $SlashC + ' '*(Get-Random -Minimum 0 -Maximum 2) + "%$VariableName2%"
              $CmdSyntax   = $SlashC + ' '*(Get-Random -Minimum 0 -Maximum 4) + '"' + $SetSyntax + ' '*(Get-Random -Minimum 0 -Maximum 3)+ $ScriptString + ' '*(Get-Random -Minimum 0 -Maximum 3) + '&&' + ' '*(Get-Random -Minimum 0 -Maximum 3) + $SetSyntax2 + $Echo + ' '*(Get-Random -Minimum 1 -Maximum 3) + $InvokeOption + ' '*(Get-Random -Minimum 0 -Maximum 3) + '^|' + ' '*(Get-Random -Minimum 0 -Maximum 3) + $PathToPowerShell + $PSCmdSyntax + '&&' + ' '*(Get-Random -Minimum 0 -Maximum 3) + $PathToCmd + $CmdSyntax2 + '"'
    
              
              $ArgsDefenderWillSee += , @($PathToCmd       , $CmdSyntax)
              $ArgsDefenderWillSee += , @($PathToCmd       , $CmdSyntax2)
              $ArgsDefenderWillSee += , @($PathToPowerShell, $PSCmdSyntax.Replace('^',''))

              $CmdLineOutput = $PathToCmd + $CmdSyntax
          }
        10 {
              
              
              

              
              If($ScriptString.Contains('\"')) {$ScriptString = $ScriptString.Replace('\"','"')}
             
              
              $PowerShellClip = Out-RandomClipboardInvokeSyntax

              
              ForEach($Char in @('<','>','|','&'))
              {
                  
                  If($PowerShellClip.Contains("^$Char")) 
                  {
                      $PowerShellClip = $PowerShellClip.Replace("^$Char","^^^$Char")
                  }
              }

              
              
              
              
              
              $CommandFlagValue = $NULL
              If($PSBoundParameters['Command'] -OR $Command)
              {
                  $UpperLimit = $PowerShellFlagsArray.Count-1
                  $CommandFlagValue = $PowerShellFlagsArray[$PowerShellFlagsArray.Count-1]
              }
              Else
              {
                  $UpperLimit = $PowerShellFlagsArray.Count
              }

              
              $PowerShellFlags = @()
              For($i=0; $i -lt $UpperLimit; $i++)
              {
                  $PowerShellFlags += $PowerShellFlagsArray[$i]
              }

              
              $PowerShellFlags += (Get-Random -Input @('-st','-sta'))
              
              
              
              If($PowerShellFlags.Count -gt 1)
              {
                  $PowerShellFlags = Get-Random -InputObject $PowerShellFlags -Count $PowerShellFlags.Count
              }

              
              If($CommandFlagValue)
              {
                  $PowerShellFlags += $CommandFlagValue
              }

              
              For($i=0; $i -lt $PowerShellFlags.Count; $i++)
              {
                  $PowerShellFlags[$i] = ([Char[]]$PowerShellFlags[$i] | ForEach-Object {$Char = $_.ToString().ToLower(); If(Get-Random -Input @(0..1)) {$Char = $Char.ToUpper()} $Char}) -Join ''
              }

              
              $PowerShellFlags = ($PowerShellFlags | ForEach-Object {$_ + ' '*(Get-Random -Minimum 1 -Maximum 3)}) -Join ''
              $PowerShellFlags = ' '*(Get-Random -Minimum 1 -Maximum 3) + $PowerShellFlags + ' '*(Get-Random -Minimum 1 -Maximum 3)

              
              $PSCmdSyntax = $PowerShellFlags + $PowerShellClip
              $CmdSyntax2  = $SlashC + ' '*(Get-Random -Minimum 0 -Maximum 4) + $PathToPowerShell + $PsCmdSyntax
              $CmdSyntax   = $SlashC + ' '*(Get-Random -Minimum 0 -Maximum 4) + '"'  + ' '*(Get-Random -Minimum 0 -Maximum 3) + $Echo + (Get-Random -Input ('/','\',' '*(Get-Random -Minimum 1 -Maximum 3))) + $ScriptString + ' '*(Get-Random -Minimum 0 -Maximum 2) + '|' + ' '*(Get-Random -Minimum 0 -Maximum 2) + $PathToClip + ' '*(Get-Random -Minimum 0 -Maximum 2) + '&&' + $PathToCmd + $CmdSyntax2 + '"'
    
              
              $ArgsDefenderWillSee += , @($PathToCmd       , $CmdSyntax)
              $ArgsDefenderWillSee += , @($PathToCmd       , $CmdSyntax2)
              $ArgsDefenderWillSee += , @($PathToPowerShell, $PSCmdSyntax.Replace('^',''))

              $CmdLineOutput = $PathToCmd + $CmdSyntax
          }
        11 {
              
              
              

              

              
              ForEach($Char in $CharsToEscape)
              {
                  If($ScriptString.Contains("^^^$Char")) {$ScriptString = $ScriptString.Replace("^^^$Char","^$Char")}
              }
              If($ScriptString.Contains('^^^^'))
              {
                  $ScriptString = $ScriptString.Replace('^^^^','^^')
              }

              
              If($ScriptString.Contains('\"')) {$ScriptString = $ScriptString.Replace('\"','"')}
              
              
              
              $CharsForVarName = @('a','b','c','d','e','f','g','h','i','j','k','l','m','n','o','p','q','r','s','t','u','v','w','x','y','z')
              $VariableName  = (Get-Random -Input $CharsForVarName -Count ($CharsForVarName.Count/(Get-Random -Input @(5..10)))) -Join ''
              $VariableName  = ([Char[]]$VariableName.ToLower() | ForEach-Object {$Char = $_; If(Get-Random -Input (0..1)){$Char = $Char.ToString().ToUpper()} $Char}) -Join ''
              
              
              $SetSyntax  = ([Char[]]'set' | ForEach-Object {$Char = $_; If(Get-Random -Input (0..1)){$Char = $Char.ToString().ToUpper()} $Char}) -Join ''
              $SetSyntax  = $SetSyntax + ' '*(Get-Random -Minimum 2 -Maximum 4) + $VariableName + '='
              
              
              $SetSyntax     = ([Char[]]$SetSyntax.ToLower()     | ForEach-Object {$Char = $_; If(Get-Random -Input (0..1)){$Char = $Char.ToString().ToUpper()} $Char}) -Join ''
              $VariableName  = ([Char[]]$VariableName.ToLower()  | ForEach-Object {$Char = $_; If(Get-Random -Input (0..1)){$Char = $Char.ToString().ToUpper()} $Char}) -Join ''
              
              
              $InvokeOption = (Out-RandomInvokeRandomEnvironmentVariableSyntax $VariableName).Replace('\"',"'").Replace('`','')

              
              $Shell32Dll = ([Char[]]'SHELL32.DLL' | ForEach-Object {$Char = $_; If(Get-Random -Input (0..1)){$Char = $Char.ToString().ToUpper()} $Char}) -Join ''

              
              $ExecutionFlagsRunDllSyntax = ($PowerShellFlagsArray | Where-Object {$_.Trim().Length -gt 0} | ForEach-Object {'"' + ' '*(Get-Random -Minimum 0 -Maximum 3) + $_ + ' '*(Get-Random -Minimum 0 -Maximum 3) + '"' + ' '*(Get-Random -Minimum 1 -Maximum 4)}) -Join ''
 
              
              $PSCmdSyntax     = ' '*(Get-Random -Minimum 1 -Maximum 4) + $ExecutionFlagsRunDllSyntax + ' '*(Get-Random -Minimum 1 -Maximum 4) + "`"$InvokeOption`""
              $RundllCmdSyntax = ' '*(Get-Random -Minimum 1 -Maximum 4) + $Shell32Dll + (Get-Random -Input @(',',' ', ((Get-Random -Input @(',',',',',',' ',' ',' ') -Count (Get-Random -Input @(4..6)))-Join''))) + 'ShellExec_RunDLL' + ' '*(Get-Random -Minimum 1 -Maximum 4) + "`"$PathToPowerShell`"" + $PSCmdSyntax
              $CmdSyntax       = $SlashC + ' '*(Get-Random -Minimum 0 -Maximum 4) + '"' + $SetSyntax + $ScriptString + '&&' + $PathToRunDll + $RundllCmdSyntax
    
              
              $ArgsDefenderWillSee += , @($PathToCmd             , $CmdSyntax)
              $ArgsDefenderWillSee += , @($PathToRunDll          , $RundllCmdSyntax)
              $ArgsDefenderWillSee += , @("`"$PathToPowerShell`"", $PSCmdSyntax.Replace('^',''))

              $CmdLineOutput = $PathToCmd + $CmdSyntax
        }
        12 {
              
              
              

              
              ForEach($Char in $CharsToEscape)
              {
                  If($ScriptString.Contains("^^^$Char")) {$ScriptString = $ScriptString.Replace("^^^$Char","^$Char")}
              }
              If($ScriptString.Contains('^^^^'))
              {
                  $ScriptString = $ScriptString.Replace('^^^^','^^')
              }

              
              If($ScriptString.Contains('\"')) {$ScriptString = $ScriptString.Replace('\"','"')}
              
              
              
              $CharsForVarName = @('a','b','c','d','e','f','g','h','i','j','k','l','m','n','o','p','q','r','s','t','u','v','w','x','y','z')
              $VariableName  = (Get-Random -Input $CharsForVarName -Count ($CharsForVarName.Count/(Get-Random -Input @(5..10)))) -Join ''
              $VariableName  = ([Char[]]$VariableName.ToLower() | ForEach-Object {$Char = $_; If(Get-Random -Input (0..1)){$Char = $Char.ToString().ToUpper()} $Char}) -Join ''
              
              
              $SetSyntax  = ([Char[]]'set' | ForEach-Object {$Char = $_; If(Get-Random -Input (0..1)){$Char = $Char.ToString().ToUpper()} $Char}) -Join ''
              $SetSyntax  = $SetSyntax + ' '*(Get-Random -Minimum 2 -Maximum 4) + $VariableName + '='
              
              
              $SetSyntax     = ([Char[]]$SetSyntax.ToLower()     | ForEach-Object {$Char = $_; If(Get-Random -Input (0..1)){$Char = $Char.ToString().ToUpper()} $Char}) -Join ''
              $VariableName  = ([Char[]]$VariableName.ToLower()  | ForEach-Object {$Char = $_; If(Get-Random -Input (0..1)){$Char = $Char.ToString().ToUpper()} $Char}) -Join ''
              
              
              
              $InvokeOption = (Out-RandomInvokeRandomEnvironmentVariableSyntax $VariableName).Replace('\"',"'").Replace('`','')
              While($InvokeOption.Length -gt 200)
              {
                  $InvokeOption = (Out-RandomInvokeRandomEnvironmentVariableSyntax $VariableName).Replace('\"',"'").Replace('`','')
              }

              
              $CreateObject = ([Char[]]'VBScript:CreateObject' | ForEach-Object {$Char = $_; If(Get-Random -Input (0..1)){$Char = $Char.ToString().ToUpper()} $Char}) -Join ''
              $WScriptShell = ([Char[]]'WScript.Shell'         | ForEach-Object {$Char = $_; If(Get-Random -Input (0..1)){$Char = $Char.ToString().ToUpper()} $Char}) -Join ''
              $Run          = ([Char[]]'.Run'                  | ForEach-Object {$Char = $_; If(Get-Random -Input (0..1)){$Char = $Char.ToString().ToUpper()} $Char}) -Join ''
              $TrueString   = ([Char[]]'True'                  | ForEach-Object {$Char = $_; If(Get-Random -Input (0..1)){$Char = $Char.ToString().ToUpper()} $Char}) -Join ''
              $WindowClose  = ([Char[]]'Window.Close'          | ForEach-Object {$Char = $_; If(Get-Random -Input (0..1)){$Char = $Char.ToString().ToUpper()} $Char}) -Join ''
            
              
              If((Get-Random -Input @(0..1)) -eq 0)
              {
                  $WScriptShell = Out-ConcatenatedString $WScriptShell '"'
              }
              Else
              {
                  $WScriptShell = '"' + $WScriptShell + '"'
              }

              
              If((Get-Random -Input @(0..1)) -eq 0)
              {
                  
                  $SubStringArray += (Out-ConcatenatedString $InvokeOption.Trim('"') '"').Replace('`"','"')

                  
                  If($InvokeOption.Contains('^"+"'))
                  {
                      $InvokeOption = $InvokeOption.Replace('^"+"','^')
                  }
              }

              
              If((Get-Random -Input @(0..1)) -eq 0)
              {
                  $One = 1
              }
              Else
              {
                  
                  $RandomNumber = Get-Random -Minimum 3 -Maximum 25
                  If(Get-Random -Input @(0..1))
                  {
                      $One = [String]$RandomNumber + '-' + ($RandomNumber-1)
                  }
                  Else
                  {
                      $SecondRandomNumber = Get-Random -Minimum 1 -Maximum $RandomNumber
                      $One = [String]$RandomNumber + '-' + $SecondRandomNumber + '-' + ($RandomNumber-$SecondRandomNumber-1)
                  }

                  
                  If((Get-Random -Input @(0..1)) -eq 0)
                  {
                      $One = '(' + $One + ')'
                  }
              }

              
              $PSCmdSyntax    = $PowerShellFlags + ' '*(Get-Random -Minimum 0 -Maximum 3) + $InvokeOption + '",' + $One + ',' + $TrueString + ")($WindowClose)"
              $MshtaCmdSyntax = ' '*(Get-Random -Minimum 1 -Maximum 4) + $CreateObject + "($WScriptShell)" + $Run + '("' + $PathToPowerShell + $PSCmdSyntax + '"'
              $CmdSyntax      = $SlashC + ' '*(Get-Random -Minimum 0 -Maximum 4) + '"' + $SetSyntax + $ScriptString + '&&' + $PathToMshta + $MshtaCmdSyntax
    
              
              $ArgsDefenderWillSee += , @($PathToCmd       , $CmdSyntax)
              $ArgsDefenderWillSee += , @($PathToMshta     , $MshtaCmdSyntax)
              $ArgsDefenderWillSee += , @($PathToPowerShell, $PSCmdSyntax.Replace('^',''))

              $CmdLineOutput = $PathToCmd + $CmdSyntax
          }
        default {Write-Error "An invalid `$LaunchType value ($LaunchType) was passed to switch block for Out-PowerShellLauncher."; Exit;}
    }

    
    If($ArgsDefenderWillSee.Count -gt 0)
    {
        Write-Host "`n`nProcess Argument Tree of ObfuscatedCommand with current launcher:"
    
        $Counter = -1
        ForEach($Line in $ArgsDefenderWillSee)
        {
            If($Line.Count -gt 1)
            {
                $Part1 = $Line[0]
                $Part2 = $Line[1]
            }
            Else
            {
                $Part1 = $Line
                $Part2 = ''
            }

            $LineSpacing = ''
            If($Counter -ge 0)
            {
                $LineSpacing = '     '*$Counter
                Write-Host "$LineSpacing|`n$LineSpacing\--> " -NoNewline
            }

            
            Write-Host $Part1 -NoNewLine -ForegroundColor Yellow

            
            $CmdMaxLength = 8190

            If($Part2.Length -gt $CmdMaxLength)
            {
                
                $RedactedPrintLength = $CmdMaxLength/5
        
                
                $CmdLineWidth = (Get-Host).UI.RawUI.BufferSize.Width
                $RedactionMessage = "<REDACTED: ArgumentLength = $($Part1.Length + $Part2.Length)>"
                $CenteredRedactionMessageStartIndex = (($CmdLineWidth-$RedactionMessage.Length)/2) - ($Part1.Length+$LineSpacing.Length)
                $CurrentRedactionMessageStartIndex = ($RedactedPrintLength % $CmdLineWidth)
        
                If($CurrentRedactionMessageStartIndex -gt $CenteredRedactionMessageStartIndex)
                {
                    $RedactedPrintLength = $RedactedPrintLength-($CurrentRedactionMessageStartIndex-$CenteredRedactionMessageStartIndex)
                }
                Else
                {
                    $RedactedPrintLength = $RedactedPrintLength+($CenteredRedactionMessageStartIndex-$CurrentRedactionMessageStartIndex)
                }
    
                Write-Host $Part2.SubString(0,$RedactedPrintLength) -NoNewLine -ForegroundColor Cyan
                Write-Host $RedactionMessage -NoNewLine -ForegroundColor Magenta
                Write-Host $Part2.SubString($Part2.Length-$RedactedPrintLength) -ForegroundColor Cyan
            }
            Else
            {
                Write-Host $Part2 -ForegroundColor Cyan
            }

            $Counter++
        }
        Start-Sleep 1
    }

    
    
    $CmdMaxLength = 8190
    If(($CmdLineOutput.Length -gt $CmdMaxLength) -AND ($LaunchType -lt 13))
    {
        Write-Host ""
        Write-Warning "This command exceeds the cmd.exe maximum allowed length of $CmdMaxLength characters! Its length is $($CmdLineOutput.Length) characters."
        Start-Sleep 1
    }

    Return $CmdLineOutput
}


Function Out-RandomInvokeRandomEnvironmentVariableSyntax
{


    [CmdletBinding()] Param (
        [Parameter(Position = 0)]
        [ValidateNotNullOrEmpty()]
        [String[]]
        $EnvVarName
    )

    
    $EnvVarName = Get-Random -Input $EnvVarName

    
    $ExecContextVariables  = @()
    $ExecContextVariables += '(' + (Get-Random -Input @('DIR','Get-ChildItem','GCI','ChildItem','LS','Get-Item','GI','Item')) + ' ' + "'variable:" + (Get-Random -Input @('ex*xt','ExecutionContext')) + "').Value"
    $ExecContextVariables += '(' + (Get-Random -Input @('Get-Variable','GV','Variable')) + ' ' + "'" + (Get-Random -Input @('ex*xt','ExecutionContext')) + "'" + (Get-Random -Input (').Value',(' ' + ('-ValueOnly'.SubString(0,(Get-Random -Minimum 3 -Maximum ('-ValueOnly'.Length+1)))) + ')')))

    
    $ExecContextVariable = Get-Random -Input $ExecContextVariables

    
    $GetRandomVariableSyntax  = @()
    $GetRandomVariableSyntax += '(' + (Get-Random -Input @('DIR','Get-ChildItem','GCI','ChildItem','LS','Get-Item','GI','Item')) + ' ' + 'env:' + $EnvVarName + ').Value'
    $GetRandomVariableSyntax += ('(' + '[Environment]::GetEnvironmentVariable(' + "'$EnvVarName'" + ',' + "'Process'" + ')' + ')')
    
    
    $GetRandomVariableSyntax = Get-Random -Input $GetRandomVariableSyntax

    
    
    $ExpressionToInvoke = $GetRandomVariableSyntax
    If(Get-Random -Input @(0..1))
    {
        
        $InvokeOption = Out-EncapsulatedInvokeExpression $ExpressionToInvoke
    }
    Else
    {
        $InvokeOption = (Get-Random -Input @('$ExecutionContext','${ExecutionContext}',$ExecContextVariable)) + '.InvokeCommand.InvokeScript(' + ' '*(Get-Random -Minimum 0 -Maximum 3) + $ExpressionToInvoke + ' '*(Get-Random -Minimum 0 -Maximum 3) + ')'
    }

    
    $InvokeOption = ([Char[]]$InvokeOption.ToLower() | ForEach-Object {$Char = $_; If(Get-Random -Input (0..1)){$Char = $Char.ToString().ToUpper()} $Char}) -Join ''

    
    If($InvokeOption -ne '-')
    {
        
        $InvokeOption = Out-ObfuscatedTokenCommand -ScriptBlock ([ScriptBlock]::Create($InvokeOption))
        $InvokeOption = Out-ObfuscatedTokenCommand -ScriptBlock ([ScriptBlock]::Create($InvokeOption)) 'RandomWhitespace' 1
    }
    
    
    ForEach($Char in @('<','>','|','&'))
    {
        
        If($InvokeOption.Contains("$Char")) 
        {
            $InvokeOption = $InvokeOption.Replace("$Char","^$Char")
        }
    }
    
    
    If($InvokeOption.Contains('"'))
    {
        $InvokeOption = $InvokeOption.Replace('"','\"')
    }
    
    Return $InvokeOption
}


Function Out-RandomPowerShellStdInInvokeSyntax
{

    
    
    
    
    
    
    $ExecContextVariables  = @()
    $ExecContextVariables += '(' + (Get-Random -Input @('DIR','Get-ChildItem','GCI','ChildItem','LS','Get-Item','GI','Item')) + ' ' + "'variable:" + (Get-Random -Input @('ex*xt','ExecutionContext')) + "').Value"
    $ExecContextVariables += '(' + (Get-Random -Input @('Get-Variable','GV','Variable')) + ' ' + "'" + (Get-Random -Input @('ex*xt','ExecutionContext')) + "'" + (Get-Random -Input (').Value',(' ' + ('-ValueOnly'.SubString(0,(Get-Random -Minimum 3 -Maximum ('-ValueOnly'.Length+1)))) + ')')))
    
    $ExecContextVariable = (Get-Random -Input $ExecContextVariables)

    $RandomInputVariable = (Get-Random -Input @('$Input','${Input}'))

    
    
    $ExpressionToInvoke = $RandomInputVariable
    If(Get-Random -Input @(0..1))
    {
        
        $InvokeOption = Out-EncapsulatedInvokeExpression $ExpressionToInvoke
    }
    Else
    {
        $InvokeOption = (Get-Random -Input @('$ExecutionContext','${ExecutionContext}',$ExecContextVariable)) + '.InvokeCommand.InvokeScript(' + ' '*(Get-Random -Minimum 0 -Maximum 3) + $ExpressionToInvoke + ' '*(Get-Random -Minimum 0 -Maximum 3) + ')'
    }

    
    $InvokeOption = ([Char[]]$InvokeOption.ToLower() | ForEach-Object {$Char = $_; If(Get-Random -Input (0..1)){$Char = $Char.ToString().ToUpper()} $Char}) -Join ''

    
    If($NoExit)
    {
        $InvokeOption = '-'
    }

    
    $PowerShellStdIn = $InvokeOption

    
    $PowerShellStdIn = ([Char[]]$PowerShellStdIn.ToLower() | ForEach-Object {$Char = $_; If(Get-Random -Input (0..1)){$Char = $Char.ToString().ToUpper()} $Char}) -Join ''

    
    If($PowerShellStdIn -ne '-')
    {
        
        $InvokeOption = Out-ObfuscatedTokenCommand -ScriptBlock ([ScriptBlock]::Create($InvokeOption))
        $InvokeOption = Out-ObfuscatedTokenCommand -ScriptBlock ([ScriptBlock]::Create($InvokeOption)) 'RandomWhitespace' 1
    }
    
    
    ForEach($Char in @('<','>','|','&'))
    {
        
        If($PowerShellStdIn.Contains("$Char")) 
        {
            $PowerShellStdIn = $PowerShellStdIn.Replace("$Char","^$Char")
        }
    }
    
    
    If($PowerShellStdIn.Contains('"'))
    {
        $PowerShellStdIn = $PowerShellStdIn.Replace('"','\"')
    }

    Return $PowerShellStdIn
}


Function Out-RandomClipboardInvokeSyntax
{


    
    $ReflectionAssembly    = Get-Random -Input @('System.Reflection.Assembly','Reflection.Assembly')
    $WindowsClipboard      = Get-Random -Input @('Windows.Clipboard','System.Windows.Clipboard')
    $WindowsFormsClipboard = Get-Random -Input @('System.Windows.Forms.Clipboard','Windows.Forms.Clipboard')
    
    
    $FullArgument = "-AssemblyName"
    
    $AssemblyNameFlags = @()
    $AssemblyNameFlags += '-AN'
    For($Index=2; $Index -le $FullArgument.Length; $Index++)
    {
        $AssemblyNameFlags += $FullArgument.SubString(0,$Index)
    }
    $AssemblyNameFlag = Get-Random -Input $AssemblyNameFlags

    
    
    $CharsToRandomVarName  = @(0..9)
    $CharsToRandomVarName += @('A','B','C','D','E','F','G','H','I','J','K','L','M','N','O','P','Q','R','S','T','U','V','W','X','Y','Z')

    
    $RandomVarLength = (Get-Random -Input @(3..6))
   
    
    If($CharsToRandomVarName.Count -lt $RandomVarLength) {$RandomVarLength = $CharsToRandomVarName.Count}
    $RandomVarName = ((Get-Random -Input $CharsToRandomVarName -Count $RandomVarLength) -Join '').Replace(' ','')

    
    $RandomVarName = ((Get-Random -Input $CharsToRandomVarName -Count $RandomVarLength) -Join '').Replace(' ','')

    
    $RandomClipSyntaxValue = Get-Random -Input @(1..3)
    Switch($RandomClipSyntaxValue)
    {
        1 {
            $LoadClipboardClassOption   = "Add-Type $AssemblyNameFlag PresentationCore"
            $GetClipboardContentsOption = "([$WindowsClipboard]::GetText())"
            $ClearClipboardOption       = "[$WindowsClipboard]::" + (Get-Random -Input @('Clear()',"SetText(' ')"))
        }
        2 {
            $LoadClipboardClassOption   = "Add-Type $AssemblyNameFlag System.Windows.Forms"
            $GetClipboardContentsOption = "([$WindowsFormsClipboard]::GetText())"
            $ClearClipboardOption       = "[$WindowsFormsClipboard]::" + (Get-Random -Input @('Clear()',"SetText(' ')"))
        }
        3 {
            $LoadClipboardClassOption   =  (Get-Random -Input @('[Void]','$NULL=',"`$$RandomVarName=")) + "[$ReflectionAssembly]::LoadWithPartialName('System.Windows.Forms')"
            $GetClipboardContentsOption = "([$WindowsFormsClipboard]::GetText())"
            $ClearClipboardOption       = "[$WindowsFormsClipboard]::" + (Get-Random -Input @('Clear()',"SetText(' ')"))
        }
        default {Write-Error "An invalid RandomClipSyntaxValue value ($RandomClipSyntaxValue) was passed to switch block for Out-RandomClipboardInvokeSyntax."; Exit;}
    }
    
    
    $ExecContextVariables  = @()
    $ExecContextVariables += '(' + (Get-Random -Input @('DIR','Get-ChildItem','GCI','ChildItem','LS','Get-Item','GI','Item')) + ' ' + "'variable:" + (Get-Random -Input @('ex*xt','ExecutionContext')) + "').Value"
    $ExecContextVariables += '(' + (Get-Random -Input @('Get-Variable','GV','Variable')) + ' ' + "'" + (Get-Random -Input @('ex*xt','ExecutionContext')) + "'" + (Get-Random -Input (').Value',(' ' + ('-ValueOnly'.SubString(0,(Get-Random -Minimum 3 -Maximum ('-ValueOnly'.Length+1)))) + ')')))
    
    $ExecContextVariable = Get-Random -Input $ExecContextVariables

    
    
    $ExpressionToInvoke = $GetClipboardContentsOption
    If(Get-Random -Input @(0..1))
    {
        
        $InvokeOption = Out-EncapsulatedInvokeExpression $ExpressionToInvoke
    }
    Else
    {
        $InvokeOption = (Get-Random -Input @('$ExecutionContext','${ExecutionContext}',$ExecContextVariable)) + '.InvokeCommand.InvokeScript(' + ' '*(Get-Random -Minimum 0 -Maximum 3) + $ExpressionToInvoke + ' '*(Get-Random -Minimum 0 -Maximum 3) + ')'
    }

    
    $InvokeOption = ([Char[]]$InvokeOption.ToLower() | ForEach-Object {$Char = $_; If(Get-Random -Input (0..1)){$Char = $Char.ToString().ToUpper()} $Char}) -Join ''

    
    $PowerShellClip = $LoadClipboardClassOption + ' '*(Get-Random -Minimum 0 -Maximum 3) + ';' + ' '*(Get-Random -Minimum 0 -Maximum 3) + $InvokeOption
    
    
    $PowerShellClip = $PowerShellClip + ' '*(Get-Random -Minimum 0 -Maximum 3) + ';' + ' '*(Get-Random -Minimum 0 -Maximum 3) + $ClearClipboardOption

    
    $PowerShellClip = Out-ObfuscatedTokenCommand -ScriptBlock ([ScriptBlock]::Create($PowerShellClip)) 'Member'
    $PowerShellClip = Out-ObfuscatedTokenCommand -ScriptBlock ([ScriptBlock]::Create($PowerShellClip)) 'Member'
    $PowerShellClip = Out-ObfuscatedTokenCommand -ScriptBlock ([ScriptBlock]::Create($PowerShellClip)) 'Command'
    $PowerShellClip = Out-ObfuscatedTokenCommand -ScriptBlock ([ScriptBlock]::Create($PowerShellClip)) 'CommandArgument'
    $PowerShellClip = Out-ObfuscatedTokenCommand -ScriptBlock ([ScriptBlock]::Create($PowerShellClip)) 'Variable'
    $PowerShellClip = Out-ObfuscatedTokenCommand -ScriptBlock ([ScriptBlock]::Create($PowerShellClip)) 'String'
    $PowerShellClip = Out-ObfuscatedTokenCommand -ScriptBlock ([ScriptBlock]::Create($PowerShellClip)) 'RandomWhitespace'
    
    
    ForEach($Char in @('<','>','|','&'))
    {
        
        If($PowerShellClip.Contains("$Char")) 
        {
            $PowerShellClip = $PowerShellClip.Replace("$Char","^$Char")
        }
    }
    
    
    If($PowerShellClip.Contains('"'))
    {
        $PowerShellClip = $PowerShellClip.Replace('"','\"')
    }

    Return $PowerShellClip
}