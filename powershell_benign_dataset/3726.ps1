














function Test-SmartGroupChangeState
{
	
	$smartGroups = Get-AzSmartGroup -TimeRange 1h
	$smartGroupId = $smartGroups[0].Id

	$oldSmartGroup = Get-AzSmartGroup -SmartGroupId $smartGroupId
	$newState = "Acknowledged"
	$updatedSmartGroup = Update-AzSmartGroupState -SmartGroupId $smartGroupId -State $newState
	Assert-AreEqual $newState $updatedSmartGroup.State

	
	$oldSmartGroup = Update-AzSmartGroupState -SmartGroupId $smartGroupId -State $oldSmartGroup.State
}