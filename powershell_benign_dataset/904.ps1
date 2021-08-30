$fqdn="<Replace with your custom domain name>"
$webappname="mywebapp$(Get-Random)"
$location="West Europe"


New-AzResourceGroup -Name $webappname -Location $location


New-AzAppServicePlan -Name $webappname -Location $location `
-ResourceGroupName $webappname -Tier Free


New-AzWebApp -Name $webappname -Location $location -AppServicePlan $webappname `
-ResourceGroupName $webappname

Write-Host "Configure a CNAME record that maps $fqdn to $webappname.azurewebsites.net"
Read-Host "Press [Enter] key when ready ..."






Set-AzAppServicePlan -Name $webappname -ResourceGroupName $webappname `
-Tier Shared


Set-AzWebApp -Name $webappname -ResourceGroupName $webappname `
-HostNames @($fqdn,"$webappname.azurewebsites.net")
