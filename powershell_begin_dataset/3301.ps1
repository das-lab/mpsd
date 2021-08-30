
function New-PoshBotFileUpload {
    
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseShouldProcessForStateChangingFunctions', '', Scope='Function', Target='*')]
    [cmdletbinding(DefaultParameterSetName = 'Path')]
    param(
        [parameter(
            Mandatory,
            ParameterSetName  = 'Path',
            Position = 0,
            ValueFromPipeline,
            ValueFromPipelineByPropertyName
        )]
        [ValidateNotNullOrEmpty()]
        [SupportsWildcards()]
        [string[]]$Path,

        [parameter(
            Mandatory,
            ParameterSetName = 'LiteralPath',
            Position = 0,
            ValueFromPipelineByPropertyName
        )]
        [ValidateNotNullOrEmpty()]
        [Alias('PSPath')]
        [string[]]$LiteralPath,

        [parameter(
            Mandatory,
            ParameterSetName = 'Content')]
        [string]$Content,

        [parameter(
            ParameterSetName = 'Content'
        )]
        [string]$FileType,

        [parameter(
            ParameterSetName = 'Content'
        )]
        [string]$FileName,

        [string]$Title = [string]::Empty,

        [switch]$DM,

        [switch]$KeepFile
    )

    process {
        if ($PSCmdlet.ParameterSetName -eq 'Content') {
            [pscustomobject][ordered]@{
                PSTypeName = 'PoshBot.File.Upload'
                Content    = $Content
                FileName   = $FileName
                FileType   = $FileType
                Title      = $Title
                DM         = $DM.IsPresent
                KeepFile   = $KeepFile.IsPresent
            }
        } else {
            
            if ($PSCmdlet.ParameterSetName -eq 'Path') {
                $paths = Resolve-Path -Path $Path | Select-Object -ExpandProperty Path
            } elseIf ($PSCmdlet.ParameterSetName -eq 'LiteralPath') {
                $paths = Resolve-Path -LiteralPath $LiteralPath | Select-Object -ExpandProperty Path
            }

            foreach ($item in $paths) {
                [pscustomobject][ordered]@{
                    PSTypeName = 'PoshBot.File.Upload'
                    Path       = $item
                    Title      = $Title
                    DM         = $DM.IsPresent
                    KeepFile   = $KeepFile.IsPresent
                }
            }
        }
    }
}

Export-ModuleMember -Function 'New-PoshBotFileUpload'
