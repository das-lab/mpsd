function Get-SCSMWorkItemParent
{
    
    [CmdletBinding()]
    PARAM (
        [Parameter(ParameterSetName = 'GUID', Mandatory)]
        [Alias('ID')]
        $WorkItemGUID,

        [Parameter(ParameterSetName = 'Object', Mandatory)]
        $WorkItemObject
    )
    BEGIN
    {
        IF (-not (Get-Module -Name Smlets))
        {
            TRY
            {
                Import-Module -Name smlets -ErrorAction Stop
            }
            CATCH
            {
                Write-Error -Message "[BEGIN] Error importing smlets"
                $Error[0].Exception.Message
            }
        }
        ELSE {Write-Verbose -Message "[BEGIN] Smlets module already loaded"}
    }
    PROCESS
    {
        TRY
        {
            IF ($PSBoundParameters['WorkItemGUID'])
            {
                
                Write-Verbose -Message "[PROCESS] Retrieving WorkItem with GUID"
                $ActivityObject = Get-SCSMObject -id $WorkItemGUID
            }
            IF ($PSBoundParameters['WorkItemObject'])
            {
                
                Write-Verbose -Message "[PROCESS] Retrieving WorkItem with SM Object"
                $ActivityObject = Get-SCSMObject -id $WorkItemObject.get_id()
            }

            
            Write-Verbose -Message "[PROCESS] Activity: $($ActivityObject.name)"
            Write-Verbose -Message "[PROCESS] Retrieving WorkItem Parent"
            $ParentRelationshipID = '2da498be-0485-b2b2-d520-6ebd1698e61b'
            $ParentRelatedObject = Get-SCSMRelationshipObject -ByTarget $ActivityObject | Where-Object{ $_.RelationshipId -eq $ParentRelationshipID }
            $ParentObject = $ParentRelatedObject.SourceObject

            Write-Verbose -Message "[PROCESS] Activity: $($ActivityObject.name) - Parent: $($ParentObject.name)"


            If ($ParentObject.ClassName -eq 'System.WorkItem.ServiceRequest' -OR $ParentObject.ClassName -eq 'System.WorkItem.ChangeRequest' -OR $ParentObject.ClassName -eq 'System.WorkItem.ReleaseRecord' -OR $ParentObject.ClassName -eq 'System.WorkItem.Incident')
            {
                Write-Verbose -Message "[PROCESS] This is the top level parent"
                Write-Output $ParentObject

                
                
            }
            Else
            {
                Write-Verbose -Message "[PROCESS] Not the top level parent. Running Get-SCSMWorkItemParent against this object"
                
                Get-SCSMWorkItemParent -WorkItemGUID $ParentObject.id.guid
            }
        }
        CATCH
        {
            Write-Error -Message $Error[0].Exception.Message
        }
    } 
    END
    {
        remove-module -Name smlets -ErrorAction SilentlyContinue
    }
} 