function Get-VirtualMemoryInfo {


    Param (
        [Parameter(Position = 0, Mandatory = $True)]
        [ValidateScript({Get-Process -Id $_})]
        [Int]
        $ProcessID,

        [Parameter(Position = 1, Mandatory = $True)]
        [IntPtr]
        $ModuleBaseAddress,

        [Int]
        $PageSize = 0x1000
    )

    $Mod = New-InMemoryModule -ModuleName MemUtils

    $MemProtection = psenum $Mod MEMUTIL.MEM_PROTECT Int32 @{
        PAGE_EXECUTE =           0x00000010
        PAGE_EXECUTE_READ =      0x00000020
        PAGE_EXECUTE_READWRITE = 0x00000040
        PAGE_EXECUTE_WRITECOPY = 0x00000080
        PAGE_NOACCESS =          0x00000001
        PAGE_READONLY =          0x00000002
        PAGE_READWRITE =         0x00000004
        PAGE_WRITECOPY =         0x00000008
        PAGE_GUARD =             0x00000100
        PAGE_NOCACHE =           0x00000200
        PAGE_WRITECOMBINE =      0x00000400
    } -Bitfield

    $MemState = psenum $Mod MEMUTIL.MEM_STATE Int32 @{
        MEM_COMMIT =  0x00001000
        MEM_FREE =    0x00010000
        MEM_RESERVE = 0x00002000
    } -Bitfield

    $MemType = psenum $Mod MEMUTIL.MEM_TYPE Int32 @{
        MEM_IMAGE =   0x01000000
        MEM_MAPPED =  0x00040000
        MEM_PRIVATE = 0x00020000
    } -Bitfield

    if ([IntPtr]::Size -eq 4) {
        $MEMORY_BASIC_INFORMATION = struct $Mod MEMUTIL.MEMORY_BASIC_INFORMATION @{
            BaseAddress = field 0 Int32
            AllocationBase = field 1 Int32
            AllocationProtect = field 2 $MemProtection
            RegionSize = field 3 Int32
            State = field 4 $MemState
            Protect = field 5 $MemProtection
            Type = field 6 $MemType
        }
    } else {
        $MEMORY_BASIC_INFORMATION = struct $Mod MEMUTIL.MEMORY_BASIC_INFORMATION @{
            BaseAddress = field 0 Int64
            AllocationBase = field 1 Int64
            AllocationProtect = field 2 $MemProtection
            Alignment1 = field 3 Int32
            RegionSize = field 4 Int64
            State = field 5 $MemState
            Protect = field 6 $MemProtection
            Type = field 7 $MemType
            Alignment2 = field 8 Int32
        }
    }

    $FunctionDefinitions = @(
        (func kernel32 VirtualQueryEx ([Int32]) @([IntPtr], [IntPtr], $MEMORY_BASIC_INFORMATION.MakeByRefType(), [Int]) -SetLastError),
        (func kernel32 OpenProcess ([IntPtr]) @([UInt32], [Bool], [UInt32]) -SetLastError),
        (func kernel32 CloseHandle ([Bool]) @([IntPtr]) -SetLastError)
    )

    $Types = $FunctionDefinitions | Add-Win32Type -Module $Mod -Namespace 'Win32MemUtils'
    $Kernel32 = $Types['kernel32']

    
    $hProcess = $Kernel32::OpenProcess(0x400, $False, $ProcessID) 

    if (-not $hProcess) {
        throw "Unable to get a process handle for process ID: $ProcessID"
    }

    $MemoryInfo = New-Object $MEMORY_BASIC_INFORMATION
    $BytesRead = $Kernel32::VirtualQueryEx($hProcess, $ModuleBaseAddress, [Ref] $MemoryInfo, $PageSize)

    $null = $Kernel32::CloseHandle($hProcess)

    $Fields = @{
        BaseAddress = $MemoryInfo.BaseAddress
        AllocationBase = $MemoryInfo.AllocationBase
        AllocationProtect = $MemoryInfo.AllocationProtect
        RegionSize = $MemoryInfo.RegionSize
        State = $MemoryInfo.State
        Protect = $MemoryInfo.Protect
        Type = $MemoryInfo.Type
    }

    $Result = New-Object PSObject -Property $Fields
    $Result.PSObject.TypeNames.Insert(0, 'MEM.INFO')

    $Result
}

