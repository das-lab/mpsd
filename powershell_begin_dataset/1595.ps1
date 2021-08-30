



function Write-Object {
    param (
        [Parameter(
            ValueFromPipeline=$True,
            ValueFromPipelinebyPropertyName=$True)]
        [object[]]$Object,
        [string]$Header,
        [string]$Footer
    )
    
    if ($input) {
        $Object = @($input)
    }
    
    if (!$Object) {
        throw 'Must provide an object.'
    }
    
    if ($Header) {
        Write-Host $Header
    }

    ($Object | Format-List * | Out-String).Split("`n").Trim() | ? {$_ -notmatch '^(\s+)?$'} | % {Write-Host $_}

    if ($Footer) {
        Write-Host $Footer
    }
}
