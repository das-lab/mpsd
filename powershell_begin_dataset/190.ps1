function Get-SCSMIncidentRequestComment
{


    PARAM
    (
        [Parameter(ParameterSetName = 'General',
                   Mandatory = $true)]
        $DateTime = $((Get-Date).AddHours(-24)),

        [Parameter(ParameterSetName = 'GUID')]
        $GUID
    )
    BEGIN
    {
        $AssignedUserClassRelation = Get-SCSMRelationshipClass -Id 15e577a3-6bf9-6713-4eac-ba5a5b7c4722
    }
    PROCESS
    {

        IF ($PSBoundParameters['GUID'])
        {
            $Tickets = Get-SCSMObject -id $GUID
        }
        ELSE
        {
            if ($DateTime -is [String]) { $DateTime = Get-Date $DateTime }
            $DateTime = $DateTime.ToString(“yyy-MM-dd HH:mm:ss”)
            $Tickets = Get-SCSMObject -Class (Get-SCSMClass System.WorkItem.incident$) -Filter "CreatedDate -gt '$DateTime'" 
        }

        $Tickets |
        ForEach-Object {
            $CurrentTicket = $_
            $relatedObjects = Get-scsmrelatedobject -SMObject $CurrentTicket
            $AssignedTo = (Get-SCSMRelatedObject -SMObject $CurrentTicket -Relationship $AssignedUserClassRelation)
            Foreach ($Comment in ($relatedObjects | Where-Object { $_.classname -eq 'System.WorkItem.TroubleTicket.UserCommentLog' -or $_.classname -eq 'System.WorkItem.TroubleTicket.AnalystCommentLog' -or $_.classname -eq 'System.WorkItem.TroubleTicket.AuditCommentLog' }))
            {
                
                [pscustomobject][ordered] @{
                    TicketName = $CurrentTicket.Name
                    TicketClassName = $CurrentTicket.Classname
                    TicketDisplayName = $CurrentTicket.DisplayName
                    TicketID = $CurrentTicket.ID
                    TicketGUID = $CurrentTicket.get_id()
                    TicketTierQueue = $CurrentTicket.TierQueue.displayname
                    TicketAssignedTo = $AssignedTo.DisplayName
                    TicketCreatedDate = $CurrentTicket.CreatedDate
                    Comment = $Comment.Comment
                    CommentEnteredBy = $Comment.EnteredBy
                    CommentEnteredDate = $Comment.EnteredDate
                    CommentClassName = $Comment.ClassName
                }
            }
        }

    }
}