

$Random=(New-Guid).ToString().Substring(0,8)


$ResourceGroup="MyResourceGroup$Random"
$AppName="webappwithSQL$Random"
$Location="West US"
$ServerName="webappwithsql$Random"
$StartIP="0.0.0.0"
$EndIP="0.0.0.0"
$Username="ServerAdmin"
$Password="<provide-a-password>"
$SqlServerPassword=New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $Username,(ConvertTo-SecureString -String $Password -AsPlainText -Force)


New-AzResourceGroup -Name $ResourceGroup -Location $Location


New-AzAppservicePlan -Name WebAppwithSQLPlan -ResourceGroupName $ResourceGroup -Location $Location -Tier Basic


New-AzWebApp -Name $AppName -ResourceGroupName $ResourceGroup -Location $Location -AppServicePlan WebAppwithSQLPlan


New-AzSQLServer -ServerName $ServerName -Location $Location -SqlAdministratorCredentials $SqlServerPassword -ResourceGroupName $ResourceGroup


New-AzSqlServerFirewallRule -FirewallRuleName "AllowYourIp" -StartIpAddress $StartIP -EndIPAddress $EndIP -ServerName $ServerName -ResourceGroupName $ResourceGroup


New-AzSQLDatabase -ServerName $ServerName -DatabaseName MySampleDatabase -ResourceGroupName $ResourceGroup


Set-AzWebApp -ConnectionStrings @{ MyConnectionString = @{ Type="SQLAzure"; Value ="Server=tcp:$ServerName.database.windows.net;Database=MySampleDatabase;User ID=$Username@$ServerName;Password=$password;Trusted_Connection=False;Encrypt=True;" } } -Name $AppName -ResourceGroupName $ResourceGroup
