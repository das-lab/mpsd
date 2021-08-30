
$rgName1="MyResourceGroup1"
$rgName2="MyResourceGroup2"
$location1="eastus"
$location2="westeurope"


$webApp1="mywebapp$(Get-Random)"
$webApp2="mywebapp$(Get-Random)"
$webAppL1="MyWebAppL1"
$webAppL2="MyWebAppL2"


New-AzResourceGroup -Name $rgName1 -Location $location1


New-AzResourceGroup -Name $rgName2 -Location $location2


$gitrepo="https://github.com/Azure-Samples/app-service-web-dotnet-get-started.git"



$appServicePlan = New-AzAppServicePlan -Name $webappl1 -ResourceGroupName $rgName1 `
  -Location $location1 -Tier Standard 

$web1 = New-AzWebApp -ResourceGroupName $rgname1 -Name $webApp1 -Location $location1 `
  -AppServicePlan $webappl1


$PropertiesObject = @{
    repoUrl = "$gitrepo";
    branch = "master";
    isManualIntegration = "true";
}

Set-AzResource -PropertyObject $PropertiesObject -ResourceGroupName $rgname1 `
-ResourceType Microsoft.Web/sites/sourcecontrols -ResourceName $webapp1/web `
-ApiVersion 2015-08-01 -Force



$appServicePlan = New-AzAppServicePlan -Name $webappl2 -ResourceGroupName $rgName2 `
  -Location $location2 -Tier Standard 

$web2 = New-AzWebApp -ResourceGroupName $rgname2 -Name $webApp2 `
  -Location $location2 -AppServicePlan $webappl2

$PropertiesObject = @{
    repoUrl = "$gitrepo";
    branch = "master";
    isManualIntegration = "true";
}

Set-AzResource -PropertyObject $PropertiesObject -ResourceGroupName $rgname2 `
  -ResourceType Microsoft.Web/sites/sourcecontrols -ResourceName $webapp2/web `
  -ApiVersion 2015-08-01 -Force


$tm = New-AzTrafficManagerProfile -Name 'MyTrafficManagerProfile' -ResourceGroupName $rgname1 `
  -TrafficRoutingMethod Priority -RelativeDnsName $web1.SiteName -Ttl 60 `
  -MonitorProtocol HTTP -MonitorPort 80 -MonitorPath /



$endpoint = New-AzTrafficManagerEndpoint -Name 'MyEndPoint1' -ProfileName $tm.Name `
  -ResourceGroupName $rgname1 -Type AzureEndpoints -Priority 1 `
  -TargetResourceId $web1.Id -EndpointStatus Enabled


$endpoint2 = New-AzTrafficManagerEndpoint -Name 'MyEndPoint2' -ProfileName $tm.Name `
  -ResourceGroupName $rgname1 -Type AzureEndpoints -Priority 2 `
  -TargetResourceId $web2.Id -EndpointStatus Enabled

