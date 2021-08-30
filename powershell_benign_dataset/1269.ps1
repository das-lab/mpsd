
function Get-CHttpUrlAcl
{
    
    [CmdletBinding(DefaultParameterSetName='AllUrls')]
    [OutputType([Carbon.Security.HttpUrlSecurity])]
    param(
        [Parameter(ParameterSetName='ByWildcardUrl')]
        [string]
        
        
        
        $Url,

        [Parameter(ParameterSetName='ByLiteralUrl')]
        [string]
        
        
        
        $LiteralUrl
    )

    Set-StrictMode -Version 'Latest'

    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    $errorActionParam = @{ 'ErrorAction' = $ErrorActionPreference }
    if( $ErrorActionPreference -eq 'Ignore' )
    {
        $ErrorActionPreference = 'SilentlyContinue'
    }

    $acls = @()
    [Carbon.Security.HttpUrlSecurity]::GetHttpUrlSecurity() |
        Where-Object {
            if( $PSCmdlet.ParameterSetName -eq 'AllUrls' )
            {
                return $true
            }

            if( $PSCmdlet.ParameterSetName -eq 'ByWildcardUrl' )
            {
                Write-Debug -Message ('{0} -like {1}' -f $_.Url,$Url)
                return $_.Url -like $Url
            }

            Write-Debug -Message ('{0} -eq {1}' -f $_.Url,$LiteralUrl)
            return $_.Url -eq $LiteralUrl
        } |
        Tee-Object -Variable 'acls'

    if( -not $acls )
    {
        if( $PSCmdlet.ParameterSetName -eq 'ByLiteralUrl' )
        {
            Write-Error ('HTTP ACL for URL {0} not found. The HTTP API adds a trailing forward slash (/) to the end of all URLs. Make sure your URL ends with a trailing slash.' -f $LiteralUrl) @errorActionParam
        }
        elseif( -not [Management.Automation.WildcardPattern]::ContainsWildcardCharacters($Url) )
        {
            Write-Error ('HTTP ACL for URL {0} not found. The HTTP API adds a trailing forward slash (/) to the end of all URLs. Make sure your URL ends with a trailing slash.' -f $Url) @errorActionParam
        }
    }
}
