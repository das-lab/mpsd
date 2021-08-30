
function Get-CUser
{
    
    [CmdletBinding()]
    [OutputType([System.DirectoryServices.AccountManagement.UserPrincipal])]
    param(
        [ValidateLength(1,20)]
        
        [string]$UserName 
    )

    Set-StrictMode -Version 'Latest'
    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    Write-Timing 'Get-CUser'
    
    Write-Timing ('           Creating searcher')
    $ctx = New-Object 'DirectoryServices.AccountManagement.PrincipalContext' ([DirectoryServices.AccountManagement.ContextType]::Machine)
    $query = New-Object 'DirectoryServices.AccountManagement.UserPrincipal' $ctx
    try
    {
        $users = Get-CPrincipal -Principal $query -Filter { 
            if( $UserName )
            {
                return $_.SamAccountName -eq $UserName
            }
            return $true
        }

        if( $UserName )
        {
            $usersCount = $users | Measure-Object | Select-Object -ExpandProperty 'Count'
            if( $usersCount -gt 1 )
            {
                Write-Error -Message ('Found {0} users with username "{1}".' -f $userCount,$UserName) -ErrorAction $ErrorActionPreference
            }
            if( $usersCount -eq 0 )
            {
                Write-Error -Message ('Local user "{0}" not found.' -f $Username) -ErrorAction $ErrorActionPreference
            }
        }

        return $users
    }
    finally
    {
        $query.Dispose()
        Write-Timing ('Get-CUser')
    }
}
