















[reflection.assembly]::LoadwithPartialName("Microsoft.SQLServer.SMO") | out-Null



[boolean]$defaulted = $false
if ($args[0] -ne $null) {
    $server = $args[0] }
else {
    $server = "default_server"
    $defaulted = $true
     }
 
if ($args[1] -ne $null) {
    $filename = $args[1] }
else {
    $filename = "E:\Dexma\logs\" + $server + "_ScriptedObjects.txt"
    $defaulted = $true
     }
 
if ($args[2] -ne $null) {
    $action = $args[2] }
else {
    $action = "linkedservers"
    $defaulted = $true
     }
 




 

$sql = New-Object 'Microsoft.sqlserver.management.smo.server' $server
 

$scropt = New-Object 'Microsoft.sqlserver.management.smo.scriptingoptions'
$scropt.FileName = $filename
$scropt.includeheaders = $true
$scropt.appendtofile = $true
 

switch ($action) {
       "linkedservers" {
              
              $sql.LinkedServers | foreach-Object {$_.script($scropt) | out-null}
       }
       "logins" {
                     
                     $sql.Logins| foreach-Object {$_.script($scropt) | out-null}
       }
       "jobs" {
                     
                     $sql.JobServer.jobs| foreach-Object {$_.script($scropt) | out-null}
       }
       default {
              
              "ERROR: Action not recognised"
              return 2
       }
}
 

$action + " on " + $server + " scripted to " + $filename
 

if ($defaulted -eq $false) {
    return
    }
else
    {
    ""
    "WARNING: One or more of the required command line parameters was not provided. Defaults were used"
    ""
       "Expected parameters: "
       "  <server> <filename to script to> <linkedservers|logins>"
    return 1
    }