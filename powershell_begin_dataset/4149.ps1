

param
(
	[string]
	$OutputFile = 'AdobeAcrobatReport.csv',
	[string]
	$Path
)

function ProcessTextFile {
	If ((Test-Path -Path $OutputFile) -eq $true) {
		Remove-Item -Path $OutputFile -Force
	}
}

function Get-CollectionSystems {
    Param([string]$CollectionID)

	
	Set-Variable -Name System -Scope Local -Force
	Set-Variable -Name SystemArray -Scope Local -Force
	Set-Variable -Name Systems -Scope Local -Force
	
    $SystemArray = @()
	$Systems = get-cmdevice -collectionid $CollectionID | select name | Sort-Object Name
    Foreach ($System in $Systems) {
        $SystemArray = $SystemArray + $System.Name
    }
	Return $SystemArray
	
	
	Remove-Variable -Name System -Scope Local -Force
	Remove-Variable -Name SystemArray -Scope Local -Force
	Remove-Variable -Name Systems -Scope Local -Force
}


cls
Import-Module "D:\Program Files\Microsoft Configuration Manager\AdminConsole\bin\ConfigurationManager.psd1" -Force -Scope Global
Set-Location SCCMSiteCode:
$CollectionSystems = @()
$QuerySystems = @()
$UnlicensedSystems = @()

$WQL = 'select *  from  SMS_R_System inner join SMS_G_System_ADD_REMOVE_PROGRAMS on SMS_G_System_ADD_REMOVE_PROGRAMS.ResourceID = SMS_R_System.ResourceId where SMS_G_System_ADD_REMOVE_PROGRAMS.DisplayName = "Adobe Acrobat 8 Professional" or SMS_G_System_ADD_REMOVE_PROGRAMS.DisplayName = "Adobe Acrobat X Pro - English, Français, Deutsch" or SMS_G_System_ADD_REMOVE_PROGRAMS.DisplayName = "Adobe Acrobat X Standard - English, Français, Deutsch" or SMS_G_System_ADD_REMOVE_PROGRAMS.DisplayName = "Adobe Acrobat XI Pro" or SMS_G_System_ADD_REMOVE_PROGRAMS.DisplayName = "Adobe Acrobat XI Standard"'
$WMI = Get-WmiObject -Namespace Root\SMS\Site_BNA -Query $WQL

$CollectionSystems = Get-CollectionSystems -CollectionID "SCCM00024"
Set-Location c:
$OutputFile = $Path + "\" + $OutputFile
ProcessTextFile
$Output = "Computer Name"
Out-File -FilePath $OutputFile -InputObject $Output -Force -Encoding UTF8
Foreach ($Item in $WMI) {
	$QuerySystems = $QuerySystems + $Item.SMS_R_System.Name
}
Foreach ($QuerySystem in $QuerySystems) {
    $SystemVerified = $false
    Foreach ($CollectionSystem in $CollectionSystems) {
        If ($QuerySystem -eq $CollectionSystem) {
            $SystemVerified = $true
        }
    }
    If ($SystemVerified -eq $false) {
        Out-File -FilePath $OutputFile -InputObject $QuerySystem -Force -Encoding UTF8
    }
}