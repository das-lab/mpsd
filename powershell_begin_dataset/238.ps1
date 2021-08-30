function Get-SCSMWorkItemRequestOffering
{
	
	PARAM (
		[Parameter(ValueFromPipeline)]
		$SMObject
	)
	BEGIN { Import-Module -Name SMLets -ErrorAction Stop }
	PROCESS
	{
		foreach ($Item in $SMObject)
		{
			(Get-SCSMRelationshipObject -BySource $Item | Where-Object { $_.RelationshipID -eq "2730587f-3d88-a4e4-42d8-08cf94535a6e" }).TargetObject |
			Select-Object -property @{ Label = "WorkItemName"; Expression = { $Item.Name } }, @{ Label = "WorkItemGUID"; Expression = { $Item.get_id() } }, *

		}
	}
	END {Remove-Module -Name Smlets -ErrorAction SilentlyContinue}
}