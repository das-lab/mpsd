
 










$csv_SiteList = ".\input\sites.csv"
$csv_siteheaders = 'Url'


$date = Get-Date
$date = $date.ToString("yyyymmddhhss")


$file_name = $date + 'LinkMatches.csv'


$creation_path = ".\PowerShell\GetLinks"


$List = "SitePages"


$headers = "Site Title|Page Title|Page Url|Href Tag"


$ofs = "`n"


$delim = '|'


$regex ='<a\s+(?:[^>]*?\s+)?href=(["])(.*?)\1>'


$creds = Get-Credential


$sites = Import-Csv -Path $csv_SiteList -Header $csv_siteheaders


$csv_outputheader = $headers + $ofs


$csv_path = $creation_path + '/' + $file_name


New-Item -Path $creation_path -Name $file_name -ItemType File -Value $csv_outputheader


foreach($site in $sites)
{
    
    $connection = Connect-PnPOnline -Url $site.Url -Credentials $creds
    $pnpsite = Get-PnPWeb -Connection $connection
    $site_title = $pnpsite.Title
    $pages = (Get-PnPListItem -List $List -Fields "CanvasContent1", "Title" -Connection $connection).FieldValues

    
    
    foreach($page in $pages)
    {
        $page_title = $page.Get_Item("Title")
        $fileref = $page.Get_Item("FileRef")
        $canvascontent = $page.Get_Item("CanvasContent1")
        
        if ($canvascontent.Length -gt 0) 
        {
            
            $hrefmatches = ($canvascontent | select-string -pattern $regex -AllMatches).Matches.Value

            
            foreach($hrefmatch in $hrefmatches)
            {
                $row = $site_title + $delim + $page_title + $delim + $fileref + $delim + $hrefmatch
                Add-Content -Path $csv_path -Value $row
            }
        }
    }
    Disconnect-PnPOnline -Connection $connection
}