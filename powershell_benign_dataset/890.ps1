
$gitrepo="https://github.com/Azure-Samples/app-service-web-dotnet-get-started.git"
$webappname="mywebapp$(Get-Random)"
$location="West Europe"


New-AzResourceGroup -Name myResourceGroup -Location $location


New-AzAppServicePlan -Name $webappname -Location $location `
-ResourceGroupName myResourceGroup -Tier Free


New-AzWebApp -Name $webappname -Location $location `
-AppServicePlan $webappname -ResourceGroupName myResourceGroup


Set-AzAppServicePlan -Name $webappname -ResourceGroupName myResourceGroup `
-Tier Standard


New-AzWebAppSlot -Name $webappname -ResourceGroupName myResourceGroup `
-Slot staging


$PropertiesObject = @{
    repoUrl = "$gitrepo";
    branch = "master";
}
Set-AzResource -PropertyObject $PropertiesObject -ResourceGroupName myResourceGroup `
-ResourceType Microsoft.Web/sites/slots/sourcecontrols `
-ResourceName $webappname/staging/web -ApiVersion 2015-08-01 -Force


Switch-AzWebAppSlot -Name $webappname -ResourceGroupName myResourceGroup `
-SourceSlotName staging -DestinationSlotName production
