function Join-Parts
{
    
    [cmdletbinding()]
    param
    (
    [string]$Separator = "/",

    [parameter(ValueFromRemainingArguments=$true)]
    [string[]]$Parts = $null
        
    )

    ( $Parts |
        Where { $_ } |
        Foreach { ( [string]$_ ).trim($Separator) } |
        Where { $_ }
    ) -join $Separator
}
