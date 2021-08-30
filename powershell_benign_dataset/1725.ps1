function Get-ServiceNowRequestItem {


    [OutputType([System.Management.Automation.PSCustomObject])]
    [CmdletBinding(DefaultParameterSetName, SupportsPaging)]
    param(
        
        [parameter(Mandatory = $false)]
        [string]$OrderBy = 'opened_at',

        
        [parameter(Mandatory = $false)]
        [ValidateSet('Desc', 'Asc')]
        [string]$OrderDirection = 'Desc',

        
        [parameter(Mandatory = $false)]
        [int]$Limit,

        
        [Parameter(Mandatory = $false)]
        [Alias('Fields')]
        [string[]]$Properties,

        
        [parameter(Mandatory = $false)]
        [hashtable]$MatchExact = @{},

        
        [parameter(Mandatory = $false)]
        [hashtable]$MatchContains = @{},

        
        [parameter(Mandatory = $false)]
        [ValidateSet('true', 'false', 'all')]
        [string]$DisplayValues = 'true',

        [Parameter(ParameterSetName = 'SpecifyConnectionFields', Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [Alias('ServiceNowCredential')]
        [PSCredential]$Credential,

        [Parameter(ParameterSetName = 'SpecifyConnectionFields', Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$ServiceNowURL,

        [Parameter(ParameterSetName = 'UseConnectionObject', Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [hashtable]$Connection
    )

    
    $newServiceNowQuerySplat = @{
        OrderBy        = $OrderBy
        MatchExact     = $MatchExact
        OrderDirection = $OrderDirection
        MatchContains  = $MatchContains
    }
    $Query = New-ServiceNowQuery @newServiceNowQuerySplat

    
    $getServiceNowTableSplat = @{
        Table         = 'sc_req_item'
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
        $Result | ForEach-Object {$_.PSObject.TypeNames.Insert(0,'ServiceNow.RequestItem')}
    }
    $Result
}
