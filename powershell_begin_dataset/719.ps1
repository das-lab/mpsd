


function Remove-RsSubscription
{
    

    [CmdletBinding(SupportsShouldProcess = $True, ConfirmImpact = 'High')]
    param (
        [Parameter(ParameterSetName='MutipleSubscriptions', Mandatory=$True, ValueFromPipeline=$True)]
        [object[]]
        $Subscription,

        [Parameter(ParameterSetName='SingleSubscription', Mandatory=$True)]
        [string]
        $SubscriptionId,

        [string]
        $ReportServerUri,

        [System.Management.Automation.PSCredential]
        $Credential,

        $Proxy
    )
    Begin
    {
        $Proxy = New-RsWebServiceProxyHelper -BoundParameters $PSBoundParameters
    }
    Process
    {
        if ([System.String]::IsNullOrEmpty($SubscriptionId)) 
        {
            foreach ($item in $Subscription)
            {
                if ($PSCmdlet.ShouldProcess($item.SubscriptionId, "Delete the subscription"))
                {
                    try 
                    {
                        Write-Verbose "Deleting subscription $($item.SubscriptionId) ..."
                        $Proxy.DeleteSubscription($item.SubscriptionId)
                        Write-Verbose "Subscription deleted successfully!"
                    }
                    catch 
                    {
                        throw (New-Object System.Exception("Exception occurred while deleting subscription id '$($item.SubscriptionId)'! $($_.Exception.Message)", $_.Exception))
                    }
                }
            }
        }
        else
        {
            if ($PSCmdlet.ShouldProcess($SubscriptionId, "Delete the subscription"))
            {
                try 
                {
                    Write-Verbose "Deleting subscription $SubscriptionId..."
                    $Proxy.DeleteSubscription($SubscriptionId)
                    Write-Verbose "Subscription deleted successfully!"
                }
                catch 
                {
                    throw (New-Object System.Exception("Exception occurred while deleting subscription id '$SubscriptionId'! $($_.Exception.Message)", $_.Exception))
                }
            }
        }
    }
}
