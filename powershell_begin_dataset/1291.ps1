
function Get-CPermission
{
    
    [CmdletBinding()]
    [OutputType([System.Security.AccessControl.AccessRule])]
    param(
        [Parameter(Mandatory=$true)]
        [string]
        
        $Path,
        
        [string]
        
        $Identity,
        
        [Switch]
        
        $Inherited
    )
   
    Set-StrictMode -Version 'Latest'

    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    $account = $null
    if( $Identity )
    {
        $account = Test-CIdentity -Name $Identity -PassThru
        if( $account )
        {
            $Identity = $account.FullName
        }
    }

    if( -not (Test-Path -Path $Path) )
    {
        Write-Error ('Path ''{0}'' not found.' -f $Path)
        return
    }
    
    Invoke-Command -ScriptBlock {
        Get-Item -Path $Path -Force |
            ForEach-Object { 
                if( $_.PSProvider.Name -eq 'Certificate' )
                {
                    if( $_.HasPrivateKey -and $_.PrivateKey )
                    {
                        $_.PrivateKey.CspKeyContainerInfo.CryptoKeySecurity
                    }
                }
                else
                {
                    $_.GetAccessControl([Security.AccessControl.AccessControlSections]::Access)
                }
            }
        } |
        Select-Object -ExpandProperty Access |
        Where-Object { 
            if( $Inherited )
            {
                return $true 
            }
            return (-not $_.IsInherited)
        } |
        Where-Object {
            if( $Identity )
            {
                return ($_.IdentityReference.Value -eq $Identity)
            }
            
            return $true
        }    
}

Set-Alias -Name 'Get-Permissions' -Value 'Get-CPermission'

