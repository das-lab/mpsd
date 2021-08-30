

$Random=(New-Guid).ToString().Substring(0,8)


$ResourceGroupName="myResourceGroup$random"
$AppName="AppServiceManualScale$random"
$Location="WestUS"


New-AzResourceGroup -Name $ResourceGroupName -Location $Location


New-AzAppservicePlan -Name AppServiceManualScalePlan -ResourceGroupName $ResourceGroupName -Location $Location -Tier Basic


New-AzWebApp -Name $AppName -ResourceGroupName $ResourceGroupName -Location $Location -AppServicePlan AppServiceManualScalePlan


Set-AzAppServicePlan -NumberofWorkers 2 -Name AppServiceManualScalePlan -ResourceGroupName $ResourceGroupName
