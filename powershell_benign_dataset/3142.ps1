
$Result = [pscustomobject] @{
    Result1 = $Result1
    Result2 = $Result2
}

Return $Result




[System.Collections.ArrayList]$Results = @()

foreach($Item in $Items)
{
    $Result = [pscustomobject] @{
        Result1 = $Item.Result1
        Result2 = $Item.Result2
    }

    [void]$Results.Add($Result)
}

Return $Results