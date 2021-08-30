function Get-ServiceNowTable {


    [OutputType([System.Management.Automation.PSCustomObject])]
    [CmdletBinding(DefaultParameterSetName, SupportsPaging)]
    Param (
        
        [parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$Table,

        
        [Parameter(Mandatory = $false)]
        [string]$Query,

        
        [Parameter(Mandatory = $false)]
        [int]$Limit,

        
        [Parameter(Mandatory = $false)]
        [Alias('Fields')]
        [string[]]$Properties,

        
        [Parameter(Mandatory = $false)]
        [ValidateSet('true', 'false', 'all')]
        [string]$DisplayValues = 'true',

        [Parameter(ParameterSetName = 'SpecifyConnectionFields', Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [Alias('ServiceNowCredential')]
        [PSCredential]$Credential,

        [Parameter(ParameterSetName = 'SpecifyConnectionFields', Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [Alias('Url')]
        [string]$ServiceNowURL,

        [Parameter(ParameterSetName = 'UseConnectionObject', Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [hashtable]$Connection
    )

    
    if ($null -ne $Connection) {
        $SecurePassword = ConvertTo-SecureString $Connection.Password -AsPlainText -Force
        $Credential = New-Object System.Management.Automation.PSCredential ($Connection.Username, $SecurePassword)
        $ServiceNowURL = 'https://' + $Connection.ServiceNowUri + '/api/now/v1'
    }
    elseif ($null -ne $Credential -and $null -ne $ServiceNowURL) {
        Try {
            $null = Test-ServiceNowURL -Url $ServiceNowURL -ErrorAction Stop
            $ServiceNowURL = 'https://' + $ServiceNowURL + '/api/now/v1'
        }
        Catch {
            Throw $PSItem
        }
    }
    elseif ((Test-ServiceNowAuthIsSet)) {
        $Credential = $Global:ServiceNowCredentials
        $ServiceNowURL = $global:ServiceNowRESTURL
    }
    else {
        throw "Exception:  You must do one of the following to authenticate: `n 1. Call the Set-ServiceNowAuth cmdlet `n 2. Pass in an Azure Automation connection object `n 3. Pass in an endpoint and credential"
    }

    $Body = @{'sysparm_display_value' = $DisplayValues}

    
    
    
    

    if ($PSBoundParameters.ContainsKey('Limit')) {
        Write-Warning "The -Limit parameter is deprecated, and may be removed in a future release. Use the -First parameter instead."
        $Body['sysparm_limit'] = $Limit
    }
    elseif ($PSCmdlet.PagingParameters.First -ne [uint64]::MaxValue) {
        $Body['sysparm_limit'] = $PSCmdlet.PagingParameters.First
    }
    else {
        $Body['sysparm_limit'] = 10
    }

    if ($PSCmdlet.PagingParameters.Skip) {
        $Body['sysparm_offset'] = $PSCmdlet.PagingParameters.Skip
    }

    if ($PSCmdlet.PagingParameters.IncludeTotalCount) {
        
        

        
        
        

        
        
        

        
        

        [double] $accuracy = 0.0
        $PSCmdlet.PagingParameters.NewTotalCount($PSCmdlet.PagingParameters.First, $accuracy)
    }

    
    if ($Query) {
        $Body.sysparm_query = $Query
    }

    if ($Properties) {
        $Body.sysparm_fields = ($Properties -join ',').ToLower()
    }

    
    $Uri = $ServiceNowURL + "/table/$Table"
    $Result = (Invoke-RestMethod -Uri $Uri -Credential $Credential -Body $Body -ContentType "application/json").Result

    
    $ConvertToDateField = @('closed_at', 'expected_start', 'follow_up', 'opened_at', 'sys_created_on', 'sys_updated_on', 'work_end', 'work_start')
    ForEach ($SNResult in $Result) {
        ForEach ($Property in $ConvertToDateField) {
            If (-not [string]::IsNullOrEmpty($SNResult.$Property)) {
                Try {
                    
                    $CultureDateTimeFormat = (Get-Culture).DateTimeFormat
                    $DateFormat = $CultureDateTimeFormat.ShortDatePattern
                    $TimeFormat = $CultureDateTimeFormat.LongTimePattern
                    $DateTimeFormat = "$DateFormat $TimeFormat"
                    $SNResult.$Property = [DateTime]::ParseExact($($SNResult.$Property), $DateTimeFormat, [System.Globalization.DateTimeFormatInfo]::InvariantInfo, [System.Globalization.DateTimeStyles]::None)
                }
                Catch {
                    Try {
                        
                        $DateTimeFormat = 'yyyy-MM-dd HH:mm:ss'
                        $SNResult.$Property = [DateTime]::ParseExact($($SNResult.$Property), $DateTimeFormat, [System.Globalization.DateTimeFormatInfo]::InvariantInfo, [System.Globalization.DateTimeStyles]::None)
                    }
                    Catch {
                        
                        $null = 'Silencing a PSSA alert with this line'
                    }
                }
            }
        }
    }

    
    $Result
}
