function New-FunctionDelegate {


    [OutputType([Delegate])]
    [CmdletBinding(DefaultParameterSetName = 'Bytes')]
    Param (
        [Parameter(Position = 0)]
        [ValidateCount(1, 10)]
        [Type[]]
        $Parameters = (New-Object Type[](0)),
            
        [Parameter(Position = 1)]
        [Type]
        $ReturnType = [Void],

        [Parameter(Position = 2, Mandatory = $True, ParameterSetName = 'Bytes')]
        [ValidateNotNullOrEmpty()]
        [Byte[]]
        $FunctionBytes,

        [Parameter(Position = 2, Mandatory = $True, ParameterSetName = 'Address')]
        [IntPtr]
        $FunctionAddress,

        [Parameter(Position = 3)]
        [Runtime.InteropServices.CallingConvention]
        $CallingConvention,

        [Switch]
        $DebugBreak
    )

    function local:Get-DelegateType {
        
        [OutputType([Type])]
        Param (
            [Parameter(Position = 0)]
            [Type[]]
            $Parameters = (New-Object Type[](0)),
            
            [Parameter(Position = 1)]
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

    
    try { $Kernel32 = [FunctionDelegate.Kernel32] } catch [Management.Automation.RuntimeException] {
        $DynAssembly = New-Object System.Reflection.AssemblyName('FunctionDelegate_Win32_Assembly')
        $AssemblyBuilder = [AppDomain]::CurrentDomain.DefineDynamicAssembly($DynAssembly, [Reflection.Emit.AssemblyBuilderAccess]::Run)
        $ModuleBuilder = $AssemblyBuilder.DefineDynamicModule('FunctionDelegate_Win32_Module', $False)

        $TypeBuilder = $ModuleBuilder.DefineType('FunctionDelegate.Kernel32', 'Public, Class')

        $PInvokeMethod = $TypeBuilder.DefineMethod(
                                'VirtualAlloc',
                                'Public, Static, HideBySig', 
                                [Reflection.CallingConventions]::Standard, 
                                [IntPtr],
                                [Type[]]@([IntPtr], [IntPtr], [UInt32], [UInt32]))

        $PreserveSigConstructor = [Runtime.InteropServices.PreserveSigAttribute].GetConstructor(@())
        $PreserveSigCustomAttribute = New-Object Reflection.Emit.CustomAttributeBuilder($PreserveSigConstructor, @())

        $DllImportConstructor = [Runtime.InteropServices.DllImportAttribute].GetConstructor(@([String]))
        $FieldArray = [Reflection.FieldInfo[]] @(
            [Runtime.InteropServices.DllImportAttribute].GetField('EntryPoint'),
            [Runtime.InteropServices.DllImportAttribute].GetField('SetLastError'),
            [Runtime.InteropServices.DllImportAttribute].GetField('CallingConvention')
        )

        $FieldValueArray = [Object[]] @(
            'VirtualAlloc',
            $True,
            [Runtime.InteropServices.CallingConvention]::Winapi
        )

        $DllImportCustomAttribute = New-Object Reflection.Emit.CustomAttributeBuilder($DllImportConstructor,
                                                                                        @('kernel32.dll'),
                                                                                        $FieldArray,
                                                                                        $FieldValueArray)

        $PInvokeMethod.SetCustomAttribute($DllImportCustomAttribute)
        $null = $PInvokeMethod.DefineParameter(1, 'None', 'lpAddress')
        $null = $PInvokeMethod.DefineParameter(2, 'None', 'dwSize')
        $null = $PInvokeMethod.DefineParameter(3, 'None', 'flAllocationType')
        $null = $PInvokeMethod.DefineParameter(4, 'None', 'flProtect')

        $Kernel32 = $TypeBuilder.CreateType()
    }

    if ($DebugBreak) { $Int3 = [Byte[]] @(0xCC) } else { $Int3 = [Byte[]] @(0x90) }

    if ([IntPtr]::Size -eq 4) {
        if (-not $CallingConvention) {
            throw 'You must specify a calling convention for 32-bit code.'
        }

        
        $CommonPrologueBytes = [Byte[]] @(
            0x55,      
            0x89,0xE5, 
            0x57,      
            0x56,      
            0x53       
        )

        
        $StdcallArgs = @(
            [Byte[]] @(0xFF, 0x75, 0x08), 
            [Byte[]] @(0xFF, 0x75, 0x0C)  
        )

        
        $FastcallArgs = @(
            [Byte[]] @(0x8B, 0x4D, 0x08), 
            [Byte[]] @(0x8B, 0x55, 0x0C)  
        )

        
        $ThiscallArgs = @(
            [Byte[]] @(0x8B, 0x4D, 0x08), 
            [Byte[]] @(0xFF, 0x75, 0x0C)  
        )

        
        $CommonArgs = @(
            [Byte[]] @(0xFF, 0x75, 0x10), 
            [Byte[]] @(0xFF, 0x75, 0x14), 
            [Byte[]] @(0xFF, 0x75, 0x18), 
            [Byte[]] @(0xFF, 0x75, 0x1C), 
            [Byte[]] @(0xFF, 0x75, 0x20), 
            [Byte[]] @(0xFF, 0x75, 0x24), 
            [Byte[]] @(0xFF, 0x75, 0x28), 
            [Byte[]] @(0xFF, 0x75, 0x2C)  
        )

        
        $CommonEpilogueBytes = [Byte[]] @(
            0x5B,      
            0x5E,      
            0x5F,      
            0x89,0xEC, 
            0x5D,      
            0xC3)      


        
        
        $Adjustment = [Byte[]] @([IntPtr]::Size * $Parameters.Length)

        $StackAdjustment = [Byte[]] @()

        
        
        switch ($CallingConvention) {
            'StdCall'  { $Arguments = $StdcallArgs }

            'Winapi' { $Arguments = $StdcallArgs }

            'FastCall' { $Arguments = $FastcallArgs }

            'Cdecl' {
                $Arguments = $StdcallArgs
                $StackAdjustment = [Byte[]] @(0x83, 0xC4) + $Adjustment 
            }

            'ThisCall' { $Arguments = $ThiscallArgs }
        }

        
        $Arguments += $CommonArgs

        
        $ArgumentBytes = [Byte[]] @()

        
        for ($i = 0; $i -lt $Parameters.Length; $i++) { $ArgumentBytes += $Arguments[$i] }

        
        
        
        
        
        if ($FunctionBytes) {
            $PBytes = $Kernel32::VirtualAlloc([IntPtr]::Zero, [IntPtr] $FunctionBytes.Length, 0x3000, 0x40)
            [Runtime.InteropServices.Marshal]::Copy($FunctionBytes, 0, $PBytes, $FunctionBytes.Length)
        } else {
            
            
            $PBytes = $FunctionAddress
        }

        $AddrBytes = [BitConverter]::GetBytes([Int32] $PBytes)

        
        $CallBytes = [Byte[]] @(
            0xB8 ) + $AddrBytes + [Byte[]] @( 
            0xFF, 0xD0) +                     
            $StackAdjustment

        
        [Byte[]] $FunctionWrapperBytes = $Int3 +
            $CommonPrologueBytes +
            $ArgumentBytes +
            $CallBytes +
            $CommonEpilogueBytes

        
        
        $PWrapper = $Kernel32::VirtualAlloc([IntPtr]::Zero, [IntPtr] $FunctionWrapperBytes.Length, 0x3000, 0x40)
        [Runtime.InteropServices.Marshal]::Copy($FunctionWrapperBytes, 0, $PWrapper, $FunctionWrapperBytes.Length)

        
        $Prototype = Get-DelegateType $Parameters $ReturnType
        $Delegate = [Runtime.InteropServices.Marshal]::GetDelegateForFunctionPointer($PWrapper, $Prototype)
    } else {
        if ($FunctionBytes) {
            if ($CallingConvention -eq 'FastCall') {
                

                $X64Bytes = $Int3 + $FunctionBytes

                
                
                $PBytes = $Kernel32::VirtualAlloc([IntPtr]::Zero, [IntPtr] $X64Bytes.Length, 0x3000, 0x40)
                [Runtime.InteropServices.Marshal]::Copy($X64Bytes, 0, $PBytes, $X64Bytes.Length)

                
                $Prototype = Get-DelegateType $Parameters $ReturnType
                $Delegate = [Runtime.InteropServices.Marshal]::GetDelegateForFunctionPointer($PBytes, $Prototype)
            } else {
                Write-Error "The $CallingConvention calling convention is not supported on X86_64. Only FastCall is supported."
            }
        } else {
            Write-Error '-FunctionAddress is not currently supported on X86_64.'
            return
        }
    }

    return $Delegate
}