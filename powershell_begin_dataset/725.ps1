


function Get-RsSubscription
{
    

    [cmdletbinding()]
    param
    (
        [Alias('Path')]
        [Parameter(Mandatory = $True, ValueFromPipeline = $true)]
        [string[]]
        $RsItem,

        [string]
        $ReportServerUri,

        [ValidateSet('2005','2006','2010')]
        [string]
        $ApiVersion = '2010',

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
        foreach ($item in $RsItem)
        {
            try
            {
                Write-Verbose "Retrieving subscriptions contents..."

                if ($Proxy.Url -match 'ReportService2005.asmx')
                {
                    if ($item -eq '/') { $item = $null }
                    $subscriptions = $Proxy.ListSubscriptions($Item,$null)
                }
                else
                {
                    $subscriptions = $Proxy.ListSubscriptions($Item)
                }

                Write-Verbose "Subscriptions retrieved successfully!"

                $namespace = $proxy.GetType().Namespace
                $DataRetrievalPlanDataType = "$namespace.DataRetrievalPlan"
                $ExtensionSettingsDataType = "$namespace.ExtensionSettings"
                $ActiveStateDataType = "$namespace.ActiveState"

                foreach ($subscription in $subscriptions)
                {
                    $extSettings = $null
                    $DataRetrievalPlan = $null
                    $desc = $null
                    $active = $null
                    $status = $null
                    $eventType = $null
                    $matchData = $null
                    $values = $null
                    $Result = $null

                    try
                    {
                        Write-Verbose "Retrieving subscription properties for $($subscription.SubscriptionID)..."

                        if ($subscription.IsDataDriven)
                        {
                            $null = $Proxy.GetDataDrivenSubscriptionProperties($subscription.SubscriptionID, [ref]$extSettings, [ref]$DataRetrievalPlan, [ref]$desc, [ref]$active, [ref]$status, [ref]$eventType, [ref]$matchData, [ref]$values)
                        }
                        else
                        {
                            $null = $Proxy.GetSubscriptionProperties($subscription.SubscriptionID, [ref]$extSettings, [ref]$desc, [ref]$active, [ref]$status, [ref]$eventType, [ref]$matchData, [ref]$values)
                        }

                        Write-Verbose "Subscription properties for $($subscription.SubscriptionID) retrieved successfully!"

                        
                        $ExtensionSettings = New-Object $ExtensionSettingsDataType
                        $ExtensionSettings.Extension = $subscription.DeliverySettings.Extension
                        $ExtensionSettings.ParameterValues = $subscription.DeliverySettings.ParameterValues

                        
                        $ActiveState = New-Object $ActiveStateDataType
                        $ActiveState.DeliveryExtensionRemoved          = $subscription.Active.DeliveryExtensionRemoved
                        $ActiveState.DeliveryExtensionRemovedSpecified = $subscription.Active.DeliveryExtensionRemovedSpecified
                        $ActiveState.SharedDataSourceRemoved           = $subscription.Active.SharedDataSourceRemoved
                        $ActiveState.SharedDataSourceRemovedSpecified  = $subscription.Active.SharedDataSourceRemovedSpecified
                        $ActiveState.MissingParameterValue             = $subscription.Active.MissingParameterValue
                        $ActiveState.MissingParameterValueSpecified    = $subscription.Active.MissingParameterValueSpecified
                        $ActiveState.InvalidParameterValue             = $subscription.Active.InvalidParameterValue
                        $ActiveState.InvalidParameterValueSpecified    = $subscription.Active.InvalidParameterValueSpecified
                        $ActiveState.UnknownReportParameter            = $subscription.Active.UnknownReportParameter
                        $ActiveState.UnknownReportParameterSpecified   = $subscription.Active.UnknownReportParameterSpecified

                        $Result = @{
                            SubscriptionID        = $subscription.SubscriptionID
                            Owner                 = $subscription.Owner
                            Path                  = $subscription.Path
                            VirtualPath           = $subscription.VirtualPath
                            Report                = $subscription.Report
                            DeliverySettings      = $ExtensionSettings
                            Description           = $subscription.Description
                            Status                = $subscription.Status
                            Active                = $ActiveState
                            LastExecuted          = $subscription.LastExecuted
                            LastExecutedSpecified = $subscription.LastExecutedSpecified
                            ModifiedBy            = $subscription.ModifiedBy
                            ModifiedDate          = $subscription.ModifiedDate
                            EventType             = $subscription.EventType
                            IsDataDriven          = $subscription.IsDataDriven
                            MatchData             = $matchData
                            Values                = $values
                        }

                        if ($subscription.IsDataDriven)
                        {
                            $Result.Add('DataRetrievalPlan',$DataRetrievalPlan)
                        }

                        [pscustomobject]$Result
                    }
                    catch
                    {
                        Write-Error (New-Object System.Exception("Exception while retrieving subscription properties! $($_.Exception.Message)", $_.Exception))
                        Write-Verbose ($subscription | format-list | out-string)
                    }
                }
            }
            catch
            {
                throw (New-Object System.Exception("Exception while retrieving subscription(s)! $($_.Exception.Message)", $_.Exception))
            }
        }
    }
}
