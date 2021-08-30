function Get-ServiceNowIncident{
    [OutputType([System.Management.Automation.PSCustomObject])]
    [CmdletBinding(DefaultParameterSetName, SupportsPaging)]
    Param(
        
        [Parameter(Mandatory = $false)]
        [string]$OrderBy = 'opened_at',

        
        [Parameter(Mandatory = $false)]
        [ValidateSet('Desc', 'Asc')]
        [string]$OrderDirection = 'Desc',

        
        [Parameter(Mandatory = $false)]
        [int]$Limit,

        
        [Parameter(Mandatory = $false)]
        [Alias('Fields')]
        [string[]]$Properties,

        
        [Parameter(Mandatory = $false)]
        [hashtable]$MatchExact = @{},

        
        [Parameter(Mandatory = $false)]
        [hashtable]$MatchContains = @{},

        
        [Parameter(Mandatory = $false)]
        [ValidateSet('true', 'false', 'all')]
        [string]$DisplayValues = 'true',

        [Parameter(ParameterSetName = 'SpecifyConnectionFields', Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [Alias('ServiceNowCredential')]
        [PSCredential]$Credential,

        [Parameter(ParameterSetName = 'SpecifyConnectionFields', Mandatory = $true)]
        [ValidateScript({Test-ServiceNowURL -Url $_})]
        [Alias('Url')]
        [string]$ServiceNowURL,

        [Parameter(ParameterSetName = 'UseConnectionObject', Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [hashtable]$Connection
    )

    
    $newServiceNowQuerySplat = @{
        OrderBy = $OrderBy
        OrderDirection = $OrderDirection
        MatchExact = $MatchExact
        MatchContains = $MatchContains
    }
    $Query = New-ServiceNowQuery @newServiceNowQuerySplat

    
    $getServiceNowTableSplat = @{
        Table         = 'incident'
        Query         = $Query
        Fields        = $Properties
        DisplayValues = $DisplayValues
    }

    
    if ($null -ne $PSBoundParameters.Connection) {
        $getServiceNowTableSplat.Add('Connection', $Connection)
    }
    elseif ($null -ne $PSBoundParameters.Credential -and $null -ne $PSBoundParameters.ServiceNowURL) {
        $getServiceNowTableSplat.Add('Credential', $Credential)
        $getServiceNowTableSplat.Add('ServiceNowURL', $ServiceNowURL)
    }

    
    if ($PSBoundParameters.ContainsKey('Limit')) {
        $getServiceNowTableSplat.Add('Limit', $Limit)
    }

    
    ($PSCmdlet.PagingParameters | Get-Member -MemberType Property).Name | Foreach-Object {
        $getServiceNowTableSplat.Add($_, $PSCmdlet.PagingParameters.$_)
    }

    
    $Result = Get-ServiceNowTable @getServiceNowTableSplat
    If (-not $Properties) {
        $Result | ForEach-Object{$_.PSObject.TypeNames.Insert(0,"ServiceNow.Incident")}
    }
    $Result
}
