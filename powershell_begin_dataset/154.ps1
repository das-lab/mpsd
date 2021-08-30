function Get-SCSMIRComment
{

    [CmdletBinding()]
    PARAM
    (
        [System.WorkItem.Incident[]]$Incident
    )
    PROCESS
    {
        FOREACH ($IR in $Incident)
        {
            TRY
            {
                
                $FilteredIncidents = $IR.AppliesToTroubleTicket | Where-Object {
                    $_.ClassName -eq "System.WorkItem.TroubleTicket.UserCommentLog" -OR $_.ClassName -eq "System.WorkItem.TroubleTicket.AnalystCommentLog"
                }

                IF ($FilteredIncidents.count -gt 0)
                {
                    FOREACH ($Comment in $FilteredIncidents)
                    {
                        $Properties = @{
                            IncidentID = $IR.ID
                            EnteredDate = $Comment.EnteredDate
                            EnteredBy = $Comment.EnteredBy
                            Comment = $Comment.Comment
                            ClassName = $Comment.ClassName
                            IsPrivate = $Comment.IsPrivate
                        }

                        New-Object -TypeName PSObject -Property $Properties
                    } 
                } 
            }
            CATCH
            {
                $Error[0]
            }
        } 

    } 
} 