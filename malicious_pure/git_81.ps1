


















Function Out-CompressedCommand
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
        $ScriptString = [IO.File]::ReadAllBytes((Resolve-Path $Path))
    }
    Else
    {
        $ScriptString = ([Text.Encoding]::ASCII).GetBytes($ScriptBlock)
    }

    
    
    $CompressedStream = New-Object IO.MemoryStream
    $DeflateStream = New-Object IO.Compression.DeflateStream ($CompressedStream, [IO.Compression.CompressionMode]::Compress)
    $DeflateStream.Write($ScriptString, 0, $ScriptString.Length)
    $DeflateStream.Dispose()
    $CompressedScriptBytes = $CompressedStream.ToArray()
    $CompressedStream.Dispose()
    $EncodedCompressedScript = [Convert]::ToBase64String($CompressedScriptBytes)

    
    $StreamReader     = Get-Random -Input @('IO.StreamReader','System.IO.StreamReader')
    $DeflateStream    = Get-Random -Input @('IO.Compression.DeflateStream','System.IO.Compression.DeflateStream')
    $MemoryStream     = Get-Random -Input @('IO.MemoryStream','System.IO.MemoryStream')
    $Convert          = Get-Random -Input @('Convert','System.Convert')
    $CompressionMode  = Get-Random -Input @('IO.Compression.CompressionMode','System.IO.Compression.CompressionMode')
    $Encoding         = Get-Random -Input @('Text.Encoding','System.Text.Encoding')
    $ForEachObject    = Get-Random -Input @('ForEach','ForEach-Object','%')
    $StreamReader     = ([Char[]]$StreamReader      | ForEach-Object {$Char = $_.ToString().ToLower(); If(Get-Random -Input @(0..1)) {$Char = $Char.ToUpper()} $Char}) -Join ''
    $DeflateStream    = ([Char[]]$DeflateStream     | ForEach-Object {$Char = $_.ToString().ToLower(); If(Get-Random -Input @(0..1)) {$Char = $Char.ToUpper()} $Char}) -Join ''
    $MemoryStream     = ([Char[]]$MemoryStream      | ForEach-Object {$Char = $_.ToString().ToLower(); If(Get-Random -Input @(0..1)) {$Char = $Char.ToUpper()} $Char}) -Join ''
    $Convert          = ([Char[]]$Convert           | ForEach-Object {$Char = $_.ToString().ToLower(); If(Get-Random -Input @(0..1)) {$Char = $Char.ToUpper()} $Char}) -Join ''
    $CompressionMode  = ([Char[]]$CompressionMode   | ForEach-Object {$Char = $_.ToString().ToLower(); If(Get-Random -Input @(0..1)) {$Char = $Char.ToUpper()} $Char}) -Join ''
    $Encoding         = ([Char[]]$Encoding          | ForEach-Object {$Char = $_.ToString().ToLower(); If(Get-Random -Input @(0..1)) {$Char = $Char.ToUpper()} $Char}) -Join ''
    $NewObject        = ([Char[]]'New-Object'       | ForEach-Object {$Char = $_.ToString().ToLower(); If(Get-Random -Input @(0..1)) {$Char = $Char.ToUpper()} $Char}) -Join ''
    $FromBase64       = ([Char[]]'FromBase64String' | ForEach-Object {$Char = $_.ToString().ToLower(); If(Get-Random -Input @(0..1)) {$Char = $Char.ToUpper()} $Char}) -Join ''
    $Decompress       = ([Char[]]'Decompress'       | ForEach-Object {$Char = $_.ToString().ToLower(); If(Get-Random -Input @(0..1)) {$Char = $Char.ToUpper()} $Char}) -Join ''
    $Ascii            = ([Char[]]'Ascii'            | ForEach-Object {$Char = $_.ToString().ToLower(); If(Get-Random -Input @(0..1)) {$Char = $Char.ToUpper()} $Char}) -Join ''
    $ReadToEnd        = ([Char[]]'ReadToEnd'        | ForEach-Object {$Char = $_.ToString().ToLower(); If(Get-Random -Input @(0..1)) {$Char = $Char.ToUpper()} $Char}) -Join ''
    $ForEachObject    = ([Char[]]$ForEachObject     | ForEach-Object {$Char = $_.ToString().ToLower(); If(Get-Random -Input @(0..1)) {$Char = $Char.ToUpper()} $Char}) -Join ''
    $ForEachObject2   = ([Char[]]$ForEachObject     | ForEach-Object {$Char = $_.ToString().ToLower(); If(Get-Random -Input @(0..1)) {$Char = $Char.ToUpper()} $Char}) -Join ''

    
    $Base64 = ' '*(Get-Random -Input @(0,1)) + "[$Convert]::$FromBase64(" + ' '*(Get-Random -Input @(0,1)) + "'$EncodedCompressedScript'" + ' '*(Get-Random -Input @(0,1)) + ")" + ' '*(Get-Random -Input @(0,1))
    $DeflateStreamSyntax = ' '*(Get-Random -Input @(0,1)) + "$DeflateStream(" + ' '*(Get-Random -Input @(0,1)) + "[$MemoryStream]$Base64," + ' '*(Get-Random -Input @(0,1)) + "[$CompressionMode]::$Decompress" + ' '*(Get-Random -Input @(0,1)) + ")" + ' '*(Get-Random -Input @(0,1))

    
    $NewScriptArray   = @()
    $NewScriptArray  += "(" + ' '*(Get-Random -Input @(0,1)) + "$NewObject " + ' '*(Get-Random -Input @(0,1)) + "$StreamReader(" + ' '*(Get-Random -Input @(0,1)) + "(" + ' '*(Get-Random -Input @(0,1)) + "$NewObject $DeflateStreamSyntax)" + ' '*(Get-Random -Input @(0,1)) + "," + ' '*(Get-Random -Input @(0,1)) + "[$Encoding]::$Ascii)" + ' '*(Get-Random -Input @(0,1)) + ").$ReadToEnd(" + ' '*(Get-Random -Input @(0,1)) + ")"
    $NewScriptArray  += "(" + ' '*(Get-Random -Input @(0,1)) + "$NewObject $DeflateStreamSyntax|" + ' '*(Get-Random -Input @(0,1)) + "$ForEachObject" + ' '*(Get-Random -Input @(0,1)) + "{" + ' '*(Get-Random -Input @(0,1)) + "$NewObject " + ' '*(Get-Random -Input @(0,1)) + "$StreamReader(" + ' '*(Get-Random -Input @(0,1)) + "`$_" + ' '*(Get-Random -Input @(0,1)) + "," + ' '*(Get-Random -Input @(0,1)) + "[$Encoding]::$Ascii" + ' '*(Get-Random -Input @(0,1)) + ")" + ' '*(Get-Random -Input @(0,1)) + "}" + ' '*(Get-Random -Input @(0,1)) + ").$ReadToEnd(" + ' '*(Get-Random -Input @(0,1)) + ")"
    $NewScriptArray  += "(" + ' '*(Get-Random -Input @(0,1)) + "$NewObject $DeflateStreamSyntax|" + ' '*(Get-Random -Input @(0,1)) + "$ForEachObject" + ' '*(Get-Random -Input @(0,1)) + "{" + ' '*(Get-Random -Input @(0,1)) + "$NewObject " + ' '*(Get-Random -Input @(0,1)) + "$StreamReader(" + ' '*(Get-Random -Input @(0,1)) + "`$_" + ' '*(Get-Random -Input @(0,1)) + "," + ' '*(Get-Random -Input @(0,1)) + "[$Encoding]::$Ascii" + ' '*(Get-Random -Input @(0,1)) + ")" + ' '*(Get-Random -Input @(0,1)) + "}" + ' '*(Get-Random -Input @(0,1)) + "|" + ' '*(Get-Random -Input @(0,1)) + "$ForEachObject2" + ' '*(Get-Random -Input @(0,1)) + "{" + ' '*(Get-Random -Input @(0,1)) + "`$_.$ReadToEnd(" + ' '*(Get-Random -Input @(0,1)) + ")" + ' '*(Get-Random -Input @(0,1)) + "}" + ' '*(Get-Random -Input @(0,1)) + ")"
    
    
    $NewScript = (Get-Random -Input $NewScriptArray)

    
    
    $InvokeExpressionSyntax  = @()
    $InvokeExpressionSyntax += (Get-Random -Input @('IEX','Invoke-Expression'))
    
    
    
    $InvocationOperator = (Get-Random -Input @('.','&')) + ' '*(Get-Random -Input @(0,1))
    $InvokeExpressionSyntax += $InvocationOperator + "( `$ShellId[1]+`$ShellId[13]+'x')"
    $InvokeExpressionSyntax += $InvocationOperator + "( `$PSHome[" + (Get-Random -Input @(4,21)) + "]+`$PSHome[" + (Get-Random -Input @(30,34)) + "]+'x')"
    $InvokeExpressionSyntax += $InvocationOperator + "( `$env:ComSpec[4," + (Get-Random -Input @(15,24,26)) + ",25]-Join'')"
    $InvokeExpressionSyntax += $InvocationOperator + "((" + (Get-Random -Input @('Get-Variable','GV','Variable')) + " '*mdr*').Name[3,11,2]-Join'')"
    $InvokeExpressionSyntax += $InvocationOperator + "( " + (Get-Random -Input @('$VerbosePreference.ToString()','([String]$VerbosePreference)')) + "[1,3]+'x'-Join'')"
    
    
    
    
    $InvokeExpression = (Get-Random -Input $InvokeExpressionSyntax)

    
    $InvokeExpression = ([Char[]]$InvokeExpression | ForEach-Object {$Char = $_.ToString().ToLower(); If(Get-Random -Input @(0..1)) {$Char = $Char.ToUpper()} $Char}) -Join ''
    
    
    $InvokeOptions  = @()
    $InvokeOptions += ' '*(Get-Random -Input @(0,1)) + $InvokeExpression + ' '*(Get-Random -Input @(0,1)) + $NewScript + ' '*(Get-Random -Input @(0,1))
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
                'normal'    {If(Get-Random -Input @(0..1)) {$ArgumentValue = 0}}
                'hidden'    {If(Get-Random -Input @(0..1)) {$ArgumentValue = 1}}
                'minimized' {If(Get-Random -Input @(0..1)) {$ArgumentValue = 2}}
                'maximized' {If(Get-Random -Input @(0..1)) {$ArgumentValue = 3}}
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
            $CommandLineOutput = "$($Env:windir)\SysWOW64\WindowsPowerShell\v1.0\powershell.exe $($CommandlineOptions) `"$NewScript`""
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