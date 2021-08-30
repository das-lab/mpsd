function Get-SCSMReviewActivityReviewer
{
    

    [CmdletBinding(DefaultParameterSetName = 'Object')]
    param
    (
        [Parameter(ParameterSetName = 'Object',
                   Mandatory = $true,
                   ValueFromPipeline = $true)]
        $ActivityObject,

        [Parameter(ParameterSetName = 'Name',
                   Mandatory = $true)]
        $ActivityName,

        [Parameter(ParameterSetName = 'GUID',
                   Mandatory = $true)]
        $ActivityGUID
    )

    BEGIN { Import-Module -Name SMLets -ErrorAction Stop }
    PROCESS
    {
        IF ($PSBoundParameters['ActivityGUID'])
        {
            $RA = Get-SCSMObject -Id $ActivityGUID
        }
        IF ($PSBoundParameters['ActivityName'])
        {
            $RA = Get-SCSMObject (Get-SCSMClass System.WorkItem.Activity.ReviewActivity$) -Filter Id -eq $ActivityName
        }
        IF ($PSBoundParameters['ActivityObject'])
        {
            $RA = $ActivityObject
        }


        $RelationshipClassHasReviewer = Get-SCSMRelationshipClass System.ReviewActivityHasReviewer$
        $RelationshipClassReviewerIsUser = Get-SCSMRelationshipClass System.ReviewerIsUser$
        foreach ($Reviewer in (Get-SCSMRelatedObject -SMObject $RA -Relationship $RelationshipClassHasReviewer))
        {
            Get-SCSMRelatedObject -SMObject $Reviewer -Relationship $RelationshipClassReviewerIsUser
        }
    }
}