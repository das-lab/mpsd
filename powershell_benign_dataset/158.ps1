function Get-SCSMWorkItemAffectedCI
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
		Where-Object { $_.relationshipid -eq 'b73a6094-c64c-b0ff-9706-1822df5c2e82' }
	}
}