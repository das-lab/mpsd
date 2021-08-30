
function Install-CUser
{
    
    [CmdletBinding(SupportsShouldProcess=$true,DefaultParameterSetName='WithUserNameAndPassword')]
    [OutputType([System.DirectoryServices.AccountManagement.UserPrincipal])]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingUserNameAndPassWordParams","")]
    param(
        [Parameter(Mandatory=$true,ParameterSetName='WithUserNameAndPassword',DontShow=$true)]
        [ValidateLength(1,20)]
        [string]
        
        $UserName,
        
        [Parameter(Mandatory=$true,ParameterSetName='WithUserNameAndPassword',DontShow=$true)]
        [string]
        
        $Password,

        [Parameter(Mandatory=$true,ParameterSetName='WithCredential')]
        [pscredential]
        
        
        
        $Credential,
        
        [string]
        
        $Description,
        
        [string]
        
        $FullName,

        [Switch]
        
        $UserCannotChangePassword,

        [Switch]
        
        $PasswordExpires,

        [Switch]
        
        $PassThru
    )

    Set-StrictMode -Version 'Latest'
    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    Write-Timing 'Install-CUser Start'
    
    if( $PSCmdlet.ParameterSetName -eq 'WithCredential' )
    {
        $UserName = $Credential.UserName
    }


    Write-Timing '              Getting user'
    $user = Get-CUser -userName $UserName -ErrorAction Ignore
    
    Write-Timing '              Creating PrincipalContext'
    if( $user )
    {
        $ctx = $user.Context
    }
    else
    {
        $ctx = New-Object 'DirectoryServices.AccountManagement.PrincipalContext' ([DirectoryServices.AccountManagement.ContextType]::Machine)
    }

    try
    {
        $operation = 'update'
        if( -not $user )
        {
            Write-Timing '              Creating UserPrincipal'
            $operation = 'create'
            $user = New-Object 'DirectoryServices.AccountManagement.UserPrincipal' $ctx
            $creating = $true
        }

        $user.SamAccountName = $UserName
        $user.DisplayName = $FullName
        $user.Description = $Description
        $user.UserCannotChangePassword = $UserCannotChangePassword
        $user.PasswordNeverExpires = -not $PasswordExpires

        Write-Timing '              Setting password'
        if( $PSCmdlet.ParameterSetName -eq 'WithUserNameAndPassword' )
        {
            Write-Warning ('Install-CUser function''s `UserName` and `Password` parameters are obsolete and will be removed in a future version of Carbon. Please use the `Credential` parameter instead.')
            $user.SetPassword( $Password )
        }
        else
        {
            $user.SetPassword( $Credential.GetNetworkCredential().Password )
        }


        if( $PSCmdlet.ShouldProcess( $Username, "$operation local user" ) )
        {
            Write-Timing '              Saving'
            $user.Save()
        }

        if( $PassThru )
        {
            return $user
        }
    }
    finally
    {
        Write-Timing '              Finally'
        if( -not $PassThru )
        {
            $user.Dispose()
            $ctx.Dispose()
        }
        Write-Timing 'Install-CUser Done'
    }
}

