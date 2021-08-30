function Invoke-LoadLibrary {


    [OutputType([Diagnostics.ProcessModule])]
    [CmdletBinding()]
    Param (
        [Parameter(Position = 0, Mandatory = $True, ValueFromPipeline = $True)]
        [ValidateNotNullOrEmpty()]
        [String]
        $FileName
    )

    BEGIN {
        $SafeNativeMethods = $null
        $LoadLibrary = $null

        
        
        
        $UnmanagedClass = 'Microsoft.Win32.SafeNativeMethods'
        $SafeNativeMethods = [Uri].Assembly.GetType($UnmanagedClass)

        
        
        
        if ($SafeNativeMethods -eq $null) {
            throw 'Unable to get a reference to the ' +
                  'Microsoft.Win32.SafeNativeMethods within System.dll.'
        }

        $LoadLibrary = $SafeNativeMethods.GetMethod('LoadLibrary')

        if ($LoadLibrary -eq $null) {
            throw 'Unable to get a reference to LoadLibrary within' +
                  'Microsoft.Win32.SafeNativeMethods.'
        }
    }

    PROCESS {
        $LoadedModuleInfo = $null

        $LibAddress = $LoadLibrary.Invoke($null, @($FileName))
        $Exception = [Runtime.InteropServices.Marshal]::GetLastWin32Error()

        if ($LibAddress -eq [IntPtr]::Zero) {
            $Exception = New-Object ComponentModel.Win32Exception($Exception)
            throw $Exception.Message
        }

        $IntPtrPrintWidth = "X$([IntPtr]::Size * 2)"

        Write-Verbose "$FileName loaded at 0x$(($LibAddress).ToString($IntPtrPrintWidth))"

        $CurrentProcess = Get-Process -Id $PID

        $LoadedModuleInfo = $CurrentProcess.Modules |
            Where-Object { $_.BaseAddress -eq $LibAddress }

        if ($LoadedModuleInfo -eq $null) {
            throw 'Unable to obtain loaded module information for ' +
                "$FileName. The module was likely already unloaded."
        }

        return $LoadedModuleInfo
    }
}

function New-DllExportFunction {


    [OutputType([Delegate])]
    Param (
        [Parameter(Mandatory = $True)]
        [Diagnostics.ProcessModule]
        [ValidateNotNull()]
        $Module,

        [Parameter(Mandatory = $True)]
        [String]
        [ValidateNotNullOrEmpty()]
        $ProcedureName,

        [Type[]]
        $Parameters = (New-Object Type[](0)),

        [Type]
        $ReturnType = [Void]
    )

    function Local:Get-DelegateType
    {
        [OutputType([Type])]
        Param (    
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
        $ModuleBuilder = $AssemblyBuilder.DefineDynamicModule('InMemoryModule', $False)
        $TypeBuilder = $ModuleBuilder.DefineType('MyDelegateType', 'Class, Public, Sealed, AnsiClass, AutoClass', [System.MulticastDelegate])
        $ConstructorBuilder = $TypeBuilder.DefineConstructor('RTSpecialName, HideBySig, Public', [System.Reflection.CallingConventions]::Standard, $Parameters)
        $ConstructorBuilder.SetImplementationFlags('Runtime, Managed')
        $MethodBuilder = $TypeBuilder.DefineMethod('Invoke', 'Public, HideBySig, NewSlot, Virtual', $ReturnType, $Parameters)
        $MethodBuilder.SetImplementationFlags('Runtime, Managed')
        
        return $TypeBuilder.CreateType()
    }

    function Local:Get-ProcAddress
    {
        [OutputType([IntPtr])]
        Param (
            [Parameter( Position = 0, Mandatory = $True )]
            [Diagnostics.ProcessModule]
            $Module,
            
            [Parameter( Position = 1, Mandatory = $True )]
            [String]
            $ProcedureName
        )

        $UnsafeNativeMethods = $null
        $GetProcAddress = $null

        
        
        
        $UnmanagedClass = 'Microsoft.Win32.UnsafeNativeMethods'
        $UnsafeNativeMethods = [Uri].Assembly.GetType($UnmanagedClass)

        
        
        
        if ($UnsafeNativeMethods -eq $null) {
            throw 'Unable to get a reference to the ' +
                  'Microsoft.Win32.UnsafeNativeMethods within System.dll.'
        }

        $GetProcAddress = $UnsafeNativeMethods.GetMethod('GetProcAddress')

        if ($GetProcAddress -eq $null) {
            throw 'Unable to get a reference to GetProcAddress within' +
                  'Microsoft.Win32.UnsafeNativeMethods.'
        }

        $TempPtr = New-Object IntPtr
        $HandleRef = New-Object System.Runtime.InteropServices.HandleRef($TempPtr, $Module.BaseAddress)
        
        $ProcAddr = $GetProcAddress.Invoke($null, @([Runtime.InteropServices.HandleRef] $HandleRef, $ProcedureName))

        if ($ProcAddr -eq [IntPtr]::Zero) {
            Write-Error "Unable to obtain the address of $($Module.ModuleName)!$ProcedureName. $ProcedureName is likely not exported."

            return [IntPtr]::Zero
        }

        return $ProcAddr
    }

    $ProcAddress = Get-ProcAddress -Module $Module -ProcedureName $ProcedureName

    if ($ProcAddress -ne [IntPtr]::Zero) {
        $IntPtrPrintWidth = "X$([IntPtr]::Size * 2)"

        Write-Verbose "$($Module.ModuleName)!$ProcedureName address: 0x$(($ProcAddress).ToString($IntPtrPrintWidth))"
    
        $DelegateType = Get-DelegateType -Parameters $Parameters -ReturnType $ReturnType
        $ProcedureDelegate = [Runtime.InteropServices.Marshal]::GetDelegateForFunctionPointer($ProcAddress, $DelegateType)

        return $ProcedureDelegate
    }
}