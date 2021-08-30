
$ResourceGroupName = "ResourceGroup01"
$SubscriptionID = "SubscriptionID"
$WorkspaceName = "DefaultWorkspace-" + (Get-Random -Maximum 99999) + "-" + $ResourceGroupName
$Location = "eastus"


$ErrorActionPreference = "Stop"


Write-Output "Pulling Azure account credentials..."


$Account = Add-AzAccount


if ([string]::IsNullOrEmpty($SubscriptionID)) {
   
    
    $Subscription =  Get-AzSubscription

    
    $SubscriptionID = (($Subscription).SubscriptionId | Select -First 1).toString()

    
    $TenantID = (($Subscription).TenantId | Select -First 1).toString()

} else {

    
    $Subscription = Get-AzSubscription -SubscriptionId $SubscriptionID
    
    $TenantID = $Subscription.TenantId
}


$null = Set-AzContext -SubscriptionID $SubscriptionID


$null = Get-AzResourceGroup -Name $ResourceGroupName

try {

    $Workspace = Get-AzOperationalInsightsWorkspace -Name $WorkspaceName -ResourceGroupName $ResourceGroupName  -ErrorAction Stop
    $ExistingtLocation = $Workspace.Location
    Write-Output "Workspace named $WorkspaceName in region $ExistingLocation already exists."
	Write-Output "No further action required, script quitting."

} catch {

    Write-Output "Creating new workspace named $WorkspaceName in region $Location..."
    
    $Workspace = New-AzOperationalInsightsWorkspace -Location $Location -Name $WorkspaceName -Sku Standard -ResourceGroupName $ResourceGroupName

}


