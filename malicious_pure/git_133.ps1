function Get-VolumeShadowCopy
{


    $UserIdentity = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent())

    if (-not $UserIdentity.IsInRole([Security.Principal.WindowsBuiltInRole]'Administrator'))
    {
        Throw 'You must run Get-VolumeShadowCopy from an elevated command prompt.'
    }

    Get-WmiObject -Namespace root\cimv2 -Class Win32_ShadowCopy | ForEach-Object { $_.DeviceObject }
}

function New-VolumeShadowCopy
{

    Param(
        [Parameter(Mandatory = $True)]
        [ValidatePattern('^\w:\\')]
        [String]
        $Volume,

        [Parameter(Mandatory = $False)]
        [ValidateSet("ClientAccessible")]
        [String]
        $Context = "ClientAccessible"
    )

    $UserIdentity = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent())

    if (-not $UserIdentity.IsInRole([Security.Principal.WindowsBuiltInRole]'Administrator'))
    {
        Throw 'You must run Get-VolumeShadowCopy from an elevated command prompt.'
    }

    
    $running = (Get-Service -Name VSS).Status

    $class = [WMICLASS]"root\cimv2:win32_shadowcopy"

    $return = $class.create("$Volume", "$Context")

    switch($return.returnvalue)
    {
        1 {Write-Error "Access denied."; break}
        2 {Write-Error "Invalid argument."; break}
        3 {Write-Error "Specified volume not found."; break}
        4 {Write-Error "Specified volume not supported."; break}
        5 {Write-Error "Unsupported shadow copy context."; break}
        6 {Write-Error "Insufficient storage."; break}
        7 {Write-Error "Volume is in use."; break}
        8 {Write-Error "Maximum number of shadow copies reached."; break}
        9 {Write-Error "Another shadow copy operation is already in progress."; break}
        10 {Write-Error "Shadow copy provider vetoed the operation."; break}
        11 {Write-Error "Shadow copy provider not registered."; break}
        12 {Write-Error "Shadow copy provider failure."; break}
        13 {Write-Error "Unknown error."; break}
        default {break}
    }

    
    if($running -eq "Stopped")
    {
        Stop-Service -Name VSS
    }
}

function Remove-VolumeShadowCopy
{

    [CmdletBinding(SupportsShouldProcess = $True)]
    Param(
        [Parameter(Mandatory = $True, ValueFromPipeline = $True)]
        [ValidatePattern('^\\\\\?\\GLOBALROOT\\Device\\HarddiskVolumeShadowCopy[0-9]{1,3}$')]
        [String]
        $DevicePath
    )

    PROCESS
    {
        if($PSCmdlet.ShouldProcess("The VolumeShadowCopy at DevicePath $DevicePath will be removed"))
        {
            (Get-WmiObject -Namespace root\cimv2 -Class Win32_ShadowCopy | Where-Object {$_.DeviceObject -eq $DevicePath}).Delete()
        }
    }
}

function Mount-VolumeShadowCopy
{


    Param (
        [Parameter(Mandatory = $True)]
        [ValidateNotNullOrEmpty()]
        [String]
        $Path,

        [Parameter(Mandatory = $True, ValueFromPipeline = $True)]
        [ValidatePattern('^\\\\\?\\GLOBALROOT\\Device\\HarddiskVolumeShadowCopy[0-9]{1,3}$')]
        [String[]]
        $DevicePath
    )

    BEGIN
    {
        $UserIdentity = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent())

        if (-not $UserIdentity.IsInRole([Security.Principal.WindowsBuiltInRole]'Administrator'))
        {
            Throw 'You must run Get-VolumeShadowCopy from an elevated command prompt.'
        }

        
        Get-ChildItem $Path -ErrorAction Stop | Out-Null

        $DynAssembly = New-Object System.Reflection.AssemblyName('VSSUtil')
        $AssemblyBuilder = [AppDomain]::CurrentDomain.DefineDynamicAssembly($DynAssembly, [Reflection.Emit.AssemblyBuilderAccess]::Run)
        $ModuleBuilder = $AssemblyBuilder.DefineDynamicModule('VSSUtil', $False)

        
        
        $TypeBuilder = $ModuleBuilder.DefineType('VSS.Kernel32', 'Public, Class')
        $PInvokeMethod = $TypeBuilder.DefinePInvokeMethod('CreateSymbolicLink',
                                                            'kernel32.dll',
                                                            ([Reflection.MethodAttributes]::Public -bor [Reflection.MethodAttributes]::Static),
                                                            [Reflection.CallingConventions]::Standard,
                                                            [Bool],
                                                            [Type[]]@([String], [String], [UInt32]),
                                                            [Runtime.InteropServices.CallingConvention]::Winapi,
                                                            [Runtime.InteropServices.CharSet]::Auto)
        $DllImportConstructor = [Runtime.InteropServices.DllImportAttribute].GetConstructor(@([String]))
        $SetLastError = [Runtime.InteropServices.DllImportAttribute].GetField('SetLastError')
        $SetLastErrorCustomAttribute = New-Object Reflection.Emit.CustomAttributeBuilder($DllImportConstructor,
                                                                                         @('kernel32.dll'),
                                                                                         [Reflection.FieldInfo[]]@($SetLastError),
                                                                                         @($true))
        $PInvokeMethod.SetCustomAttribute($SetLastErrorCustomAttribute)

        $Kernel32Type = $TypeBuilder.CreateType()
    }

    PROCESS
    {
        foreach ($Volume in $DevicePath)
        {
            $Volume -match '^\\\\\?\\GLOBALROOT\\Device\\(?<LinkName>HarddiskVolumeShadowCopy[0-9]{1,3})$' | Out-Null
            
            $LinkPath = Join-Path $Path $Matches.LinkName

            if (Test-Path $LinkPath)
            {
                Write-Warning "'$LinkPath' already exists."
                continue
            }

            if (-not $Kernel32Type::CreateSymbolicLink($LinkPath, "$($Volume)\", 1))
            {
                Write-Error "Symbolic link creation failed for '$Volume'."
                continue
            }

            Get-Item $LinkPath
        }
    }

    END
    {

    }
}
