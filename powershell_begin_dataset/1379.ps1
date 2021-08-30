
function Uninstall-CFileShare
{
    
    [CmdletBinding(SupportsShouldProcess=$true)]
    param(
        [Parameter(Mandatory=$true)]
        [string]
        
        $Name
    )

    Set-StrictMode -Version 'Latest'

    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

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

    if( -not (Test-CFileShare -Name $Name) )
    {
        return
    }

    Get-CFileShare -Name $Name |
        ForEach-Object { 
            $share = $_
            $deletePhysicalPath = $false
            if( -not (Test-Path -Path $share.Path -PathType Container) )
            {
                New-Item -Path $share.Path -ItemType 'Directory' -Force | Out-String | Write-Debug
                $deletePhysicalPath = $true
            }

            if( $PSCmdlet.ShouldProcess( ('{0} ({1})' -f $share.Name,$share.Path), 'delete' ) )
            {
                Write-Verbose ('Deleting file share ''{0}'' (Path: {1}).' -f $share.Name,$share.Path)
                $result = $share.Delete() 
                if( $result.ReturnValue )
                {
                    Write-Error ('Failed to delete share ''{0}'' (Path: {1}). Win32_Share.Delete() method returned error code {2} which means: {3}.' -f $Name,$share.Path,$result.ReturnValue,$errors[$result.ReturnValue])
                }
            }

            if( $deletePhysicalPath -and (Test-Path -Path $share.Path) )
            {
                Remove-Item -Path $share.Path -Force -Recurse
            }
        }
}

