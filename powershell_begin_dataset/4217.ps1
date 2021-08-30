











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
        [ValidateSet("NT4","DN","Simple","Canonical")]
        $InputType,

        [String]
        [ValidateSet("NT4","DN","Simple","Canonical")]
        $OutputType
    )

    $NameTypes = @{
        'DN'        = 1
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
        elseif($ObjectName -match '^CN=.*') {
            $InputType = 'DN'
        }
        else {
            Write-Warning "Can not identify InType for $ObjectName"
        }
    }
    elseif($InputType -eq 'NT4') {
        $ObjectName = $ObjectName.replace('/', '\')
    }

    if(-not $PSBoundParameters['OutputType']) {
        $OutputType = Switch($InputType) {
            'NT4' {'Canonical'}
            'Simple' {'NT4'}
            'DN' {'NT4'}
            'Canonical' {'NT4'}
        }
    }

    
    $Domain = Switch($InputType) {
        'NT4' { $ObjectName.split("\")[0] }
        'Simple' { $ObjectName.split("@")[1] }
        'Canonical' { $ObjectName.split("/")[0] }
        'DN' {$ObjectName.subString($ObjectName.IndexOf('DC=')) -replace 'DC=','' -replace ',','.'}
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
        
    }

    Set-Property $Translate "ChaseReferral" (0x60)

    try {
        Invoke-Method $Translate "Set" ($NameTypes[$InputType], $ObjectName)
        (Invoke-Method $Translate "Get" ($NameTypes[$OutputType]))
    }
    catch [System.Management.Automation.MethodInvocationException] {
        
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
            Write-Verbose "Get-NetComputer filter : $CompFilter"
            $CompSearcher.filter = $CompFilter
            if(-not $FullData) {
                $Null = $CompSearcher.PropertiesToLoad.Add('dnshostname')
            }

            try {
                ForEach($ComputerResult in $CompSearcher.FindAll()) {
                    if($ComputerResult) {
                        $Up = $True
                        if($Ping) {
                            $Up = Test-Connection -Count 1 -Quiet -ComputerName $ComputerResult.properties.dnshostname
                        }
                        if($Up) {
                            
                            if ($FullData) {
                                
                                $Computer = Convert-LDAPProperty -Properties $ComputerResult.Properties
                                $Computer.PSObject.TypeNames.Add('PowerView.Computer')
                                $Computer
                            }
                            else {
                                
                                $ComputerResult.properties.dnshostname
                            }
                        }
                    }
                }

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
        if($SID -and (-not $Domain)) {
            
            try {
                $Name = Convert-SidToName $SID
                if($Name) {
                    $Canonical = Convert-ADName -ObjectName $Name -InputType NT4 -OutputType Canonical
                    if($Canonical) {
                        $Domain = $Canonical.split("/")[0]
                    }
                    else {
                        Write-Verbose "Error resolving SID '$SID'"
                        return $Null
                    }
                }
            }
            catch {
                Write-Verbose "Error resolving SID '$SID' : $_"
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

            try {
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
            }
            catch {
                Write-Verbose "Error building the searcher object!"
            }
            $ObjectSearcher.dispose()
        }
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


function Get-DomainSID {


    param(
        [String]
        $Domain,

        [String]
        $DomainController
    )

    $ComputerSearcher = Get-DomainSearcher -Domain $TargetDomain -DomainController $DomainController
    $ComputerSearcher.Filter = '(sAMAccountType=805306369)'
    $Null = $ComputerSearcher.PropertiesToLoad.Add('objectsid')
    $Result = $ComputerSearcher.FindOne()

    if(-not $Result) {
        Write-Verbose "Get-DomainSID: no results retrieved"
    }
    else {
        $DCObject = Convert-LDAPProperty -Properties $Result.Properties
        $DCSID = $DCObject.objectsid
        $DCSID.Substring(0, $DCSID.LastIndexOf('-'))
    }
}


function Get-NetFileServer {


    [CmdletBinding()]
    param(
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

    function Split-Path {
        
        param([String]$Path)

        if ($Path -and ($Path.split("\\").Count -ge 3)) {
            $Temp = $Path.split("\\")[2]
            if($Temp -and ($Temp -ne '')) {
                $Temp
            }
        }
    }

    $UserSearcher = Get-DomainSearcher -Domain $Domain -DomainController $DomainController -Credential $Credential -PageSize $PageSize

    
    $UserSearcher.filter = "(&(samAccountType=805306368)(|(homedirectory=*)(scriptpath=*)(profilepath=*)))"

    
    $UserSearcher.PropertiesToLoad.AddRange(('homedirectory', 'scriptpath', 'profilepath'))

    
    Sort-Object -Unique -InputObject $(ForEach($UserResult in $UserSearcher.FindAll()) {if($UserResult.Properties['homedirectory']) {Split-Path($UserResult.Properties['homedirectory'])}if($UserResult.Properties['scriptpath']) {Split-Path($UserResult.Properties['scriptpath'])}if($UserResult.Properties['profilepath']) {Split-Path($UserResult.Properties['profilepath'])}})
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








function Get-GptTmpl {


    [CmdletBinding()]
    Param (
        [Parameter(Mandatory=$True, ValueFromPipeline=$True)]
        [String]
        $GptTmplPath,

        [Switch]
        $UsePSDrive
    )

    begin {
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
    }

    process {
        try {
            Write-Verbose "Attempting to parse GptTmpl: $TargetGptTmplPath"
            $TargetGptTmplPath | Get-IniContent -ErrorAction SilentlyContinue
        }
        catch {
            
        }
    }

    end {
        if($UsePSDrive -and $RandDrive) {
            Write-Verbose "Removing temp PSDrive $RandDrive"
            Get-PSDrive -Name $RandDrive -ErrorAction SilentlyContinue | Remove-PSDrive -Force
        }
    }
}


function Get-GroupsXML {


    [CmdletBinding()]
    Param (
        [Parameter(Mandatory=$True, ValueFromPipeline=$True)]
        [String]
        $GroupsXMLPath,

        [Switch]
        $UsePSDrive
    )

    begin {
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
    }

    process {

        try {
            Write-Verbose "Attempting to parse Groups.xml: $TargetGroupsXMLPath"
            [XML]$GroupsXMLcontent = Get-Content $TargetGroupsXMLPath -ErrorAction Stop

            
            $GroupsXMLcontent | Select-Xml "//Groups" | Select-Object -ExpandProperty node | ForEach-Object {

                $Groupname = $_.Group.Properties.groupName

                
                $GroupSID = $_.Group.Properties.GroupSid
                if(-not $LocalSid) {
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

                
                $Members = $_.Group.Properties.members | Select-Object -ExpandProperty Member | Where-Object { $_.action -match 'ADD' } | ForEach-Object {
                    if($_.sid) { $_.sid }
                    else { $_.name }
                }

                if ($Members) {

                    
                    if($_.Group.filters) {
                        $Filters = $_.Group.filters.GetEnumerator() | ForEach-Object {
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
            
        }
    }

    end {
        if($UsePSDrive -and $RandDrive) {
            Write-Verbose "Removing temp PSDrive $RandDrive"
            Get-PSDrive -Name $RandDrive -ErrorAction SilentlyContinue | Remove-PSDrive -Force
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

    $GPOSearcher = Get-DomainSearcher -Domain $Domain -DomainController $DomainController -Credential $Credential -ADSpath $ADSpath -PageSize $PageSize
    $GPOSearcher.filter="(&(objectCategory=groupPolicyContainer)(name=*)(gpcfilesyspath=*))"
    $GPOSearcher.PropertiesToLoad.AddRange(('displayname', 'name', 'gpcfilesyspath'))

    ForEach($GPOResult in $GPOSearcher.FindAll()) {

        $GPOdisplayName = $GPOResult.Properties['displayname']
        $GPOname = $GPOResult.Properties['name']
        $GPOPath = $GPOResult.Properties['gpcfilesyspath']
        Write-Verbose "Get-NetGPOGroup: enumerating $GPOPath"

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

    $TargetSIDs = @('*')

    
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

    
    Sort-Object -Property GPOName -Unique -InputObject $(ForEach($GPOGroup in (Get-NetGPOGroup @GPOGroupArgs)) {
        
        
        if($GPOgroup.GroupSID -match $TargetLocalSID) {
            ForEach($GPOgroupMember in $GPOgroup.GroupMembers) {
                if($GPOgroupMember) {
                    if ( ($TargetSIDs[0] -eq '*') -or ($TargetSIDs -Contains $GPOgroupMember) ) {
                        $GPOgroup
                    }
                }
            }
        }
        
        if( ($GPOgroup.GroupMemberOf -contains $TargetLocalSID) ) {
            if( ($TargetSIDs[0] -eq '*') -or ($TargetSIDs -Contains $GPOgroup.GroupSID) ) {
                $GPOgroup
            }
        }
    }) | ForEach-Object {

        $GPOname = $_.GPODisplayName
        write-verbose "GPOname: $GPOname"
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
                
                
                $FilterValue = $Filters.Value
                $OUComputers = ForEach($OUComputer in (Get-NetComputer -Domain $Domain -DomainController $DomainController -Credential $Credential -ADSpath $_.ADSpath -PageSize $PageSize)) {
                    if($OUComputer.ToLower() -match $Filters.Value) {
                        $OUComputer
                    }
                }
            }
            else {
                $OUComputers = Get-NetComputer -Domain $Domain -DomainController $DomainController -Credential $Credential -ADSpath $_.ADSpath -PageSize $PageSize
            }

            if($OUComputers) {
                if($OUComputers -isnot [System.Array]) {$OUComputers = @($OUComputers)}
                ForEach ($TargetSid in $TargetObjectSIDs) {
                    $Object = Get-ADObject -SID $TargetSid
                    if (-not $Object) {
                        $Object = Get-ADObject -SID $TargetSid -Domain $Domain -DomainController $DomainController -Credential $Credential -PageSize $PageSize
                    }
                    if($Object) {
                        $MemberDN = $Object.distinguishedName
                        $ObjectDomain = $MemberDN.subString($MemberDN.IndexOf("DC=")) -replace 'DC=','' -replace ',','.'
                        $IsGroup = @('268435456','268435457','536870912','536870913') -contains $Object.samaccounttype

                        $GPOLocation = New-Object PSObject
                        $GPOLocation | Add-Member Noteproperty 'ObjectDomain' $ObjectDomain
                        $GPOLocation | Add-Member Noteproperty 'ObjectName' $Object.samaccountname
                        $GPOLocation | Add-Member Noteproperty 'ObjectDN' $Object.distinguishedname
                        $GPOLocation | Add-Member Noteproperty 'ObjectSID' $Object.objectsid
                        $GPOLocation | Add-Member Noteproperty 'IsGroup' $IsGroup
                        $GPOLocation | Add-Member Noteproperty 'GPODomain' $Domain
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
        }

        
        Get-NetSite -Domain $Domain -DomainController $DomainController -GUID $GPOguid -PageSize $PageSize -FullData | ForEach-Object {

            ForEach ($TargetSid in $TargetObjectSIDs) {
                
                $Object = Get-ADObject -SID $TargetSid
                if (-not $Object) {
                    $Object = Get-ADObject -SID $TargetSid -Domain $Domain -DomainController $DomainController -Credential $Credential -PageSize $PageSize                        
                }
                if($Object) {
                    $MemberDN = $Object.distinguishedName
                    $ObjectDomain = $MemberDN.subString($MemberDN.IndexOf("DC=")) -replace 'DC=','' -replace ',','.'
                    $IsGroup = @('268435456','268435457','536870912','536870913') -contains $Object.samaccounttype

                    $AppliedSite = New-Object PSObject
                    $GPOLocation | Add-Member Noteproperty 'ObjectDomain' $ObjectDomain
                    $AppliedSite | Add-Member Noteproperty 'ObjectName' $Object.samaccountname
                    $AppliedSite | Add-Member Noteproperty 'ObjectDN' $Object.distinguishedname
                    $AppliedSite | Add-Member Noteproperty 'ObjectSID' $Object.objectsid
                    $AppliedSite | Add-Member Noteproperty 'IsGroup' $IsGroup
                    $AppliedSite | Add-Member Noteproperty 'GPODomain' $Domain
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

        [Parameter(ParameterSetName = 'API')]
        [Switch]
        $API,

        [Switch]
        $IsDomain,

        [ValidateNotNullOrEmpty()]
        [String]
        $DomainSID
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

                        $SidString = ''
                        $Result2 = $Advapi32::ConvertSidToStringSid($Info.lgrmi2_sid, [ref]$SidString);$LastError = [Runtime.InteropServices.Marshal]::GetLastWin32Error()

                        if($Result2 -eq 0) {
                            
                        }
                        else {
                            $IsGroup = $($Info.lgrmi2_sidusage -ne 'SidTypeUser')
                            $LocalUsers += @{
                                'ComputerName' = $Server
                                'AccountName' = $Info.lgrmi2_domainandname
                                'SID' = $SidString
                                'IsGroup' = $IsGroup
                                'Type' = 'LocalUser'
                            }
                        }
                    }

                    
                    $Null = $Netapi32::NetApiBufferFree($PtrInfo)

                    $MachineSid = ($LocalUsers | Where-Object {$_['SID'] -like '*-500'})['SID']
                    $MachineSid = $MachineSid.Substring(0, $MachineSid.LastIndexOf('-'))
                    try {
                        ForEach($LocalUser in $LocalUsers) {
                            if($DomainSID -and ($LocalUser['SID'] -match $DomainSID)) {
                                $LocalUser['IsDomain'] = $True
                            }
                            elseif($LocalUser['SID'] -match $MachineSid) {
                                $LocalUser['IsDomain'] = $False
                            }
                            else {
                                $LocalUser['IsDomain'] = $True
                            }
                            if($IsDomain) {
                                if($LocalUser['IsDomain']) {
                                    $LocalUser
                                }
                            }
                            else {
                                $LocalUser
                            }
                        }
                    }
                    catch { }
                }
                else {
                    
                }
            }

            else {
                
                try {
                    $LocalUsers = @()
                    $Members = @($([ADSI]"WinNT://$Server/$GroupName,group").psbase.Invoke('Members'))

                    $Members | ForEach-Object {
                        $LocalUser = ([ADSI]$_)

                        $AdsPath = $LocalUser.InvokeGet('AdsPath').Replace('WinNT://', '')

                        if(([regex]::Matches($AdsPath, '/')).count -eq 1) {
                            
                            $MemberIsDomain = $True
                            $Name = $AdsPath.Replace('/', '\')
                        }
                        else {
                            
                            $MemberIsDomain = $False
                            $Name = $AdsPath.Substring($AdsPath.IndexOf('/')+1).Replace('/', '\')
                        }

                        $IsGroup = ($LocalUser.SchemaClassName -like 'group')
                        if($IsDomain) {
                            if($MemberIsDomain) {
                                $LocalUsers += @{
                                    'ComputerName' = $Server
                                    'AccountName' = $Name
                                    'SID' = ((New-Object System.Security.Principal.SecurityIdentifier($LocalUser.InvokeGet('ObjectSID'),0)).Value)
                                    'IsGroup' = $IsGroup
                                    'IsDomain' = $MemberIsDomain
                                    'Type' = 'LocalUser'
                                }
                            }
                        }
                        else {
                            $LocalUsers += @{
                                'ComputerName' = $Server
                                'AccountName' = $Name
                                'SID' = ((New-Object System.Security.Principal.SecurityIdentifier($LocalUser.InvokeGet('ObjectSID'),0)).Value)
                                'IsGroup' = $IsGroup
                                'IsDomain' = $MemberIsDomain
                                'Type' = 'LocalUser'
                            }
                        }
                    }
                    $LocalUsers
                }
                catch {
                    Write-Verbose "Get-NetLocalGroup error for $Server : $_"
                }
            }
        }
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
    catch { }
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








function New-ThreadedFunction {
    
    [CmdletBinding()]
    Param(
        [Parameter(Position = 0, Mandatory = $True, ValueFromPipeline = $True, ValueFromPipelineByPropertyName = $True)]
        [String[]]
        $ComputerName,

        [Parameter(Position = 1, Mandatory = $True)]
        [System.Management.Automation.ScriptBlock]
        $ScriptBlock,

        [Parameter(Position = 2)]
        [Hashtable]
        $ScriptParameters,

        [Int]
        [ValidateRange(1,  100)]
        $Threads = 20,

        [Switch]
        $NoImports
    )

    BEGIN {
        
        
        $SessionState = [System.Management.Automation.Runspaces.InitialSessionState]::CreateDefault()
        $SessionState.ApartmentState = [System.Threading.Thread]::CurrentThread.GetApartmentState()

        
        
        if (-not $NoImports) {
            
            $MyVars = Get-Variable -Scope 2

            
            $VorbiddenVars = @('?','args','ConsoleFileName','Error','ExecutionContext','false','HOME','Host','input','InputObject','MaximumAliasCount','MaximumDriveCount','MaximumErrorCount','MaximumFunctionCount','MaximumHistoryCount','MaximumVariableCount','MyInvocation','null','PID','PSBoundParameters','PSCommandPath','PSCulture','PSDefaultParameterValues','PSHOME','PSScriptRoot','PSUICulture','PSVersionTable','PWD','ShellId','SynchronizedHash','true')

            
            ForEach ($Var in $MyVars) {
                if ($VorbiddenVars -NotContains $Var.Name) {
                $SessionState.Variables.Add((New-Object -TypeName System.Management.Automation.Runspaces.SessionStateVariableEntry -ArgumentList $Var.name,$Var.Value,$Var.description,$Var.options,$Var.attributes))
                }
            }

            
            ForEach ($Function in (Get-ChildItem Function:)) {
                $SessionState.Commands.Add((New-Object -TypeName System.Management.Automation.Runspaces.SessionStateFunctionEntry -ArgumentList $Function.Name, $Function.Definition))
            }
        }

        
        
        

        
        $Pool = [RunspaceFactory]::CreateRunspacePool(1, $Threads, $SessionState, $Host)
        $Pool.Open()

        
        $Method = $Null
        ForEach ($M in [PowerShell].GetMethods() | Where-Object { $_.Name -eq 'BeginInvoke' }) {
            $MethodParameters = $M.GetParameters()
            if (($MethodParameters.Count -eq 2) -and $MethodParameters[0].Name -eq 'input' -and $MethodParameters[1].Name -eq 'output') {
                $Method = $M.MakeGenericMethod([Object], [Object])
                break
            }
        }

        $Jobs = @()
        $ComputerName = $ComputerName | Where-Object { $_ -and ($_ -ne '') }
        Write-Verbose "[New-ThreadedFunction] Total number of hosts: $($ComputerName.count)"

        
        if ($Threads -ge $ComputerName.Length) {
            $Threads = $ComputerName.Length
        }
        $ElementSplitSize = [Int]($ComputerName.Length/$Threads)
        $ComputerNamePartitioned = @()
        $Start = 0
        $End = $ElementSplitSize

        for($i = 1; $i -le $Threads; $i++) {
            $List = New-Object System.Collections.ArrayList
            if ($i -eq $Threads) {
                $End = $ComputerName.Length
            }
            $List.AddRange($ComputerName[$Start..($End-1)])
            $Start += $ElementSplitSize
            $End += $ElementSplitSize
            $ComputerNamePartitioned += @(,@($List.ToArray()))
        }

        Write-Verbose "[New-ThreadedFunction] Total number of threads/partitions: $Threads"

        ForEach ($ComputerNamePartition in $ComputerNamePartitioned) {
            
            $PowerShell = [PowerShell]::Create()
            $PowerShell.runspacepool = $Pool

            
            $Null = $PowerShell.AddScript($ScriptBlock).AddParameter('ComputerName', $ComputerNamePartition)
            if ($ScriptParameters) {
                ForEach ($Param in $ScriptParameters.GetEnumerator()) {
                    $Null = $PowerShell.AddParameter($Param.Name, $Param.Value)
                }
            }

            
            $Output = New-Object Management.Automation.PSDataCollection[Object]

            
            $Jobs += @{
                PS = $PowerShell
                Output = $Output
                Result = $Method.Invoke($PowerShell, @($Null, [Management.Automation.PSDataCollection[Object]]$Output))
            }
        }
    }

    END {
        Write-Verbose "[New-ThreadedFunction] Threads executing"
        
        
        Do {
            ForEach ($Job in $Jobs) {
                $Job.Output.ReadAll()
            }
            Start-Sleep -Seconds 1
        }
        While (($Jobs | Where-Object { -not $_.Result.IsCompleted }).Count -gt 0)
        Write-Verbose "[New-ThreadedFunction] Waiting 120 seconds for final cleanup..."
        Start-Sleep -Seconds 120

        
        ForEach ($Job in $Jobs) {
            $Job.Output.ReadAll()
            $Job.PS.Dispose()
        }

        $Pool.Dispose()
        Write-Verbose "[New-ThreadedFunction] all threads completed"
    }
}


function Get-GlobalCatalogUserMapping {

    [CmdletBinding()]
    param(
        [ValidatePattern('^GC://')]
        [String]
        $GlobalCatalog
    )

    if(-not $PSBoundParameters['GlobalCatalog']) {
        $GCPath = ([ADSI]'LDAP://RootDSE').dnshostname
        $ADSPath = "GC://$GCPath"
        Write-Verbose "Enumerated global catalog location: $ADSPath"
    }
    else {
        $ADSpath = $GlobalCatalog
    }

    $UserDomainMappings = @{}

    $UserSearcher = Get-DomainSearcher -ADSpath $ADSpath
    $UserSearcher.filter = '(samAccountType=805306368)'
    $UserSearcher.PropertiesToLoad.AddRange(('samaccountname','distinguishedname', 'cn', 'objectsid'))

    ForEach($User in $UserSearcher.FindAll()) {
        $UserName = $User.Properties['samaccountname'][0].ToUpper()
        $UserDN = $User.Properties['distinguishedname'][0]

        if($UserDN -and ($UserDN -ne '')) {
            if (($UserDN -match 'ForeignSecurityPrincipals') -and ($UserDN -match 'S-1-5-21')) {
                try {
                    if(-not $MemberSID) {
                        $MemberSID = $User.Properties['cn'][0]
                    }
                    $UserSid = (New-Object System.Security.Principal.SecurityIdentifier($User.Properties['objectsid'][0],0)).Value
                    $MemberSimpleName = Convert-SidToName -SID $UserSid | Convert-ADName -InputType 'NT4' -OutputType 'Canonical'
                    if($MemberSimpleName) {
                        $UserDomain = $MemberSimpleName.Split('/')[0]
                    }
                    else {
                        Write-Verbose "Error converting $UserDN"
                        $UserDomain = $Null
                    }
                }
                catch {
                    Write-Verbose "Error converting $UserDN"
                    $UserDomain = $Null
                }
            }
            else {
                
                $UserDomain = ($UserDN.subString($UserDN.IndexOf('DC=')) -replace 'DC=','' -replace ',','.').ToUpper()
            }
            if($UserDomain) {
                if(-not $UserDomainMappings[$UserName]) {
                    $UserDomainMappings[$UserName] = @($UserDomain)
                }
                elseif($UserDomainMappings[$UserName] -notcontains $UserDomain) {
                    $UserDomainMappings[$UserName] += $UserDomain
                }
            }
        }
    }

    $UserSearcher.dispose()
    $UserDomainMappings
}


function Invoke-BloodHound {


    [CmdletBinding(DefaultParameterSetName = 'CSVExport')]
    param(
        [Parameter(ValueFromPipeline=$True)]
        [Alias('HostName')]
        [String[]]
        [ValidateNotNullOrEmpty()]
        $ComputerName,

        [String]
        $ComputerADSpath,

        [String]
        $UserADSpath,

        [String]
        $Domain,

        [String]
        $DomainController,

        [String]
        [ValidateSet('Group', 'Containers', 'ACLs', 'ComputerOnly', 'LocalGroup', 'GPOLocalGroup', 'Session', 'LoggedOn', 'Stealth', 'Trusts', 'Default')]
        $CollectionMethod = 'Default',

        [Switch]
        $SearchForest,

        [Parameter(ParameterSetName = 'CSVExport')]
        [ValidateScript({ Test-Path -Path $_ })]
        [String]
        $CSVFolder = $(Get-Location),

        [Parameter(ParameterSetName = 'CSVExport')]
        [ValidateNotNullOrEmpty()]
        [String]
        $CSVPrefix,

        [Parameter(ParameterSetName = 'RESTAPI', Mandatory = $True)]
        [URI]
        $URI,

        [Parameter(ParameterSetName = 'RESTAPI', Mandatory = $True)]
        [String]
        [ValidatePattern('.*:.*')]
        $UserPass,

        [ValidatePattern('^GC://')]
        [String]
        $GlobalCatalog,

        [Switch]
        $SkipGCDeconfliction,

        [ValidateRange(1,50)]
        [Int]
        $Threads = 20,

        [ValidateRange(1,5000)]
        [Int]
        $Throttle = 1000
    )

    BEGIN {

        Switch ($CollectionMethod) {
            'Group'         { $UseGroup = $True; $SkipComputerEnumeration = $True; $SkipGCDeconfliction2 = $True }
            'Containers'    { $UseContainers = $True; $SkipComputerEnumeration = $True; $SkipGCDeconfliction2 = $True }
            'ACLs'          { $UseGroup = $False; $SkipComputerEnumeration = $True; $SkipGCDeconfliction2 = $True; $UseACLs = $True }
            'ComputerOnly'  { $UseGroup = $False; $UseLocalGroup = $True; $UseSession = $True; $UseLoggedOn = $True; $SkipGCDeconfliction2 = $False }
            'LocalGroup'    { $UseLocalGroup = $True; $SkipGCDeconfliction2 = $True }
            'GPOLocalGroup' { $UseGPOGroup = $True; $SkipComputerEnumeration = $True; $SkipGCDeconfliction2 = $True }
            'Session'       { $UseSession = $True; $SkipGCDeconfliction2 = $False }
            'LoggedOn'      { $UseLoggedOn = $True; $SkipGCDeconfliction2 = $True }
            'Trusts'        { $UseDomainTrusts = $True; $SkipComputerEnumeration = $True; $SkipGCDeconfliction2 = $True }
            'Stealth'       {
                $UseGroup = $True
                $UseContainers = $True
                $UseGPOGroup = $True
                $UseSession = $True
                $UseDomainTrusts = $True
                $SkipGCDeconfliction2 = $False
            }
            'Default'       {
                $UseGroup = $True
                $UseContainers = $True
                $UseLocalGroup = $True
                $UseSession = $True
                $UseLoggedOn = $False
                $UseDomainTrusts = $True
                $SkipGCDeconfliction2 = $False
            }
        }

        if($SkipGCDeconfliction) {
            $SkipGCDeconfliction2 = $True
        }

        $GCPath = ([ADSI]'LDAP://RootDSE').dnshostname
        $GCADSPath = "GC://$GCPath"

        
        
        
        $ACLGeneralRightsRegex = [regex] 'GenericAll|GenericWrite|WriteOwner|WriteDacl'

        if ($PSCmdlet.ParameterSetName -eq 'CSVExport') {
            try {
                $OutputFolder = $CSVFolder | Resolve-Path -ErrorAction Stop | Select-Object -ExpandProperty Path
            }
            catch {
                throw "Error: $_"
            }

            if($CSVPrefix) {
                $CSVExportPrefix = "$($CSVPrefix)_"
            }
            else {
                $CSVExportPrefix = ''
            }

            Write-Output "Writing output to CSVs in: $OutputFolder\$CSVExportPrefix"

            if($UseSession -or $UseLoggedon) {
                $SessionPath = "$OutputFolder\$($CSVExportPrefix)user_sessions.csv"
                $Exists = [System.IO.File]::Exists($SessionPath)
                $SessionFileStream = New-Object IO.FileStream($SessionPath, [System.IO.FileMode]::Append, [System.IO.FileAccess]::Write, [IO.FileShare]::Read)
                $SessionWriter = New-Object System.IO.StreamWriter($SessionFileStream)
                $SessionWriter.AutoFlush = $True
                if (-not $Exists) {
                    
                    $SessionWriter.WriteLine('"ComputerName","UserName","Weight"')
                }
            }

            if($UseGroup) {
                $GroupPath = "$OutputFolder\$($CSVExportPrefix)group_memberships.csv"
                $Exists = [System.IO.File]::Exists($GroupPath)
                $GroupFileStream = New-Object IO.FileStream($GroupPath, [System.IO.FileMode]::Append, [System.IO.FileAccess]::Write, [IO.FileShare]::Read)
                $GroupWriter = New-Object System.IO.StreamWriter($GroupFileStream)
                $GroupWriter.AutoFlush = $True
                if (-not $Exists) {
                    
                    $GroupWriter.WriteLine('"GroupName","AccountName","AccountType"')
                }
            }

            if($UseContainers) {
                $ContainerPath = "$OutputFolder\$($CSVExportPrefix)container_structure.csv"
                $Exists = [System.IO.File]::Exists($ContainerPath)
                $ContainerFileStream = New-Object IO.FileStream($ContainerPath, [System.IO.FileMode]::Append, [System.IO.FileAccess]::Write, [IO.FileShare]::Read)
                $ContainerWriter = New-Object System.IO.StreamWriter($ContainerFileStream)
                $ContainerWriter.AutoFlush = $True
                if (-not $Exists) {
                    
                    $ContainerWriter.WriteLine('"ContainerType","ContainerName","ContainerGUID","ContainerBlocksInheritence","ObjectType","ObjectName","ObjectGUIDorSID"')
                }

                $GPLinkPath = "$OutputFolder\$($CSVExportPrefix)container_gplinks.csv"
                $Exists = [System.IO.File]::Exists($GPLinkPath)
                $GPLinkFileStream = New-Object IO.FileStream($GPLinkPath, [System.IO.FileMode]::Append, [System.IO.FileAccess]::Write, [IO.FileShare]::Read)
                $GPLinkWriter = New-Object System.IO.StreamWriter($GPLinkFileStream)
                $GPLinkWriter.AutoFlush = $True
                if (-not $Exists) {
                    
                    $GPLinkWriter.WriteLine('"ObjectType","ObjectName","ObjectGUID","GPODisplayName","GPOGUID","IsEnforced"')
                }
            }

            if($UseACLs) {
                $ACLPath = "$OutputFolder\$($CSVExportPrefix)acls.csv"
                $Exists = [System.IO.File]::Exists($ACLPath)
                $ACLFileStream = New-Object IO.FileStream($ACLPath, [System.IO.FileMode]::Append, [System.IO.FileAccess]::Write, [IO.FileShare]::Read)
                $ACLWriter = New-Object System.IO.StreamWriter($ACLFileStream)
                $ACLWriter.AutoFlush = $True
                if (-not $Exists) {
                    
                    $ACLWriter.WriteLine('"ObjectName","ObjectType","ObjectGuid","PrincipalName","PrincipalType","ActiveDirectoryRights","ACEType","AccessControlType","IsInherited"')
                }
            }

            if($UseLocalGroup -or $UseGPOGroup) {
                $LocalAdminPath = "$OutputFolder\$($CSVExportPrefix)local_admins.csv"
                $Exists = [System.IO.File]::Exists($LocalAdminPath)
                $LocalAdminFileStream = New-Object IO.FileStream($LocalAdminPath, [System.IO.FileMode]::Append, [System.IO.FileAccess]::Write, [IO.FileShare]::Read)
                $LocalAdminWriter = New-Object System.IO.StreamWriter($LocalAdminFileStream)
                $LocalAdminWriter.AutoFlush = $True
                if (-not $Exists) {
                    
                    $LocalAdminWriter.WriteLine('"ComputerName","AccountName","AccountType"')
                }
            }

            if($UseDomainTrusts) {
                $TrustsPath = "$OutputFolder\$($CSVExportPrefix)trusts.csv"
                $Exists = [System.IO.File]::Exists($TrustsPath)
                $TrustsFileStream = New-Object IO.FileStream($TrustsPath, [System.IO.FileMode]::Append, [System.IO.FileAccess]::Write, [IO.FileShare]::Read)
                $TrustWriter = New-Object System.IO.StreamWriter($TrustsFileStream)
                $TrustWriter.AutoFlush = $True
                if (-not $Exists) {
                    
                    $TrustWriter.WriteLine('"SourceDomain","TargetDomain","TrustDirection","TrustType","Transitive"')
                }
            }
        }

        else {
            
            $WebClient = New-Object System.Net.WebClient

            $Base64UserPass = [System.Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes($UserPass))

            
            $WebClient.Headers.Add('Accept','application/json; charset=UTF-8')
            $WebClient.Headers.Add('Authorization',"Basic $Base64UserPass")

            
            try {
                $Null = $WebClient.DownloadString($URI.AbsoluteUri + 'user/neo4j')
                Write-Verbose "Connection established with neo4j ingestion interface at $($URI.AbsoluteUri)"
                $Authorized = $True
            }
            catch {
                $Authorized = $False
                throw "Error connecting to Neo4j rest REST server at '$($URI.AbsoluteUri)'"
            }

            Write-Output "Sending output to neo4j RESTful API interface at: $($URI.AbsoluteUri)"

            $Null = [Reflection.Assembly]::LoadWithPartialName("System.Web.Extensions")

            
            function ConvertTo-Json20([object] $Item){
                $ps_js = New-Object System.Web.Script.Serialization.javascriptSerializer
                return $ps_js.Serialize($item)
            }

            $Authorized = $True
            $Statements = New-Object System.Collections.ArrayList

            
            $Null = $Statements.Add( @{ "statement"="CREATE CONSTRAINT ON (c:User) ASSERT c.UserName IS UNIQUE" } )
            $Null = $Statements.Add( @{ "statement"="CREATE CONSTRAINT ON (c:Computer) ASSERT c.ComputerName IS UNIQUE"} )
            $Null = $Statements.Add( @{ "statement"="CREATE CONSTRAINT ON (c:Group) ASSERT c.GroupName IS UNIQUE" } )
            $Json = @{ "statements"=[System.Collections.Hashtable[]]$Statements }
            $JsonRequest = ConvertTo-Json20 $Json
            $Null = $WebClient.UploadString($URI.AbsoluteUri + "db/data/transaction/commit", $JsonRequest)
            $Statements.Clear()
        }

        $UserDomainMappings = @{}
        if(-not $SkipGCDeconfliction2) {
            
            
            if($PSBoundParameters['GlobalCatalog']) {
                $UserDomainMappings = Get-GlobalCatalogUserMapping -GlobalCatalog $GlobalCatalog
            }
            else {
                $UserDomainMappings = Get-GlobalCatalogUserMapping
            }
        }
        $DomainShortnameMappings = @{}

        if($Domain) {
            $TargetDomains = @($Domain)
        }
        elseif($SearchForest) {
            
            $TargetDomains = Get-NetForestDomain | Select-Object -ExpandProperty Name
        }
        else {
            
            $TargetDomains = @( (Get-NetDomain).Name )
        }

        if($UseGroup -and $TargetDomains) {
            $Title = (Get-Culture).TextInfo
            ForEach ($TargetDomain in $TargetDomains) {
                
                Write-Verbose "Enumerating group memberships for domain $TargetDomain"

                
                $GroupDNMappings = @{}
                $PrimaryGroups = @{}
                $DomainSID = Get-DomainSID -Domain $TargetDomain -DomainController $DomainController

                $ObjectSearcher = Get-DomainSearcher -Domain $TargetDomain -DomainController $DomainController -ADSPath $UserADSpath
                
                $ObjectSearcher.Filter = '(memberof=*)'
                
                $Null = $ObjectSearcher.PropertiesToLoad.AddRange(('samaccountname', 'distinguishedname', 'cn', 'dnshostname', 'samaccounttype', 'primarygroupid', 'memberof'))
                $Counter = 0
                $ObjectSearcher.FindAll() | ForEach-Object {
                    if($Counter % 1000 -eq 0) {
                        Write-Verbose "Group object counter: $Counter"
                        if($GroupWriter) {
                            $GroupWriter.Flush()
                        }
                        [GC]::Collect()
                    }
                    $Properties = $_.Properties

                    $MemberDN = $Null
                    $MemberDomain = $Null
                    try {
                        $MemberDN = $Properties['distinguishedname'][0]

                        if (($MemberDN -match 'ForeignSecurityPrincipals') -and ($MemberDN -match 'S-1-5-21')) {
                            try {
                                if(-not $MemberSID) {
                                    $MemberSID = $Properties.cn[0]
                                }
                                $MemberSimpleName = Convert-SidToName -SID $MemberSID | Convert-ADName -InputType 'NT4' -OutputType 'Canonical'
                                if($MemberSimpleName) {
                                    $MemberDomain = $MemberSimpleName.Split('/')[0]
                                }
                                else {
                                    Write-Verbose "Error converting $MemberDN"
                                }
                            }
                            catch {
                                Write-Verbose "Error converting $MemberDN"
                            }
                        }
                        else {
                            
                            $MemberDomain = $MemberDN.subString($MemberDN.IndexOf("DC=")) -replace 'DC=','' -replace ',','.'
                        }
                    }
                    catch {}

                    if (@('268435456','268435457','536870912','536870913') -contains $Properties['samaccounttype']) {
                        $ObjectType = 'group'
                        if($Properties['samaccountname']) {
                            $MemberName = $Properties['samaccountname'][0]
                        }
                        else {
                            
                            try {
                                $MemberName = Convert-SidToName $Properties['cn'][0]
                            }
                            catch {
                                
                                $MemberName = $Properties['cn'][0]
                            }
                        }
                        if ($MemberName -Match "\\") {
                            
                            
                            $AccountName = $MemberName.split('\')[1] + '@' + $MemberDomain
                        }
                        else {
                            $AccountName = "$MemberName@$MemberDomain"
                        }
                    }
                    elseif (@('805306369') -contains $Properties['samaccounttype']) {
                        $ObjectType = 'computer'
                        if ($Properties['dnshostname']) {
                            $AccountName = $Properties['dnshostname'][0]
                        }
                    }
                    elseif (@('805306368') -contains $Properties['samaccounttype']) {
                        $ObjectType = 'user'
                        if($Properties['samaccountname']) {
                            $MemberName = $Properties['samaccountname'][0]
                        }
                        else {
                            
                            try {
                                $MemberName = Convert-SidToName $Properties['cn'][0]
                            }
                            catch {
                                
                                $MemberName = $Properties['cn'][0]
                            }
                        }
                        if ($MemberName -Match "\\") {
                            
                            
                            $AccountName = $MemberName.split('\')[1] + '@' + $MemberDomain
                        }
                        else {
                            $AccountName = "$MemberName@$MemberDomain"
                        }
                    }
                    else {
                        Write-Verbose "Unknown account type for object $($Properties['distinguishedname']) : $($Properties['samaccounttype'])"
                    }

                    if($AccountName -and (-not $AccountName.StartsWith('@'))) {

                        
                        $MemberPrimaryGroupName = $Null
                        try {
                            if($AccountName -match $TargetDomain) {
                                
                                if($Properties['primarygroupid'] -and $Properties['primarygroupid'][0] -and ($Properties['primarygroupid'][0] -ne '')) {
                                    $PrimaryGroupSID = "$DomainSID-$($Properties['primarygroupid'][0])"
                                    
                                    if($PrimaryGroups[$PrimaryGroupSID]) {
                                        $PrimaryGroupName = $PrimaryGroups[$PrimaryGroupSID]
                                    }
                                    else {
                                        $RawName = Convert-SidToName -SID $PrimaryGroupSID
                                        if ($RawName -notmatch '^S-1-.*') {
                                            $PrimaryGroupName = $RawName.split('\')[-1]
                                            $PrimaryGroups[$PrimaryGroupSID] = $PrimaryGroupName
                                        }
                                    }
                                    if ($PrimaryGroupName) {
                                        $MemberPrimaryGroupName = "$PrimaryGroupName@$TargetDomain"
                                    }
                                }
                                else { }
                            }
                        }
                        catch { }

                        if($MemberPrimaryGroupName) {
                            
                            if ($PSCmdlet.ParameterSetName -eq 'CSVExport') {
                                $GroupWriter.WriteLine("`"$MemberPrimaryGroupName`",`"$AccountName`",`"$ObjectType`"")
                            }
                            else {
                                $ObjectTypeCap = $Title.ToTitleCase($ObjectType)
                                $Null = $Statements.Add( @{ "statement"="MERGE ($($ObjectType)1:$ObjectTypeCap { name: UPPER('$AccountName') }) MERGE (group2:Group { name: UPPER('$MemberPrimaryGroupName') }) MERGE ($($ObjectType)1)-[:MemberOf]->(group2)" } )
                            }
                        }

                        
                        ForEach($GroupDN in $_.properties['memberof']) {
                            $GroupDomain = $GroupDN.subString($GroupDN.IndexOf('DC=')) -replace 'DC=','' -replace ',','.'

                            if($GroupDNMappings[$GroupDN]) {
                                $GroupName = $GroupDNMappings[$GroupDN]
                            }
                            else {
                                $GroupName = Convert-ADName -ObjectName $GroupDN
                                if($GroupName) {
                                    $GroupName = $GroupName.Split('\')[-1]
                                }
                                else {
                                    $GroupName = $GroupDN.SubString(0, $GroupDN.IndexOf(',')).Split('=')[-1]
                                }
                                $GroupDNMappings[$GroupDN] = $GroupName
                            }

                            if ($PSCmdlet.ParameterSetName -eq 'CSVExport') {
                                $GroupWriter.WriteLine("`"$GroupName@$GroupDomain`",`"$AccountName`",`"$ObjectType`"")
                            }
                            else {
                                
                                $ObjectTypeCap = $Title.ToTitleCase($ObjectType)

                                $Null = $Statements.Add( @{ "statement"="MERGE ($($ObjectType)1:$ObjectTypeCap { name: UPPER('$AccountName') }) MERGE (group2:Group { name: UPPER('$GroupName@$GroupDomain') }) MERGE ($($ObjectType)1)-[:MemberOf]->(group2)" } )

                                if ($Statements.Count -ge $Throttle) {
                                    $Json = @{ "statements"=[System.Collections.Hashtable[]]$Statements }
                                    $JsonRequest = ConvertTo-Json20 $Json
                                    $Null = $WebClient.UploadString($URI.AbsoluteUri + "db/data/transaction/commit", $JsonRequest)
                                    $Statements.Clear()
                                }
                            }
                        }
                        $Counter += 1
                    }
                }
                $ObjectSearcher.Dispose()

                if ($PSCmdlet.ParameterSetName -eq 'RESTAPI') {
                    $Json = @{ "statements"=[System.Collections.Hashtable[]]$Statements }
                    $JsonRequest = ConvertTo-Json20 $Json
                    $Null = $WebClient.UploadString($URI.AbsoluteUri + "db/data/transaction/commit", $JsonRequest)
                    $Statements.Clear()
                }
                Write-Verbose "Done with group enumeration for domain $TargetDomain"
            }
            [GC]::Collect()
        }

        if ($UseContainers -and $TargetDomains) {
            ForEach ($TargetDomain in $TargetDomains) {
                Write-Verbose "Enumerating container memberships and gpLinks for domain: $TargetDomain"
                $OUs = New-Object System.Collections.Queue

                
                
                $GPOSearcher = Get-DomainSearcher -Domain $TargetDomain -DomainController $DomainController
                $GPOSearcher.filter="(&(objectCategory=groupPolicyContainer)(name=*)(gpcfilesyspath=*))"
                $GPOSearcher.PropertiesToLoad.AddRange(('displayname', 'name'))
                $GPOs = @{}

                ForEach($GPOResult in $GPOSearcher.FindAll()) {
                    $GPOdisplayName = $GPOResult.Properties['displayname'][0]
                    $GPOname = $GPOResult.Properties['name'][0]
                    $GPOName = $GPOName.Substring(1, $GPOName.Length-2)
                    $GPOs[$GPOname] = $GPOdisplayName
                }

                
                $DomainSearcher = Get-DomainSearcher -Domain $TargetDomain -DomainController $DomainController
                $DomainSearcher.SearchScope = 'Base'
                $Null = $DomainSearcher.PropertiesToLoad.AddRange(('gplink', 'objectguid'))
                $DomainObject = $DomainSearcher.FindOne()
                $DomainGUID = (New-Object Guid (,$DomainObject.Properties['objectguid'][0])).Guid

                if ($DomainObject.Properties['gplink']) {
                    $DomainObject.Properties['gplink'][0].split('][') | ForEach-Object {
                        if ($_.startswith('LDAP')) {
                            $Parts = $_.split(';')
                            $GPODN = $Parts[0]
                            if ($Parts[1] -eq 2) { $Enforced = $True }
                            else { $Enforced = $False }

                            $i = $GPODN.IndexOf("CN=")+4
                            $GPOName = $GPODN.subString($i, $i+25)
                            $GPODisplayName = $GPOs[$GPOname]
                            $GPLinkWriter.WriteLine("`"domain`",`"$TargetDomain`",`"$DomainGUID`",`"$GPODisplayName`",`"$GPOName`",`"$Enforced`"")
                        }
                    }
                }

                
                
                $DomainSearcher.SearchScope = 'OneLevel'
                $Null = $DomainSearcher.PropertiesToLoad.AddRange(('name'))
                $DomainSearcher.Filter = "(objectClass=container)"
                $DomainSearcher.FindAll() | ForEach-Object {
                    $ContainerName = ,$_.Properties['name'][0]
                    $ContainerPath = $_.Properties['adspath']
                    Write-Verbose "ContainerPath: $ContainerPath"

                    $ContainerSearcher = Get-DomainSearcher -ADSpath $ContainerPath

                    $Null = $ContainerSearcher.PropertiesToLoad.AddRange(('name', 'objectsid', 'samaccounttype'))
                    $ContainerSearcher.Filter = '(|(samAccountType=805306368)(samAccountType=805306369))'
                    $ContainerSearcher.SearchScope = 'SubTree'

                    $ContainerSearcher.FindAll() | ForEach-Object {
                        $ObjectName = ,$_.Properties['name'][0]
                        Write-Verbose "ObjectName: $ObjectName"
                        if ( (,$_.Properties['samaccounttype'][0]) -eq '805306368') {
                            $ObjectType = 'user'
                        }
                        else {
                            $ObjectType = 'computer'
                        }
                        $ObjectSID = (New-Object System.Security.Principal.SecurityIdentifier($_.Properties['objectsid'][0],0)).Value
                        $ContainerWriter.WriteLine("`"domain`",`"$TargetDomain`",`"$DomainGUID`",`"$False`",`"$ObjectType`",`"$ObjectName`",`"$ObjectSID`"")
                    }
                    $ContainerSearcher.Dispose()
                }

                
                $DomainSearcher.SearchScope = 'OneLevel'
                $Null = $DomainSearcher.PropertiesToLoad.AddRange(('name', 'objectguid', 'gplink'))
                $DomainSearcher.Filter = "(objectCategory=organizationalUnit)"
                $DomainSearcher.FindAll() | ForEach-Object {
                    $OUGuid = (New-Object Guid (,$_.Properties['objectguid'][0])).Guid
                    $OUName = ,$_.Properties['name'][0]

                    $ContainerWriter.WriteLine("`"domain`",`"$TargetDomain`",`"$DomainGUID`",`"$False`",`"ou`",`"$OUName`",`"$OUGuid`"")

                    $OUs.Enqueue($_.Properties['adspath'])
                }
                $DomainSearcher.Dispose()

                while ($OUs.Count -gt 0) {
                    
                    $ADSPath = $OUs.Dequeue()
                    Write-Verbose "Enumerating OU: '$ADSPath'"

                    
                    $DomainSearcher = Get-DomainSearcher -ADSpath $ADSPath
                    $Null = $DomainSearcher.PropertiesToLoad.AddRange(('name', 'objectguid', 'gplink', 'gpoptions'))
                    $DomainSearcher.SearchScope = 'Base'
                    $OU = $DomainSearcher.FindOne()
                    $OUGuid = (New-Object Guid (,$OU.Properties['objectguid'][0])).Guid
                    $OUName = ,$OU.Properties['name'][0]
                    $ContainerBlocksInheritence = $False
                    if ($OU.Properties['gpoptions'] -and ($OU.Properties['gpoptions'] -eq 1)) {
                        $ContainerBlocksInheritence = $True
                    }

                    
                    if ($OU.Properties['gplink'] -and $OU.Properties['gplink'][0]) {
                        $OU.Properties['gplink'][0].split('][') | ForEach-Object {
                            if ($_.startswith('LDAP')) {
                                $Parts = $_.split(';')
                                $GPODN = $Parts[0]
                                if ($Parts[1] -eq 2) { $Enforced = $True }
                                else { $Enforced = $False }

                                $i = $GPODN.IndexOf('CN=', [System.StringComparison]::CurrentCultureIgnoreCase)+4
                                $GPOName = $GPODN.SubString($i, $i+25)
                                $GPODisplayName = $GPOs[$GPOname]
                                $GPLinkWriter.WriteLine("`"ou`",`"$OUName`",`"$OUGuid`",`"$GPODisplayName`",`"$GPOName`",`"$Enforced`"")
                            }
                        }
                    }

                    
                    $Null = $DomainSearcher.PropertiesToLoad.AddRange(('name', 'objectsid', 'objectguid', 'gplink', 'gpoptions', 'objectclass'))
                    $DomainSearcher.Filter = '(|(samAccountType=805306368)(samAccountType=805306369)(objectclass=organizationalUnit))'
                    $DomainSearcher.SearchScope = 'OneLevel'

                    $DomainSearcher.FindAll() | ForEach-Object {
                        if ($_.Properties['objectclass'] -contains 'organizationalUnit') {
                            $SubOUName = ,$_.Properties['name'][0]
                            $SubOUGuid = (New-Object Guid (,$_.Properties['objectguid'][0])).Guid
                            $ContainerWriter.WriteLine("`"ou`",`"$OUName`",`"$OUGuid`",`"$ContainerBlocksInheritence`",`"ou`",`"$SubOUName`",`"$SubOUGuid`"")
                            $OUs.Enqueue($_.Properties['adspath'])
                        }
                        elseif ($_.Properties['objectclass'] -contains 'computer') {
                            $SubComputerName = ,$_.Properties['name'][0]
                            $SubComputerSID = (New-Object System.Security.Principal.SecurityIdentifier($_.Properties['objectsid'][0],0)).Value
                            $ContainerWriter.WriteLine("`"ou`",`"$OUName`",`"$OUGuid`",`"$ContainerBlocksInheritence`",`"computer`",`"$SubComputerName`",`"$SubComputerSID`"")
                        }
                        else {
                            $SubUserName = ,$_.Properties['name'][0]
                            $SubUserSID = (New-Object System.Security.Principal.SecurityIdentifier($_.Properties['objectsid'][0],0)).Value
                            $ContainerWriter.WriteLine("`"ou`",`"$OUName`",`"$OUGuid`",`"$ContainerBlocksInheritence`",`"user`",`"$SubUserName`",`"$SubUserSID`"")
                        }
                    }

                    $DomainSearcher.Dispose()
                }

                Write-Verbose "Done with container memberships and gpLink enumeration for domain: $TargetDomain"
            }
            [GC]::Collect()
        }

        if($UseACLs -and $TargetDomains) {

            
            $PrincipalMapping = @{}
            $Counter = 0

            
            $CommonSidMapping = @{
                'S-1-0'         = @('Null Authority', 'USER')
                'S-1-0-0'       = @('Nobody', 'USER')
                'S-1-1'         = @('World Authority', 'USER')
                'S-1-1-0'       = @('Everyone', 'GROUP')
                'S-1-2'         = @('Local Authority', 'USER')
                'S-1-2-0'       = @('Local', 'GROUP')
                'S-1-2-1'       = @('Console Logon', 'GROUP')
                'S-1-3'         = @('Creator Authority', 'USER')
                'S-1-3-0'       = @('Creator Owner', 'USER')
                'S-1-3-1'       = @('Creator Group', 'GROUP')
                'S-1-3-2'       = @('Creator Owner Server', 'COMPUTER')
                'S-1-3-3'       = @('Creator Group Server', 'COMPUTER')
                'S-1-3-4'       = @('Owner Rights', 'GROUP')
                'S-1-4'         = @('Non-unique Authority', 'USER')
                'S-1-5'         = @('NT Authority', 'USER')
                'S-1-5-1'       = @('Dialup', 'GROUP')
                'S-1-5-2'       = @('Network', 'GROUP')
                'S-1-5-3'       = @('Batch', 'GROUP')
                'S-1-5-4'       = @('Interactive', 'GROUP')
                'S-1-5-6'       = @('Service', 'GROUP')
                'S-1-5-7'       = @('Anonymous', 'GROUP')
                'S-1-5-8'       = @('Proxy', 'GROUP')
                'S-1-5-9'       = @('Enterprise Domain Controllers', 'GROUP')
                'S-1-5-10'      = @('Principal Self', 'USER')
                'S-1-5-11'      = @('Authenticated Users', 'GROUP')
                'S-1-5-12'      = @('Restricted Code', 'GROUP')
                'S-1-5-13'      = @('Terminal Server Users', 'GROUP')
                'S-1-5-14'      = @('Remote Interactive Logon', 'GROUP')
                'S-1-5-15'      = @('This Organization ', 'GROUP')
                'S-1-5-17'      = @('This Organization ', 'GROUP')
                'S-1-5-18'      = @('Local System', 'USER')
                'S-1-5-19'      = @('NT Authority', 'USER')
                'S-1-5-20'      = @('NT Authority', 'USER')
                'S-1-5-80-0'    = @('All Services ', 'GROUP')
                'S-1-5-32-544'  = @('Administrators', 'GROUP')
                'S-1-5-32-545'  = @('Users', 'GROUP')
                'S-1-5-32-546'  = @('Guests', 'GROUP')
                'S-1-5-32-547'  = @('Power Users', 'GROUP')
                'S-1-5-32-548'  = @('Account Operators', 'GROUP')
                'S-1-5-32-549'  = @('Server Operators', 'GROUP')
                'S-1-5-32-550'  = @('Print Operators', 'GROUP')
                'S-1-5-32-551'  = @('Backup Operators', 'GROUP')
                'S-1-5-32-552'  = @('Replicators', 'GROUP')
                'S-1-5-32-554'  = @('Pre-Windows 2000 Compatible Access', 'GROUP')
                'S-1-5-32-555'  = @('Remote Desktop Users', 'GROUP')
                'S-1-5-32-556'  = @('Network Configuration Operators', 'GROUP')
                'S-1-5-32-557'  = @('Incoming Forest Trust Builders', 'GROUP')
                'S-1-5-32-558'  = @('Performance Monitor Users', 'GROUP')
                'S-1-5-32-559'  = @('Performance Log Users', 'GROUP')
                'S-1-5-32-560'  = @('Windows Authorization Access Group', 'GROUP')
                'S-1-5-32-561'  = @('Terminal Server License Servers', 'GROUP')
                'S-1-5-32-562'  = @('Distributed COM Users', 'GROUP')
                'S-1-5-32-569'  = @('Cryptographic Operators', 'GROUP')
                'S-1-5-32-573'  = @('Event Log Readers', 'GROUP')
                'S-1-5-32-574'  = @('Certificate Service DCOM Access', 'GROUP')
                'S-1-5-32-575'  = @('RDS Remote Access Servers', 'GROUP')
                'S-1-5-32-576'  = @('RDS Endpoint Servers', 'GROUP')
                'S-1-5-32-577'  = @('RDS Management Servers', 'GROUP')
                'S-1-5-32-578'  = @('Hyper-V Administrators', 'GROUP')
                'S-1-5-32-579'  = @('Access Control Assistance Operators', 'GROUP')
                'S-1-5-32-580'  = @('Access Control Assistance Operators', 'GROUP')
            }

            ForEach ($TargetDomain in $TargetDomains) {
                
                Write-Verbose "Enumerating ACLs for objects in domain: $TargetDomain"

                $ObjectSearcher = Get-DomainSearcher -Domain $TargetDomain -DomainController $DomainController -ADSPath $UserADSpath
                $ObjectSearcher.SecurityMasks = [System.DirectoryServices.SecurityMasks]'Dacl,Owner'

                
                
                
                
                
                $ObjectSearcher.Filter = '(|(samAccountType=805306368)(samAccountType=805306369)(samAccountType=268435456)(samAccountType=268435457)(samAccountType=536870912)(samAccountType=536870913)(objectCategory=groupPolicyContainer))'
                $ObjectSearcher.PropertiesToLoad.AddRange(('distinguishedName','samaccountname','dnshostname','displayname','objectclass','objectsid','name','ntsecuritydescriptor'))

                $ObjectSearcher.FindAll() | ForEach-Object {
                    $Object = $_.Properties
                    if($Object -and $Object.distinguishedname -and $Object.distinguishedname[0]) {
                        $DN = $Object.distinguishedname[0]
                        $ObjectDomain = $DN.SubString($DN.IndexOf('DC=')) -replace 'DC=','' -replace ',','.'
                        $ObjectName, $ObjectADType, $ObjectGuid = $Null
                        if ($Object.objectclass.contains('computer')) {
                            $ObjectADType = 'COMPUTER'
                            if ($Object.dnshostname) {
                                $ObjectName = $Object.dnshostname[0]
                            }
                        }
                        elseif ($Object.objectclass.contains('groupPolicyContainer')) {
                            $ObjectADType = 'GPO'
                            $ObjectGuid = $Object.name[0].trim('{}')
                            $ObjectDisplayName = $Object.displayname[0]
                            $ObjectName = "$ObjectDisplayName@$ObjectDomain"
                        }
                        else {
                            if($Object.samaccountname) {
                                $ObjectSamAccountName = $Object.samaccountname[0]
                            }
                            else {
                                $ObjectSamAccountName = $Object.name[0]
                            }
                            $ObjectName = "$ObjectSamAccountName@$ObjectDomain"

                            if ($Object.objectclass.contains('group')) {
                                $ObjectADType = 'GROUP'
                            }
                            elseif ($Object.objectclass.contains('user')) {
                                $ObjectADType = 'USER'
                            }
                            else {
                                $ObjectADType = 'OTHER'
                            }
                        }

                        if ($ObjectName -and $ObjectADType) {
                            try {
                                
                                $SecDesc = New-Object -TypeName Security.AccessControl.RawSecurityDescriptor -ArgumentList $Object['ntsecuritydescriptor'][0], 0
                                $SecDesc| Select-Object -Expand DiscretionaryAcl | ForEach-Object {
                                    $Counter += 1
                                    if($Counter % 10000 -eq 0) {
                                        Write-Verbose "ACE counter: $Counter"
                                        if($ACLWriter) {
                                            $ACLWriter.Flush()
                                        }
                                        [GC]::Collect()
                                    }

                                    $RawActiveDirectoryRights = ([Enum]::ToObject([System.DirectoryServices.ActiveDirectoryRights], $_.AccessMask))

                                    
                                    
                                    
                                    
                                    
                                    
                                    
                                    
                                    
                                    
                                    
                                    if (
                                            ( ($RawActiveDirectoryRights -match 'GenericAll|GenericWrite') -and (-not $_.ObjectAceType -or $_.ObjectAceType -eq '00000000-0000-0000-0000-000000000000') ) -or 
                                            ( ($RawActiveDirectoryRights -match 'WriteProperty') -and (-not $_.ObjectAceType -or $_.ObjectAceType -eq '00000000-0000-0000-0000-000000000000') ) -or 
                                            ( ($RawActiveDirectoryRights -match 'ExtendedRight') -and (-not $_.ObjectAceType -or $_.ObjectAceType -eq '00000000-0000-0000-0000-000000000000') ) -or 
                                            ($RawActiveDirectoryRights -match 'WriteDacl|WriteOwner') -or 
                                            (($_.ObjectAceType -eq '00299570-246d-11d0-a768-00aa006e0529') -and ($RawActiveDirectoryRights -match 'ExtendedRight')) -or
                                            (($_.ObjectAceType -eq 'bf9679c0-0de6-11d0-a285-00aa003049e2') -and ($RawActiveDirectoryRights -match 'WriteProperty')) -or
                                            (($_.ObjectAceType -eq 'bf9679a8-0de6-11d0-a285-00aa003049e2') -and ($RawActiveDirectoryRights -match 'WriteProperty')) -or
                                            (($_.ObjectAceType -eq 'f30e3bc1-9ff0-11d1-b603-0000f80367c1') -and ($RawActiveDirectoryRights -match 'WriteProperty'))
                                        ) {

                                        $PrincipalSid = $_.SecurityIdentifier.ToString()
                                        $PrincipalSimpleName, $PrincipalObjectClass, $ACEType = $Null

                                        
                                        
                                        $ActiveDirectoryRights = $ACLGeneralRightsRegex.Matches($RawActiveDirectoryRights) | Select-Object -ExpandProperty Value
                                        if (-not $ActiveDirectoryRights) {
                                            if ($RawActiveDirectoryRights -match 'ExtendedRight') {
                                                $ActiveDirectoryRights = 'ExtendedRight'
                                            }
                                            else {
                                                $ActiveDirectoryRights = 'WriteProperty'
                                            }

                                            
                                            $ACEType = Switch ($_.ObjectAceType) {
                                                '00299570-246d-11d0-a768-00aa006e0529' {'User-Force-Change-Password'}
                                                'bf9679c0-0de6-11d0-a285-00aa003049e2' {'Member'}
                                                'bf9679a8-0de6-11d0-a285-00aa003049e2' {'Script-Path'}
                                                'f30e3bc1-9ff0-11d1-b603-0000f80367c1' {'GPC-File-Sys-Path'}
                                                Default {'All'}
                                            }
                                        }

                                        if ($PrincipalMapping[$PrincipalSid]) {
                                            
                                            $PrincipalSimpleName, $PrincipalObjectClass = $PrincipalMapping[$PrincipalSid]
                                        }
                                        elseif ($CommonSidMapping[$PrincipalSid]) {
                                            $PrincipalName, $PrincipalObjectClass = $CommonSidMapping[$PrincipalSid]
                                            $PrincipalSimpleName = "$PrincipalName@$TargetDomain"
                                            $PrincipalMapping[$PrincipalSid] = $PrincipalSimpleName, $PrincipalObjectClass
                                        }
                                        else {
                                            
                                            $SIDSearcher = Get-DomainSearcher -Domain $TargetDomain -DomainController $DomainController
                                            $SIDSearcher.PropertiesToLoad.AddRange(('samaccountname','distinguishedname','dnshostname','objectclass'))
                                            $SIDSearcher.Filter = "(objectsid=$PrincipalSid)"
                                            $PrincipalObject = $SIDSearcher.FindOne()

                                            if ((-not $PrincipalObject) -and ((-not $DomainController) -or (-not $DomainController.StartsWith('GC:')))) {
                                                
                                                $GCSearcher = Get-DomainSearcher -ADSpath $GCADSPath
                                                $GCSearcher.PropertiesToLoad.AddRange(('samaccountname','distinguishedname','dnshostname','objectclass'))
                                                $GCSearcher.Filter = "(objectsid=$PrincipalSid)"
                                                $PrincipalObject = $GCSearcher.FindOne()
                                            }

                                            if ($PrincipalObject) {
                                                if ($PrincipalObject.Properties.objectclass.contains('computer')) {
                                                    $PrincipalObjectClass = 'COMPUTER'
                                                    $PrincipalSimpleName = $PrincipalObject.Properties.dnshostname[0]
                                                }
                                                else {
                                                    $PrincipalSamAccountName = $PrincipalObject.Properties.samaccountname[0]
                                                    $PrincipalDN = $PrincipalObject.Properties.distinguishedname[0]
                                                    $PrincipalDomain = $PrincipalDN.SubString($PrincipalDN.IndexOf('DC=')) -replace 'DC=','' -replace ',','.'
                                                    $PrincipalSimpleName = "$PrincipalSamAccountName@$PrincipalDomain"

                                                    if ($PrincipalObject.Properties.objectclass.contains('group')) {
                                                        $PrincipalObjectClass = 'GROUP'
                                                    }
                                                    elseif ($PrincipalObject.Properties.objectclass.contains('user')) {
                                                        $PrincipalObjectClass = 'USER'
                                                    }
                                                    else {
                                                        $PrincipalObjectClass = 'OTHER'
                                                    }
                                                }
                                            }
                                            else {
                                                Write-Verbose "SID not resolved: $PrincipalSid"
                                            }

                                            $PrincipalMapping[$PrincipalSid] = $PrincipalSimpleName, $PrincipalObjectClass
                                        }

                                        if ($PrincipalSimpleName -and $PrincipalObjectClass) {
                                            if ($PSCmdlet.ParameterSetName -eq 'CSVExport') {
                                                
                                                $ACLWriter.WriteLine("`"$ObjectName`",`"$ObjectADType`",`"$ObjectGuid`",`"$PrincipalSimpleName`",`"$PrincipalObjectClass`",`"$ActiveDirectoryRights`",`"$ACEType`",`"$($_.AceQualifier)`",`"$($_.IsInherited)`"")
                                            }
                                            else {
                                                Write-Warning 'TODO: implement neo4j RESTful API ingestion for ACLs!'
                                            }
                                        }
                                    }
                                }
                                $SecDesc | Select-Object -Expand Owner | ForEach-Object {
                                    
                                    $Counter += 1
                                    if($Counter % 10000 -eq 0) {
                                        Write-Verbose "ACE counter: $Counter"
                                        if($ACLWriter) {
                                            $ACLWriter.Flush()
                                        }
                                        [GC]::Collect()
                                    }

                                    if ($_ -and $_.Value) {
                                        $PrincipalSid = $_.Value
                                        $PrincipalSimpleName, $PrincipalObjectClass, $ACEType = $Null

                                        if ($PrincipalMapping[$PrincipalSid]) {
                                            
                                            $PrincipalSimpleName, $PrincipalObjectClass = $PrincipalMapping[$PrincipalSid]
                                        }
                                        elseif ($CommonSidMapping[$PrincipalSid]) {
                                            $PrincipalName, $PrincipalObjectClass = $CommonSidMapping[$PrincipalSid]
                                            $PrincipalSimpleName = "$PrincipalName@$TargetDomain"
                                            $PrincipalMapping[$PrincipalSid] = $PrincipalSimpleName, $PrincipalObjectClass
                                        }
                                        else {
                                            
                                            $SIDSearcher = Get-DomainSearcher -Domain $TargetDomain -DomainController $DomainController
                                            $SIDSearcher.PropertiesToLoad.AddRange(('samaccountname','distinguishedname','dnshostname','objectclass'))
                                            $SIDSearcher.Filter = "(objectsid=$PrincipalSid)"
                                            $PrincipalObject = $SIDSearcher.FindOne()

                                            if ((-not $PrincipalObject) -and ((-not $DomainController) -or (-not $DomainController.StartsWith('GC:')))) {
                                                
                                                $GCSearcher = Get-DomainSearcher -ADSpath $GCADSPath
                                                $GCSearcher.PropertiesToLoad.AddRange(('samaccountname','distinguishedname','dnshostname','objectclass'))
                                                $GCSearcher.Filter = "(objectsid=$PrincipalSid)"
                                                $PrincipalObject = $GCSearcher.FindOne()
                                            }

                                            if ($PrincipalObject) {
                                                if ($PrincipalObject.Properties.objectclass.contains('computer')) {
                                                    $PrincipalObjectClass = 'COMPUTER'
                                                    $PrincipalSimpleName = $PrincipalObject.Properties.dnshostname[0]
                                                }
                                                else {
                                                    $PrincipalSamAccountName = $PrincipalObject.Properties.samaccountname[0]
                                                    $PrincipalDN = $PrincipalObject.Properties.distinguishedname[0]
                                                    $PrincipalDomain = $PrincipalDN.SubString($PrincipalDN.IndexOf('DC=')) -replace 'DC=','' -replace ',','.'
                                                    $PrincipalSimpleName = "$PrincipalSamAccountName@$PrincipalDomain"

                                                    if ($PrincipalObject.Properties.objectclass.contains('group')) {
                                                        $PrincipalObjectClass = 'GROUP'
                                                    }
                                                    elseif ($PrincipalObject.Properties.objectclass.contains('user')) {
                                                        $PrincipalObjectClass = 'USER'
                                                    }
                                                    else {
                                                        $PrincipalObjectClass = 'OTHER'
                                                    }
                                                }
                                            }
                                            else {
                                                Write-Verbose "SID not resolved: $PrincipalSid"
                                            }

                                            $PrincipalMapping[$PrincipalSid] = $PrincipalSimpleName, $PrincipalObjectClass
                                        }

                                        if ($PrincipalSimpleName -and $PrincipalObjectClass) {
                                            if ($PSCmdlet.ParameterSetName -eq 'CSVExport') {
                                                
                                                $ACLWriter.WriteLine("`"$ObjectName`",`"$ObjectADType`",`"$ObjectGuid`",`"$PrincipalSimpleName`",`"$PrincipalObjectClass`",`"Owner`",`"`",`"AccessAllowed`",`"False`"")
                                            }
                                            else {
                                                Write-Warning 'TODO: implement neo4j RESTful API ingestion for ACLs!'
                                            }
                                        }
                                    }
                                }
                            }
                            catch {
                                Write-Verbose "ACL ingestion error: $_"
                            }
                        }
                    }
                }
            }
        }

        if($UseDomainTrusts -and $TargetDomains) {
            Write-Verbose "Mapping domain trusts"
            Invoke-MapDomainTrust | ForEach-Object {
                if($_.SourceDomain) {
                    $SourceDomain = $_.SourceDomain
                }
                else {
                    $SourceDomain = $_.SourceName
                }
                if($_.TargetDomain) {
                    $TargetDomain = $_.TargetDomain
                }
                else {
                    $TargetDomain = $_.TargetName
                }

                if ($PSCmdlet.ParameterSetName -eq 'CSVExport') {
                    $TrustWriter.WriteLine("`"$SourceDomain`",`"$TargetDomain`",`"$($_.TrustDirection)`",`"$($_.TrustType)`",`"$True`"")
                }
                else {
                    $Null = $Statements.Add( @{ "statement"="MERGE (SourceDomain:Domain { name: UPPER('$SourceDomain') }) MERGE (TargetDomain:Domain { name: UPPER('$TargetDomain') })" } )

                    $TrustType = $_.TrustType
                    $Transitive = $True

                    Switch ($_.TrustDirection) {
                        'Inbound' {
                             $Null = $Statements.Add( @{ "statement"="MERGE (SourceDomain)-[:TrustedBy{ TrustType: UPPER('$TrustType'), Transitive: UPPER('$Transitive')}]->(TargetDomain)" } )
                        }
                        'Outbound' {
                             $Null = $Statements.Add( @{ "statement"="MERGE (TargetDomain)-[:TrustedBy{ TrustType: UPPER('$TrustType'), Transitive: UPPER('$Transitive')}]->(SourceDomain)" } )
                        }
                        'Bidirectional' {
                             $Null = $Statements.Add( @{ "statement"="MERGE (TargetDomain)-[:TrustedBy{ TrustType: UPPER('$TrustType'), Transitive: UPPER('$Transitive')}]->(SourceDomain) MERGE (SourceDomain)-[:TrustedBy{ TrustType: UPPER('$TrustType'), Transitive: UPPER('$Transitive')}]->(TargetDomain)" } )
                        }
                    }

                }
            }
            if ($PSCmdlet.ParameterSetName -eq 'RESTAPI') {
                $Json = @{ "statements"=[System.Collections.Hashtable[]]$Statements }
                $JsonRequest = ConvertTo-Json20 $Json
                $Null = $WebClient.UploadString($URI.AbsoluteUri + "db/data/transaction/commit", $JsonRequest)
                $Statements.Clear()
            }
            Write-Verbose "Done mapping domain trusts"
        }

        if($UseGPOGroup -and $TargetDomains) {
            ForEach ($TargetDomain in $TargetDomains) {

                Write-Verbose "Enumerating GPO local group memberships for domain $TargetDomain"
                Find-GPOLocation -Domain $TargetDomain -DomainController $DomainController | ForEach-Object {
                    $AccountName = "$($_.ObjectName)@$($_.ObjectDomain)"
                    ForEach($Computer in $_.ComputerName) {
                        if($_.IsGroup) {
                            if ($PSCmdlet.ParameterSetName -eq 'CSVExport') {
                                $LocalAdminWriter.WriteLine("`"$Computer`",`"$AccountName`",`"group`"")
                            }
                            else {
                                $Null = $Statements.Add( @{"statement"="MERGE (group:Group { name: UPPER('$AccountName') }) MERGE (computer:Computer { name: UPPER('$Computer') }) MERGE (group)-[:AdminTo]->(computer)" } )
                            }
                        }
                        else {
                            if ($PSCmdlet.ParameterSetName -eq 'CSVExport') {
                                $LocalAdminWriter.WriteLine("`"$Computer`",`"$AccountName`",`"user`"")
                            }
                            else {
                                $Null = $Statements.Add( @{"statement"="MERGE (user:User { name: UPPER('$AccountName') }) MERGE (computer:Computer { name: UPPER('$Computer') }) MERGE (user)-[:AdminTo]->(computer)" } )
                            }
                        }
                    }
                }
                Write-Verbose "Done enumerating GPO local group memberships for domain $TargetDomain"
            }
            Write-Verbose "Done enumerating GPO local group"
            
        }

        
        $CurrentUser = ([Environment]::UserName).toLower()

        
        $HostEnumBlock = {
            Param($ComputerName, $CurrentUser2, $UseLocalGroup2, $UseSession2, $UseLoggedon2, $DomainSID2)

            ForEach ($TargetComputer in $ComputerName) {
                $Up = Test-Connection -Count 1 -Quiet -ComputerName $TargetComputer
                if($Up) {
                    if($UseLocalGroup2) {
                        
                        $Results = Get-NetLocalGroup -ComputerName $TargetComputer -API -IsDomain -DomainSID $DomainSID2
                        if($Results) {
                            $Results
                        }
                        else {
                            Get-NetLocalGroup -ComputerName $TargetComputer -IsDomain -DomainSID $DomainSID2
                        }
                    }

                    $IPAddress = @(Get-IPAddress -ComputerName $TargetComputer)[0].IPAddress

                    if($UseSession2) {
                        ForEach ($Session in $(Get-NetSession -ComputerName $TargetComputer)) {
                            $UserName = $Session.sesi10_username
                            $CName = $Session.sesi10_cname

                            if($CName -and $CName.StartsWith("\\")) {
                                $CName = $CName.TrimStart("\")
                            }

                            
                            if (($UserName) -and ($UserName.trim() -ne '') -and ($UserName -notmatch '\$') -and ($UserName -notmatch $CurrentUser2)) {
                                
                                try {
                                    $CNameDNSName = [System.Net.Dns]::GetHostEntry($CName) | Select-Object -ExpandProperty HostName
                                }
                                catch {
                                    $CNameDNSName = $CName
                                }
                                @{
                                    'UserDomain' = $Null
                                    'UserName' = $UserName
                                    'ComputerName' = $TargetComputer
                                    'IPAddress' = $IPAddress
                                    'SessionFrom' = $CName
                                    'SessionFromName' = $CNameDNSName
                                    'LocalAdmin' = $Null
                                    'Type' = 'UserSession'
                                }
                            }
                        }
                    }

                    if($UseLoggedon2) {
                        ForEach ($User in $(Get-NetLoggedon -ComputerName $TargetComputer)) {
                            $UserName = $User.wkui1_username
                            $UserDomain = $User.wkui1_logon_domain

                            
                            if($TargetComputer -notmatch "^$UserDomain") {
                                if (($UserName) -and ($UserName.trim() -ne '') -and ($UserName -notmatch '\$')) {
                                    @{
                                        'UserDomain' = $UserDomain
                                        'UserName' = $UserName
                                        'ComputerName' = $TargetComputer
                                        'IPAddress' = $IPAddress
                                        'SessionFrom' = $Null
                                        'SessionFromName' = $Null
                                        'LocalAdmin' = $Null
                                        'Type' = 'UserSession'
                                    }
                                }
                            }
                        }

                        ForEach ($User in $(Get-LoggedOnLocal -ComputerName $TargetComputer)) {
                            $UserName = $User.UserName
                            $UserDomain = $User.UserDomain

                            
                            if($TargetComputer -notmatch "^$UserDomain") {
                                @{
                                    'UserDomain' = $UserDomain
                                    'UserName' = $UserName
                                    'ComputerName' = $TargetComputer
                                    'IPAddress' = $IPAddress
                                    'SessionFrom' = $Null
                                    'SessionFromName' = $Null
                                    'LocalAdmin' = $Null
                                    'Type' = 'UserSession'
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    PROCESS {
        if ($TargetDomains -and (-not $SkipComputerEnumeration)) {
            
            if($Statements) {
                $Statements.Clear()
            }
            [Array]$TargetComputers = @()

            ForEach ($TargetDomain in $TargetDomains) {

                $DomainSID = Get-DomainSid -Domain $TargetDomain

                $ScriptParameters = @{
                    'CurrentUser2' = $CurrentUser
                    'UseLocalGroup2' = $UseLocalGroup
                    'UseSession2' = $UseSession
                    'UseLoggedon2' = $UseLoggedon
                    'DomainSID2' = $DomainSID
                }

                if($CollectionMethod -eq 'Stealth') {
                    Write-Verbose "Executing stealth computer enumeration of domain $TargetDomain"

                    Write-Verbose "Querying domain $TargetDomain for File Servers"
                    $TargetComputers += Get-NetFileServer -Domain $TargetDomain -DomainController $DomainController

                    Write-Verbose "Querying domain $TargetDomain for DFS Servers"
                    $TargetComputers += ForEach($DFSServer in $(Get-DFSshare -Domain $TargetDomain -DomainController $DomainController)) {
                        $DFSServer.RemoteServerName
                    }

                    Write-Verbose "Querying domain $TargetDomain for Domain Controllers"
                    $TargetComputers += ForEach($DomainController in $(Get-NetDomainController -LDAP -DomainController $DomainController -Domain $TargetDomain)) {
                        $DomainController.dnshostname
                    }

                    $TargetComputers = $TargetComputers | Where-Object {$_ -and ($_.Trim() -ne '')} | Sort-Object -Unique
                }
                else {
                    if($ComputerName) {
                        Write-Verbose "Using specified -ComputerName target set"
                        if($ComputerName -isnot [System.Array]) {$ComputerName = @($ComputerName)}
                        $TargetComputers = $ComputerName
                    }
                    else {
                        Write-Verbose "Enumerating all machines in domain $TargetDomain"
                        $ComputerSearcher = Get-DomainSearcher -Domain $TargetDomain -DomainController $DomainController -ADSPath $ComputerADSpath
                        $ComputerSearcher.filter = '(sAMAccountType=805306369)'
                        $Null = $ComputerSearcher.PropertiesToLoad.Add('dnshostname')
                        $TargetComputers = $ComputerSearcher.FindAll() | ForEach-Object {$_.Properties.dnshostname}
                        $ComputerSearcher.Dispose()
                    }
                }
                $TargetComputers = $TargetComputers | Where-Object { $_ }

                New-ThreadedFunction -ComputerName $TargetComputers -ScriptBlock $HostEnumBlock -ScriptParameters $ScriptParameters -Threads $Threads | ForEach-Object {
                    if($_['Type'] -eq 'UserSession') {
                        if($_['SessionFromName']) {
                            try {
                                $SessionFromName = $_['SessionFromName']
                                $UserName = $_['UserName'].ToUpper()
                                $ComputerDomain = $_['SessionFromName'].SubString($_['SessionFromName'].IndexOf('.')+1).ToUpper()

                                if($UserDomainMappings) {
                                    $UserDomain = $Null
                                    if($UserDomainMappings[$UserName]) {
                                        if($UserDomainMappings[$UserName].Count -eq 1) {
                                            $UserDomain = $UserDomainMappings[$UserName]
                                            $LoggedOnUser = "$UserName@$UserDomain"
                                            if ($PSCmdlet.ParameterSetName -eq 'CSVExport') {
                                                $SessionWriter.WriteLine("`"$SessionFromName`",`"$LoggedOnUser`",`"1`"")
                                            }
                                            else {
                                                $Null = $Statements.Add( @{"statement"="MERGE (user:User { name: UPPER('$LoggedOnUser') }) MERGE (computer:Computer { name: UPPER('$SessionFromName') }) MERGE (computer)-[:HasSession {Weight: '1'}]->(user)" } )
                                            }
                                        }
                                        else {
                                            $ComputerDomain = $_['SessionFromName'].SubString($_['SessionFromName'].IndexOf('.')+1).ToUpper()

                                            $UserDomainMappings[$UserName] | ForEach-Object {
                                                
                                                if($_ -eq $ComputerDomain) {
                                                    $UserDomain = $_
                                                    $LoggedOnUser = "$UserName@$UserDomain"
                                                    if ($PSCmdlet.ParameterSetName -eq 'CSVExport') {
                                                        $SessionWriter.WriteLine("`"$SessionFromName`",`"$LoggedOnUser`",`"1`"")
                                                    }
                                                    else {
                                                        $Null = $Statements.Add( @{"statement"="MERGE (user:User { name: UPPER('$LoggedOnUser') }) MERGE (computer:Computer { name: UPPER('$SessionFromName') }) MERGE (computer)-[:HasSession {Weight: '1'}]->(user)" } )
                                                    }
                                                }
                                                
                                                else {
                                                    $UserDomain = $_
                                                    $LoggedOnUser = "$UserName@$UserDomain"
                                                    if ($PSCmdlet.ParameterSetName -eq 'CSVExport') {
                                                        $SessionWriter.WriteLine("`"$SessionFromName`",`"$LoggedOnUser`",`"2`"")
                                                    }
                                                    else {
                                                        $Null = $Statements.Add( @{"statement"="MERGE (user:User { name: UPPER('$LoggedOnUser') }) MERGE (computer:Computer { name: UPPER('$SessionFromName') }) MERGE (computer)-[:HasSession {Weight: '2'}]->(user)" } )
                                                    }
                                                }
                                            }
                                        }
                                    }
                                    else {
                                        
                                        $LoggedOnUser = "$UserName@UNKNOWN"
                                        if ($PSCmdlet.ParameterSetName -eq 'CSVExport') {
                                            $SessionWriter.WriteLine("`"$SessionFromName`",`"$LoggedOnUser`",`"2`"")
                                        }
                                        else {
                                            $Null = $Statements.Add( @{"statement"="MERGE (user:User { name: UPPER('$LoggedOnUser') }) MERGE (computer:Computer { name: UPPER('$SessionFromName') }) MERGE (computer)-[:HasSession {Weight: '2'}]->(user)" } )
                                        }
                                    }
                                }
                                else {
                                    
                                    $LoggedOnUser = "$UserName@$ComputerDomain"
                                    if ($PSCmdlet.ParameterSetName -eq 'CSVExport') {
                                        $SessionWriter.WriteLine("`"$SessionFromName`",`"$LoggedOnUser`",`"2`"")
                                    }
                                    else {
                                        $Null = $Statements.Add( @{"statement"="MERGE (user:User { name: UPPER('$LoggedOnUser') }) MERGE (computer:Computer { name: UPPER('$SessionFromName') }) MERGE (computer)-[:HasSession {Weight: '2'}]->(user)"} )
                                    }
                                }
                            }
                            catch {
                                Write-Warning "Error extracting domain from $SessionFromName"
                            }
                        }
                        elseif($_['SessionFrom']) {
                            $SessionFromName = $_['SessionFrom']
                            $LoggedOnUser = "$($_['UserName'])@UNKNOWN"
                            if ($PSCmdlet.ParameterSetName -eq 'CSVExport') {
                                $SessionWriter.WriteLine("`"$SessionFromName`",`"$LoggedOnUser`",`"2`"")
                            }
                            else {
                                $Null = $Statements.Add( @{"statement"="MERGE (user:User { name: UPPER(`"$LoggedOnUser`") }) MERGE (computer:Computer { name: UPPER(`"$SessionFromName`") }) MERGE (computer)-[:HasSession {Weight: '2'}]->(user)"} )
                            }
                        }
                        else {
                            
                            $UserDomain = $_['UserDomain']
                            $UserName = $_['UserName']
                            try {
                                if($DomainShortnameMappings[$UserDomain]) {
                                    
                                    $AccountName = "$UserName@$($DomainShortnameMappings[$UserDomain])"
                                }
                                else {
                                    $MemberSimpleName = "$UserDomain\$UserName" | Convert-ADName -InputType 'NT4' -OutputType 'Canonical'

                                    if($MemberSimpleName) {
                                        $MemberDomain = $MemberSimpleName.Split('/')[0]
                                        $AccountName = "$UserName@$MemberDomain"
                                        $DomainShortnameMappings[$UserDomain] = $MemberDomain
                                    }
                                    else {
                                        $AccountName = "$UserName@UNKNOWN"
                                    }
                                }

                                $SessionFromName = $_['ComputerName']

                                if ($PSCmdlet.ParameterSetName -eq 'CSVExport') {
                                    $SessionWriter.WriteLine("`"$SessionFromName`",`"$AccountName`",`"1`"")
                                }
                                else {
                                    $Null = $Statements.Add( @{"statement"="MERGE (user:User { name: UPPER('$AccountName') }) MERGE (computer:Computer { name: UPPER('$SessionFromName') }) MERGE (computer)-[:HasSession {Weight: '1'}]->(user)" } )
                                }
                            }
                            catch {
                                Write-Verbose "Error converting $UserDomain\$UserName : $_"
                            }
                        }
                    }
                    elseif($_['Type'] -eq 'LocalUser') {
                        $Parts = $_['AccountName'].split('\')
                        $UserDomain = $Parts[0]
                        $UserName = $Parts[-1]

                        if($DomainShortnameMappings[$UserDomain]) {
                            
                            $AccountName = "$UserName@$($DomainShortnameMappings[$UserDomain])"
                        }
                        else {
                            $MemberSimpleName = "$UserDomain\$UserName" | Convert-ADName -InputType 'NT4' -OutputType 'Canonical'

                            if($MemberSimpleName) {
                                $MemberDomain = $MemberSimpleName.Split('/')[0]
                                $AccountName = "$UserName@$MemberDomain"
                                $DomainShortnameMappings[$UserDomain] = $MemberDomain
                            }
                            else {
                                $AccountName = "$UserName@UNKNOWN"
                            }
                        }

                        $ComputerName = $_['ComputerName']
                        if($_['IsGroup']) {
                            if ($PSCmdlet.ParameterSetName -eq 'CSVExport') {
                                $LocalAdminWriter.WriteLine("`"$ComputerName`",`"$AccountName`",`"group`"")
                            }
                            else {
                                $Null = $Statements.Add( @{ "statement"="MERGE (group:Group { name: UPPER('$AccountName') }) MERGE (computer:Computer { name: UPPER('$ComputerName') }) MERGE (group)-[:AdminTo]->(computer)" } )
                            }
                        }
                        else {
                            if ($PSCmdlet.ParameterSetName -eq 'CSVExport') {
                                $LocalAdminWriter.WriteLine("`"$ComputerName`",`"$AccountName`",`"user`"")
                            }
                            else {
                                $Null = $Statements.Add( @{"statement"="MERGE (user:User { name: UPPER('$AccountName') }) MERGE (computer:Computer { name: UPPER('$ComputerName') }) MERGE (user)-[:AdminTo]->(computer)" } )
                            }
                        }
                    }

                    if (($PSCmdlet.ParameterSetName -eq 'RESTAPI') -and ($Statements.Count -ge $Throttle)) {
                        $Json = @{ "statements"=[System.Collections.Hashtable[]]$Statements }
                        $JsonRequest = ConvertTo-Json20 $Json
                        $Null = $WebClient.UploadString($URI.AbsoluteUri + "db/data/transaction/commit", $JsonRequest)
                        $Statements.Clear()
                        [GC]::Collect()
                    }
                }
            }
        }
    }

    END {

        if ($PSCmdlet.ParameterSetName -eq 'CSVExport') {
            if($SessionWriter) {
                $SessionWriter.Dispose()
                $SessionFileStream.Dispose()
            }
            if($GroupWriter) {
                $GroupWriter.Dispose()
                $GroupFileStream.Dispose()
            }
            if($ContainerWriter) {
                $ContainerWriter.Dispose()
                $ContainerFileStream.Dispose()
            }
            if($GPLinkWriter) {
                $GPLinkWriter.Dispose()
                $GPLinkFileStream.Dispose()
            }
            if($ACLWriter) {
                $ACLWriter.Dispose()
                $ACLFileStream.Dispose()
            }
            if($LocalAdminWriter) {
                $LocalAdminWriter.Dispose()
                $LocalAdminFileStream.Dispose()
            }
            if($TrustWriter) {
                $TrustWriter.Dispose()
                $TrustsFileStream.Dispose()
            }

            Write-Output "Done writing output to CSVs in: $OutputFolder\$CSVExportPrefix"
        }
        else {
           $Json = @{ "statements"=[System.Collections.Hashtable[]]$Statements }
           $JsonRequest = ConvertTo-Json20 $Json
           $Null = $WebClient.UploadString($URI.AbsoluteUri + "db/data/transaction/commit", $JsonRequest)
           $Statements.Clear()
           Write-Output "Done sending output to neo4j RESTful API interface at: $($URI.AbsoluteUri)"
        }

        [GC]::Collect()
    }
}











$Mod = New-InMemoryModule -ModuleName Win32


$FunctionDefinitions = @(
    (func netapi32 NetWkstaUserEnum ([Int]) @([String], [Int], [IntPtr].MakeByRefType(), [Int], [Int32].MakeByRefType(), [Int32].MakeByRefType(), [Int32].MakeByRefType())),
    (func netapi32 NetSessionEnum ([Int]) @([String], [String], [String], [Int], [IntPtr].MakeByRefType(), [Int], [Int32].MakeByRefType(), [Int32].MakeByRefType(), [Int32].MakeByRefType())),
    (func netapi32 NetLocalGroupGetMembers ([Int]) @([String], [String], [Int], [IntPtr].MakeByRefType(), [Int], [Int32].MakeByRefType(), [Int32].MakeByRefType(), [Int32].MakeByRefType())),
    (func netapi32 DsEnumerateDomainTrusts ([Int]) @([String], [UInt32], [IntPtr].MakeByRefType(), [IntPtr].MakeByRefType())),
    (func netapi32 NetApiBufferFree ([Int]) @([IntPtr])),
    (func advapi32 ConvertSidToStringSid ([Int]) @([IntPtr], [String].MakeByRefType()) -SetLastError)
)


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

Set-Alias Get-BloodHoundData Invoke-BloodHound
