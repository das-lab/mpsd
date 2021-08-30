


function Copy-RsSubscription
{
    

    [cmdletbinding(SupportsShouldProcess = $true, ConfirmImpact = 'Medium')]
    param
    (
        [string]
        $ReportServerUri,

        [System.Management.Automation.PSCredential]
        $Credential,

        $Proxy,

        [Alias('ReportPath','ItemPath','Path')]
        [Parameter(ParameterSetName='Report', Mandatory=$True)]
        [string]
        $RsItem,

        [Alias('Folder')]
        [Parameter(ParameterSetName='Folder', Mandatory=$True)]
        [string]
        $RsFolder,

        [Parameter(Mandatory = $True, ValueFromPipeline=$true)]
        [object[]]
        $Subscription
    )
    Begin
    {
        $Proxy = New-RsWebServiceProxyHelper -BoundParameters $PSBoundParameters

        
        $itemNullOrEmpty = [System.String]::IsNullOrEmpty($RsItem)
        $folderNullOrEmpty = [System.String]::IsNullOrEmpty($RsFolder)
        if ($itemNullOrEmpty -and $folderNullOrEmpty)
        {
            throw 'No folder or report path was specified! You need to specify -RsFolder or -RsItem.'
        }
        elseif (!$itemNullOrEmpty -and !$folderNullOrEmpty)
        {
            throw 'Both folder and report path were specified! Please specify either -RsFolder or -RsItem.'
        }
        
    }
    Process
    {
        try
        {
            foreach ($sub in $Subscription)
            {
                if ($RsFolder)
                {
                    $RsItem = "$RsFolder/$($sub.Report)"
                }
                else 
                {
                    $RsFolder = (Split-Path $RsItem -Parent).Replace("\", "/")
                }

                Write-Verbose "Validating if target report exists..."
                if (((Get-RsFolderContent -Proxy $Proxy -RsFolder $RsFolder | Where-Object Path -eq $RsItem).Count) -eq 0)
                {
                    Write-Warning "Can't find the report $RsItem. Skipping."
                    Continue
                }

                if ($PSCmdlet.ShouldProcess($RsItem, "Creating new subscription"))
                {
                    Write-Verbose "Creating Subscription..."
                    if ($sub.IsDataDriven)
                    {
                        $subscriptionId = $Proxy.CreateDataDrivenSubscription($RsItem, $sub.DeliverySettings, $sub.DataRetrievalPlan, $sub.Description, $sub.EventType, $sub.MatchData, $sub.Values)
                    }
                    else
                    {
                        $subscriptionId = $Proxy.CreateSubscription($RsItem, $sub.DeliverySettings, $sub.Description, $sub.EventType, $sub.MatchData, $sub.Values)
                    }

                    [pscustomobject]@{
                        NewSubscriptionId = $subscriptionId
                        DestinationReport = $RsItem
                        OriginalReport    = $sub.Path
                    }
                    Write-Verbose "Subscription created successfully! Generated subscriptionId: $subscriptionId"
                }
            }
        }
        catch
        {
            throw (New-Object System.Exception("Exception occurred while creating subscription! $($_.Exception.Message)", $_.Exception))
        }
    }
}
