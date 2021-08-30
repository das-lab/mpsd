function Get-SCSMServiceRequestComment
{


	PARAM
	(
		[Parameter(ParameterSetName = 'General',
				   Mandatory = $true)]
		$DateTime = $((Get-Date).AddHours(-24)),

		[Parameter(ParameterSetName = 'GUID')]
		$GUID
	)

	IF ($PSBoundParameters['GUID'])
	{
		$Tickets = Get-SCSMObject -id $GUID
	}
	ELSE
	{
		if ($DateTime -is [String]){ $DateTime = Get-Date $DateTime}
		$DateTime = $DateTime.ToString(“yyy-MM-dd HH:mm:ss”)
		$Tickets = Get-SCSMObject -Class (Get-SCSMClass System.WorkItem.servicerequest$) -Filter "CreatedDate -gt '$DateTime'" 
	}

	$Tickets |
	ForEach-Object {
		$CurrentTicket = $_
		$relatedObjects = Get-scsmrelatedobject -SMObject $CurrentTicket
		Foreach ($Comment in ($relatedObjects | Where-Object { $_.classname -eq 'System.WorkItem.TroubleTicket.UserCommentLog' -or $_.classname -eq 'System.WorkItem.TroubleTicket.AnalystCommentLog' -or $_.classname -eq 'System.WorkItem.TroubleTicket.AuditCommentLog'}))
		{
			
			[pscustomobject][ordered] @{
				TicketName = $CurrentTicket.Name
				TicketClassName = $CurrentTicket.Classname
				TicketDisplayName = $CurrentTicket.DisplayName
				TicketID = $CurrentTicket.ID
				TicketGUID = $CurrentTicket.get_id()
				TicketSupportGroup = $CurrentTicket.SupportGroup.displayname
				TicketAssignedTo = $CurrentTicket.AssignedTo
				TicketCreatedDate = $CurrentTicket.CreatedDate
				Comment = $Comment.Comment
				CommentEnteredBy = $Comment.EnteredBy
				CommentEnteredDate = $Comment.EnteredDate
				CommentClassName = $Comment.ClassName
			}
		}
	}
}