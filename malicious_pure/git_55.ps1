function Invoke-PsExec {

    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $True)] 
        [String]
        $ComputerName,

        [String]
        $Command,

        [String]
        $ServiceName = "TestSVC",

        [String]
        $ResultFile,

        [String]
        $ServiceEXE,

        [switch]
        $NoCleanup
    )

    $ErrorActionPreference = "Stop"

    
    function Local:Get-RandomString 
    {
        param (
            [int]$Length = 12
        )
        $set = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ".ToCharArray()
        $result = ""
        for ($x = 0; $x -lt $Length; $x++) {
            $result += $set | Get-Random
        }
        $result
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


    function Local:Invoke-PsExecCmd
    {
        param(
            [Parameter(Mandatory = $True)] 
            [String]
            $ComputerName,

            [Parameter(Mandatory = $True)]
            [String]
            $Command,

            [String]
            $ServiceName = "TestSVC",

            [switch]
            $NoCleanup
        )

        
        
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

        
        
        
        
        $ManagerHandle = $OpenSCManagerA.Invoke("\\$ComputerName", "ServicesActive", 0xF003F)
        

        
        if ($ManagerHandle -and ($ManagerHandle -ne 0)){

            
            
            
            
            
            
            $ServiceHandle = $CreateServiceA.Invoke($ManagerHandle, $ServiceName, $ServiceName, 0xF003F, 0x10, 0x3, 0x1, $Command, $null, $null, $null, $null, $null)
            

            if ($ServiceHandle -and ($ServiceHandle -ne 0)){

                

                
                
                $t = $CloseServiceHandle.Invoke($ServiceHandle)

                
                
                $ServiceHandle = $OpenServiceA.Invoke($ManagerHandle, $ServiceName, 0xF003F)
                

                if ($ServiceHandle -and ($ServiceHandle -ne 0)){

                    
                    
                    $val = $StartServiceA.Invoke($ServiceHandle, $null, $null)

                    
                    if ($val -ne 0){
                        
                        
                        Start-Sleep -s 1
                    }
                    else{
                        
                        $err = $GetLastError.Invoke()
                        if ($err -eq 1053){
                            
                        }
                        else{
                            
                            "[!] StartService failed, LastError: $err"
                        }
                        
                        Start-Sleep -s 1
                    }

                    if (-not $NoCleanup) {
                        
                        
                        
                        $val = $DeleteService.invoke($ServiceHandle)
                        
                        if ($val -eq 0){
                            
                            $err = $GetLastError.Invoke()
                            
                        }
                        else{
                            
                        }
                    }
                    
                    
                    
                    $val = $CloseServiceHandle.Invoke($ServiceHandle)
                    

                }
                else{
                    
                    $err = $GetLastError.Invoke()
                    
                    "[!] OpenServiceA failed, LastError: $err"
                }
            }

            else{
                
                $err = $GetLastError.Invoke()
                
                "[!] CreateService failed, LastError: $err"
            }

            
            
            $t = $CloseServiceHandle.Invoke($ManagerHandle)
        }
        else{
            
            $err = $GetLastError.Invoke()
            
            "[!] OpenSCManager failed, LastError: $err"
        }
    }

    if ($Command -and ($Command -ne "")) { 

        if ($ResultFile -and ($ResultFile -ne "")) {
            

            
            $TempText = $(Get-RandomString) + ".txt"
            $TempBat = $(Get-RandomString) + ".bat"

            
            $cmd = "%COMSPEC% /C echo $Command ^> %systemroot%\Temp\$TempText > %systemroot%\Temp\$TempBat & %COMSPEC% /C start %COMSPEC% /C %systemroot%\Temp\$TempBat"

            

            try {
                
                "[*] Executing command and retrieving results: '$Command'"
                Invoke-PsExecCmd -ComputerName $ComputerName -Command $cmd -ServiceName $ServiceName

                
                $RemoteResultFile = "\\$ComputerName\Admin$\Temp\$TempText"
                "[*] Copying result file $RemoteResultFile to '$ResultFile'"
                Copy-Item -Force -Path $RemoteResultFile -Destination $ResultFile
                
                
                
                Remove-Item -Force $RemoteResultFile

                
                Remove-Item -Force "\\$ComputerName\Admin$\Temp\$TempBat"
            }
            catch {
                
                "Error: $_"
            }
        }

        else {
            
            
            Invoke-PsExecCmd -ComputerName $ComputerName -Command $Command -ServiceName $ServiceName
        }

    }

    elseif ($ServiceEXE -and ($ServiceEXE -ne "")) {
        

        
        $RemoteUploadPath = "\\$ComputerName\Admin$\$ServiceEXE"
        "[*] Copying service binary $ServiceEXE to '$RemoteUploadPath'"
        Copy-Item -Force -Path $ServiceEXE -Destination $RemoteUploadPath

        if(-not $NoCleanup) {
            
            "[*] Executing service .EXE '$RemoteUploadPath' as service '$ServiceName' and cleaning up."
            Invoke-PsExecCmd -ComputerName $ComputerName -Command $RemoteUploadPath -ServiceName $ServiceName

            
            "[*] Removing the remote service .EXE '$RemoteUploadPath'"
            Remove-Item -Path $RemoteUploadPath -Force
        }
        else {
            
           "[*] Executing service .EXE '$RemoteUploadPath' as service '$ServiceName' and not cleaning up."
            Invoke-PsExecCmd -ComputerName $ComputerName -Command $RemoteUploadPath -ServiceName $ServiceName -NoCleanup
        }
    }

    else {
        
        
    }
}
