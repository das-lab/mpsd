
function ConvertTo-ProviderAccessControlRights
{
    
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [ValidateSet('FileSystem','Registry','CryptoKey')]
        [string]
        
        $ProviderName,

        [Parameter(Mandatory=$true,ValueFromPipeline=$true)]
        [string[]]
        
        $InputObject
    )

    begin
    {
        Set-StrictMode -Version 'Latest'

        Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

        $rights = 0
        $rightTypeName = 'Security.AccessControl.{0}Rights' -f $ProviderName
        $foundInvalidRight = $false
    }

    process
    {
        $InputObject | ForEach-Object { 
            $right = ($_ -as $rightTypeName)
            if( -not $right )
            {
                $allowedValues = [Enum]::GetNames($rightTypeName)
                Write-Error ("System.Security.AccessControl.{0}Rights value '{1}' not found.  Must be one of: {2}." -f $providerName,$_,($allowedValues -join ' '))
                $foundInvalidRight = $true
                return
            }
            $rights = $rights -bor $right
        }
    }

    end
    {
        if( $foundInvalidRight )
        {
            return $null
        }
        else
        {
            $rights
        }
    }
}
