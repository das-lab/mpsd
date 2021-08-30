







if (-not (Get-Module -ListAvailable -Name SharePointPnPPowerShellOnline)) 
{
    Install-Module SharePointPnPPowerShellOnline
}

Import-Module SharePointPnPPowerShellOnline


$csvConfig = $null


$credentials = $null


$winCredentialsManagerLabel = "SPFX"


try 
{ 
    $csvConfig = Import-Csv -Path "./CreateSites.csv"
} 
catch 
{
    
    $csvConfigPath = Read-Host -Prompt "Please enter the csv configuration template full path"
    $csvConfig = Import-Csv -Path $csvConfigPath
}




if((Get-PnPStoredCredential -Name $winCredentialsManagerLabel) -ne $null)
{
    $credentials = $winCredentialsManagerLabel
}
else
{
    
    $email = Read-Host -Prompt "Please enter tenant admin email"
    $pass = Read-host -AsSecureString "Please enter tenant admin password"
    $credentials = New-Object -TypeName "System.Management.Automation.PSCredential" –ArgumentList $email, $pass
}

if($credentials -eq $null -or $csvConfig -eq $null) 
{
    Write-Host "Error: Not enough details." -ForegroundColor DarkRed
    exit 1
}


foreach ($item in $csvConfig) 
{
    $tenantUrl = $item.RootUrl -replace ".sharepoint.com.+", ".sharepoint.com"
    $siteUrl = -join($item.RootUrl, "/", $item.SiteUrl)
    
    if ($item.Type -eq "SiteCollection") 
    {
        Connect-PnPOnline $tenantUrl -Credentials $credentials

        Write-Host "Provisioning site collection $siteUrl" -ForegroundColor Yellow
         
        if(Get-PnPTenantSite | where-Object -FilterScript {$_.Url -eq $siteUrl}) 
        {
            Write-Host "Site collection $siteUrl exists. Moving to the next one." -ForegroundColor Yellow
            continue
        }

        
        New-PnPTenantSite -Owner $item.Owner -TimeZone $item.TimeZone -Title $item.Title -Url $siteUrl -Template $item.Template -Lcid $item.Locale -Wait

        Write-Host "SiteCollection $siteUrl successfully created." -ForegroundColor Green
    }  
    elseif ($item.Type -eq "SubWeb") 
    {

        $siteCollectionUrl = $item.RootUrl

        Connect-PnPOnline $siteCollectionUrl -Credentials $credentials

        Write-Host "Provisioning sub web $siteUrl." -ForegroundColor Yellow
        
        if(Get-PnPSubWebs | where-Object -FilterScript {$_.Url -eq $siteUrl}) 
        {
            Write-Host "Sub web $siteUrl exists. Moving to the next one." -ForegroundColor Yellow
            continue
        }
        
        
        New-PnPWeb -Template $item.Template -Title $item.Title -Url $item.SiteUrl -Locale $item.Locale

        Write-Host "Sub web $siteUrl successfully created." -ForegroundColor Green
    }
}