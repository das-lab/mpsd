param(
	[switch]
	$Force
)








if($Host.Version.Major -lt 2){
    throw "Only compatible with Powershell version 2 and higher"
}


if (-not (Test-Path $Profile)){

    
    Write-Host "Add a default profile script"
	New-Item -path $Profile -type file -force | Out-Null
}





    

$PSProfileConfig = Join-Path -Path (Get-Location).Path -ChildPath "Microsoft.PowerShell_profile.config.ps1"
if((Test-Path $PSProfileConfig) -and ($PSProfile -eq $null -or $Force)){
    iex $PSProfileConfig
}elseif($PSProfile -ne $null){
	Write-Host "Using global configuration of this session"
}elseif(-not (Test-Path $PSProfileConfig)){
    throw "Couldn't find $PSProfileConfig"
}







Get-childitem ($PSfunctions.Path) -Recurse | where{($_.Name.EndsWith("ps1")) -and (-not $_.PSIsContainer)} | foreach{. ($_.Fullname)}






$Features = @()
$Systemvariables = @()


Get-ChildItem -Path $PSconfigs.Path -Filter $PSconfigs.Profile.Filter -Recurse | %{
    [xml]$(get-content $_.FullName)} | %{
        $Features += $_.Content.Feature;$Systemvariables += $_.Content.Systemvariable}
        



        

$PPContent = @()
$PPISEContent = @()



$PPContent += @'
    
$Metadata = @{
Title = "Powershell Profile"
Filename = "Microsoft.PowerShell_profile.ps1"
Description = ""
Tags = "powershell, profile"
Project = ""
Author = "Janik von Rotz"
AuthorContact = "http://janikvonrotz.ch"
CreateDate = "2013-04-22"
LastEditDate = "2014-01-29"
Version = "7.1.1"
License = "This work is licensed under the Creative Commons Attribution-NonCommercial-NoDerivs 3.0 Unported License. To view a copy of this license, visit http://creativecommons.org/licenses/by-nc-nd/3.0/ or send a letter to Creative Commons, 444 Castro Street, Suite 900, Mountain View, California, 94041, USA."
}

'@



 
$PPISEContent += @'
    
$Metadata = @{
Title = "Powershell ISE Profile"
Filename = "Microsoft.PowerShellISE_profile.ps1"
Description = ""
Tags = "powershell, ise, profile"
Project = ""
Author = "Janik von Rotz"
AuthorContact = "http://janikvonrotz.ch"
CreateDate = "2013-04-22"
LastEditDate = "2014-01-29"
Version = "7.1.1"
License = "This work is licensed under the Creative Commons Attribution-NonCommercial-NoDerivs 3.0 Unported License. To view a copy of this license, visit http://creativecommons.org/licenses/by-nc-nd/3.0/ or send a letter to Creative Commons, 444 Castro Street, Suite 900, Mountain View, California, 94041, USA."
}

'@






$PPContent += $Content = @'

