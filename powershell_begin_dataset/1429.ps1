
function Revoke-CPermission
{
    
    [CmdletBinding(SupportsShouldProcess=$true)]
    param(
        [Parameter(Mandatory=$true)]
        [string]
        
        $Path,
        
        [Parameter(Mandatory=$true)]
        [string]
        
        $Identity
    )

    Set-StrictMode -Version 'Latest'

    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState
    
    $Path = Resolve-Path -Path $Path
    if( -not $Path )
    {
        return
    }

    $providerName = Get-CPathProvider -Path $Path | Select-Object -ExpandProperty 'Name'
    if( $providerName -eq 'Certificate' )
    {
        $providerName = 'CryptoKey'
    }

    $rulesToRemove = Get-CPermission -Path $Path -Identity $Identity
    if( $rulesToRemove )
    {
        $Identity = Resolve-CIdentityName -Name $Identity
        $rulesToRemove | ForEach-Object { Write-Verbose ('[{0}] [{1}]  {2} -> ' -f $Path,$Identity,$_."$($providerName)Rights") }

        Get-Item $Path -Force |
            ForEach-Object {
                if( $_.PSProvider.Name -eq 'Certificate' )
                {
                    [Security.Cryptography.X509Certificates.X509Certificate2]$certificate = $_

                    [Security.AccessControl.CryptoKeySecurity]$keySecurity = $certificate.PrivateKey.CspKeyContainerInfo.CryptoKeySecurity

                    $rulesToRemove | ForEach-Object { [void] $keySecurity.RemoveAccessRule($_) }

                    Set-CryptoKeySecurity -Certificate $certificate -CryptoKeySecurity $keySecurity -Action ('revoke {0}''s permissions' -f $Identity)
                }
                else
                {
                    
                    
                    
                    $currentAcl = $_.GetAccessControl('Access')
                    $rulesToRemove | ForEach-Object { [void]$currentAcl.RemoveAccessRule($_) }
                    if( $PSCmdlet.ShouldProcess( $Path, ('revoke {0}''s permissions' -f $Identity)) )
                    {
                        Set-Acl -Path $Path -AclObject $currentAcl
                    }
                }
            }

    }
    
}

