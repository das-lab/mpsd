function Get-SCSMWorkItemRelatedCI
{

	PARAM (
		[parameter()]
		[Alias()]
		$GUID
	)
	PROCESS
	{
		
		$WorkItemObject = Get-SCSMObject -id $GUID

		
		Get-SCSMRelationshipObject -BySource $WorkItemObject |
		Where-Object { $_.relationshipid -eq 'd96c8b59-8554-6e77-0aa7-f51448868b43' }
	}
}