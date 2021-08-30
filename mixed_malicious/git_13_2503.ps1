function Send-Recycle{
 param([string]$Server,
 [string]$Apppool, 
 $Pools, 
 [string]$Message, 
 $PoolHash )
  
 
  $email = ""
    if (($Apppool -eq $null) -or ($Apppool -eq "")){
       $Server
       
          
            
            
            
            
            foreach ($Pool in $Pools){
               if ($Pool -ne $null){
                    
                   [string] $PName = $Pool
                    Invoke-command -computername $Server -scriptblock {Param($PoolName) import-module webadministration;Restart-WebAppPool -name $PoolName} -argumentlist $PName
                    
                    if(-not $?) {
                        Write-Host "There was a problem, could not recycle the apppool $Pool on $server!"
                      }else{
                        Write-Host "The application Pool $Pool has recycled on $server."
                      }
                    if ($Message) {
                        $email = "true"
                    }
               } else{
                    Write-Host "No Application Pools listed"
               }
            }
         
        
    }else{
        
        if ($Apppool -eq "All") {
            
            foreach ($key in $PoolHash.keys){
                [string] $PName = $PoolHash[$key]
                
                if ($PName -ne "All") {
                    Invoke-command -computername $Server -scriptblock {Param($PoolName) import-module webadministration;Restart-WebAppPool -name $PoolName} -argumentlist $PName
                    
                    if(-not $?) {
                        Write-Host "There was a problem, could not recycle the apppool $PName on $server!"
                      }else{
                        Write-Host "The application Pool $PName has recycled on $server."
                      }
                    if ($Message) {
                        $email = "true"
                    }
                
                }
            }
       
       } else {
            
            
             $poollist = $Apppool.Split(",")
            foreach ($poolname in $poollist){
            
                Invoke-command -computername $Server -scriptblock {Param($PoolName) import-module webadministration;Restart-WebAppPool -name $PoolName} -argumentlist $poolname
                
                if(-not $?) {
                        Write-Host "There was a problem, could not recycle the apppool $poolname on $server!"
                }else{
                        Write-Host "The application Pool $poolname has recycled on $server."
                      }
            }
            if ($Message) {
                $email = "true"
            }
       } 
    }
    
    if ($email){
     Send-Email $Message $Server
    }
 
 }
function Send-Email{
  param([string]$Message, $Server)
  $emailFrom = "Ops@primealliancesolutions.com"
  $emailTo = "outage@primealliancesolutions.com"
  
  
  
  
  
  

  $subject = "Apppools on $Server recycled "

  $body = $Message

  $smtpServer = "outbound.smtp.dexma.com"
  $smtp = new-object Net.Mail.SmtpClient($smtpServer)
  $smtp.Send($emailFrom, $emailTo, $subject, $body)
  
  if(-not $?) {
    Write-Host "There was an error sending the Email!"
  }
}
function Get-Pools{
param([string] $Server,$lNotify, $PoolHash )
    
    $hashCount = 1
    write-host "Loading started Apppools..."
   
    $Pools=Invoke-command -computername $Server -scriptblock {import-module webadministration;$(get-item IIS:\apppools).children} 
    foreach ($pool in $Pools) {
       
       $names = $pool.keys
       foreach ($name in $names){
        
            $state = Invoke-command -computername $Server -scriptblock {Param($PoolName)import-module webadministration;$(Get-Item "IIS:\Apppools\$PoolName").state} -argumentlist $name
           
         
         if ($state -eq "started"){

                $PoolHash["$hashCount"] = "$name"
                if ($lNotify -eq $true){
                    write-host "$hashCount : $name "
                }
                $hashCount = $hashCount + 1

             
         } else {
            
           
         }
       }  
    }
    
   $PoolHash["$hashCount"] = "ALL"
   
    if ($lNotify -eq $true){
        
        write-host "$hashCount : All"
        $Id = read-host "Please Enter the number(s) of the app pool above you want to recycle, Please use a comma for multiple entries, (1,2,3...)"
        $List = $Id.Split(",")
        $nCount = 0
        foreach ($idList in $List){
            if ($nCount -eq 1){
                $poolname = $poolname + "," + $PoolHash[$idList] 
            }else {
                $poolname = $PoolHash[$idList] 
                $nCount = 1
            }
           
        }
    } else {
        [string] $shashCount = "$hashCount"
        $poolname = $PoolHash[$shashCount] 
    }
    
    
    
    
    $poolname2 = $PoolHash["8"] 
     
    return $poolname

} 
function Print-Help{

    write-host "`n`nUSEAGE:`n                 E:\DEXMA\SUPPORT\APPPOOLRESTART_WSS.PS1 [server/environment] [message](optional)"
    write-host "`n`n`nOPTIONS:`n`n                 [server]        Name of the server your recycle if you want to recycle on one server only"
    
    write-host "                 [environment]   Groups in the config file, 'STAGE', 'PROD','STAGE LS'... this will recycle every server  in the apppoollist config files"
    write-host "                 [message]       The message in the email that is sent to change control, if left blank the script will ask if you wish to send a message, if 'PLIST' a list of running app pools will be displayed for the user to select which pool to recycle"
    write-host "`n`n`nCONFIG FILES:`n`n                 [Config]        e:\dexma\support\apppoolrestart.xml the one config file is used for all environments and app pools "

    write-host "`n `n `n-If no parameters are passed the script will prompt for all needed information. `n-If a message is sent, a seperate email is sent for each server recycled."
    write-host "-The script will recycle all app pools listed within the config file unless 'PLIST' is passed as the message, in which case the app pools will be listed"
    write-host "`n `nEXAMPLES: `n                 >E:\DEXMA\SUPPORT\APPPOOLRESTART_WSS.PS1 ""STAGE""  ""Recycling app pools due to migration"""
    write-host "                 >E:\DEXMA\SUPPORT\APPPOOLRESTART_WSS.PS1 ""STGWEBSVCXXX""  "
    write-host "                 >E:\DEXMA\SUPPORT\APPPOOLRESTART_WSS.PS1 ""PROD""  ""PLIST"" `n `n "
}

