
function Get-CRegistryKeyValue
{
    
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]
        
        $Path,
        
        [Parameter(Mandatory=$true)]
        [string]
        
        $Name
    )
    
    Set-StrictMode -Version 'Latest'

    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    if( -not (Test-CRegistryKeyValue -Path $Path -Name $Name) )
    {
        return $null
    }
    
    $itemProperties = Get-ItemProperty -Path $Path -Name *
    $value = $itemProperties.$Name
    Write-Debug -Message ('[{0}@{1}: {2} -is {3}' -f $Path,$Name,$value,$value.GetType())
    return $value
}

