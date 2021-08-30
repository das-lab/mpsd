function New-ServiceNowQuery {
    

    
    [System.Diagnostics.CodeAnalysis.SuppressMessage('PSUseShouldProcessForStateChangingFunctions','')]

    [CmdletBinding()]
    [OutputType([System.String])]

    param(
        
        [parameter(mandatory=$false)]
        [string]$OrderBy='opened_at',

        
        [parameter(mandatory=$false)]
        [ValidateSet("Desc", "Asc")]
        [string]$OrderDirection='Desc',

        
        [parameter(mandatory=$false)]
        [hashtable]$MatchExact,

        
        [parameter(mandatory=$false)]
        [hashtable]$MatchContains
    )

    Try {
        
        $Query = New-Object System.Text.StringBuilder

        
        $Order = Switch ($OrderDirection) {
            'Asc'   {'ORDERBY'; break}
            Default {'ORDERBYDESC'}
        }
        [void]$Query.Append($Order)

        
        [void]$Query.Append($OrderBy)

        
        If ($MatchExact) {
            ForEach ($Field in $MatchExact.keys) {
                $ExactString = "^{0}={1}" -f $Field.ToString().ToLower(), ($MatchExact.$Field)
                [void]$Query.Append($ExactString)
            }
        }

        
        If ($MatchContains) {
            ForEach ($Field in $MatchContains.keys) {
                $ContainsString = "^{0}LIKE{1}" -f $Field.ToString().ToLower(), ($MatchContains.$Field)
                [void]$Query.Append($ContainsString)
            }
        }

        
        $Query.ToString()
    }
    Catch {
        Write-Error $PSItem
    }
}
