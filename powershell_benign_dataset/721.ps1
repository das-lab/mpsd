


function New-RsSubscription
{
    
    
    [cmdletbinding(SupportsShouldProcess = $true, ConfirmImpact = 'Medium', DefaultParameterSetName='FileShare')]
    param(
        [string]
        $ReportServerUri,

        [System.Management.Automation.PSCredential]
        $Credential,

        $Proxy,

        [Alias('ReportPath','ItemPath','Path')]
        [Parameter(Mandatory=$True)]
        [string]
        $RsItem,

        [string]
        $Description,

        [ValidateSet('TimedSubscription','SnapshotUpdated')] 
        [string]
        $EventType = 'TimedSubscription',

        [Parameter(Mandatory=$True)]
        [string]
        $Schedule,

        [Parameter(Mandatory=$True)]
        [ValidateSet('Email','FileShare')] 
        [string]
        $DeliveryMethod,

        [Parameter(Mandatory=$True)]
        [ValidateSet('PDF','MHTML','IMAGE','CSV','XML','EXCELOPENXML','ATOM','PPTX','WORDOPENXML')]
        [string]
        $RenderFormat = 'PDF',

        [Parameter(ParameterSetName='Email',Mandatory=$True)]
        [string]
        $To,

        [Parameter(ParameterSetName='Email')]
        [string]
        $CC,

        [Parameter(ParameterSetName='Email')]
        [string]
        $BCC,

        [Parameter(ParameterSetName='Email')]
        [string]
        $ReplyTo,

        [Parameter(ParameterSetName='Email')]
        [switch]
        $ExcludeReport,

        [Parameter(ParameterSetName='Email',Mandatory=$True)]
        [string]
        $Subject,

        [Parameter(ParameterSetName='Email')]
        [string]
        $Comment,

        [Parameter(ParameterSetName='Email')]
        [switch]
        $ExcludeLink,

        [Parameter(ParameterSetName='Email')]
        [ValidateSet('LOW', 'NORMAL', 'HIGH')]
        [string]
        $Priority = 'NORMAL',

        [Alias('DestinationPath')]
        [Parameter(ParameterSetName='FileShare',Mandatory=$True)]
        [string]
        $FileSharePath,

        [Parameter(ParameterSetName='FileShare')]
        [System.Management.Automation.PSCredential]
        $FileShareCredentials,

        [Parameter(ParameterSetName='FileShare',Mandatory=$True)]
        [string]
        $Filename,

        [Parameter(ParameterSetName='FileShare')]
        [ValidateSet('None','Overwrite','AutoIncrement')]
        [string]
        $FileWriteMode = 'Overwrite'
    )

    Begin
    {
        $Proxy = New-RsWebServiceProxyHelper -BoundParameters $PSBoundParameters
    }
    Process
    {
        if ([System.String]::IsNullOrEmpty($RsItem))
        {
            throw 'No report path was specified! You need to specify -RsItem variable.'
        }

        try
        {
            Write-Verbose "Validating if target report exists..."
            if (((Get-RsFolderContent -Proxy $Proxy -RsFolder ((Split-Path $RsItem -Parent).Replace('\','/')) | Where-Object Path -eq $RsItem).Count) -eq 0)
            {
                Write-Warning "Can't find the report $RsItem. Skipping."
                Continue
            }

            $Namespace = $Proxy.GetType().NameSpace

            switch ($DeliveryMethod)
            {
                'Email'
                {
                    $Params = @{
                        TO = $To
                        CC = $CC
                        BCC = $BCC
                        ReplyTo = $ReplyTo
                        IncludeReport = (-not $ExcludeReport)
                        IncludeLink = (-not $ExcludeLink)
                        Subject = $Subject
                        Comment = $Comment
                        RenderFormat = $RenderFormat
                        Priority = $Priority
                    }
                }
                'FileShare'
                {
                    $Params = @{
                        PATH = $FileSharePath
                        FILENAME = $Filename
                        RENDER_FORMAT = $RenderFormat
                        WRITEMODE = $FileWriteMode
                    }

                    if ($FileShareCredentials -ne $null)
                    {
                        $Params.USERNAME = $FileShareCredentials.UserName
                        $Params.PASSWORD = $FileShareCredentials.GetNetworkCredential().Password
                        $Params.DEFAULTCREDENTIALS = $false
                    }
                    else
                    {
                        $Params.DEFAULTCREDENTIALS = $true
                    }
                }
            }

            $ParameterValues = @()
            $Params.GetEnumerator() | ForEach-Object {
                $ParameterValues = $ParameterValues + (New-Object "$Namespace.ParameterValue" -Property @{ Name = $_.Name; Value = $_.Value })
            }

            $ExtensionSettings = New-Object "$Namespace.ExtensionSettings" -Property @{ Extension = "Report Server $DeliveryMethod"; ParameterValues = $ParameterValues }

            $MatchData = $Schedule
            $ReportParameters = $Null

            if ($PSCmdlet.ShouldProcess($RsItem, "Creating new subscription"))
            {
                Write-Verbose "Creating Subscription..."
                $subscriptionId = $Proxy.CreateSubscription($RsItem, $ExtensionSettings, $Description, $EventType, $MatchData, $ReportParameters)

                [pscustomobject]@{
                    NewSubscriptionId = $subscriptionId
                }

                Write-Verbose "Subscription created successfully! Generated subscriptionId: $subscriptionId"
            }
        }
        catch
        {
            throw (New-Object System.Exception("Exception occurred while creating subscription! $($_.Exception.Message)", $_.Exception))
        }
    }
}
