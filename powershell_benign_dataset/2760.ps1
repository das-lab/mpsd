


function Get-LogonSession
{
    param
    (
        [Parameter(Mandatory = $true)]
        [UInt32]
        $LogonId
    )
    
    $LogonMap = @{}
    Get-WmiObject Win32_LoggedOnUser  | %{
    
        $Identity = $_.Antecedent | Select-String 'Domain="(.*)",Name="(.*)"'
        $LogonSession = $_.Dependent | Select-String 'LogonId="(\d+)"'

        $LogonMap[$LogonSession.Matches[0].Groups[1].Value] = New-Object PSObject -Property @{
            Domain = $Identity.Matches[0].Groups[1].Value
            UserName = $Identity.Matches[0].Groups[2].Value
        }
    }

    Get-WmiObject Win32_LogonSession -Filter "LogonId = `"$($LogonId)`"" | %{
        $LogonType = $Null
        switch($_.LogonType) {
            $null {$LogonType = 'None'}
            0 { $LogonType = 'System' }
            2 { $LogonType = 'Interactive' }
            3 { $LogonType = 'Network' }
            4 { $LogonType = 'Batch' }
            5 { $LogonType = 'Service' }
            6 { $LogonType = 'Proxy' }
            7 { $LogonType = 'Unlock' }
            8 { $LogonType = 'NetworkCleartext' }
            9 { $LogonType = 'NewCredentials' }
            10 { $LogonType = 'RemoteInteractive' }
            11 { $LogonType = 'CachedInteractive' }
            12 { $LogonType = 'CachedRemoteInteractive' }
            13 { $LogonType = 'CachedUnlock' }
            default { $LogonType = $_.LogonType}
        }

        New-Object PSObject -Property @{
            UserName = $LogonMap[$_.LogonId].UserName
            Domain = $LogonMap[$_.LogonId].Domain
            LogonId = $_.LogonId
            LogonType = $LogonType
            AuthenticationPackage = $_.AuthenticationPackage
            Caption = $_.Caption
            Description = $_.Description
            InstallDate = $_.InstallDate
            Name = $_.Name
            StartTime = $_.ConvertToDateTime($_.StartTime)
        }
    }
}



function New-InMemoryModule
{


    Param
    (
        [Parameter(Position = 0)]
        [ValidateNotNullOrEmpty()]
        [String]
        $ModuleName = [Guid]::NewGuid().ToString()
    )

    $AppDomain = [Reflection.Assembly].Assembly.GetType('System.AppDomain').GetProperty('CurrentDomain').GetValue($null, @())
    $LoadedAssemblies = $AppDomain.GetAssemblies()

    foreach ($Assembly in $LoadedAssemblies) {
        if ($Assembly.FullName -and ($Assembly.FullName.Split(',')[0] -eq $ModuleName)) {
            return $Assembly
        }
    }

    $DynAssembly = New-Object Reflection.AssemblyName($ModuleName)
    $Domain = $AppDomain
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
        [string]
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

        [String]
        $EntryPoint,

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
    if ($EntryPoint) { $Properties['EntryPoint'] = $EntryPoint }

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

        [Parameter(ValueFromPipelineByPropertyName = $True)]
        [String]
        $EntryPoint,

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
            foreach($Parameter in $ParameterTypes)
            {
                if ($Parameter.IsByRef)
                {
                    [void] $Method.DefineParameter($i, 'Out', $null)
                }

                $i++
            }

            $DllImport = [Runtime.InteropServices.DllImportAttribute]
            $SetLastErrorField = $DllImport.GetField('SetLastError')
            $CallingConventionField = $DllImport.GetField('CallingConvention')
            $CharsetField = $DllImport.GetField('CharSet')
            $EntryPointField = $DllImport.GetField('EntryPoint')
            if ($SetLastError) { $SLEValue = $True } else { $SLEValue = $False }

            if ($PSBoundParameters['EntryPoint']) { $ExportedFuncName = $EntryPoint } else { $ExportedFuncName = $FunctionName }

            
            $Constructor = [Runtime.InteropServices.DllImportAttribute].GetConstructor([String])
            $DllImportAttribute = New-Object Reflection.Emit.CustomAttributeBuilder($Constructor,
                $DllName, [Reflection.PropertyInfo[]] @(), [Object[]] @(),
                [Reflection.FieldInfo[]] @($SetLastErrorField,
                                           $CallingConventionField,
                                           $CharsetField,
                                           $EntryPointField),
                [Object[]] @($SLEValue,
                             ([Runtime.InteropServices.CallingConvention] $NativeCallingConvention),
                             ([Runtime.InteropServices.CharSet] $Charset),
                             $ExportedFuncName))

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

        foreach ($Key in $TypeHash.Keys)
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

    foreach ($Key in $EnumElements.Keys)
    {
        
        $null = $EnumBuilder.DefineLiteral($Key, $EnumElements[$Key] -as $EnumType)
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

    
    
    
    foreach ($Field in $StructFields.Keys)
    {
        $Index = $StructFields[$Field]['Position']
        $Fields[$Index] = @{FieldName = $Field; Properties = $StructFields[$Field]}
    }

    foreach ($Field in $Fields)
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





$Mod = New-InMemoryModule -ModuleName Thread

$LuidAttributes = psenum $Mod Thread.LuidAttributes UInt32 @{
    DISABLED                            =   '0x00000000'
    SE_PRIVILEGE_ENABLED_BY_DEFAULT     =   '0x00000001'
    SE_PRIVILEGE_ENABLED                =   '0x00000002'
    SE_PRIVILEGE_REMOVED                =   '0x00000004'
    SE_PRIVILEGE_USED_FOR_ACCESS        =   '0x80000000'
} -Bitfield

$MemProtection = psenum $Mod Thread.MemProtection UInt32 @{
    PAGE_EXECUTE = 0x10
    PAGE_EXECUTE_READ = 0x20
    PAGE_EXECUTE_READWRITE = 0x40
    PAGE_EXECUTE_WRITECOPY = 0x80
    PAGE_NOACCESS = 0x01
    PAGE_READONLY = 0x02
    PAGE_READWRITE = 0x04
    PAGE_WRITECOPY = 0x08
    PAGE_TARGETS_INVALID = 0x40000000
    PAGE_TARGETS_NO_UPDATE = 0x40000000
    PAGE_GUARD = 0x100
    PAGE_NOCACHE = 0x200
    PAGE_WRITECOMBINE = 0x400
} -Bitfield

$MemState = psenum $Mod Thread.MemState UInt32 @{
    MEM_COMMIT = 0x1000
    MEM_RESERVE = 0x2000
    MEM_FREE = 0x10000
}

$MemType = psenum $Mod Thread.MemType UInt32 @{
    MEM_PRIVATE = 0x20000
    MEM_MAPPED = 0x40000
    MEM_IMAGE = 0x1000000
}

$SecurityEntity = psenum $Mod Thread.SecurityEntity UInt32 @{
    SeCreateTokenPrivilege              =   1
    SeAssignPrimaryTokenPrivilege       =   2
    SeLockMemoryPrivilege               =   3
    SeIncreaseQuotaPrivilege            =   4
    SeUnsolicitedInputPrivilege         =   5
    SeMachineAccountPrivilege           =   6
    SeTcbPrivilege                      =   7
    SeSecurityPrivilege                 =   8
    SeTakeOwnershipPrivilege            =   9
    SeLoadDriverPrivilege               =   10
    SeSystemProfilePrivilege            =   11
    SeSystemtimePrivilege               =   12
    SeProfileSingleProcessPrivilege     =   13
    SeIncreaseBasePriorityPrivilege     =   14
    SeCreatePagefilePrivilege           =   15
    SeCreatePermanentPrivilege          =   16
    SeBackupPrivilege                   =   17
    SeRestorePrivilege                  =   18
    SeShutdownPrivilege                 =   19
    SeDebugPrivilege                    =   20
    SeAuditPrivilege                    =   21
    SeSystemEnvironmentPrivilege        =   22
    SeChangeNotifyPrivilege             =   23
    SeRemoteShutdownPrivilege           =   24
    SeUndockPrivilege                   =   25
    SeSyncAgentPrivilege                =   26
    SeEnableDelegationPrivilege         =   27
    SeManageVolumePrivilege             =   28
    SeImpersonatePrivilege              =   29
    SeCreateGlobalPrivilege             =   30
    SeTrustedCredManAccessPrivilege     =   31
    SeRelabelPrivilege                  =   32
    SeIncreaseWorkingSetPrivilege       =   33
    SeTimeZonePrivilege                 =   34
    SeCreateSymbolicLinkPrivilege       =   35
}

$SidNameUser = psenum $Mod Thread.SID_NAME_USE UInt32 @{
  SidTypeUser                            = 1
  SidTypeGroup                           = 2
  SidTypeDomain                          = 3
  SidTypeAlias                           = 4
  SidTypeWellKnownGroup                  = 5
  SidTypeDeletedAccount                  = 6
  SidTypeInvalid                         = 7
  SidTypeUnknown                         = 8
  SidTypeComputer                        = 9
}

$TokenInformationClass = psenum $Mod Thread.TOKEN_INFORMATION_CLASS UInt16 @{ 
  TokenUser                             = 1
  TokenGroups                           = 2
  TokenPrivileges                       = 3
  TokenOwner                            = 4
  TokenPrimaryGroup                     = 5
  TokenDefaultDacl                      = 6
  TokenSource                           = 7
  TokenType                             = 8
  TokenImpersonationLevel               = 9
  TokenStatistics                       = 10
  TokenRestrictedSids                   = 11
  TokenSessionId                        = 12
  TokenGroupsAndPrivileges              = 13
  TokenSessionReference                 = 14
  TokenSandBoxInert                     = 15
  TokenAuditPolicy                      = 16
  TokenOrigin                           = 17
  TokenElevationType                    = 18
  TokenLinkedToken                      = 19
  TokenElevation                        = 20
  TokenHasRestrictions                  = 21
  TokenAccessInformation                = 22
  TokenVirtualizationAllowed            = 23
  TokenVirtualizationEnabled            = 24
  TokenIntegrityLevel                   = 25
  TokenUIAccess                         = 26
  TokenMandatoryPolicy                  = 27
  TokenLogonSid                         = 28
  TokenIsAppContainer                   = 29
  TokenCapabilities                     = 30
  TokenAppContainerSid                  = 31
  TokenAppContainerNumber               = 32
  TokenUserClaimAttributes              = 33
  TokenDeviceClaimAttributes            = 34
  TokenRestrictedUserClaimAttributes    = 35
  TokenRestrictedDeviceClaimAttributes  = 36
  TokenDeviceGroups                     = 37
  TokenRestrictedDeviceGroups           = 38
  TokenSecurityAttributes               = 39
  TokenIsRestricted                     = 40
  MaxTokenInfoClass                     = 41
}

$LUID = struct $Mod Thread.Luid @{
    LowPart         =   field 0 $SecurityEntity
    HighPart        =   field 1 Int32
}

$LUID_AND_ATTRIBUTES = struct $Mod Thread.LuidAndAttributes @{
    Luid            =   field 0 $LUID
    Attributes      =   field 1 UInt32
}

$MEMORYBASICINFORMATION = struct $Mod Thread.MEMORY_BASIC_INFORMATION @{
  BaseAddress       = field 0 UIntPtr
  AllocationBase    = field 1 UIntPtr
  AllocationProtect = field 2 UInt32
  RegionSize        = field 3 UIntPtr
  State             = field 4 UInt32
  Protect           = field 5 UInt32
  Type              = field 6 UInt32
}

$SID_AND_ATTRIBUTES = struct $Mod Thread.SidAndAttributes @{
    Sid             =   field 0 IntPtr
    Attributes      =   field 1 UInt32
}

$THREADENTRY32 = struct $Mod Thread.THREADENTRY32 @{
    dwSize          = field 0 UInt32
    cntUsage        = field 1 UInt32
    th32ThreadID    = field 2 UInt32
    th32OwnerProcessID = field 3 UInt32
    tpBasePri       = field 4 UInt32
    tpDeltaPri      = field 5 UInt32
    dwFlags         = field 6 UInt32
}

$TOKEN_MANDATORY_LABEL = struct $Mod Thread.TokenMandatoryLabel @{
    Label           = field 0 $SID_AND_ATTRIBUTES;
}

$TOKEN_ORIGIN = struct $Mod Thread.TokenOrigin @{
  OriginatingLogonSession = field 0 UInt64
}

$TOKEN_PRIVILEGES = struct $Mod Thread.TokenPrivileges @{
    PrivilegeCount  = field 0 UInt32
    Privileges      = field 1 $LUID_AND_ATTRIBUTES.MakeArrayType() -MarshalAs @('ByValArray', 50)
}

$TOKEN_USER = struct $Mod Thread.TOKEN_USER @{
    User            = field 0 $SID_AND_ATTRIBUTES
}

$FunctionDefinitions = @(
    (func kernel32 CloseHandle ([bool]) @(
        [IntPtr]                                  
    ) -SetLastError),
    
    (func advapi32 ConvertSidToStringSid ([bool]) @(
        [IntPtr]                                  
        [IntPtr].MakeByRefType()                  
    ) -SetLastError),
    
    (func kernel32 CreateToolhelp32Snapshot ([IntPtr]) @(
        [UInt32],                                 
        [UInt32]                                  
    ) -SetLastError),
    
    (func advapi32 GetTokenInformation ([bool]) @(
      [IntPtr],                                   
      [Int32],                                    
      [IntPtr],                                   
      [UInt32],                                   
      [UInt32].MakeByRefType()                    
    ) -SetLastError),

    (func ntdll NtQueryInformationThread ([UInt32]) @(
        [IntPtr],                                 
        [Int32],                                  
        [IntPtr],                                 
        [Int32],                                  
        [IntPtr]                                  
    )),

    (func kernel32 OpenProcess ([IntPtr]) @(
        [UInt32],                                 
        [bool],                                   
        [UInt32]                                  
    ) -SetLastError),
    
    (func advapi32 OpenProcessToken ([bool]) @(
      [IntPtr],                                   
      [UInt32],                                   
      [IntPtr].MakeByRefType()                    
    ) -SetLastError),

    (func kernel32 OpenThread ([IntPtr]) @(
        [UInt32],                                  
        [bool],                                    
        [UInt32]                                   
    ) -SetLastError),
    
    (func advapi32 OpenThreadToken ([bool]) @(
      [IntPtr],                                    
      [UInt32],                                    
      [bool],                                      
      [IntPtr].MakeByRefType()                     
    ) -SetLastError),
    
    (func kernel32 QueryFullProcessImageName ([bool]) @(
      [IntPtr]                                     
      [UInt32]                                     
      [System.Text.StringBuilder]                  
      [UInt32].MakeByRefType()                     
    ) -SetLastError),
    
    (func kernel32 ReadProcessMemory ([Bool]) @(
        [IntPtr],                                  
        [IntPtr],                                  
        [Byte[]],                                  
        [Int],                                     
        [Int].MakeByRefType()                      
    ) -SetLastError),
    
    (func kernel32 TerminateThread ([bool]) @(
        [IntPtr],                                  
        [UInt32]                                   
    ) -SetLastError),
    
    (func kernel32 Thread32First ([bool]) @(
        [IntPtr],                                  
        $THREADENTRY32.MakeByRefType()             
    ) -SetLastError)
    
    (func kernel32 Thread32Next ([bool]) @(
        [IntPtr],                                  
        $THREADENTRY32.MakeByRefType()             
    ) -SetLastError),
    
    (func kernel32 VirtualQueryEx ([Int32]) @(
        [IntPtr],                                  
        [IntPtr],                                  
        $MEMORYBASICINFORMATION.MakeByRefType(),   
        [UInt32]                                   
    ) -SetLastError)
)

$Types = $FunctionDefinitions | Add-Win32Type -Module $Mod -Namespace 'Win32SysInfo'
$Kernel32 = $Types['kernel32']
$Ntdll = $Types['ntdll']
$Advapi32 = $Types['advapi32']

$DELETE = 0x00010000
$READ_CONTROL = 0x00020000
$SYNCHRONIZE = 0x00100000
$WRITE_DAC = 0x00040000
$WRITE_OWNER = 0x00080000

$PROCESS_CREATE_PROCESS = 0x0080
$PROCESS_CREATE_THREAD = 0x0002
$PROCESS_DUP_HANDLE = 0x0040
$PROCESS_QUERY_INFORMATION = 0x0400
$PROCESS_QUERY_LIMITED_INFORMATION = 0x1000
$PROCESS_SET_INFORMATION = 0x0200
$PROCESS_SET_QUOTA = 0x0100
$PROCESS_SUSPEND_RESUME = 0x0800
$PROCESS_TERMINATE = 0x0001
$PROCESS_VM_OPERATION = 0x0008
$PROCESS_VM_READ = 0x0010
$PROCESS_VM_WRITE = 0x0020
$PROCESS_ALL_ACCESS = $DELETE -bor
                      $READ_CONTROL -bor
                      $SYNCHRONIZE -bor
                      $WRITE_DAC -bor
                      $WRITE_OWNER -bor
                      $PROCESS_CREATE_PROCESS -bor
                      $PROCESS_CREATE_THREAD -bor
                      $PROCESS_DUP_HANDLE -bor
                      $PROCESS_QUERY_INFORMATION -bor
                      $PROCESS_QUERY_LIMITED_INFORMATION -bor
                      $PROCESS_SET_INFORMATION -bor
                      $PROCESS_SET_QUOTA -bor
                      $PROCESS_SUSPEND_RESUME -bor
                      $PROCESS_TERMINATE -bor
                      $PROCESS_VM_OPERATION -bor
                      $PROCESS_VM_READ -bor
                      $PROCESS_VM_WRITE

$THREAD_DIRECT_IMPERSONATION = 0x0200
$THREAD_GET_CONTEXT = 0x0008
$THREAD_IMPERSONATE = 0x0100
$THREAD_QUERY_INFORMATION = 0x0040
$THREAD_QUERY_LIMITED_INFORMATION = 0x0800
$THREAD_SET_CONTEXT = 0x0010
$THREAD_SET_INFORMATION = 0x0020
$THREAD_SET_LIMITED_INFORMATION = 0x0400
$THREAD_SET_THREAD_TOKEN = 0x0080
$THREAD_SUSPEND_RESUME = 0x0002
$THREAD_TERMINATE = 0x0001
$THREAD_ALL_ACCESS = $DELETE -bor
                     $READ_CONTROL -bor
                     $SYNCHRONIZE -bor
                     $WRITE_DAC -bor
                     $WRITE_OWNER -bor
                     $THREAD_DIRECT_IMPERSONATION -bor
                     $THREAD_GET_CONTEXT -bor
                     $THREAD_IMPERSONATE -bor
                     $THREAD_QUERY_INFORMATION -bor
                     $THREAD_QUERY_LIMITED_INFORMATION -bor
                     $THREAD_SET_CONTEXT -bor
                     $THREAD_SET_LIMITED_INFORMATION -bor
                     $THREAD_SET_THREAD_TOKEN -bor
                     $THREAD_SUSPEND_RESUME -bor
                     $THREAD_TERMINATE

$STANDARD_RIGHTS_REQUIRED = 0x000F0000
$TOKEN_ASSIGN_PRIMARY = 0x0001
$TOKEN_DUPLICATE = 0x0002
$TOKEN_IMPERSONATE = 0x0004
$TOKEN_QUERY = 0x0008
$TOKEN_QUERY_SOURCE = 0x0010
$TOKEN_ADJUST_PRIVILEGES = 0x0020
$TOKEN_ADJUST_GROUPS = 0x0040
$TOKEN_ADJUST_DEFAULT = 0x0080
$TOKEN_ADJUST_SESSIONID = 0x0100
$TOKEN_ALL_ACCESS = $STANDARD_RIGHTS_REQUIRED -bor 
                    $TOKEN_ASSIGN_PRIMARY -bor
                    $TOKEN_DUPLICATE -bor
                    $TOKEN_IMPERSONATE -bor
                    $TOKEN_QUERY -bor
                    $TOKEN_QUERY_SOURCE -bor
                    $TOKEN_ADJUST_PRIVILEGES -bor
                    $TOKEN_ADJUST_GROUPS -bor 
                    $TOKEN_ADJUST_DEFAULT
                    
                    
$UNTRUSTED_MANDATORY_LEVEL = "S-1-16-0"
$LOW_MANDATORY_LEVEL = "S-1-16-4096"
$MEDIUM_MANDATORY_LEVEL = "S-1-16-8192"
$MEDIUM_PLUS_MANDATORY_LEVEL = "S-1-16-8448"
$HIGH_MANDATORY_LEVEL = "S-1-16-12288"
$SYSTEM_MANDATORY_LEVEL = "S-1-16-16384"
$PROTECTED_PROCESS_MANDATORY_LEVEL = "S-1-16-20480"
$SECURE_PROCESS_MANDATORY_LEVEL = "S-1-16-28672"





function CloseHandle
{
    

    param
    (
        [Parameter(Mandatory = $true)]
        [IntPtr]
        $Handle    
    )
    
    
    
    $Success = $Kernel32::CloseHandle($Handle); $LastError = [Runtime.InteropServices.Marshal]::GetLastWin32Error()

    if(-not $Success) 
    {
        Write-Debug "Close Handle Error: $(([ComponentModel.Win32Exception] $LastError).Message)"
    }
}

function ConvertSidToStringSid
{
    

    param
    (
        [Parameter(Mandatory = $true)]
        [IntPtr]
        $SidPointer    
    )
    
    
    
    $StringPtr = [IntPtr]::Zero
    $Success = $Advapi32::ConvertSidToStringSid($SidPointer, [ref]$StringPtr); $LastError = [Runtime.InteropServices.Marshal]::GetLastWin32Error()

    if(-not $Success) 
    {
        Write-Debug "ConvertSidToStringSid Error: $(([ComponentModel.Win32Exception] $LastError).Message)"
    }
    
    Write-Output ([System.Runtime.InteropServices.Marshal]::PtrToStringAuto($StringPtr))
}

function CreateToolhelp32Snapshot
{
    

    param
    (
        [Parameter(Mandatory = $true)]
        [UInt32]
        $ProcessId,
        
        [Parameter(Mandatory = $true)]
        [UInt32]
        $Flags
    )
    
    
    
    $hSnapshot = $Kernel32::CreateToolhelp32Snapshot($Flags, $ProcessId); $LastError = [Runtime.InteropServices.Marshal]::GetLastWin32Error()

    if(-not $hSnapshot) 
    {
        Write-Debug "CreateToolhelp32Snapshot Error: $(([ComponentModel.Win32Exception] $LastError).Message)"
    }
    
    Write-Output $hSnapshot
}

function GetTokenInformation
{
    

    param
    (
        [Parameter(Mandatory = $true)]
        [IntPtr]
        $TokenHandle,
        
        [Parameter(Mandatory = $true)]
        $TokenInformationClass 
    )
    
    
    
    
    $TokenPtrSize = 0
    $Success = $Advapi32::GetTokenInformation($TokenHandle, $TokenInformationClass, 0, $TokenPtrSize, [ref]$TokenPtrSize)
    [IntPtr]$TokenPtr = [System.Runtime.InteropServices.Marshal]::AllocHGlobal($TokenPtrSize)
    
    
    $Success = $Advapi32::GetTokenInformation($TokenHandle, $TokenInformationClass, $TokenPtr, $TokenPtrSize, [ref]$TokenPtrSize); $LastError = [Runtime.InteropServices.Marshal]::GetLastWin32Error()
    
    if($Success)
    {
        switch($TokenInformationClass)
        {
            1 
            {    
                $TokenUser = $TokenPtr -as $TOKEN_USER
                ConvertSidToStringSid -SidPointer $TokenUser.User.Sid
            }
            3 
            {
                
                $TokenPrivileges = $TokenPtr -as $TOKEN_PRIVILEGES
                
                $sb = New-Object System.Text.StringBuilder
                
                for($i=0; $i -lt $TokenPrivileges.PrivilegeCount; $i++) 
                {
                    if((($TokenPrivileges.Privileges[$i].Attributes -as $LuidAttributes) -band $LuidAttributes::SE_PRIVILEGE_ENABLED) -eq $LuidAttributes::SE_PRIVILEGE_ENABLED)
                    {
                       $sb.Append(", $($TokenPrivileges.Privileges[$i].Luid.LowPart.ToString())") | Out-Null  
                    }
                }
                Write-Output $sb.ToString().TrimStart(', ')
            }
            17 
            {
                $TokenOrigin = $TokenPtr -as $LUID
                Write-Output (Get-LogonSession -LogonId $TokenOrigin.LowPart)
            }
            22 
            {
            
            }
            25 
            {
                $TokenIntegrity = $TokenPtr -as $TOKEN_MANDATORY_LABEL
                switch(ConvertSidToStringSid -SidPointer $TokenIntegrity.Label.Sid)
                {
                    $UNTRUSTED_MANDATORY_LEVEL
                    {
                        Write-Output "UNTRUSTED_MANDATORY_LEVEL"
                    }
                    $LOW_MANDATORY_LEVEL
                    {
                        Write-Output "LOW_MANDATORY_LEVEL"
                    }
                    $MEDIUM_MANDATORY_LEVEL
                    {
                        Write-Output "MEDIUM_MANDATORY_LEVEL"
                    }
                    $MEDIUM_PLUS_MANDATORY_LEVEL
                    {
                        Write-Output "MEDIUM_PLUS_MANDATORY_LEVEL"
                    }
                    $HIGH_MANDATORY_LEVEL
                    {
                        Write-Output "HIGH_MANDATORY_LEVEL"
                    }
                    $SYSTEM_MANDATORY_LEVEL
                    {
                        Write-Output "SYSTEM_MANDATORY_LEVEL"
                    }
                    $PROTECTED_PROCESS_MANDATORY_LEVEL
                    {
                        Write-Output "PROTECTED_PROCESS_MANDATORY_LEVEL"
                    }
                    $SECURE_PROCESS_MANDATORY_LEVEL
                    {
                        Write-Output "SECURE_PROCESS_MANDATORY_LEVEL"
                    }
                }
            }
        }
    }
    else
    {
        Write-Debug "GetTokenInformation Error: $(([ComponentModel.Win32Exception] $LastError).Message)"
    }        
    try
    {
        [System.Runtime.InteropServices.Marshal]::FreeHGlobal($TokenPtr)
    }
    catch
    {
    
    }
}

function NtQueryInformationThread
{
    

    param
    (
        [Parameter(Mandatory = $true)]
        [IntPtr]
        $ThreadHandle  
    )
    
    
    
    $buf = [System.Runtime.InteropServices.Marshal]::AllocHGlobal([IntPtr]::Size)

    $Success = $Ntdll::NtQueryInformationThread($ThreadHandle, 9, $buf, [IntPtr]::Size, [IntPtr]::Zero); $LastError = [Runtime.InteropServices.Marshal]::GetLastWin32Error()

    if(-not $Success) 
    {
        Write-Debug "NtQueryInformationThread Error: $(([ComponentModel.Win32Exception] $LastError).Message)"
    }
    
    Write-Output ([System.Runtime.InteropServices.Marshal]::ReadIntPtr($buf))
}

function OpenProcess
{
    

    param
    (
        [Parameter(Mandatory = $true)]
        [UInt32]
        $ProcessId,
        
        [Parameter(Mandatory = $true)]
        [UInt32]
        $DesiredAccess,
        
        [Parameter()]
        [bool]
        $InheritHandle = $false
    )
    
    
    
    $hProcess = $Kernel32::OpenProcess($DesiredAccess, $InheritHandle, $ProcessId); $LastError = [Runtime.InteropServices.Marshal]::GetLastWin32Error()

    if($hProcess -eq 0) 
    {
        Write-Debug "OpenProcess Error: $(([ComponentModel.Win32Exception] $LastError).Message)"
    }
    
    Write-Output $hProcess
}

function OpenProcessToken
{ 
    

    param
    (
        [Parameter(Mandatory = $true)]
        [IntPtr]
        $ProcessHandle,
        
        [Parameter(Mandatory = $true)]
        [UInt32]
        $DesiredAccess  
    )
    
    
    
    $hToken = [IntPtr]::Zero
    $Success = $Advapi32::OpenProcessToken($ProcessHandle, $DesiredAccess, [ref]$hToken); $LastError = [Runtime.InteropServices.Marshal]::GetLastWin32Error()

    if(-not $Success) 
    {
        Write-Debug "OpenProcessToken Error: $(([ComponentModel.Win32Exception] $LastError).Message)"
    }
    
    Write-Output $hToken
}

function OpenThread
{
    

    param
    (
        [Parameter(Mandatory = $true)]
        [UInt32]
        $ThreadId,
        
        [Parameter(Mandatory = $true)]
        [UInt32]
        $DesiredAccess,
        
        [Parameter()]
        [bool]
        $InheritHandle = $false
    )
    
    
    
    $hThread = $Kernel32::OpenThread($DesiredAccess, $InheritHandle, $ThreadId); $LastError = [Runtime.InteropServices.Marshal]::GetLastWin32Error()

    if($hThread -eq 0) 
    {
        Write-Debug "OpenThread Error: $(([ComponentModel.Win32Exception] $LastError).Message)"
    }
    
    Write-Output $hThread
}

function OpenThreadToken
{
    

    param
    (
        [Parameter(Mandatory = $true)]
        [IntPtr]
        $ThreadHandle,
        
        [Parameter(Mandatory = $true)]
        [UInt32]
        $DesiredAccess,
        
        [Parameter()]
        [bool]
        $OpenAsSelf = $false   
    )
    
    
    
    $hToken = [IntPtr]::Zero
    $Success = $Advapi32::OpenThreadToken($ThreadHandle, $DesiredAccess, $OpenAsSelf, [ref]$hToken); $LastError = [Runtime.InteropServices.Marshal]::GetLastWin32Error()

    if(-not $Success) 
    {
        Write-Debug "OpenThreadToken Error: $(([ComponentModel.Win32Exception] $LastError).Message)"
        throw "OpenThreadToken Error: $(([ComponentModel.Win32Exception] $LastError).Message)"
    }
    
    Write-Output $hToken
}

function QueryFullProcessImageName
{
    

    param
    (
        [Parameter(Mandatory = $true)]
        [IntPtr]
        $ProcessHandle,
        
        [Parameter()]
        [UInt32]
        $Flags = 0
    )
    
    $capacity = 2048
    $sb = New-Object -TypeName System.Text.StringBuilder($capacity)

    $Success = $Kernel32::QueryFullProcessImageName($ProcessHandle, $Flags, $sb, [ref]$capacity); $LastError = [Runtime.InteropServices.Marshal]::GetLastWin32Error()

    if(-not $Success) 
    {
        Write-Debug "QueryFullProcessImageName Error: $(([ComponentModel.Win32Exception] $LastError).Message)"
    }
    
    Write-Output $sb.ToString()
}

function ReadProcessMemory
{
    

    param
    (
        [Parameter(Mandatory = $true)]
        [IntPtr]
        $ProcessHandle,
        
        [Parameter(Mandatory = $true)]
        [IntPtr]
        $BaseAddress,
        
        [Parameter(Mandatory = $true)]
        [Int]
        $Size    
    )
    
    
    
    $buf = New-Object byte[]($Size)
    [Int32]$NumberOfBytesRead = 0
    
    $Success = $Kernel32::ReadProcessMemory($ProcessHandle, $BaseAddress, $buf, $buf.Length, [ref]$NumberOfBytesRead); $LastError = [Runtime.InteropServices.Marshal]::GetLastWin32Error()

    if(-not $Success) 
    {
        Write-Debug "ReadProcessMemory Error: $(([ComponentModel.Win32Exception] $LastError).Message)"
    }
    
    Write-Output $buf
}    

function TerminateThread
{
    

    param
    (
        [Parameter(Mandatory = $true)]
        [IntPtr]
        $ThreadHandle,
        
        [Parameter()]
        [UInt32]
        $ExitCode = 0
    )
    
    
    
    $Success = $Kernel32::TerminateThread($ThreadHandle, $ExitCode); $LastError = [Runtime.InteropServices.Marshal]::GetLastWin32Error()

    if(-not $Success) 
    {
        Write-Debug "TerminateThread Error: $(([ComponentModel.Win32Exception] $LastError).Message)"
    }
}

function Thread32First
{
    

    param
    (
        [Parameter(Mandatory = $true)]
        [IntPtr]
        $SnapshotHandle
    )
    
    
    
    $Thread = [Activator]::CreateInstance($THREADENTRY32)
    $Thread.dwSize = $THREADENTRY32::GetSize()

    $Success = $Kernel32::Thread32First($hSnapshot, [Ref]$Thread); $LastError = [Runtime.InteropServices.Marshal]::GetLastWin32Error()

    if(-not $Success) 
    {
        Write-Debug "Thread32First Error: $(([ComponentModel.Win32Exception] $LastError).Message)"
    }
    
    Write-Output $Thread
}    

function VirtualQueryEx
{
    

    param
    (
        [Parameter(Mandatory = $true)]
        [IntPtr]
        $ProcessHandle,
        
        [Parameter(Mandatory = $true)]
        [IntPtr]
        $BaseAddress
    )
    
    
    
    $memory_basic_info = [Activator]::CreateInstance($MEMORYBASICINFORMATION)
    $Success = $Kernel32::VirtualQueryEx($ProcessHandle, $BaseAddress, [Ref]$memory_basic_info, $MEMORYBASICINFORMATION::GetSize()); $LastError = [Runtime.InteropServices.Marshal]::GetLastWin32Error()

    if(-not $Success) 
    {
        Write-Debug "VirtualQueryEx Error: $(([ComponentModel.Win32Exception] $LastError).Message)"
        
        
    }
    
    Write-Output $memory_basic_info
}






$hSnapshot = CreateToolhelp32Snapshot -ProcessId 0 -Flags 4

$Thread = Thread32First -SnapshotHandle $hSnapshot
do
{
    $proc = Get-Process -Id $Thread.th32OwnerProcessId
    
    if($Thread.th32OwnerProcessId -ne 0 -and $Thread.th32OwnerProcessId -ne 4)
    {
        $hThread = OpenThread -ThreadId $Thread.th32ThreadID -DesiredAccess $THREAD_ALL_ACCESS -InheritHandle $false
        if($hThread -ne 0)
        {
            $BaseAddress = NtQueryInformationThread -ThreadHandle $hThread
            $hProcess = OpenProcess -ProcessId $Thread.th32OwnerProcessID -DesiredAccess $PROCESS_ALL_ACCESS -InheritHandle $false
            
            if($hProcess -ne 0)
            {
                $memory_basic_info = VirtualQueryEx -ProcessHandle $hProcess -BaseAddress $BaseAddress
                $AllocatedMemoryProtection = $memory_basic_info.AllocationProtect -as $MemProtection
                $MemoryProtection = $memory_basic_info.Protect -as $MemProtection
                $MemoryState = $memory_basic_info.State -as $MemState
                $MemoryType = $memory_basic_info.Type -as $MemType
                
                if($MemoryState -eq $MemState::MEM_COMMIT -and $MemoryType -ne $MemType::MEM_IMAGE)
                {   
                    $buf = ReadProcessMemory -ProcessHandle $hProcess -BaseAddress $BaseAddress -Size 100
                    $proc = Get-WmiObject Win32_Process -Filter "ProcessId = '$($Thread.th32OwnerProcessID)'"
                    $KernelPath = QueryFullProcessImageName -ProcessHandle $hProcess
                    $PathMismatch = $proc.Path.ToLower() -ne $KernelPath.ToLower()
                                
                    
                    try
                    {
                        $hThreadToken = OpenThreadToken -ThreadHandle $hThread -DesiredAccess $TOKEN_ALL_ACCESS
                        $SID = GetTokenInformation -TokenHandle $hThreadToken -TokenInformationClass 1
                        $Privs = GetTokenInformation -TokenHandle $hThreadToken -TokenInformationClass 3 
                        $LogonSession = GetTokenInformation -TokenHandle $hThreadToken -TokenInformationClass 17 
                        $Integrity = GetTokenInformation -TokenHandle $hThreadToken -TokenInformationClass 25 
                        $IsUniqueThreadToken = $true               
                    }
                    catch
                    {
                        $hProcessToken = OpenProcessToken -ProcessHandle $hProcess -DesiredAccess $TOKEN_ALL_ACCESS
                        $SID = GetTokenInformation -TokenHandle $hProcessToken -TokenInformationClass 1
                        $Privs = GetTokenInformation -TokenHandle $hProcessToken -TokenInformationClass 3 
                        $LogonSession = GetTokenInformation -TokenHandle $hProcessToken -TokenInformationClass 17 
                        $Integrity = GetTokenInformation -TokenHandle $hProcessToken -TokenInformationClass 25
                        $IsUniqueThreadToken = $false
                    }
                    
                    $ThreadDetail = New-Object PSObject
                    $ThreadDetail | Add-Member -MemberType Noteproperty -Name ProcessName -Value $proc.Name
                    $ThreadDetail | Add-Member -MemberType Noteproperty -Name ProcessId -Value $proc.ProcessId
                    $ThreadDetail | Add-Member -MemberType Noteproperty -Name Path -Value $proc.Path
                    $ThreadDetail | Add-Member -MemberType Noteproperty -Name KernelPath -Value $KernelPath
                    $ThreadDetail | Add-Member -MemberType Noteproperty -Name CommandLine -Value $proc.CommandLine
                    $ThreadDetail | Add-Member -MemberType Noteproperty -Name PathMismatch -Value $PathMismatch
                    $ThreadDetail | Add-Member -MemberType Noteproperty -Name ThreadId -Value $Thread.th32ThreadId
                    $ThreadDetail | Add-Member -MemberType Noteproperty -Name AllocatedMemoryProtection -Value $AllocatedMemoryProtection
                    $ThreadDetail | Add-Member -MemberType Noteproperty -Name MemoryProtection -Value $MemoryProtection
                    $ThreadDetail | Add-Member -MemberType Noteproperty -Name MemoryState -Value $MemoryState
                    $ThreadDetail | Add-Member -MemberType Noteproperty -Name MemoryType -Value $MemoryType
                    $ThreadDetail | Add-Member -MemberType Noteproperty -Name BasePriority -Value $Thread.tpBasePri
                    $ThreadDetail | Add-Member -MemberType Noteproperty -Name IsUniqueThreadToken -Value $IsUniqueThreadToken
                    $ThreadDetail | Add-Member -MemberType Noteproperty -Name Integrity -Value $Integrity
                    $ThreadDetail | Add-Member -MemberType Noteproperty -Name Privilege -Value $Privs
                    $ThreadDetail | Add-Member -MemberType Noteproperty -Name LogonId -Value $LogonSession.LogonId
                    $ThreadDetail | Add-Member -MemberType Noteproperty -Name SecurityIdentifier -Value $SID
                    $ThreadDetail | Add-Member -MemberType Noteproperty -Name UserName -Value "$($LogonSession.Domain)\$($LogonSession.UserName)"
                    $ThreadDetail | Add-Member -MemberType Noteproperty -Name LogonSessionStartTime -Value $LogonSession.StartTime
                    $ThreadDetail | Add-Member -MemberType Noteproperty -Name LogonType -Value $LogonSession.LogonType
                    $ThreadDetail | Add-Member -MemberType Noteproperty -Name AuthenticationPackage -Value $LogonSession.AuthenticationPackage
                    $ThreadDetail | Add-Member -MemberType Noteproperty -Name BaseAddress -Value $BaseAddress
                    $ThreadDetail | Add-Member -MemberType Noteproperty -Name Size -Value $memory_basic_info.RegionSize
                    $ThreadDetail | Add-Member -MemberType Noteproperty -Name Bytes -Value $buf
                    $ThreadDetail
                }
                CloseHandle($hProcess)
            }
        }
        CloseHandle($hThread)
    }
} while($Kernel32::Thread32Next($hSnapshot, [ref]$Thread))
CloseHandle($hSnapshot)