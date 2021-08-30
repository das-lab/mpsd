function Add-SCSMReviewActivityReviewer
{

    [CmdletBinding()]
    PARAM
    (
        [System.String]$UserName,

        [Boolean]$veto = $false,

        [Boolean]$mustvote = $false,

        $WorkItemID
    )

    BEGIN { Import-Module -Name SMLets -ErrorAction Stop }
    PROCESS
    {
        
        $ADUserClassID = '10a7f898-e672-ccf3-8881-360bfb6a8f9a'
        $ADUserClassObject = Get-ScsmClass -Id $ADUserClassID

        $ScsmUser = Get-ScsmObject -class $ADUserClassObject -filter "Username -eq $UserName"

        if ($ScsmUser)
        {
            
            $RelationShipClass_HasReviewer = Get-SCSMRelationshipClass -name "System.ReviewActivityHasReviewer"
            $RelationShipClass_ReviewerIsUser = Get-SCSMRelationshipClass -name "System.ReviewerIsUser"
            $Class_ReviewerClass = Get-SCSMClass -name "System.Reviewer$"

            
            $ReviewerArgs = @{ ReviewerID = "{0}"; Mustvote = $mustvote; Veto = $veto }

            $Reviewer = new-scsmobject -class $class_ReviewerClass -propertyhashtable $ReviewerArgs -nocommit

            $WorkItem = Get-SCSMObject -Class (Get-SCSMClass -Name System.WorkItem.Activity.ReviewActivity$) -filter "ID -eq '$WorkItemID'"

            $reviewerStep1 = New-SCSMRelationshipObject -nocommit -Relationship $RelationShipClass_HasReviewer -Source $WorkItem -Target $Reviewer
            $reviewerStep2 = New-SCSMRelationshipObject -nocommit -Relationship $RelationShipClass_ReviewerIsUser -Source $Reviewer -Target $ScsmUser
            $reviewerStep1.Commit()
            $reviewerStep2.Commit()
        }
    }
}
