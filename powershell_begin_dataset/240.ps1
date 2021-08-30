function Get-SCSMObjectPrefix
{


	[OutputType([psobject])]
	param
	(
		[ValidateSet(
			   'DependentActivity',
			   'ManualActivity',
			   'ParallelActivity',
			   'ReviewActivity',
			   'RunbookAutomationActivity',
			   'SequentialActivity',
			   'IncidentRequest',
			   'ServiceRequest',
			   'Change',
			   'Knowledge',
			   'Problem',
			   'Release'
	)]
		[string]$ClassName
	)

	BEGIN
	{
		Import-Module -Name Smlets

		$ActivitySettingsObj = Get-SCSMObject -Class (Get-SCSMClass -Name "System.GlobalSetting.ActivitySettings")
		$ChangeSettingsObj = Get-SCSMObject -Class (Get-SCSMClass -Name "System.GlobalSetting.ChangeSettings")
		$KnowledgedSettingsObj = Get-SCSMObject -Class (Get-SCSMClass -Name "System.GlobalSetting.KnowledgeSettings")
		$ProblemSettingsObj = Get-SCSMObject -Class (Get-SCSMClass -Name "System.GlobalSetting.ProblemSettings")
		$ReleaseSettingsObj = Get-SCSMObject -Class (Get-SCSMClass -Name "System.GlobalSetting.ReleaseSettings")
		$ServiceRequestSettingsObj = Get-SCSMObject -Class (Get-SCSMClass -Name "System.GlobalSetting.ServiceRequestSettings")
		$IncidentRequestSettingsObj = Get-SCSMObject -Class (Get-SCSMClass -Name "System.WorkItem.Incident.GeneralSetting")
	}
	PROCESS
	{
		Switch ($ClassName)
		{
			"DependentActivity" { $ActivitySettingsObj.SystemWorkItemActivityDependentActivityIdPrefix }
			"ManualActivity" { $ActivitySettingsObj.SystemWorkItemActivityManualActivityIdPrefix }
			"ParallelActivity" { $ActivitySettingsObj.SystemWorkItemActivityParallelActivityIdPrefix }
			"ReviewActivity" { $ActivitySettingsObj.SystemWorkItemActivityReviewActivityIdPrefix }
			"RunbookAutomationActivity" { $ActivitySettingsObj.MicrosoftSystemCenterOrchestratorRunbookAutomationActivityBaseIdPrefix }
			"SequentialActivity" { $ActivitySettingsObj.SystemWorkItemActivitySequentialActivityIdPrefix }
			"IncidentRequest" { $IncidentRequestSettingsObj.PrefixForId }
			"ServiceRequest" { $ServiceRequestSettingsObj.ServiceRequestPrefix }
			"Change" { $ChangeSettingsObj.SystemWorkItemChangeRequestIdPrefix }
			"Knowledge" { $KnowledgedSettingsObj.SystemKnowledgeArticleIdPrefix }
			"Problem" { $ProblemSettingsObj.ProblemIdPrefix }
			"Release" { $ReleaseSettingsObj.SystemWorkItemReleaseRecordIdPrefix }
			default
			{
				[pscustomobject][ordered]@{
					"DependentActivity" = $ActivitySettingsObj.SystemWorkItemActivityDependentActivityIdPrefix
					"ManualActivity" = $ActivitySettingsObj.SystemWorkItemActivityManualActivityIdPrefix
					"ParallelActivity" = $ActivitySettingsObj.SystemWorkItemActivityParallelActivityIdPrefix
					"ReviewActivity" = $ActivitySettingsObj.SystemWorkItemActivityReviewActivityIdPrefix
					"RunbookAutomationActivity" = $ActivitySettingsObj.MicrosoftSystemCenterOrchestratorRunbookAutomationActivityBaseIdPrefix
					"SequentialActivity" = $ActivitySettingsObj.SystemWorkItemActivitySequentialActivityIdPrefix
					"IncidentRequest" = $IncidentRequestSettingsObj.PrefixForId
					"ServiceRequest" = $ServiceRequestSettingsObj.ServiceRequestPrefix
					"Change" = $ChangeSettingsObj.SystemWorkItemChangeRequestIdPrefix
					"Knowledge" = $KnowledgedSettingsObj.SystemKnowledgeArticleIdPrefix
					"Problem" = $ProblemSettingsObj.ProblemIdPrefix
					"Release" = $ReleaseSettingsObj.SystemWorkItemReleaseRecordIdPrefix
				}
			}
		}
	}
}
