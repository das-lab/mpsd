
$cred = Get-Credential -UserName '<User>@<Tenant>.onmicrosoft.com' -Message "Enter SPO credentials"


Connect-SPOService -Url 'https://<Tenant>-admin.sharepoint.com' -Credential $cred


New-SPOSite -Url 'https://<Tenant>.sharepoint.com/sites/pnpdemo' -Title 'Dev Rampup Demo' -Template 'STS


Start-Sleep -Seconds 60


Connect-SPOnline -Url 'https://<Tenant>.sharepoint.com/sites/pnpdemo' -Credentials $cred -ErrorAction Stop

Get-SPOProvisioningTemplate  -Out <Local Drive Location>\pnptemplate.xml -Force



Apply-SPOProvisioningTemplate -Path <Local Drive Location>\pnptemplate.xml



Remove-SPOSite -Identity https://<Tenant>.sharepoint.com/sites/pnpdemo -NoWait -Confirm:$false 
Start-Sleep -Seconds 60
get-spodeletedsite | where-Object -FilterScript {$_.url -eq "https://<Tenant>.sharepoint.com/sites/pnpdemo" } | Remove-SPODeletedSite -Confirm:$false
Disconnect-SPOnline 
Disconnect-SPOService
