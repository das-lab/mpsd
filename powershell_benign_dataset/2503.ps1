function Send-Recycle{
 param([string]$Server,
 [string]$Apppool, 
 $Pools, 
 [string]$Message, 
 $PoolHash )
  
 
  $email = ""
    if (($Apppool -eq $null) -or ($Apppool -eq "")){
       $Server
       
          
            
            
            
            
            foreach ($Pool in $Pools){
               if ($Pool -ne $null){
                    
                   [string] $PName = $Pool
                    Invoke-command -computername $Server -scriptblock {Param($PoolName) import-module webadministration;Restart-WebAppPool -name $PoolName} -argumentlist $PName
                    
                    if(-not $?) {
                        Write-Host "There was a problem, could not recycle the apppool $Pool on $server!"
                      }else{
                        Write-Host "The application Pool $Pool has recycled on $server."
                      }
                    if ($Message) {
                        $email = "true"
                    }
               } else{
                    Write-Host "No Application Pools listed"
               }
            }
         
        
    }else{
        
        if ($Apppool -eq "All") {
            
            foreach ($key in $PoolHash.keys){
                [string] $PName = $PoolHash[$key]
                
                if ($PName -ne "All") {
                    Invoke-command -computername $Server -scriptblock {Param($PoolName) import-module webadministration;Restart-WebAppPool -name $PoolName} -argumentlist $PName
                    
                    if(-not $?) {
                        Write-Host "There was a problem, could not recycle the apppool $PName on $server!"
                      }else{
                        Write-Host "The application Pool $PName has recycled on $server."
                      }
                    if ($Message) {
                        $email = "true"
                    }
                
                }
            }
       
       } else {
            
            
             $poollist = $Apppool.Split(",")
            foreach ($poolname in $poollist){
            
                Invoke-command -computername $Server -scriptblock {Param($PoolName) import-module webadministration;Restart-WebAppPool -name $PoolName} -argumentlist $poolname
                
                if(-not $?) {
                        Write-Host "There was a problem, could not recycle the apppool $poolname on $server!"
                }else{
                        Write-Host "The application Pool $poolname has recycled on $server."
                      }
            }
            if ($Message) {
                $email = "true"
            }
       } 
    }
    
    if ($email){
     Send-Email $Message $Server
    }
 
 }
function Send-Email{
  param([string]$Message, $Server)
  $emailFrom = "Ops@primealliancesolutions.com"
  $emailTo = "outage@primealliancesolutions.com"
  
  
  
  
  
  

  $subject = "Apppools on $Server recycled "

  $body = $Message

  $smtpServer = "outbound.smtp.dexma.com"
  $smtp = new-object Net.Mail.SmtpClient($smtpServer)
  $smtp.Send($emailFrom, $emailTo, $subject, $body)
  
  if(-not $?) {
    Write-Host "There was an error sending the Email!"
  }
}
function Get-Pools{
param([string] $Server,$lNotify, $PoolHash )
    
    $hashCount = 1
    write-host "Loading started Apppools..."
   
    $Pools=Invoke-command -computername $Server -scriptblock {import-module webadministration;$(get-item IIS:\apppools).children} 
    foreach ($pool in $Pools) {
       
       $names = $pool.keys
       foreach ($name in $names){
        
            $state = Invoke-command -computername $Server -scriptblock {Param($PoolName)import-module webadministration;$(Get-Item "IIS:\Apppools\$PoolName").state} -argumentlist $name
           
         
         if ($state -eq "started"){

                $PoolHash["$hashCount"] = "$name"
                if ($lNotify -eq $true){
                    write-host "$hashCount : $name "
                }
                $hashCount = $hashCount + 1

             
         } else {
            
           
         }
       }  
    }
    
   $PoolHash["$hashCount"] = "ALL"
   
    if ($lNotify -eq $true){
        
        write-host "$hashCount : All"
        $Id = read-host "Please Enter the number(s) of the app pool above you want to recycle, Please use a comma for multiple entries, (1,2,3...)"
        $List = $Id.Split(",")
        $nCount = 0
        foreach ($idList in $List){
            if ($nCount -eq 1){
                $poolname = $poolname + "," + $PoolHash[$idList] 
            }else {
                $poolname = $PoolHash[$idList] 
                $nCount = 1
            }
           
        }
    } else {
        [string] $shashCount = "$hashCount"
        $poolname = $PoolHash[$shashCount] 
    }
    
    
    
    
    $poolname2 = $PoolHash["8"] 
     
    return $poolname

} 
function Print-Help{

    write-host "`n`nUSEAGE:`n                 E:\DEXMA\SUPPORT\APPPOOLRESTART_WSS.PS1 [server/environment] [message](optional)"
    write-host "`n`n`nOPTIONS:`n`n                 [server]        Name of the server your recycle if you want to recycle on one server only"
    
    write-host "                 [environment]   Groups in the config file, 'STAGE', 'PROD','STAGE LS'... this will recycle every server  in the apppoollist config files"
    write-host "                 [message]       The message in the email that is sent to change control, if left blank the script will ask if you wish to send a message, if 'PLIST' a list of running app pools will be displayed for the user to select which pool to recycle"
    write-host "`n`n`nCONFIG FILES:`n`n                 [Config]        e:\dexma\support\apppoolrestart.xml the one config file is used for all environments and app pools "

    write-host "`n `n `n-If no parameters are passed the script will prompt for all needed information. `n-If a message is sent, a seperate email is sent for each server recycled."
    write-host "-The script will recycle all app pools listed within the config file unless 'PLIST' is passed as the message, in which case the app pools will be listed"
    write-host "`n `nEXAMPLES: `n                 >E:\DEXMA\SUPPORT\APPPOOLRESTART_WSS.PS1 ""STAGE""  ""Recycling app pools due to migration"""
    write-host "                 >E:\DEXMA\SUPPORT\APPPOOLRESTART_WSS.PS1 ""STGWEBSVCXXX""  "
    write-host "                 >E:\DEXMA\SUPPORT\APPPOOLRESTART_WSS.PS1 ""PROD""  ""PLIST"" `n `n "
}

