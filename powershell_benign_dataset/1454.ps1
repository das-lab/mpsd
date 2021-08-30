
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
