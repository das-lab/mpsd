


















Function Out-SecureStringCommand
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

    
    If($PSBoundParameters['Path'])
    {
        Get-ChildItem $Path -ErrorAction Stop | Out-Null
        $ScriptString = [IO.File]::ReadAllText((Resolve-Path $Path))
    }
    Else
    {
        $ScriptString = [String]$ScriptBlock
    }

    
    $SecureString = ConvertTo-SecureString $ScriptString -AsPlainText -Force
    
    
    $KeyLength = Get-Random @(16,24,32)
    
    
    Switch(Get-Random -Minimum 1 -Maximum 3)
    { 
        1 {
            
            $SecureStringKey = @()
            For($i=0; $i -lt $KeyLength; $i++) {
                $SecureStringKey += Get-Random -Minimum 0 -Maximum 256
            }
            $SecureStringKeyStr = $SecureStringKey -Join ','
          }
        2 {
            
            
            $LowerBound = (Get-Random -Minimum 0 -Maximum (256-$KeyLength))
            $UpperBound = $LowerBound + ($KeyLength - 1)
            Switch(Get-Random @('Ascending','Descending'))
            {
                'Ascending'  {$SecureStringKey = ($LowerBound..$UpperBound); $SecureStringKeyStr = "($LowerBound..$UpperBound)"}
                'Descending' {$SecureStringKey = ($UpperBound..$LowerBound); $SecureStringKeyStr = "($UpperBound..$LowerBound)"}
                default {Write-Error "An invalid array ordering option was generated for switch block."; Exit;}
            }
          }
        default {Write-Error "An invalid random number was generated for switch block."; Exit;}
    }
    
    
    $SecureStringText = $SecureString | ConvertFrom-SecureString -Key $SecureStringKey

    
    $Key = (Get-Random -Input @(' -Key ',' -Ke ',' -K '))

    
    $PtrToStringAuto = (Get-Random -Input @('PtrToStringAuto',('([Runtime.InteropServices.Marshal].GetMembers()[' + (Get-Random -Input @(3,5)) + '].Name).Invoke')))
    $PtrToStringUni  = (Get-Random -Input @('PtrToStringUni' ,('([Runtime.InteropServices.Marshal].GetMembers()[' + (Get-Random -Input @(2,4)) + '].Name).Invoke')))
    $PtrToStringAnsi = (Get-Random -Input @('PtrToStringAnsi',('([Runtime.InteropServices.Marshal].GetMembers()[' + (Get-Random -Input @(0,1)) + '].Name).Invoke')))
    
    
    
    
    

    
    $PtrToStringAuto                  = ([Char[]]"[Runtime.InteropServices.Marshal]::$PtrToStringAuto("                 | ForEach-Object {$Char = $_.ToString().ToLower(); If(Get-Random -Input @(0..1)) {$Char = $Char.ToUpper()} $Char}) -Join ''
    $PtrToStringUni                   = ([Char[]]"[Runtime.InteropServices.Marshal]::$PtrToStringUni("                  | ForEach-Object {$Char = $_.ToString().ToLower(); If(Get-Random -Input @(0..1)) {$Char = $Char.ToUpper()} $Char}) -Join ''
    $PtrToStringAnsi                  = ([Char[]]"[Runtime.InteropServices.Marshal]::$PtrToStringAnsi("                 | ForEach-Object {$Char = $_.ToString().ToLower(); If(Get-Random -Input @(0..1)) {$Char = $Char.ToUpper()} $Char}) -Join ''
    $PtrToStringBSTR                  = ([Char[]]'[Runtime.InteropServices.Marshal]::PtrToStringBSTR('                  | ForEach-Object {$Char = $_.ToString().ToLower(); If(Get-Random -Input @(0..1)) {$Char = $Char.ToUpper()} $Char}) -Join ''
    $SecureStringToBSTR               = ([Char[]]'[Runtime.InteropServices.Marshal]::SecureStringToBSTR('               | ForEach-Object {$Char = $_.ToString().ToLower(); If(Get-Random -Input @(0..1)) {$Char = $Char.ToUpper()} $Char}) -Join ''
    $SecureStringToGlobalAllocUnicode = ([Char[]]'[Runtime.InteropServices.Marshal]::SecureStringToGlobalAllocUnicode(' | ForEach-Object {$Char = $_.ToString().ToLower(); If(Get-Random -Input @(0..1)) {$Char = $Char.ToUpper()} $Char}) -Join ''
    $SecureStringToGlobalAllocAnsi    = ([Char[]]'[Runtime.InteropServices.Marshal]::SecureStringToGlobalAllocAnsi('    | ForEach-Object {$Char = $_.ToString().ToLower(); If(Get-Random -Input @(0..1)) {$Char = $Char.ToUpper()} $Char}) -Join ''
    $NewObject                        = ([Char[]]'New-Object '                                                          | ForEach-Object {$Char = $_.ToString().ToLower(); If(Get-Random -Input @(0..1)) {$Char = $Char.ToUpper()} $Char}) -Join ''
    $PSCredential                     = ([Char[]]'Management.Automation.PSCredential '                                  | ForEach-Object {$Char = $_.ToString().ToLower(); If(Get-Random -Input @(0..1)) {$Char = $Char.ToUpper()} $Char}) -Join ''
    $ConvertToSecureString            = ([Char[]]'ConvertTo-SecureString'                                               | ForEach-Object {$Char = $_.ToString().ToLower(); If(Get-Random -Input @(0..1)) {$Char = $Char.ToUpper()} $Char}) -Join ''
    $Key                              = ([Char[]]$Key                                                                   | ForEach-Object {$Char = $_.ToString().ToLower(); If(Get-Random -Input @(0..1)) {$Char = $Char.ToUpper()} $Char}) -Join ''
    $GetNetworkCredential             = ([Char[]]').GetNetworkCredential().Password'                                    | ForEach-Object {$Char = $_.ToString().ToLower(); If(Get-Random -Input @(0..1)) {$Char = $Char.ToUpper()} $Char}) -Join ''

    
    $ConvertToSecureStringSyntax = '$(' + "'$SecureStringText'" + ' '*(Get-Random -Input @(0,1)) + '|' + ' '*(Get-Random -Input @(0,1)) + $ConvertToSecureString + ' '*(Get-Random -Input @(0,1)) + $Key + ' '*(Get-Random -Input @(0,1)) + $SecureStringKeyStr + ')' + ' '*(Get-Random -Input @(0,1)) + ')' + ' '*(Get-Random -Input @(0,1)) + ')' + ' '*(Get-Random -Input @(0,1)) + ')'

    
    $NewScriptArray = @()
    $NewScriptArray += '(' + ' '*(Get-Random -Input @(0,1)) + $PtrToStringAuto + ' '*(Get-Random -Input @(0,1)) + $SecureStringToBSTR               + ' '*(Get-Random -Input @(0,1)) + $ConvertToSecureStringSyntax
    $NewScriptArray += '(' + ' '*(Get-Random -Input @(0,1)) + $PtrToStringUni  + ' '*(Get-Random -Input @(0,1)) + $SecureStringToGlobalAllocUnicode + ' '*(Get-Random -Input @(0,1)) + $ConvertToSecureStringSyntax
    $NewScriptArray += '(' + ' '*(Get-Random -Input @(0,1)) + $PtrToStringAnsi + ' '*(Get-Random -Input @(0,1)) + $SecureStringToGlobalAllocAnsi    + ' '*(Get-Random -Input @(0,1)) + $ConvertToSecureStringSyntax
    $NewScriptArray += '(' + ' '*(Get-Random -Input @(0,1)) + $PtrToStringBSTR + ' '*(Get-Random -Input @(0,1)) + $SecureStringToBSTR               + ' '*(Get-Random -Input @(0,1)) + $ConvertToSecureStringSyntax
    $NewScriptArray += '(' + ' '*(Get-Random -Input @(0,1)) + $NewObject + ' '*(Get-Random -Input @(0,1)) + $PSCredential + ' '*(Get-Random -Input @(0,1)) + "' '" + ',' + ' '*(Get-Random -Input @(0,1)) + '(' + ' '*(Get-Random -Input @(0,1)) + "'$SecureStringText'" + ' '*(Get-Random -Input @(0,1)) + '|' + ' '*(Get-Random -Input @(0,1)) + $ConvertToSecureString + ' '*(Get-Random -Input @(0,1)) + $Key + ' '*(Get-Random -Input @(0,1)) + $SecureStringKeyStr + ' '*(Get-Random -Input @(0,1)) + ')' + ' '*(Get-Random -Input @(0,1)) + $GetNetworkCredential
    
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