function Get-StructFromMemory {


    [CmdletBinding()] Param (
        [Parameter(Position = 0, Mandatory = $True)]
        [Alias('ProcessId')]
        [Alias('PID')]
        [UInt16]
        $Id,

        [Parameter(Position = 1, Mandatory = $True)]
        [IntPtr]
        $MemoryAddress,

        [Parameter(Position = 2, Mandatory = $True)]
        [Alias('Type')]
        [Type]
        $StructType
    )

    Set-StrictMode -Version 2

    $PROCESS_VM_READ = 0x0010 

    
    $GetProcessHandle = [Diagnostics.Process].GetMethod('GetProcessHandle', [Reflection.BindingFlags] 'NonPublic, Instance', $null, @([Int]), $null)

    try
    {
        
        $Process = Get-Process -Id $Id -ErrorVariable GetProcessError
        
        $Handle = $Process.Handle
    }
    catch [Exception]
    {
        throw $GetProcessError
    }

    if ($Handle -eq $null)
    {
        throw "Unable to obtain a handle for PID $Id. You will likely need to run this script elevated."
    }

    
    $mscorlib = [AppDomain]::CurrentDomain.GetAssemblies() | ? { $_.FullName.Split(',')[0].ToLower() -eq 'mscorlib' }
    $Win32Native = $mscorlib.GetTypes() | ? { $_.FullName -eq 'Microsoft.Win32.Win32Native' }
    $MEMORY_BASIC_INFORMATION = $Win32Native.GetNestedType('MEMORY_BASIC_INFORMATION', [Reflection.BindingFlags] 'NonPublic')

    if ($MEMORY_BASIC_INFORMATION -eq $null)
    {
        throw 'Unable to get a reference to the MEMORY_BASIC_INFORMATION structure.'
    }

    
    $ProtectField = $MEMORY_BASIC_INFORMATION.GetField('Protect', [Reflection.BindingFlags] 'NonPublic, Instance')
    $AllocationBaseField = $MEMORY_BASIC_INFORMATION.GetField('BaseAddress', [Reflection.BindingFlags] 'NonPublic, Instance')
    $RegionSizeField = $MEMORY_BASIC_INFORMATION.GetField('RegionSize', [Reflection.BindingFlags] 'NonPublic, Instance')

    try { $NativeUtils = [NativeUtils] } catch [Management.Automation.RuntimeException] 
    {
        
        $DynAssembly = New-Object Reflection.AssemblyName('MemHacker')
        $AssemblyBuilder = [AppDomain]::CurrentDomain.DefineDynamicAssembly($DynAssembly, [Reflection.Emit.AssemblyBuilderAccess]::Run)
        $ModuleBuilder = $AssemblyBuilder.DefineDynamicModule('MemHacker', $False)
        $Attributes = 'AutoLayout, AnsiClass, Class, Public, SequentialLayout, Sealed, BeforeFieldInit'
        $TypeBuilder = $ModuleBuilder.DefineType('NativeUtils', $Attributes, [ValueType])
        $TypeBuilder.DefinePInvokeMethod('ReadProcessMemory', 'kernel32.dll', [Reflection.MethodAttributes] 'Public, Static', [Reflection.CallingConventions]::Standard, [Bool], @([IntPtr], [IntPtr], [IntPtr], [UInt32], [UInt32].MakeByRefType()), [Runtime.InteropServices.CallingConvention]::Winapi, 'Auto') | Out-Null
        $TypeBuilder.DefinePInvokeMethod('VirtualQueryEx', 'kernel32.dll', [Reflection.MethodAttributes] 'Public, Static', [Reflection.CallingConventions]::Standard, [UInt32], @([IntPtr], [IntPtr], $MEMORY_BASIC_INFORMATION.MakeByRefType(), [UInt32]), [Runtime.InteropServices.CallingConvention]::Winapi, 'Auto') | Out-Null

        $NativeUtils = $TypeBuilder.CreateType()
    }

    
    try
    {
        $SafeHandle = $GetProcessHandle.Invoke($Process, @($PROCESS_VM_READ))
        $Handle = $SafeHandle.DangerousGetHandle()
    }
    catch
    {
        throw $Error[0]
    }

    
    $MemoryBasicInformation = [Activator]::CreateInstance($MEMORY_BASIC_INFORMATION)

    
    $NativeUtils::VirtualQueryEx($Handle, $MemoryAddress, [Ref] $MemoryBasicInformation, [Runtime.InteropServices.Marshal]::SizeOf([Type] $MEMORY_BASIC_INFORMATION)) | Out-Null

    $PAGE_EXECUTE_READ = 0x20
    $PAGE_EXECUTE_READWRITE = 0x40
    $PAGE_READONLY = 2
    $PAGE_READWRITE = 4

    $Protection = $ProtectField.GetValue($MemoryBasicInformation)
    $AllocationBaseOriginal = $AllocationBaseField.GetValue($MemoryBasicInformation)
    $GetPointerValue = $AllocationBaseOriginal.GetType().GetMethod('GetPointerValue', [Reflection.BindingFlags] 'NonPublic, Instance')
    $AllocationBase = $GetPointerValue.Invoke($AllocationBaseOriginal, $null).ToInt64()
    $RegionSize = $RegionSizeField.GetValue($MemoryBasicInformation).ToUInt64()

    Write-Verbose "Protection: $Protection"
    Write-Verbose "AllocationBase: $AllocationBase"
    Write-Verbose "RegionSize: $RegionSize"

    if (($Protection -ne $PAGE_READONLY) -and ($Protection -ne $PAGE_READWRITE) -and ($Protection -ne $PAGE_EXECUTE_READ) -and ($Protection -ne $PAGE_EXECUTE_READWRITE))
    {
        $SafeHandle.Close()
        throw 'The address specified does not have read access.'
    }

    $StructSize = [Runtime.InteropServices.Marshal]::SizeOf([Type] $StructType)
    $EndOfAllocation = $AllocationBase + $RegionSize
    $EndOfStruct = $MemoryAddress.ToInt64() + $StructSize

    if ($EndOfStruct -gt $EndOfAllocation)
    {
        $SafeHandle.Close()
        throw 'You are attempting to read beyond what was allocated.'
    }

    try
    {
        
        $LocalStructPtr = [Runtime.InteropServices.Marshal]::AllocHGlobal($StructSize)
    }
    catch [OutOfMemoryException]
    {
        throw Error[0]
    }

    Write-Verbose "Memory allocated at 0x$($LocalStructPtr.ToString("X$([IntPtr]::Size * 2)"))"

    
    
    
    $ZeroBytes = New-Object Byte[]($StructSize)
    [Runtime.InteropServices.Marshal]::Copy($ZeroBytes, 0, $LocalStructPtr, $StructSize)

    $BytesRead = [UInt32] 0

    if ($NativeUtils::ReadProcessMemory($Handle, $MemoryAddress, $LocalStructPtr, $StructSize, [Ref] $BytesRead))
    {
        $SafeHandle.Close()
        [Runtime.InteropServices.Marshal]::FreeHGlobal($LocalStructPtr)
        throw ([ComponentModel.Win32Exception][Runtime.InteropServices.Marshal]::GetLastWin32Error())
    }

    Write-Verbose "Struct Size: $StructSize"
    Write-Verbose "Bytes read: $BytesRead"

    $ParsedStruct = [Runtime.InteropServices.Marshal]::PtrToStructure($LocalStructPtr, [Type] $StructType)

    [Runtime.InteropServices.Marshal]::FreeHGlobal($LocalStructPtr)
    $SafeHandle.Close()

    Write-Output $ParsedStruct
}

