
filter Out-HtmlString
{
    
    $_ | 
        Out-String -Width 9999 | 
        ForEach-Object { $_.Trim() } |
        Where-Object { $_ }
}

