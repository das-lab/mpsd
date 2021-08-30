
function Test-CDscTargetResource
{
    
    [CmdletBinding()]
    [OutputType([bool])]
    param(
        [Parameter(Mandatory=$true)]
        [hashtable]
        
        $TargetResource,

        [Parameter(Mandatory=$true)]
        [hashtable]
        
        $DesiredResource,

        [Parameter(Mandatory=$true)]
        [string]
        
        $Target
    )

    Set-StrictMode -Version 'Latest'

    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    $notEqualProperties = $TargetResource.Keys | 
                            Where-Object { $_ -ne 'Ensure' } |  
                            Where-Object { $DesiredResource.ContainsKey( $_ ) } |
                            Where-Object { 
                                $desiredObj = $DesiredResource[$_]
                                $targetObj = $TargetResource[$_]

                                if( $desiredobj -eq $null -or $targetObj -eq $null )
                                {
                                    return ($desiredObj -ne $targetObj)
                                }

                                if( -not $desiredObj.GetType().IsArray -or -not $targetObj.GetType().IsArray )
                                {
                                    return ($desiredObj -ne $targetObj)
                                }

                                if( $desiredObj.Length -ne $targetObj.Length )
                                {
                                    return $true
                                }

                                $desiredObj | Where-Object { $targetObj -notcontains $_ }
                            }

    if( $notEqualProperties )
    {
        Write-Verbose ('{0} has stale properties: ''{1}''' -f $Target,($notEqualProperties -join ''','''))
        return $false
    }

    return $true
}
