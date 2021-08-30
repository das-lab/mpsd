
function New-PoshBotCardResponse {
    
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseShouldProcessForStateChangingFunctions', '', Scope='Function', Target='*')]
    [cmdletbinding()]
    param(
        [ValidateSet('Normal', 'Warning', 'Error')]
        [string]$Type = 'Normal',

        [switch]$DM,

        [string]$Text = [string]::empty,

        [string]$Title,

        [ValidateScript({
            $uri = $null
            if ([system.uri]::TryCreate($_, [System.UriKind]::Absolute, [ref]$uri)) {
                return $true
            } else {
                $msg = 'ThumbnailUrl must be a valid URL'
                throw [System.Management.Automation.ValidationMetadataException]$msg
            }
        })]
        [string]$ThumbnailUrl,

        [ValidateScript({
            $uri = $null
            if ([system.uri]::TryCreate($_, [System.UriKind]::Absolute, [ref]$uri)) {
                return $true
            } else {
                $msg = 'ImageUrl must be a valid URL'
                throw [System.Management.Automation.ValidationMetadataException]$msg
            }
        })]
        [string]$ImageUrl,

        [ValidateScript({
            $uri = $null
            if ([system.uri]::TryCreate($_, [System.UriKind]::Absolute, [ref]$uri)) {
                return $true
            } else {
                $msg = 'LinkUrl must be a valid URL'
                throw [System.Management.Automation.ValidationMetadataException]$msg
            }
        })]
        [string]$LinkUrl,

        [System.Collections.IDictionary]$Fields,

        [ValidateScript({
            if ($_ -match '^
                return $true
            } else {
                $msg = 'Color but be a valid hexidecimal color code e.g. 
                throw [System.Management.Automation.ValidationMetadataException]$msg
            }
        })]
        [string]$Color = '

        [object]$CustomData
    )

    $response = [ordered]@{
        PSTypeName = 'PoshBot.Card.Response'
        Type = $Type
        Text = $Text.Trim()
        Private = $PSBoundParameters.ContainsKey('Private')
        DM = $PSBoundParameters['DM']
    }
    if ($PSBoundParameters.ContainsKey('Title')) {
        $response.Title = $Title
    }
    if ($PSBoundParameters.ContainsKey('ThumbnailUrl')) {
        $response.ThumbnailUrl = $ThumbnailUrl
    }
    if ($PSBoundParameters.ContainsKey('ImageUrl')) {
        $response.ImageUrl = $ImageUrl
    }
    if ($PSBoundParameters.ContainsKey('LinkUrl')) {
        $response.LinkUrl = $LinkUrl
    }
    if ($PSBoundParameters.ContainsKey('Fields')) {
        $response.Fields = $Fields
    }
    if ($PSBoundParameters.ContainsKey('CustomData')) {
        $response.CustomData = $CustomData
    }
    if ($PSBoundParameters.ContainsKey('Color')) {
        $response.Color = $Color
    } else {
        switch ($Type) {
            'Normal' {
                $response.Color = '
            }
            'Warning' {
                $response.Color = '
            }
            'Error' {
                $response.Color = '
            }
        }
    }

    [pscustomobject]$response
}

Export-ModuleMember -Function 'New-PoshBotCardResponse'