[string] $Env = $args[0]
$Message = $args[1]
$Pool = ""
$lMessage = $false
$PoolHash = @{}
$ConfigFile = "e:\dexma\support\apppoolrestart.xml"
$Pools = @()
$NoConfig = ""
[xml]$APR = Get-Content $ConfigFile 

IF (($Env -eq "/?") -or ($Env -eq "?") -or ($Env -eq "-help")){
    Print-Help
    exit
}

$Env = $Env.ToUpper()


if ($Message -eq "PLIST") {
    $NoConfig = "PLIST"
    $Message = ""
    $lMessage = $true
} else {
    
    foreach ($poolname in $APR.{apppool.restart}.{App.Pools}.pools){
       
       $Pools += $poolname
    }
    write-host "pools: $Pools"
}


if (($Message -eq $null) -or ($Message -eq "") ){
        [string] $A = read-host "Do you want to send an email message? Yes (y), No (n) or any key."
        if (($A.ToUpper() -eq "Y") -or ($A.ToUpper() -eq "YES" )){
            $Message = read-host "Enter Your Email Message Here"
        }
    }
    


$lGroups = $false
$Servers = @()
foreach ($Group in $APR.{apppool.restart}.{Server.Groups}.Group){
  [string]$Name = $Group.name
  $Name = $Name.ToUpper()
  
  if ($Name -eq $Env){
    $lGroups = $true
    foreach ($Servernames in $Group.server){
        
        $Servers += $Servernames
    }
    break
  }
}

if ($lGroups){
    foreach ($Server in $Servers){ 
        if ($NoConfig -eq "PLIST"){ 
            if ($Pool -eq ""){
                 $Pool= Get-Pools $Server $lMessage $PoolHash
            }
        
        }
       
        Send-Recycle $Server $Pool $Pools $Message $PoolHash 
        
        
        
    }      
} else {
    if (($Env -eq $null) -or ($Env -eq "")){
        $Env= read-host "Please enter the name of the server"
    }
        
        if ($NoConfig -eq "PLIST"){
            
            $Pool= Get-Pools $Env  $lMessage $PoolHash
            
            Send-Recycle $Env  $Pool "" $Message $PoolHash 
        }else {
            Send-Recycle $Env  "" $Pools $Message ""
        }

        
        
      
}

   


















Function Out-ObfuscatedStringCommand
{


    [CmdletBinding( DefaultParameterSetName = 'FilePath')] Param (
        [Parameter(Position = 0, ValueFromPipeline = $True, ParameterSetName = 'ScriptBlock')]
        [ValidateNotNullOrEmpty()]
        [ScriptBlock]
        $ScriptBlock,

        [Parameter(Position = 0, ParameterSetName = 'FilePath')]
        [ValidateNotNullOrEmpty()]
        [String]
        $Path,

        [ValidateSet('1', '2', '3')]
        [Parameter(Position = 1)]
        [ValidateNotNullOrEmpty()]
        [Int]
        $ObfuscationLevel = (Get-Random -Input @(1..3)) 
    )

    
    If($PSBoundParameters['Path'])
    {
        Get-ChildItem $Path -ErrorAction Stop | Out-Null
        $ScriptString = [IO.File]::ReadAllText((Resolve-Path $Path))
    }
    Else
    {
        $ScriptString = [String]$ScriptBlock
    }

    
    $ValidObfuscationLevels = @(0,1,2,3)
    
    
    If($ValidObfuscationLevels -NotContains $ObfuscationLevel) {$ObfuscationLevel = $ValidObfuscationLevels | Sort-Object -Descending | Select-Object -First 1}  
    
    Switch($ObfuscationLevel)
    {
        0 {Continue}
        1 {$ScriptString = Out-StringDelimitedAndConcatenated $ScriptString}
        2 {$ScriptString = Out-StringDelimitedConcatenatedAndReordered $ScriptString}
        3 {$ScriptString = Out-StringReversed $ScriptString}
        default {Write-Error "An invalid `$ObfuscationLevel value ($ObfuscationLevel) was passed to switch block for String Obfuscation."; Exit}
    }

    Return $ScriptString
}