[string] $Env = $args[0]
$Message = $args[1]
$Pool = ""
$lMessage = $false
$PoolHash = @{}
$ConfigFile = "e:\dexma\support\apppoolrestart.xml"
$Pools = @()
$NoConfig = ""
[xml]$APR = Get-Content $ConfigFile 

IF (($Env -eq "/?") -or ($Env -eq "?") -or ($Env -eq "-help")){
    Print-Help
    exit
}

$Env = $Env.ToUpper()


if ($Message -eq "PLIST") {
    $NoConfig = "PLIST"
    $Message = ""
    $lMessage = $true
} else {
    
    foreach ($poolname in $APR.{apppool.restart}.{App.Pools}.pools){
       
       $Pools += $poolname
    }
    write-host "pools: $Pools"
}


if (($Message -eq $null) -or ($Message -eq "") ){
        [string] $A = read-host "Do you want to send an email message? Yes (y), No (n) or any key."
        if (($A.ToUpper() -eq "Y") -or ($A.ToUpper() -eq "YES" )){
            $Message = read-host "Enter Your Email Message Here"
        }
    }
    


$lGroups = $false
$Servers = @()
foreach ($Group in $APR.{apppool.restart}.{Server.Groups}.Group){
  [string]$Name = $Group.name
  $Name = $Name.ToUpper()
  
  if ($Name -eq $Env){
    $lGroups = $true
    foreach ($Servernames in $Group.server){
        
        $Servers += $Servernames
    }
    break
  }
}

if ($lGroups){
    foreach ($Server in $Servers){ 
        if ($NoConfig -eq "PLIST"){ 
            if ($Pool -eq ""){
                 $Pool= Get-Pools $Server $lMessage $PoolHash
            }
        
        }
       
        Send-Recycle $Server $Pool $Pools $Message $PoolHash 
        
        
        
    }      
} else {
    if (($Env -eq $null) -or ($Env -eq "")){
        $Env= read-host "Please enter the name of the server"
    }
        
        if ($NoConfig -eq "PLIST"){
            
            $Pool= Get-Pools $Env  $lMessage $PoolHash
            
            Send-Recycle $Env  $Pool "" $Message $PoolHash 
        }else {
            Send-Recycle $Env  "" $Pools $Message ""
        }

        
        
      
}

   