function Remove-StringSpecialCharacter
{

    [CmdletBinding()]
    param
    (
        [Parameter(ValueFromPipeline)]
        [ValidateNotNullOrEmpty()]
        [Alias('Text')]
        [System.String[]]$String,

        [Alias("Keep")]
        
        [String[]]$SpecialCharacterToKeep
    )
    PROCESS
    {
        IF ($PSBoundParameters["SpecialCharacterToKeep"])
        {
            $Regex = "[^\p{L}\p{Nd}"
            Foreach ($Character in $SpecialCharacterToKeep)
            {
                IF ($Character -eq "-"){
                    $Regex +="-"
                } else {
                    $Regex += [Regex]::Escape($Character)
                }
                
            }

            $Regex += "]+"
        } 
        ELSE { $Regex = "[^\p{L}\p{Nd}]+" }

        FOREACH ($Str in $string)
        {
            Write-Verbose -Message "Original String: $Str"
            $Str -replace $regex, ""
        }
    } 
}
