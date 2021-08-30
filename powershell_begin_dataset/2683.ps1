


$cred = Get-Credential -UserName '<User>@<Tenant>.onmicrosoft.com' -Message "Enter SPO credentials"


Connect-SPOService -Url 'https://<Tenant>-admin.sharepoint.com' -Credential $cred


New-SPOSite -Url 'https://<Tenant>.sharepoint.com/sites/demo' -Title 'Tech Talk Demo' -Template 'STS


Connect-SPOnline -Url 'https://<Tenant>.sharepoint.com/sites/demo' -Credentials $cred -ErrorAction Stop


New-SPOList -Title "Demo list" -Template GenericList -Url 'lists/demo'


Add-SPOField -List "Demo list" -DisplayName "Location" -InternalName "SPSLocation" -Type Choice -Group "Demo Group" -AddToDefaultView -Choices "Stockholm","Helsinki","Oslo"


Add-SPOField -DisplayName "Demo Field" -InternalName "Demo Field" -Id "65E1E394-B354-4C67-B267-57407C416C10" -Type User -Required -Group "Demo Group" 
Add-SPOField -DisplayName "Demo Field2" -InternalName "Demo Field 2" -Id "{53FF9B38-32F2-47A0-A094-D3692CB52352}" -Type Text -Group "Demo Group" 

$parentCT = Get-SPOContentType -Identity "0x01"
$demoCT = Add-SPOContentType -Name "Demo CT" -Group "Demo Group" -ParentContentType $parentCT 

$demoField1 = Get-SPOField -Identity "65E1E394-B354-4C67-B267-57407C416C10"
$demoField2 = Get-SPOField -Identity "{53FF9B38-32F2-47A0-A094-D3692CB52352}"


Add-SPOFieldToContentType -Field $demoField1 -ContentType $demoCT
Add-SPOFieldToContentType -Field $demoField2 -ContentType $demoCT


$demoList = Get-SPOList "/lists/Demo"
Add-SPOContentTypeToList -List $demoList -ContentType $demoCT -DefaultContentType



Remove-SPOList -Identity $demoList -Force
Remove-SPOContentType -Identity $demoCT -Force
Remove-SPOField -Identity $demoField1 -Force
Remove-SPOField -Identity $demoField2 -Force
Remove-SPOSite -Identity https://<Tenant>.sharepoint.com/sites/demo -NoWait -Confirm:$false 


get-spodeletedsite | where-Object -FilterScript {$_.url -eq "https://<Tenant>.sharepoint.com/sites/demo" } | Remove-SPODeletedSite -Confirm:$false
Disconnect-SPOnline 
Disconnect-SPOService