filter Get-ProcessMemoryInfo {


    Param (
        [Parameter(ParameterSetName = 'InMemory', Position = 0, Mandatory = $True, ValueFromPipelineByPropertyName = $True)]
        [Alias('Id')]
        [ValidateScript({Get-Process -Id $_})]
        [Int]
        $ProcessID
    )

    $SysInfo = Get-SystemInfo

    $MemoryInfo = Get-VirtualMemoryInfo -ProcessID $ProcessID -ModuleBaseAddress ([IntPtr]::Zero) -PageSize $SysInfo.PageSize

    $MemoryInfo

    while (($MemoryInfo.BaseAddress + $MemoryInfo.RegionSize) -lt $SysInfo.MaximumApplicationAddress) {
        $BaseAllocation = [IntPtr] ($MemoryInfo.BaseAddress + $MemoryInfo.RegionSize)
        $MemoryInfo = Get-VirtualMemoryInfo -ProcessID $ProcessID -ModuleBaseAddress $BaseAllocation -PageSize $SysInfo.PageSize
        
        if ($MemoryInfo.State -eq 0) { break }
        $MemoryInfo
    }
}

function Get-ProcessStrings
{


    [CmdletBinding()] Param (
        [Parameter(Position = 0, Mandatory = $True, ValueFromPipelineByPropertyName = $True)]
        [Alias('Id')]
        [ValidateScript({Get-Process -Id $_})]
        [Int32]
        $ProcessID,

        [UInt16]
        $MinimumLength = 3,

        [ValidateSet('Default','Ascii','Unicode')]
        [String]
        $Encoding = 'Default',

        [Switch]
        $IncludeImages
    )

    BEGIN {
        $Mod = New-InMemoryModule -ModuleName ProcessStrings

        $FunctionDefinitions = @(
            (func kernel32 OpenProcess ([IntPtr]) @([UInt32], [Bool], [UInt32]) -SetLastError),
            (func kernel32 ReadProcessMemory ([Bool]) @([IntPtr], [IntPtr], [Byte[]], [Int], [Int].MakeByRefType()) -SetLastError),
            (func kernel32 CloseHandle ([Bool]) @([IntPtr]) -SetLastError)
        )

        $Types = $FunctionDefinitions | Add-Win32Type -Module $Mod -Namespace 'Win32ProcessStrings'
        $Kernel32 = $Types['kernel32']
    }
    
    PROCESS {
        $hProcess = $Kernel32::OpenProcess(0x10, $False, $ProcessID) 

        Get-ProcessMemoryInfo -ProcessID $ProcessID | ? { $_.State -eq 'MEM_COMMIT' } | % {
            $Allocation = $_
            $ReadAllocation = $True
            if (($Allocation.Type -eq 'MEM_IMAGE') -and (-not $IncludeImages)) { $ReadAllocation = $False }
            
            if ($Allocation.Protect.ToString().Contains('PAGE_GUARD')) { $ReadAllocation = $False }

            if ($ReadAllocation) {
                $Bytes = New-Object Byte[]($Allocation.RegionSize)

                $BytesRead = 0
                $Result = $Kernel32::ReadProcessMemory($hProcess, $Allocation.BaseAddress, $Bytes, $Allocation.RegionSize, [Ref] $BytesRead)

                if ((-not $Result) -or ($BytesRead -ne $Allocation.RegionSize)) {
                    Write-Warning "Unable to read 0x$($Allocation.BaseAddress.ToString('X16')) from PID $ProcessID. Size: 0x$($Allocation.RegionSize.ToString('X8'))"
                } else {
                    if (($Encoding -eq 'Ascii') -or ($Encoding -eq 'Default')) {
                        
                        $ArrayPtr = [Runtime.InteropServices.Marshal]::UnsafeAddrOfPinnedArrayElement($Bytes, 0)
                        $RawString = [Runtime.InteropServices.Marshal]::PtrToStringAnsi($ArrayPtr, $Bytes.Length)
                        $Regex = [Regex] "[\x20-\x7E]{$MinimumLength,}"
                        $Regex.Matches($RawString) | % {
                            $Properties = @{
                                Address = [IntPtr] ($Allocation.BaseAddress + $_.Index)
                                Encoding = 'Ascii'
                                String = $_.Value
                            }

                            $String = New-Object PSObject -Property $Properties
                            $String.PSObject.TypeNames.Insert(0, 'MEM.STRING')

                            Write-Output $String
                        }

                        
                    }

                    if (($Encoding -eq 'Unicode') -or ($Encoding -eq 'Default')) {
                        $Encoder = New-Object System.Text.UnicodeEncoding
                        $RawString = $Encoder.GetString($Bytes, 0, $Bytes.Length)
                        $Regex = [Regex] "[\u0020-\u007E]{$MinimumLength,}"
                        $Regex.Matches($RawString) | % {
                            $Properties = @{
                                Address = [IntPtr] ($Allocation.BaseAddress + ($_.Index * 2))
                                Encoding = 'Unicode'
                                String = $_.Value
                            }

                            $String = New-Object PSObject -Property $Properties
                            $String.PSObject.TypeNames.Insert(0, 'MEM.STRING')

                            Write-Output $String
                        }
                    }
                }

                $Bytes = $null
            }
        }
        
        $null = $Kernel32::CloseHandle($hProcess)
    }

    END {}
}