



$registryName = "<container-registry-name>"
$resourceGroup = "<resource-group-name>"
$servicePrincipalName = "acr-service-principal"


Import-Module Az.Resources 
$password = [guid]::NewGuid().Guid
$secpassw = New-Object Microsoft.Azure.Commands.ActiveDirectory.PSADPasswordCredential -Property @{ StartDate=Get-Date; EndDate=Get-Date -Year 2024; Password=$password}



$registry = Get-AzContainerRegistry -ResourceGroupName $resourceGroup -Name $registryName


$sp = New-AzADServicePrincipal -DisplayName $servicePrincipalName -PasswordCredential $secpassw



Start-Sleep 30






$role = New-AzRoleAssignment -ObjectId $sp.Id -RoleDefinitionName acrpull -Scope $registry.Id



Write-Host "Service principal application ID:" $sp.ApplicationId
Write-Host "Service principal passwd:" $password
