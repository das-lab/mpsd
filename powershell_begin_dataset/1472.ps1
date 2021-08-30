
filter Format-ForHtml 
{
    
    if( $_ )
    {
        [Web.HttpUtility]::HtmlEncode($_)
    }
}
