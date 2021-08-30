
function Find-CADUser
{
    
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]
        
        $DomainUrl,
        
        [Parameter(Mandatory=$true,ParameterSetName='BysAMAccountName')]
        [string]
        
        
        $sAMAccountName
    )
   
    Set-StrictMode -Version 'Latest'

    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState
    
    $domain = [adsi] $DomainUrl
    $searcher = [adsisearcher] $domain
    
    $filterPropertyName = 'sAMAccountName'
    $filterPropertyValue = $sAMAccountName
    
    $filterPropertyValue = Format-CADSearchFilterValue $filterPropertyValue
    
    $searcher.Filter = "(&(objectClass=User) ($filterPropertyName=$filterPropertyValue))"
    try
    {
        $result = $searcher.FindOne() 
        if( $result )
        {
            $result.GetDirectoryEntry() 
        }
    }
    catch
    {
        Write-Error ("Exception finding user {0} on domain controller {1}: {2}" -f $sAMAccountName,$DomainUrl,$_.Exception.Message)
        return $null
    }
    
}