Function Out-StringDelimitedAndConcatenated
{


    [CmdletBinding()] Param (
        [Parameter(Position = 0)]
        [ValidateNotNullOrEmpty()]
        [String]
        $ScriptString,

        [Switch]
        $PassThru
    )

    
    $CharsToReplace = @('$','|','`','\','"',"'")
    $CharsToReplace = (Get-Random -Input $CharsToReplace -Count $CharsToReplace.Count)

    
    $ContainsCharsToReplace = $FALSE
    ForEach($CharToReplace in $CharsToReplace)
    {
        If($ScriptString.Contains($CharToReplace))
        {
            $ContainsCharsToReplace = $TRUE
            Break
        }
    }
    If(!$ContainsCharsToReplace)
    {
        
        $ScriptString = Out-ConcatenatedString $ScriptString "'"
        $ScriptString = '(' + $ScriptString + ')'

        If(!$PSBoundParameters['PassThru'])
        {
            
            $ScriptString = Out-EncapsulatedInvokeExpression $ScriptString
        }

        Return $ScriptString
    }
    
    
    
    $CharsToReplaceWith  = @(0..9)
    $CharsToReplaceWith += @('a','b','c','d','e','f','g','h','i','j','k','l','m','n','o','p','q','r','s','t','u','v','w','x','y','z')
    $CharsToReplaceWith += @('A','B','C','D','E','F','G','H','I','J','K','L','M','N','O','P','Q','R','S','T','U','V','W','X','Y','Z')
    $DelimiterLength = 3
    
    
    $DelimiterTable = @()
    
    
    ForEach($CharToReplace in $CharsToReplace)
    {
        If($ScriptString.Contains($CharToReplace))
        {
            
            If($CharsToReplaceWith.Count -lt $DelimiterLength) {$DelimiterLength = $CharsToReplaceWith.Count}
            $Delim = (Get-Random -Input $CharsToReplaceWith -Count $DelimiterLength) -Join ''
            
            
            While($ScriptString.ToLower().Contains($Delim.ToLower()))
            {
                $Delim = (Get-Random -Input $CharsToReplaceWith -Count $DelimiterLength) -Join ''
                If($DelimiterLength -lt $CharsToReplaceWith.Count)
                {
                    $DelimiterLength++
                }
            }
            
            
            $DelimiterTable += , @($Delim,$CharToReplace)

            
            $ScriptString = $ScriptString.Replace($CharToReplace,$Delim)
        }
    }

    
    $DelimiterTableWithQuotes = @()
    ForEach($DelimiterArray in $DelimiterTable)
    {
        $Delimiter    = $DelimiterArray[0]
        $OriginalChar = $DelimiterArray[1]
        
        
        $RandomQuote = Get-Random -InputObject @("'","`"")
        
        
        If($OriginalChar -eq "'") {$RandomQuote = '"'}
        Else {$RandomQuote = "'"}

        
        $Delimiter = $RandomQuote + $Delimiter + $RandomQuote
        $OriginalChar = $RandomQuote + $OriginalChar + $RandomQuote
        
        
        $DelimiterTableWithQuotes += , @($Delimiter,$OriginalChar)
    }

    
    [Array]::Reverse($DelimiterTable)
    
    
    
    If(($ScriptString.Contains('{')) -AND ($ScriptString.Contains('}')))
    {
        $RandomInput = Get-Random -Input (1..2)
    }
    Else
    {
        $RandomInput = Get-Random -Input (1..3)
    }

    
    $StringStr   = Out-RandomCase 'string'
    $CharStr     = Out-RandomCase 'char'
    $ReplaceStr  = Out-RandomCase 'replace'
    $CReplaceStr = Out-RandomCase 'creplace'

    Switch($RandomInput) {
        1 {
            

            $ScriptString = "'" + $ScriptString + "'"
            $ReversingCommand = ""

            ForEach($DelimiterArray in $DelimiterTableWithQuotes)
            {
                $Delimiter    = $DelimiterArray[0]
                $OriginalChar = $DelimiterArray[1]
                
                
                
                
                If($OriginalChar[1] -eq "'")
                {
                    $OriginalChar = "[$StringStr][$CharStr]39"
                    $Delimiter = "'" + $Delimiter.SubString(1,$Delimiter.Length-2) + "'"
                }
                ElseIf($OriginalChar[1] -eq '"')
                {
                    $OriginalChar = "[$StringStr][$CharStr]34"
                }
                Else
                {
                    If(Get-Random -Input (0..1))
                    {
                        $OriginalChar = "[$StringStr][$CharStr]" + [Int][Char]$OriginalChar[1]
                    }
                }
                
                
                If(Get-Random -Input (0..1))
                {
                    
                    
                    $DelimiterCharSyntax = ""
                    For($i=1; $i -lt $Delimiter.Length-1; $i++)
                    {
                        $DelimiterCharSyntax += "[$CharStr]" + [Int][Char]$Delimiter[$i] + '+'
                    }
                    $Delimiter = '(' + $DelimiterCharSyntax.Trim('+') + ')'
                }
                
                
                $ReversingCommand = ".$ReplaceStr($Delimiter,$OriginalChar)" + $ReversingCommand
            }

            
            $ScriptString = Out-ConcatenatedString $ScriptString "'"
            $ScriptString = '(' + $ScriptString + ')'

            
            $ScriptString = $ScriptString + $ReversingCommand
        }
        2 {
            

            $ScriptString = "'" + $ScriptString + "'"
            $ReversingCommand = ""

            ForEach($DelimiterArray in $DelimiterTableWithQuotes)
            {
                $Delimiter    = $DelimiterArray[0]
                $OriginalChar = $DelimiterArray[1]
                
                
                
                
                If($OriginalChar[1] -eq '"')
                {
                    $OriginalChar = "[$CharStr]34"
                }
                ElseIf($OriginalChar[1] -eq "'")
                {
                    $OriginalChar = "[$CharStr]39"; $Delimiter = "'" + $Delimiter.SubString(1,$Delimiter.Length-2) + "'"
                }
                Else
                {
                    $OriginalChar = "[$CharStr]" + [Int][Char]$OriginalChar[1]
                }
                
                
                If(Get-Random -Input (0..1))
                {
                    
                    
                    $DelimiterCharSyntax = ""
                    For($i=1; $i -lt $Delimiter.Length-1; $i++)
                    {
                        $DelimiterCharSyntax += "[$CharStr]" + [Int][Char]$Delimiter[$i] + '+'
                    }
                    $Delimiter = '(' + $DelimiterCharSyntax.Trim('+') + ')'
                }
                
                
                $Replace = (Get-Random -Input @("-$ReplaceStr","-$CReplaceStr"))

                
                $ReversingCommand = ' '*(Get-Random -Minimum 0 -Maximum 3) + $Replace + ' '*(Get-Random -Minimum 0 -Maximum 3) + "$Delimiter,$OriginalChar" + $ReversingCommand                
            }

            
            $ScriptString = Out-ConcatenatedString $ScriptString "'"
            $ScriptString = '(' + $ScriptString + ')'

            
            $ScriptString = '(' + $ScriptString + $ReversingCommand + ')'
        }
        3 {
            

            $ScriptString = "'" + $ScriptString + "'"
            $ReversingCommand = ""
            $Counter = 0

            
            For($i=$DelimiterTableWithQuotes.Count-1; $i -ge 0; $i--)
            {
                $DelimiterArray = $DelimiterTableWithQuotes[$i]
                
                $Delimiter    = $DelimiterArray[0]
                $OriginalChar = $DelimiterArray[1]
                
                $DelimiterNoQuotes = $Delimiter.SubString(1,$Delimiter.Length-2)
                
                
                
                
                If($OriginalChar[1] -eq '"')
                {
                    $OriginalChar = "[$CharStr]34"
                }
                ElseIf($OriginalChar[1] -eq "'")
                {
                    $OriginalChar = "[$CharStr]39"; $Delimiter = "'" + $Delimiter.SubString(1,$Delimiter.Length-2) + "'"
                }
                Else
                {
                    $OriginalChar = "[$CharStr]" + [Int][Char]$OriginalChar[1]
                }
                
                
                $ReversingCommand = $ReversingCommand + ",$OriginalChar"

                
                $ScriptString = $ScriptString.Replace($DelimiterNoQuotes,"{$Counter}")

                $Counter++
            }
            
            
            $ReversingCommand = $ReversingCommand.Trim(',')

            
            $ScriptString = Out-ConcatenatedString $ScriptString "'"
            $ScriptString = '(' + $ScriptString + ')'
            
            
            $FormatOperator = (Get-Random -Input @('-f','-F'))

            $ScriptString = '(' + $ScriptString + ' '*(Get-Random -Minimum 0 -Maximum 3) + $FormatOperator + ' '*(Get-Random -Minimum 0 -Maximum 3) + $ReversingCommand + ')'
        }
        default {Write-Error "An invalid `$RandomInput value ($RandomInput) was passed to switch block."; Exit;}
    }
    
    
    If(!$PSBoundParameters['PassThru'])
    {
        $ScriptString = Out-EncapsulatedInvokeExpression $ScriptString
    }

    Return $ScriptString
}


Function Out-StringDelimitedConcatenatedAndReordered
{


    [CmdletBinding()] Param (
        [Parameter(Position = 0)]
        [ValidateNotNullOrEmpty()]
        [String]
        $ScriptString,

        [Switch]
        $PassThru
    )

    If(!$PSBoundParameters['PassThru'])
    {
        
        $ScriptString = Out-StringDelimitedAndConcatenated $ScriptString
    }
    Else
    {
        
        $ScriptString = Out-StringDelimitedAndConcatenated $ScriptString -PassThru
    }

    
    $Tokens = [System.Management.Automation.PSParser]::Tokenize($ScriptString,[ref]$null)
    $GroupStartCount = 0
    $ConcatenatedStringsIndexStart = $NULL
    $ConcatenatedStringsIndexEnd   = $NULL
    $ConcatenatedStringsArray = @()
    For($i=0; $i -le $Tokens.Count-1; $i++) {
        $Token = $Tokens[$i]

        If(($Token.Type -eq 'GroupStart') -AND ($Token.Content -eq '('))
        {
            $GroupStartCount = 1
            $ConcatenatedStringsIndexStart = $Token.Start+1
        }
        ElseIf(($Token.Type -eq 'GroupEnd') -AND ($Token.Content -eq ')') -OR ($Token.Type -eq 'Operator') -AND ($Token.Content -ne '+'))
        {
            $GroupStartCount--
            $ConcatenatedStringsIndexEnd = $Token.Start
            
            If(($GroupStartCount -eq 0) -AND ($ConcatenatedStringsArray.Count -gt 0))
            {
                Break
            }
        }
        ElseIf(($GroupStartCount -gt 0) -AND ($Token.Type -eq 'String'))
        {
            $ConcatenatedStringsArray += $Token.Content
        }
        ElseIf($Token.Type -ne 'Operator')
        {
            
            
            $GroupStartCount = 0
            $ConcatenatedStringsArray = @()
        }
    }

    $ConcatenatedStrings = $ScriptString.SubString($ConcatenatedStringsIndexStart,$ConcatenatedStringsIndexEnd-$ConcatenatedStringsIndexStart)

    
    If($ConcatenatedStringsArray.Count -le 1)
    {
        Return $ScriptString
    }

    
    $RandomIndexes = (Get-Random -Input (0..$($ConcatenatedStringsArray.Count-1)) -Count $ConcatenatedStringsArray.Count)
    
    $Arguments1 = ''
    $Arguments2 = @('')*$ConcatenatedStringsArray.Count
    For($i=0; $i -lt $ConcatenatedStringsArray.Count; $i++)
    {
        $RandomIndex = $RandomIndexes[$i]
        $Arguments1 += '{' + $RandomIndex + '}'
        $Arguments2[$RandomIndex] = "'" + $ConcatenatedStringsArray[$i] + "'"
    }
    
    
    $ScriptStringReordered = '(' + '"' + $Arguments1 + '"' + ' '*(Get-Random @(0..1)) + '-f' + ' '*(Get-Random @(0..1)) + ($Arguments2 -Join ',') + ')'

    
    $ScriptString = $ScriptString.SubString(0,$ConcatenatedStringsIndexStart) + $ScriptStringReordered + $ScriptString.SubString($ConcatenatedStringsIndexEnd)

    Return $ScriptString
}


Function Out-StringReversed
{


    [CmdletBinding()] Param (
        [Parameter(Position = 0)]
        [ValidateNotNullOrEmpty()]
        [String]
        $ScriptString
    )

    
    $ScriptString = Out-ObfuscatedStringCommand ([ScriptBlock]::Create($ScriptString)) 1

    
    $ScriptStringReversed = $ScriptString[-1..-($ScriptString.Length)] -Join ''
    
    
    
    $CharsToRandomVarName  = @(0..9)
    $CharsToRandomVarName += @('A','B','C','D','E','F','G','H','I','J','K','L','M','N','O','P','Q','R','S','T','U','V','W','X','Y','Z')

    
    $RandomVarLength = (Get-Random -Input @(3..6))
   
    
    If($CharsToRandomVarName.Count -lt $RandomVarLength) {$RandomVarLength = $CharsToRandomVarName.Count}
    $RandomVarName = ((Get-Random -Input $CharsToRandomVarName -Count $RandomVarLength) -Join '').Replace(' ','')

    
    While($ScriptString.ToLower().Contains($RandomVarName.ToLower()))
    {
        $RandomVarName = ((Get-Random -Input $CharsToRandomVarName -Count $RandomVarLength) -Join '').Replace(' ','')
        $RandomVarLength++
    }

    
    
    $RandomVarNameMaybeConcatenated = $RandomVarName
    $RandomVarNameMaybeConcatenatedWithVariablePrepended = 'variable:' + $RandomVarName
    If((Get-Random -Input @(0..1)) -eq 0)
    {
        $RandomVarNameMaybeConcatenated = '(' + (Out-ConcatenatedString $RandomVarName (Get-Random -Input @('"',"'"))) + ')'
        $RandomVarNameMaybeConcatenatedWithVariablePrepended = '(' + (Out-ConcatenatedString "variable:$RandomVarName" (Get-Random -Input @('"',"'"))) + ')'
    }

    
    $RandomVarValPlaceholder = '<[)(]>'

    
    $RandomVarSetSyntax  = @()
    $RandomVarSetSyntax += '$' + $RandomVarName + ' '*(Get-Random @(0..2)) + '=' + ' '*(Get-Random @(0..2)) + $RandomVarValPlaceholder
    $RandomVarSetSyntax += (Get-Random -Input @('Set-Variable','SV','Set')) + ' '*(Get-Random @(1..2)) + $RandomVarNameMaybeConcatenated + ' '*(Get-Random @(1..2)) + '(' + ' '*(Get-Random @(0..2)) + $RandomVarValPlaceholder + ' '*(Get-Random @(0..2)) + ')'
    
    
    $RandomVarSet = (Get-Random -Input $RandomVarSetSyntax)

    
    $RandomVarSet = Out-RandomCase $RandomVarSet
    
    
    $RandomVarGetSyntax  = @()
    $RandomVarGetSyntax += '$' + $RandomVarName
    $RandomVarGetSyntax += '(' + ' '*(Get-Random @(0..2)) + (Get-Random -Input @('Get-Variable','Variable')) + ' '*(Get-Random @(1..2)) + $RandomVarNameMaybeConcatenated + (Get-Random -Input ((' '*(Get-Random @(0..2)) + ').Value'),(' '*(Get-Random @(1..2)) + ('-ValueOnly'.SubString(0,(Get-Random -Minimum 3 -Maximum ('-ValueOnly'.Length+1)))) + ' '*(Get-Random @(0..2)) + ')')))
    $RandomVarGetSyntax += '(' + ' '*(Get-Random @(0..2)) + (Get-Random -Input @('DIR','Get-ChildItem','GCI','ChildItem','LS','Get-Item','GI','Item')) + ' '*(Get-Random @(1..2)) + $RandomVarNameMaybeConcatenatedWithVariablePrepended + ' '*(Get-Random @(0..2)) + ').Value'
    
    
    $RandomVarGet = (Get-Random -Input $RandomVarGetSyntax)

    
    $RandomVarGet = Out-RandomCase $RandomVarGet

    
    
    
    
    $SetOfsVarSyntax      = @()
    $SetOfsVarSyntax     += '$OFS' + ' '*(Get-Random -Input @(0,1)) + '=' + ' '*(Get-Random -Input @(0,1))  + "''"
    $SetOfsVarSyntax     += 'Set-Item' + ' '*(Get-Random -Input @(1,2)) + "'Variable:OFS'" + ' '*(Get-Random -Input @(1,2)) + "''"
    $SetOfsVarSyntax     += (Get-Random -Input @('Set-Variable','SV','SET')) + ' '*(Get-Random -Input @(1,2)) + "'OFS'" + ' '*(Get-Random -Input @(1,2)) + "''"
    $SetOfsVar            = (Get-Random -Input $SetOfsVarSyntax)

    $SetOfsVarBackSyntax  = @()
    $SetOfsVarBackSyntax += 'Set-Item' + ' '*(Get-Random -Input @(1,2)) + "'Variable:OFS'" + ' '*(Get-Random -Input @(1,2)) + "' '"
    $SetOfsVarBackSyntax += (Get-Random -Input @('Set-Variable','SV','SET')) + ' '*(Get-Random -Input @(1,2)) + "'OFS'" + ' '*(Get-Random -Input @(1,2)) + "' '"
    $SetOfsVarBack        = (Get-Random -Input $SetOfsVarBackSyntax)

    
    $SetOfsVar            = Out-RandomCase $SetOfsVar
    $SetOfsVarBack        = Out-RandomCase $SetOfsVarBack
    $StringStr            = Out-RandomCase 'string'
    $JoinStr              = Out-RandomCase 'join'
    $LengthStr            = Out-RandomCase 'length'
    $ArrayStr             = Out-RandomCase 'array'
    $ReverseStr           = Out-RandomCase 'reverse'
    $CharStr              = Out-RandomCase 'char'
    $RightToLeftStr       = Out-RandomCase 'righttoleft'
    $RegexStr             = Out-RandomCase 'regex'
    $MatchesStr           = Out-RandomCase 'matches'
    $ValueStr             = Out-RandomCase 'value'
    $ForEachObject        = Out-RandomCase (Get-Random -Input @('ForEach-Object','ForEach','%'))

    
    Switch(Get-Random -Input (1..3)) {
        1 {
            
            
            
            $RandomVarSet = $RandomVarSet.Replace($RandomVarValPlaceholder,('"' + ' '*(Get-Random -Input @(0,1)) + $ScriptStringReversed + ' '*(Get-Random -Input @(0,1)) + '"'))

            
            $ScriptString = $RandomVarSet + ' '*(Get-Random -Input @(0,1)) + ';' + ' '*(Get-Random -Input @(0,1))
            
            $RandomVarGet = $RandomVarGet + '[' + ' '*(Get-Random -Input @(0,1)) + '-' + ' '*(Get-Random -Input @(0,1)) + '1' + ' '*(Get-Random -Input @(0,1)) + '..' + ' '*(Get-Random -Input @(0,1)) + '-' + ' '*(Get-Random -Input @(0,1)) + '(' + ' '*(Get-Random -Input @(0,1)) + $RandomVarGet + ".$LengthStr" + ' '*(Get-Random -Input @(0,1)) + ')' + ' '*(Get-Random -Input @(0,1)) + ']'

            
            
            $JoinOptions  = @()
            $JoinOptions += "-$JoinStr" + ' '*(Get-Random -Input @(0,1)) + $RandomVarGet
            $JoinOptions += $RandomVarGet + ' '*(Get-Random -Input @(0,1)) + "-$JoinStr" + ' '*(Get-Random -Input @(0,1)) + "''"
            $JoinOptions += "[$StringStr]::$JoinStr" + '(' + ' '*(Get-Random -Input @(0,1)) + "''" + ' '*(Get-Random -Input @(0,1)) + ',' + ' '*(Get-Random -Input @(0,1)) + (Get-Random -Input $RandomVarGet) + ' '*(Get-Random -Input @(0,1)) + ')'
            $JoinOptions += '"' + ' '*(Get-Random -Input @(0,1)) + '$(' + ' '*(Get-Random -Input @(0,1)) + $SetOfsVar + ' '*(Get-Random -Input @(0,1)) + ')' + ' '*(Get-Random -Input @(0,1)) + '"' + ' '*(Get-Random -Input @(0,1)) + '+' + ' '*(Get-Random -Input @(0,1)) + "[$StringStr]" + ' '*(Get-Random -Input @(0,1)) + '(' + ' '*(Get-Random -Input @(0,1)) + $RandomVarGet + ' '*(Get-Random -Input @(0,1)) + ')' + ' '*(Get-Random -Input @(0,1)) + '+' + '"' + ' '*(Get-Random -Input @(0,1)) + '$(' + ' '*(Get-Random -Input @(0,1)) + $SetOfsVarBack + ' '*(Get-Random -Input @(0,1)) + ')' + ' '*(Get-Random -Input @(0,1)) + '"'
            $JoinOption = (Get-Random -Input $JoinOptions)
            
            
            $JoinOption = Out-EncapsulatedInvokeExpression $JoinOption
            
            $ScriptString = $ScriptString + $JoinOption
        }
        2 {
            
            
            
            $RandomVarSet = $RandomVarSet.Replace($RandomVarValPlaceholder,("[$CharStr[" + ' '*(Get-Random -Input @(0,1)) + ']' + ' '*(Get-Random -Input @(0,1)) + ']' + ' '*(Get-Random -Input @(0,1)) + '"' + $ScriptStringReversed + '"'))

            
            $ScriptString = $RandomVarSet + ' '*(Get-Random -Input @(0,1)) + ';' + ' '*(Get-Random -Input @(0,1))
            $ScriptString = $ScriptString + ' '*(Get-Random -Input @(0,1)) + "[$ArrayStr]::$ReverseStr(" + ' '*(Get-Random -Input @(0,1)) + $RandomVarGet + ' '*(Get-Random -Input @(0,1)) + ')' + ' '*(Get-Random -Input @(0,1)) + ';'

            
            
            $JoinOptions  = @()
            $JoinOptions += "-$JoinStr" + ' '*(Get-Random -Input @(0,1)) + $RandomVarGet
            $JoinOptions += $RandomVarGet + ' '*(Get-Random -Input @(0,1)) + "-$JoinStr" + ' '*(Get-Random -Input @(0,1)) + "''"
            $JoinOptions += "[$StringStr]::$JoinStr" + '(' + ' '*(Get-Random -Input @(0,1)) + "''" + ' '*(Get-Random -Input @(0,1)) + ',' + ' '*(Get-Random -Input @(0,1)) + $RandomVarGet + ' '*(Get-Random -Input @(0,1)) + ')'
            $JoinOptions += '"' + ' '*(Get-Random -Input @(0,1)) + '$(' + ' '*(Get-Random -Input @(0,1)) + $SetOfsVar + ' '*(Get-Random -Input @(0,1)) + ')' + ' '*(Get-Random -Input @(0,1)) + '"' + ' '*(Get-Random -Input @(0,1)) + '+' + ' '*(Get-Random -Input @(0,1)) + "[$StringStr]" + ' '*(Get-Random -Input @(0,1)) + '(' + ' '*(Get-Random -Input @(0,1)) + $RandomVarGet + ' '*(Get-Random -Input @(0,1)) + ')' + ' '*(Get-Random -Input @(0,1)) + '+' + '"' + ' '*(Get-Random -Input @(0,1)) + '$(' + ' '*(Get-Random -Input @(0,1)) + $SetOfsVarBack + ' '*(Get-Random -Input @(0,1)) + ')' + ' '*(Get-Random -Input @(0,1)) + '"'
            $JoinOption = (Get-Random -Input $JoinOptions)
            
            
            $JoinOption = Out-EncapsulatedInvokeExpression $JoinOption
            
            $ScriptString = $ScriptString + $JoinOption
        }
        3 {
            

            
            If(Get-Random -Input (0..1))
            {
                $RightToLeft = Out-ConcatenatedString $RightToLeftStr "'"
            }
            Else
            {
                $RightToLeft = "'$RightToLeftStr'"
            }
            
            
            
            $JoinOptions  = @()
            $JoinOptions += ' '*(Get-Random -Input @(0,1)) + '(' + ' '*(Get-Random -Input @(0,1)) + "-$JoinStr" + ' '*(Get-Random -Input @(0,1)) + "[$RegexStr]::$MatchesStr(" + ' '*(Get-Random -Input @(0,1)) + '"' + $ScriptStringReversed + ' '*(Get-Random -Input @(0,1)) + '"' + ' '*(Get-Random -Input @(0,1)) + ',' + ' '*(Get-Random -Input @(0,1)) + "'.'" + ' '*(Get-Random -Input @(0,1)) + ',' + ' '*(Get-Random -Input @(0,1)) + $RightToLeft + ' '*(Get-Random -Input @(0,1)) + ')' + ' '*(Get-Random -Input @(0,1)) + ')' + ' '*(Get-Random -Input @(0,1))
            $JoinOptions += ' '*(Get-Random -Input @(0,1)) + '(' + ' '*(Get-Random -Input @(0,1)) + "[$RegexStr]::$MatchesStr(" + ' '*(Get-Random -Input @(0,1)) + '"' + $ScriptStringReversed + '"' + ' '*(Get-Random -Input @(0,1)) + ',' + ' '*(Get-Random -Input @(0,1)) + "'.'" + ' '*(Get-Random -Input @(0,1)) + ',' +  ' '*(Get-Random -Input @(0,1)) + $RightToLeft + ' '*(Get-Random -Input @(0,1)) + ')' + ' '*(Get-Random -Input @(0,1)) + "-$JoinStr" + ' '*(Get-Random -Input @(0,1)) + "''" + ' '*(Get-Random -Input @(0,1)) + ')' + ' '*(Get-Random -Input @(0,1))
            $JoinOptions += ' '*(Get-Random -Input @(0,1)) + "[$StringStr]::$JoinStr(" + ' '*(Get-Random -Input @(0,1)) + "''" + ' '*(Get-Random -Input @(0,1)) + ',' + ' '*(Get-Random -Input @(0,1)) + '(' + ' '*(Get-Random -Input @(0,1)) + "[$RegexStr]::$MatchesStr(" + ' '*(Get-Random -Input @(0,1)) + '"' + $ScriptStringReversed + '"' + ' '*(Get-Random -Input @(0,1)) + ',' + ' '*(Get-Random -Input @(0,1)) + "'.'" + ' '*(Get-Random -Input @(0,1)) + ',' + ' '*(Get-Random -Input @(0,1)) + $RightToLeft + ' '*(Get-Random -Input @(0,1)) + ")" + ' '*(Get-Random -Input @(0,1)) + '|' + ' '*(Get-Random -Input @(0,1)) + $ForEachObject + ' '*(Get-Random -Input @(0,1)) + '{' + ' '*(Get-Random -Input @(0,1)) + '$_' + ".$ValueStr" + ' '*(Get-Random -Input @(0,1)) + '}' + ' '*(Get-Random -Input @(0,1)) + ')' + ' '*(Get-Random -Input @(0,1)) + ')' + ' '*(Get-Random -Input @(0,1))
            $JoinOptions += '"' + ' '*(Get-Random -Input @(0,1)) + '$(' + ' '*(Get-Random -Input @(0,1)) + $SetOfsVar + ' '*(Get-Random -Input @(0,1)) + ')' + ' '*(Get-Random -Input @(0,1)) + '"' + ' '*(Get-Random -Input @(0,1)) + '+' +          ' '*(Get-Random -Input @(0,1)) + '(' + ' '*(Get-Random -Input @(0,1)) + "[$StringStr]" + ' '*(Get-Random -Input @(0,1)) + "[$RegexStr]::$MatchesStr(" + ' '*(Get-Random -Input @(0,1)) + '"' + $ScriptStringReversed + '"' + ' '*(Get-Random -Input @(0,1)) + ',' + ' '*(Get-Random -Input @(0,1)) + "'.'" + ' '*(Get-Random -Input @(0,1)) + ',' + ' '*(Get-Random -Input @(0,1)) + $RightToLeft + ' '*(Get-Random -Input @(0,1)) + ")" + ' '*(Get-Random -Input @(0,1)) + '|' + ' '*(Get-Random -Input @(0,1)) + $ForEachObject + ' '*(Get-Random -Input @(0,1)) + '{' + ' '*(Get-Random -Input @(0,1)) + '$_' + ' '*(Get-Random -Input @(0,1)) + '}' + ' '*(Get-Random -Input @(0,1)) + ')'             + ' '*(Get-Random -Input @(0,1)) + '+' + '"' + ' '*(Get-Random -Input @(0,1)) + '$(' + ' '*(Get-Random -Input @(0,1)) + $SetOfsVarBack + ' '*(Get-Random -Input @(0,1)) + ')' + ' '*(Get-Random -Input @(0,1)) + '"'
            $ScriptString = (Get-Random -Input $JoinOptions)
            
            
            $ScriptString = Out-EncapsulatedInvokeExpression $ScriptString
        }
        default {Write-Error "An invalid value was passed to switch block."; Exit;}
    }
    
    
    
    $SpecialCharacters = @('a','b','f','n','r','u','t','v','0')
    ForEach($SpecialChar in $SpecialCharacters)
    {
        If($ScriptString.Contains("``"+$SpecialChar))
        {
            $ScriptString = $ScriptString.Replace("``"+$SpecialChar,$SpecialChar)
        }
    }
    
    Return $ScriptString
}


Function Out-EncapsulatedInvokeExpression
{


    [CmdletBinding()] Param (
        [Parameter(Position = 0)]
        [ValidateNotNullOrEmpty()]
        [String]
        $ScriptString
    )

    
    
    
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

    
    $InvokeExpression = Out-RandomCase $InvokeExpression
    
    
    $InvokeOptions  = @()
    $InvokeOptions += ' '*(Get-Random -Input @(0,1)) + $InvokeExpression + ' '*(Get-Random -Input @(0,1)) + '(' + ' '*(Get-Random -Input @(0,1)) + $ScriptString + ' '*(Get-Random -Input @(0,1)) + ')' + ' '*(Get-Random -Input @(0,1))
    $InvokeOptions += ' '*(Get-Random -Input @(0,1)) + $ScriptString + ' '*(Get-Random -Input @(0,1)) + '|' + ' '*(Get-Random -Input @(0,1)) + $InvokeExpression

    $ScriptString = (Get-Random -Input $InvokeOptions)

    Return $ScriptString
}