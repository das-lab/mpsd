

$Random=(New-Guid).ToString().Substring(0,8)


$ResourceGroupName="myResourceGroup$Random"
$AppName="AppServiceMonitor$Random"
$Location="WestUS"


New-AzResourceGroup -Name $ResourceGroupName -Location $Location


New-AzAppservicePlan -Name AppServiceMonitorPlan -ResourceGroupName $ResourceGroupName -Location $Location -Tier Basic


New-AzWebApp -Name $AppName -ResourceGroupName $ResourceGroupName -Location $Location -AppServicePlan AppServiceMonitorPlan


Set-AzWebApp -RequestTracingEnabled $True -HttpLoggingEnabled $True -DetailedErrorLoggingEnabled $True -ResourceGroupName $ResourceGroupName -Name $AppName


Invoke-WebRequest -Method "Get" -Uri https://$AppName.azurewebsites.net/404 -ErrorAction SilentlyContinue


Write-Host "In your browser, download the logs for your app at https://$AppName.scm.azurewebsites.net/api/dump"
