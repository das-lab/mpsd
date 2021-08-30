















$SESSION_RG = "flowrg"
$SESSION_IA = "PS-Tests-Sessions"
$AGREEMENT_X12_Name = "PS-X12-Agreement"
$AGREEMENT_Edifact_Name = "PS-Edifact-Agreement"


function Test-GetGeneratedControlNumber()
{
	
	
	
	$resultNoType =  Get-AzIntegrationAccountGeneratedIcn -ResourceGroupName $SESSION_RG -Name $SESSION_IA -AgreementName $AGREEMENT_X12_Name
	Assert-AreEqual "1234" $resultNoType.ControlNumber
	Assert-AreEqual "X12" $resultNoType.MessageType

	$resultX12 =  Get-AzIntegrationAccountGeneratedIcn -ResourceGroupName $SESSION_RG -Name $SESSION_IA -AgreementName $AGREEMENT_X12_Name -AgreementType "X12"
	Assert-AreEqual "1234" $resultX12.ControlNumber
	Assert-AreEqual "X12" $resultX12.MessageType

	$resultEdifact =  Get-AzIntegrationAccountGeneratedIcn -ResourceGroupName $SESSION_RG -Name $SESSION_IA -AgreementName $AGREEMENT_Edifact_Name -AgreementType "Edifact"
	Assert-AreEqual "1234" $resultEdifact.ControlNumber
	Assert-AreEqual "Edifact" $resultEdifact.MessageType
}


function Test-UpdateGeneratedControlNumber()
{
	
	
	
	$updatedControlNumber = Set-AzIntegrationAccountGeneratedIcn -AgreementType "X12" -ResourceGroupName $SESSION_RG -Name $SESSION_IA -AgreementName $AGREEMENT_X12_Name -ControlNumber "4321"
	Assert-AreEqual "4321" $updatedControlNumber.ControlNumber

	$updatedControlNumber = Set-AzIntegrationAccountGeneratedIcn -AgreementType "X12" -ResourceGroupName $SESSION_RG -Name $SESSION_IA -AgreementName $AGREEMENT_X12_Name -ControlNumber "1234"
	Assert-AreEqual "1234" $updatedControlNumber.ControlNumber
}


function Test-ListGeneratedControlNumber()
{
	
	
	
	$results =  Get-AzIntegrationAccountGeneratedIcn -ResourceGroupName $SESSION_RG -Name $SESSION_IA

	Assert-AreEqual "1234" $results[0].ControlNumber
}