. '
'@ + (Join-Path -Path $PSProfile.Path -ChildPath "Microsoft.PowerShell_profile.config.ps1") + "'`n"
$PPISEContent += $Content




Write-Host "Add Autoinclude Functions to the profile script"
$PPContent += $Content = @'

Get-childitem ($PSfunctions.Path) -Recurse | where{($_.Name.EndsWith("ps1")) -and (-not $_.PSIsContainer)} | foreach{. ($_.Fullname)}

'@
$PPISEContent += $Content



	
Write-Host "Add Transcript Logging to the profile script"
$PPContent += @'

Start-Transcript -path $PSlogs.SessionFile
Write-Host ""

'@




function Check-ProfileFeatureStatus{

	param(
		[string]
		$Name
	)
	
	if($Features | Where{($_.Name -eq $Name) -and ($_.Status -eq "Enabled")}){
	
		$true
	
	}elseif($Features | Where{($_.Name -eq $Name) -and ($_.Status -eq "Disabled")}){
	
		$false
	
	}else{
	
		throw "Could not find feature definition for: $Name"	
	}
}








if(Check-ProfileFeatureStatus "Enable Open Powershell here"){
    
    Write-Host "Adding 'Open PowerShell Here' to context menu "
	(Get-ChildItem -Path $PStemplates.Path -Filter "Open PowerShell Here.reg" -Recurse) | %{Invoke-Expression "regedit /s '$($_.Fullname)'"}
		
}




if(Check-ProfileFeatureStatus "Get Quote Of The Day"){
    Write-Host "Add Get Quote Of The Day to the profile script"
	$PPContent += $Content = @'

Get-QuoteOfTheDay
Write-Host ""

'@
    $PPISEContent += $Content
}




if(Check-ProfileFeatureStatus "Git Update"){
	
    Update-PowerShellPowerUp
    
    Copy-PPConfigurationFile -Name $PStemplates.GitUpdate.Name -Force:$Force
    
    Update-ScheduledTask "Git Update"
}




if($Features | Where{($_.Name -contains "Log File Retention") -and ($_.Status -eq "Enabled") -and ($_.Run -match "asDailyJob")}){

    Copy-PPConfigurationFile -Name $PStemplates.LogFileRetention.Name -Force:$Force
    
    Update-ScheduledTask "Log File Retention"
}




if($Features | Where{($_.Name -contains "Log File Retention") -and ($_.Status -eq "Enabled") -and ($_.Run -match "withProfileScript")}){
                    
    Write-Host "Add Log File Retention to the profile script"
    $PPContent += $Content = @'

Delete-ObsoleteLogFiles

'@
    $PPISEContent += $Content
}




if(Check-ProfileFeatureStatus "Powershell Remoting"){
    
    Write-Host "Enabling Powershell Remoting"
	try{Enable-PSRemoting -Confirm:$false}catch{$Error}
	Set-Item WSMan:\localhost\Client\TrustedHosts "RemoteComputer" -Force
	Set-Item WSMan:\localhost\Shell\MaxMemoryPerShellMB 1024
	restart-Service WinRM -Confirm:$false
}




if(Check-ProfileFeatureStatus "Custom PowerShell Profile script"){

    Copy-PPConfigurationFile -Name $PStemplates.CustomPPscript.Name -Force:$Force
    
    Write-Host "Include Custom PowerShell Profile script"
	$PPContent += $(Get-Content (Get-ChildItem -Path $PSconfigs.Path -Filter $PStemplates.CustomPPscript.Name -Recurse).Fullname) + "`n"
}




if(Check-ProfileFeatureStatus "Custom PowerShell Profile ISE script"){

    Copy-PPConfigurationFile -Name $PStemplates.CustomPPISEscript.Name -Force:$Force
    
    Write-Host "Include Custom PowerShell Profile script"
	$PPISEContent += $Content = $(Get-Content (Get-ChildItem -Path $PSconfigs.Path -Filter $PStemplates.CustomPPISEscript.Name -Recurse).Fullname) + "`n"
}


if($SystemVariables -ne $Null){$SystemVariables | %{        
       
        $Path = Get-Path $_.Value
        
        if(Test-Path $Path){
        
            $SystemVariable = $_
        
            Set-EnvironmentVariableValue -Name $SystemVariable.Name -Value (";" + $Path) -Target $SystemVariable.Target -Add
  
        }else{
        
            Write-Error "Path: $Path doesn't exist. Not possible to add value to system variable: $($_.Name)"
        }
    }
}





$PPContent += $Content = @'

Set-Location $WorkingPath

'@
$PPISEContent += $Content


Write-Host "Creating PowerShell Profile Script"
Set-Content -Value $PPContent -Path $Profile


Write-Host "Creating PowerShell ISE Profile Script"
Set-Content -Value $PPISEContent -Path (Join-Path -Path (Split-Path $profile -Parent) -ChildPath "Microsoft.PowerShellISE_profile.ps1")

Set-Location $WorkingPath

Write-Host "Finished" -BackgroundColor Black -ForegroundColor Green