
function Get-CGroup
{
    
    [CmdletBinding()]
    [OutputType([DirectoryServices.AccountManagement.GroupPrincipal])]
    param(
        
        [string]$Name 
    )

    Set-StrictMode -Version 'Latest'
    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    Write-Timing ('Get-CGroup')

    $ctx = New-Object 'DirectoryServices.AccountManagement.PrincipalContext' ([DirectoryServices.AccountManagement.ContextType]::Machine)
    $query = New-Object 'DirectoryServices.AccountManagement.GroupPrincipal' $ctx
    try
    {
        $groups = Get-CPrincipal -Principal $query -Filter {
            if( $Name )
            {
                return $_.Name -eq $Name
            }
            return $true
        }

        if( $Name )
        {
            $groupCount = $groups | Measure-Object | Select-Object -ExpandProperty 'Count'
            if( $groupCount -gt 1 )
            {
                Write-Error -Message ('Found {0} groups named "{1}".' -f $groupCount,$Name) -ErrorAction:$ErrorActionPreference
                return
            }

            if( $groupCount -eq 0 )
            {
                Write-Error ('Local group "{0}" not found.' -f $Name) -ErrorAction:$ErrorActionPreference
                return
            }
        }

        return $groups
    }
    finally
    {
        $query.Dispose()
        Write-Timing ('Get-CGroup')
    }
}
