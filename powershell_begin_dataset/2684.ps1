$basePath = "C:\DeploymentFiles"
$themePath = "/sites/psdemo/_catalogs/theme/15" 
$tenant = "<yourtenantname>"

$tenantAdmin  = Get-Credential -Message "Enter Tenant Administrator Credentials"
Connect-PnPOnline -Url https://<tenant>-admin.sharepoint.com -Credentials $tenantAdmin

New-PnPTenantSite -Title "PS Site" -Url "https://$tenant.sharepoint.com/sites/psdemo" -Owner $tenantAdmin -Lcid 1033 -TimeZone 24 -Template STS


Connect-PnPOnline -Url https://$tenant.sharepoint.com/sites/psdemo -Credentials $tenantAdmin


Set-PnPPropertyBagValue -Key "PNP_SiteType" -Value "PROJECT"


Add-PnPFile -Path "$basePath\contoso.spcolor" -Url "$themePath/contoso.spcolor"
Add-PnPFile -Path "$basePath\contoso.spfont" -Url "$themePath/contoso.spfont"
Add-PnPFile -Path "$basePath\contosobg.jpg" -Url "$themePath/contosobg.jpg"
Set-PnPTheme -ColorPaletteUrl "$themePath/contoso.spcolor" -FontSchemeUrl "$themePath/contoso.spfont" -BackgroundImageUrl "$themePath/contosobg.jpg"


New-PnPList -Title "Projects" -Template GenericList -Url "lists/projects" -QuickLaunchOptions on
Add-PnPField -List "Projects" -InternalName "ProjectManager" -DisplayName "Project Manager" -StaticName "ProjectManager" -Type User -AddToDefaultView