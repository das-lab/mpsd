function Get-ServiceNowTableEntry {
    

    [CmdletBinding(DefaultParameterSetName, SupportsPaging)]
    param(
        
        [parameter(mandatory = $true)]
        [string]$Table,

        
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
        [ValidateScript({Test-ServiceNowURL -Url $_})]
        [Alias('Url')]
        [string]$ServiceNowURL,

        [Parameter(ParameterSetName = 'UseConnectionObject', Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [hashtable]$Connection
    )

    Try {
        
        $newServiceNowQuerySplat = @{
            OrderBy        = $OrderBy
            MatchExact     = $MatchExact
            OrderDirection = $OrderDirection
            MatchContains  = $MatchContains
            ErrorAction    = 'Stop'
        }
        $Query = New-ServiceNowQuery @newServiceNowQuerySplat

        
        $getServiceNowTableSplat = @{
            Table         = $Table
            Query         = $Query
            Fields        = $Properties
            DisplayValues = $DisplayValues
            ErrorAction   = 'Stop'
        }

        
        Switch ($PSCmdlet.ParameterSetName) {
            'SpecifyConnectionFields' {
                $getServiceNowTableSplat.Add('Credential', $Credential)
                $getServiceNowTableSplat.Add('ServiceNowURL', $ServiceNowURL)
                break
            }
            'UseConnectionObject' {
                $getServiceNowTableSplat.Add('Connection', $Connection)
                break
            }
            Default {}
        }

        
        if ($PSBoundParameters.ContainsKey('Limit')) {
            $getServiceNowTableSplat.Add('Limit', $Limit)
        }

        
        ($PSCmdlet.PagingParameters | Get-Member -MemberType Property).Name | Foreach-Object {
            $getServiceNowTableSplat.Add($_, $PSCmdlet.PagingParameters.$_)
        }

        
        Get-ServiceNowTable @getServiceNowTableSplat
    }
    Catch {
        Write-Error $PSItem
    }
}
