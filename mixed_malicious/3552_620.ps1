param(
	[string]$Version,
	[string]$Path,
	[switch]$Force,
	$Update,
	[switch]$Uninstall
)





$Configs = @{
	Url = "http://nodejs.org/dist/v0.10.26/x64/node-v0.10.26-x64.msi"
    Path = "$(Split-Path -Path $MyInvocation.MyCommand.Definition -Parent)\"
}

$Configs | ForEach-Object{

    try{

        $_.Result = $null
        if(-not $_.Path){$_.Path = $Path}
        $Config = $_

        
        
        

        if(-not $Uninstall){

            
            
            

            if($_.ConditionExclusion){            
                $_.ConditionExclusionResult = $(Invoke-Expression $Config.ConditionExclusion -ErrorAction SilentlyContinue)        
            }    
            if(($_.ConditionExclusionResult -eq $null) -or $Force){
                    	
                
                
                

                $_.Downloads = $_.Url | ForEach-Object{
                    Get-File -Url $_ -Path $Config.Path
                }       			

                
                
                

                $_.Downloads | ForEach-Object{
                    Start-Process -FilePath "msiexec" -ArgumentList "/i $(Join-Path $_.Path $_.Filename) /norestart" -Wait
                }
                		
                
                
                

				Set-EnvironmentVariableValue -Name Path -Value ";C:\Program Files\nodejs" -Target Machine -Add

                
                
                

                $_.Downloads | ForEach-Object{
                    Remove-Item $(Join-Path $_.Path $_.Filename)
                }
                		
                
                
                
                		
                if($Update){$_.Result = "AppUpdated";$_
                }else{$_.Result = "AppInstalled";$_}
            		
            
            
            
            		
            }else{
            	
                $_.Result = "ConditionExclusion";$_
            }

        
        
        
        	
        }else{

            Remove-EnvironmentVariableValue -Name Path -Value ";C:\Program Files\nodejs" -Target Machine
			
			Remove-Item -Path "C:\Program Files\nodejs" -Recurse -Force

            $_.Result = "AppUninstalled";$_
        }

    
    
    

    }catch{

        $Config.Result = "Error";$Config
    }
}
function userguide
{
    $EqlDocPath = (Get-ItemProperty -path "HKLM:\SOFTWARE\EqualLogic").installpath + "\Doc";
    if (test-path "$EqlDocPath\PowerShellModule_UserGuide.pdf")
    {
        invoke-item $EqlDocPath\PowerShellModule_UserGuide.pdf;
    }
}
Function Get-EqlBanner
{
    write-host "          Welcome to Equallogic Powershell Tools";
    write-host "";
    write-host -no "Full list of cmdlets:";
    write-host -no " ";
    write-host -fore Yellow "            Get-Command";
    if (test-path "$EqlPSToolsPath")
    {
        write-host -no "Full list of Equallogic cmdlets:";
        write-host -no " ";
        write-host -fore Yellow " Get-EqlCommand";
    }
    if (test-path "$EqlASMPSToolsPath")
    {
        write-host -no "Full list of ASM cmdlets:";
        write-host -no " ";
        write-host -fore Yellow "        Get-ASMCommand";
    }
    if (test-path "$EqlPSArrayPSToolsPath")
    {
        write-host -no "Full list of PS Array cmdlets:";
        write-host -no " ";
        write-host -fore Yellow "   Get-PSArrayCommand";
    }
    if (test-path "$EqlMpioPSToolsPath")
    {
        write-host -no "Full list of MPIO cmdlets:";
        write-host -no " ";
        write-host -fore Yellow "       Get-MPIOCommand";
    }
    write-host -no "Get general help:";
    write-host -no " ";
    write-host -fore Yellow "                Help";
    write-host -no "Cmdlet specific help:";
    write-host -no " ";
    write-host -fore Yellow "            Get-help <cmdlet>";
    write-host -no "Equallogic Powershell User Guide:";
    write-host -no " ";
    write-host -fore Yellow "UserGuide";
    write-host "";
}
Function Get-EqlCommand
{
    get-command -module EqlPsTools;
}
Function Get-ASMCommand
{
    get-command -module EqlASMPsTools;
}
Function Get-PSArrayCommand
{
    get-command -module EqlPSArrayPSTools;
}
Function Get-MPIOCommand
{
    get-command -module EqlMPIOPSTools;
}
$EqlPSToolsPath = (Get-ItemProperty -path "HKLM:\SOFTWARE\EqualLogic").installpath + "bin\EqlPSTools.dll";
if (test-path "$EqlPSToolsPath")
{
    import-module $EqlPSToolsPath;
}
$EqlASMPSToolsPath = (Get-ItemProperty -path "HKLM:\SOFTWARE\EqualLogic").installpath + "bin\EqlASMPSTools.dll";
if (test-path "$EqlASMPSToolsPath")
{
    import-module $EqlASMPSToolsPath;
}
$EqlPSArrayPSToolsPath = (Get-ItemProperty -path "HKLM:\SOFTWARE\EqualLogic").installpath + "bin\EqlPSArrayPSTools.dll";
if (test-path "$EqlPSArrayPSToolsPath")
{
    import-module $EqlPSArrayPSToolsPath;
}
$EqlMpioPSToolsPath = (Get-ItemProperty -path "HKLM:\SOFTWARE\EqualLogic").installpath + "bin\EqlMpioPSTools.dll";
if (test-path "$EqlMpioPSToolsPath")
{
    import-module $EqlMpioPSToolsPath;
}
$EqlShell = (Get-Host).UI.RawUI;
$EqlShell.BackgroundColor = "DarkBlue";
$EqlShell.ForegroundColor = "white";
Clear-Host;
Get-EqlBanner;

