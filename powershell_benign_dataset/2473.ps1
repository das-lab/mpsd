













Import-Module "$nanoFolderPath\NanoServerImageGenerator.psm1"
New-NanoServerImage -MediaPath $winSrvDrivePath -BasePath $nanoFolderPath -TargetPath "$nanoFolderPath\Nano.vhd" -ComputerName NanoServer –GuestDrivers -AdministratorPassword p@$$w0rd1

















Import-Module Azure
Add-AzureAccount
Select-AzureSubscription -Default $subscription






Get-AzureLocation | select name


$affinityGroup = 'somegroup'
Get-AffinityGroup -Name $affinityGroup -ea Ignore

New-AzureAffinityGroup -Name 'testgroup' -Location 'Central US'

Get-AzureStorageAccount -Name
New-AzureStorageAccount -StorageAccountName 'adamstorage123' -AffinityGroup testgroup

Get-AzureStorageAccount | Format-Table -Property Label
$storageAccountName = "jrprlabstor01"
Get-AzureStorageContainer




$LocalVHD = "C:\NanoServer\NanoServer.vhd"

$storageEndpoint = (Get-AzureStorageAccount -StorageAccountName adamstorage123).Endpoints[0].Trim('/')


Get-AzureStorageAccount | Get-AzureStorageContainer
$imagesContainer = 'testcontainer' 

$AzureVHD = "$storageEndpoint/$imagesContainer/nano.vhd"
Add-AzureVhd -LocalFilePath $LocalVHD -Destination $AzureVHD


Add-AzureVMImage -ImageName 'nano.vhd' -MediaLocation <VHDLocation> -OS 'Windows'






