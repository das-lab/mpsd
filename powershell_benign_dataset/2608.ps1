

param([parameter(Mandatory=$true)][string] $target
 , [int]$MemGB
 , [Switch] $apply
 )


[System.Reflection.Assembly]::LoadWithPartialName('Microsoft.SqlServer.SMO') | out-null

if($target.Contains("\")){
 $sqlhost = $target.Split("\") | Select -First 1
 }
else{
 $sqlhost = $target
 }


if($MemGB){
    $totalmem = $MemGB 
    $sqlmem = [math]::floor($totalmem)
} else {
    $totalmem = (gwmi Win32_ComputerSystem -computername $sqlhost).TotalPhysicalMemory/1GB
    $sqlmem = [math]::floor($totalmem)
}


while($totalmem -gt 0){
 if($totalmem -gt 16){
 $sqlmem -= [math]::floor(($totalmem-16)/8)
 $totalmem=16
 }
 elseif($totalmem -gt 4){
 $sqlmem -= [math]::floor(($totalmem)/4)
 $totalmem = 4
 }
 else{
 $sqlmem -= 1
 $totalmem = 0
 }
}


$srv = New-Object -TypeName Microsoft.SqlServer.Management.Smo.Server $target
 "Instance:" + $target
 "Max Memory:" + $srv.Configuration.MaxServerMemory.ConfigValue/1024 + " -> " + $sqlmem
 "Min Memory:" + $srv.Configuration.MinServerMemory.ConfigValue/1024 + " -> " + $sqlmem/2
if($apply){
 $srv.Configuration.MaxServerMemory.ConfigValue = $sqlmem * 1024
 $srv.Configuration.MinServerMemory.ConfigValue = $sqlmem/2 * 1024
 $srv.Configuration.Alter()
 "Configuration Complete!"
 }