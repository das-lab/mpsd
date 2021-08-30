$gitrepo="<replace-with-URL-of-your-own-GitHub-repo>"
$gittoken="<replace-with-a-GitHub-access-token>"
$webappname="mywebapp$(Get-Random)"
$location="West Europe"


New-AzResourceGroup -Name myResourceGroup -Location $location


New-AzAppServicePlan -Name $webappname -Location $location `
-ResourceGroupName myResourceGroup -Tier Free


New-AzWebApp -Name $webappname -Location $location -AppServicePlan $webappname `
-ResourceGroupName myResourceGroup


$PropertiesObject = @{
	token = $gittoken;
}
Set-AzResource -PropertyObject $PropertiesObject `
-ResourceId /providers/Microsoft.Web/sourcecontrols/GitHub -ApiVersion 2015-08-01 -Force


$PropertiesObject = @{
    repoUrl = "$gitrepo";
    branch = "master";
}
Set-AzResource -PropertyObject $PropertiesObject -ResourceGroupName myResourceGroup `
-ResourceType Microsoft.Web/sites/sourcecontrols -ResourceName $webappname/web `
-ApiVersion 2015-08-01 -Force

