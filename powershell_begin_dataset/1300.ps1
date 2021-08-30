
function Install-CGroup
{
    
    [CmdletBinding(SupportsShouldProcess=$true)]
    [OutputType([DirectoryServices.AccountManagement.GroupPrincipal])]
    param(
        [Parameter(Mandatory=$true)]
        [string]
        
        $Name,
        
        [string]
        
        $Description = '',
        
        [Alias('Members')]
        [string[]]
        
        $Member = @(),

        [Switch]
        
        
        
        $PassThru
    )
    
    Set-StrictMode -Version 'Latest'
    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState
    
    $group = Get-CGroup -Name $Name -ErrorAction Ignore

    if( $group )
    {
        $ctx = $group.Context
    }
    else
    {
        $ctx = New-Object 'DirectoryServices.AccountManagement.PrincipalContext' ([DirectoryServices.AccountManagement.ContextType]::Machine)
    }

    $operation = 'update'
    $save = $false
    $new = $false
    if( -not $group )
    {
        $operation = 'create'
        $new = $true
        $group = New-Object 'DirectoryServices.AccountManagement.GroupPrincipal' $ctx
        $group.Name = $Name
        $group.Description = $Description
        $save = $true
    }
    else
    {
        
        if( $group.Description -ne $Description -and ($group.Description -or $Description) )
        {
            Write-Verbose -Message ('[{0}] Description  {1} -> {2}' -f $Name,$group.Description,$Description)
            $group.Description = $Description
            $save = $true
        }
    }

    try
    {

        if( $save -and $PSCmdlet.ShouldProcess( ('local group {0}' -f $Name), $operation ) )
        {
            if( $new )
            {
                Write-Verbose -Message ('[{0}]              +' -f $Name)
            }
            $group.Save()
        }

        if( $Member -and $PSCmdlet.ShouldProcess( ('local group {0}' -f $Name), 'adding members' ) )
        {
            Add-CGroupMember -Name $Name -Member $Member
        }
    
        if( $PassThru )
        {
            return $group
        }
    }
    finally
    {
        if( -not $PassThru )
        {
            $group.Dispose()
            $ctx.Dispose()
        }

    }
}

