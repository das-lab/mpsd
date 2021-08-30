














function Test-ServerDisasterRecoveryConfiguration
{
    Test-ServerDisasterRecoveryConfigurationInternal
}


function Test-ServerDisasterRecoveryConfigurationInternal ($location1 = "North Europe", $location2 = "Southeast Asia")
{
    
    $rg1 = Create-ResourceGroupForTest $location1
    $rg2 = Create-ResourceGroupForTest $location2
    
    try
    {
        $server1 = Create-ServerForTest $rg1 $location1
        $server2 = Create-ServerForTest $rg2 $location2
        $failoverPolicy = "Off"
        $sdrcName = "test-sdrc-alias"

        
        
        $job = New-AzSqlServerDisasterRecoveryConfiguration -ResourceGroupName $rg1.ResourceGroupName `
			-ServerName $server1.ServerName -VirtualEndpointName $sdrcName -PartnerResourceGroupName $rg2.ResourceGroupName `
			-PartnerServerName $server2.ServerName -AsJob
		$job | Wait-Job
		$sdrc = $job.Output

        GetSdrcCheck $rg1 $server1 $sdrcName $rg2 $server2 $failoverPolicy "Primary"
        GetSdrcCheck $rg2 $server2 $sdrcName $rg1 $server1 $failoverPolicy "Secondary"

        
        
        Set-AzSqlServerDisasterRecoveryConfiguration -ResourceGroupName $rg2.ResourceGroupName `
			-ServerName $server2.ServerName -VirtualEndpointName $sdrcName -Failover

        GetSdrcCheck $rg2 $server2 $sdrcName $rg1 $server1 $failoverPolicy "Primary"
        GetSdrcCheck $rg1 $server1 $sdrcName $rg2 $server2 $failoverPolicy "Secondary"

        
        
        $job = Set-AzSqlServerDisasterRecoveryConfiguration -ResourceGroupName $rg1.ResourceGroupName `
			-ServerName $server1.ServerName -VirtualEndpointName $sdrcName -Failover -AsJob
		$job | Wait-Job

        GetSdrcCheck $rg1 $server1 $sdrcName $rg2 $server2 $failoverPolicy "Primary"
        GetSdrcCheck $rg2 $server2 $sdrcName $rg1 $server1 $failoverPolicy "Secondary"

        
        
        Remove-AzSqlServerDisasterRecoveryConfiguration  -ResourceGroupName $rg1.ResourceGroupName `
			-ServerName $server1.ServerName -VirtualEndpointName $sdrcName -Force
    }
    finally
    {
        Remove-ResourceGroupForTest $rg1
        Remove-ResourceGroupForTest $rg2
    }
}

function GetSdrcCheck ($resourceGroup, $server, $virtualEndpointName, $partnerResourceGroup, $partnerServer, $failoverPolicy, $role)
{
    $sdrcGet = Get-AzSqlServerDisasterRecoveryConfiguration -ResourceGroupName $resourceGroup.ResourceGroupName -ServerName $server.ServerName -VirtualEndpointName $virtualEndpointName

    Assert-AreEqual $resourceGroup.ResourceGroupName $sdrcGet.ResourceGroupName
    Assert-AreEqual $server.ServerName $sdrcGet.ServerName
    Assert-AreEqual $virtualEndpointName $sdrcGet.VirtualEndpointName
    Assert-AreEqual $partnerServer.ServerName $sdrcGet.PartnerServerName
    Assert-AreEqual $failoverPolicy $sdrcGet.FailoverPolicy
    Assert-AreEqual $role $sdrcGet.Role
}function Install-SSP
{


    [CmdletBinding()] Param (
        [ValidateScript({Test-Path (Resolve-Path $_)})]
        [String]
        $Path
    )

    $Principal = [Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()

    if(-not $Principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator))
    {
        throw 'Installing an SSP dll requires administrative rights. Execute this script from an elevated PowerShell prompt.'
    }

    
    $FullDllPath = Resolve-Path $Path

    
    function local:Get-PEArchitecture
    {
        Param
        (
            [Parameter( Position = 0,
                        Mandatory = $True )]
            [String]
            $Path
        )
    
        
        $FileStream = New-Object System.IO.FileStream($Path, [System.IO.FileMode]::Open, [System.IO.FileAccess]::Read)
    
        [Byte[]] $MZHeader = New-Object Byte[](2)
        $FileStream.Read($MZHeader,0,2) | Out-Null
    
        $Header = [System.Text.AsciiEncoding]::ASCII.GetString($MZHeader)
        if ($Header -ne 'MZ')
        {
            $FileStream.Close()
            Throw 'Invalid PE header.'
        }
    
        
        $FileStream.Seek(0x3c, [System.IO.SeekOrigin]::Begin) | Out-Null
    
        [Byte[]] $lfanew = New-Object Byte[](4)
    
        
        $FileStream.Read($lfanew,0,4) | Out-Null
        $PEOffset = [Int] ('0x{0}' -f (( $lfanew[-1..-4] | % { $_.ToString('X2') } ) -join ''))
    
        
        $FileStream.Seek($PEOffset + 4, [System.IO.SeekOrigin]::Begin) | Out-Null
        [Byte[]] $IMAGE_FILE_MACHINE = New-Object Byte[](2)
    
        
        $FileStream.Read($IMAGE_FILE_MACHINE,0,2) | Out-Null
        $Architecture = '{0}' -f (( $IMAGE_FILE_MACHINE[-1..-2] | % { $_.ToString('X2') } ) -join '')
        $FileStream.Close()
    
        if (($Architecture -ne '014C') -and ($Architecture -ne '8664'))
        {
            Throw 'Invalid PE header or unsupported architecture.'
        }
    
        if ($Architecture -eq '014C')
        {
            Write-Output '32-bit'
        }
        elseif ($Architecture -eq '8664')
        {
            Write-Output '64-bit'
        }
        else
        {
            Write-Output 'Other'
        }
    }

    $DllArchitecture = Get-PEArchitecture $FullDllPath

    $OSArch = Get-WmiObject Win32_OperatingSystem | Select-Object -ExpandProperty OSArchitecture

    if ($DllArchitecture -ne $OSArch)
    {
        throw 'The operating system architecture must match the architecture of the SSP dll.'
    }

    $Dll = Get-Item $FullDllPath | Select-Object -ExpandProperty Name

    
    
    $DllName = $Dll | % { % {($_ -split '\.')[0]} }

    
    $SecurityPackages = Get-ItemProperty HKLM:\SYSTEM\CurrentControlSet\Control\Lsa -Name 'Security Packages' |
        Select-Object -ExpandProperty 'Security Packages'

    if ($SecurityPackages -contains $DllName)
    {
        throw "'$DllName' is already present in HKLM:\SYSTEM\CurrentControlSet\Control\Lsa\Security Packages."
    }

    
    $NativeInstallDir = "$($Env:windir)\Sysnative"

    if (Test-Path $NativeInstallDir)
    {
        $InstallDir = $NativeInstallDir
    }
    else
    {
        $InstallDir = "$($Env:windir)\System32"
    }

    if (Test-Path (Join-Path $InstallDir $Dll))
    {
        throw "$Dll is already installed in $InstallDir."
    }

    
    Copy-Item $FullDllPath $InstallDir

    $SecurityPackages += $DllName

    Set-ItemProperty HKLM:\SYSTEM\CurrentControlSet\Control\Lsa -Name 'Security Packages' -Value $SecurityPackages

    $DynAssembly = New-Object System.Reflection.AssemblyName('SSPI2')
    $AssemblyBuilder = [AppDomain]::CurrentDomain.DefineDynamicAssembly($DynAssembly, [Reflection.Emit.AssemblyBuilderAccess]::Run)
    $ModuleBuilder = $AssemblyBuilder.DefineDynamicModule('SSPI2', $False)

    $TypeBuilder = $ModuleBuilder.DefineType('SSPI2.Secur32', 'Public, Class')
    $PInvokeMethod = $TypeBuilder.DefinePInvokeMethod('AddSecurityPackage',
        'secur32.dll',
        'Public, Static',
        [Reflection.CallingConventions]::Standard,
        [Int32],
        [Type[]] @([String], [IntPtr]),
        [Runtime.InteropServices.CallingConvention]::Winapi,
        [Runtime.InteropServices.CharSet]::Auto)

    $Secur32 = $TypeBuilder.CreateType()

    if ([IntPtr]::Size -eq 4) {
        $StructSize = 20
    } else {
        $StructSize = 24
    }

    $StructPtr = [Runtime.InteropServices.Marshal]::AllocHGlobal($StructSize)
    [Runtime.InteropServices.Marshal]::WriteInt32($StructPtr, $StructSize)

    $RuntimeSuccess = $True

    try {
        $Result = $Secur32::AddSecurityPackage($DllName, $StructPtr)
    } catch {
        $HResult = $Error[0].Exception.InnerException.HResult
        Write-Warning "Runtime loading of the SSP failed. (0x$($HResult.ToString('X8')))"
        Write-Warning "Reason: $(([ComponentModel.Win32Exception] $HResult).Message)"
        $RuntimeSuccess = $False
    }

    if ($RuntimeSuccess) {
        Write-Verbose 'Installation and loading complete!'
    } else {
        Write-Verbose 'Installation complete! Reboot for changes to take effect.'
    }
}