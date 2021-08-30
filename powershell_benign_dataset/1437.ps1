
filter Add-IisServerManagerMember
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true,ValueFromPipeline=$true)]
        
        $InputObject,
        
        [Parameter(Mandatory=$true)]
        [Microsoft.Web.Administration.ServerManager]
        
        $ServerManager,
        
        [Switch]
        
        $PassThru
    )
    
    Set-StrictMode -Version 'Latest'

    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    $InputObject | 
        Add-Member -MemberType NoteProperty -Name 'ServerManager' -Value $ServerManager -PassThru |
        Add-Member -MemberType ScriptMethod -Name 'CommitChanges' -Value { $this.ServerManager.CommitChanges() }
        
    if( $PassThru )
    {
        return $InputObject
    }
}

