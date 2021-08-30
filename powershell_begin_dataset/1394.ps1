
function Get-CFileShare
{
    
    [CmdletBinding()]
    param(
        [string]
        
        $Name
    )

    Set-StrictMode -Version 'Latest'

    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    $filter = '(Type = 0 or Type = 2147483648)'
    $wildcardSearch = [Management.Automation.WildcardPattern]::ContainsWildcardCharacters($Name)
    if( $Name -and -not $wildcardSearch)
    {
        $filter = '{0} and Name = ''{1}''' -f $filter,$Name
    }

    $shares = Get-WmiObject -Class 'Win32_Share' -Filter $filter |
                    Where-Object { 
                        if( -not $wildcardSearch )
                        {
                            return $true
                        }

                        return $_.Name -like $Name
                    }
    
    if( $Name -and -not $shares -and -not $wildcardSearch )
    {
        Write-Error ('Share ''{0}'' not found.' -f $Name) -ErrorAction $ErrorActionPreference
    }

    $shares
}

