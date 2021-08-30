
function New-PoshBotTextResponse {
    
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseShouldProcessForStateChangingFunctions', '', Scope='Function', Target='*')]
    [cmdletbinding()]
    param(
        [parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [string[]]$Text,

        [switch]$AsCode,

        [switch]$DM
    )

    process {
        foreach ($item in $text) {
            [pscustomobject][ordered]@{
                PSTypeName = 'PoshBot.Text.Response'
                Text = $item.Trim()
                AsCode = $PSBoundParameters.ContainsKey('AsCode')
                DM = $PSBoundParameters.ContainsKey('DM')
            }
        }
    }
}

Export-ModuleMember -Function 'New-PoshBotTextResponse'
