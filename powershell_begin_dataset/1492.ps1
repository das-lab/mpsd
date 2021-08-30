













function Remove-ItemWithRetry($item, [Switch]$Recurse)
{
    if( -not (Test-Path $item) )
    {
        return
    }
    
    $RecurseParam = if( $Recurse ) { '-Recurse' } else { '' }
    $numTries = 0
    do
    {
        if( -not (Test-Path $item) )
        {
            return $true
        }
        
        if( $Recurse )
        {
            Remove-Item $item -Recurse -Force -ErrorAction SilentlyContinue
        }
        else
        {
            Remove-Item $item -Force -ErrorAction SilentlyContinue
        }
        
        if( Test-Path $item )
        {
            Start-Sleep -Milliseconds 100
        }
        else
        {
            return $true
        }
        $numTries += 1
    }
    while( $numTries -lt 20 )
    return $false
}

