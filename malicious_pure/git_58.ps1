function New-HoneyHash {

    [CmdletBinding()]
    Param (
        [Parameter(Mandatory = $True, Position = 0)]
        [ValidateNotNullOrEmpty()]
        [String]
        $Domain,

        [Parameter(Mandatory = $True, Position = 1)]
        [ValidateNotNullOrEmpty()]
        [String]
        $Username,

        [Parameter(Mandatory = $True, Position = 1)]
        [ValidateNotNullOrEmpty()]
        [String]
        $Password
    )

    $PSPassword = $Password | ConvertTo-SecureString -asPlainText -Force

    $SystemModule = [Microsoft.Win32.IntranetZoneCredentialPolicy].Module
    $NativeMethods = $SystemModule.GetType('Microsoft.Win32.NativeMethods')
    $SafeNativeMethods = $SystemModule.GetType('Microsoft.Win32.SafeNativeMethods')
    $CreateProcessWithLogonW = $NativeMethods.GetMethod('CreateProcessWithLogonW', [Reflection.BindingFlags] 'NonPublic, Static')
    $LogonFlags = $NativeMethods.GetNestedType('LogonFlags', [Reflection.BindingFlags] 'NonPublic')
    $StartupInfo = $NativeMethods.GetNestedType('STARTUPINFO', [Reflection.BindingFlags] 'NonPublic')
    $ProcessInformation = $SafeNativeMethods.GetNestedType('PROCESS_INFORMATION', [Reflection.BindingFlags] 'NonPublic')

    $Flags = [Activator]::CreateInstance($LogonFlags)
    $Flags.value__ = 2 
    $StartInfo = [Activator]::CreateInstance($StartupInfo)
    $ProcInfo = [Activator]::CreateInstance($ProcessInformation)

    $Credential = New-Object System.Management.Automation.PSCredential("$($Domain)\$($UserName)",$PSPassword)

    $PasswordPtr = [System.Runtime.InteropServices.Marshal]::SecureStringToCoTaskMemUnicode($Credential.Password)
    $StrBuilder = New-Object System.Text.StringBuilder
    $null = $StrBuilder.Append('cmd.exe')

    $Result = $CreateProcessWithLogonW.Invoke($null, @([String] $UserName,
                                             [String] $Domain,
                                             [IntPtr] $PasswordPtr,
                                             ($Flags -as $LogonFlags),     
                                             $null,
                                             [Text.StringBuilder] $StrBuilder,
                                             0x08000000, 
                                             $null,
                                             $null,
                                             $StartInfo,
                                             $ProcInfo))

    if (-not $Result) {
        throw 'Unable to create process as user.'
    }

    if ($ProcInfo.dwProcessId) {
        
        Stop-Process -Id $ProcInfo.dwProcessId
    }

    '"Honey hash" injected into LSASS successfully! Use Mimikatz to confirm.'
}