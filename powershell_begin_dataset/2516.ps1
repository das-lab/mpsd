




 
$users = "mmessano@primealliancesolutions.com" 		
$fromemail = "DataManagement@primealliancesolutions.com"
$server = "outbound.smtp.dexma.com" 

$list = "C:\Users\MMessano\Desktop\Payload_QA.txt"
$computers = get-content $list 		


[decimal]$thresholdspace = 60
 

$tableFragment = Get-WMIObject  -ComputerName $computers Win32_LogicalDisk `
| select __SERVER, DriveType, VolumeName, Name, @{n='Size (Gb)' ;e={"{0:n2}" -f ($_.size/1gb)}},@{n='FreeSpace (Gb)';e={"{0:n2}" -f ($_.freespace/1gb)}}, @{n='PercentFree';e={"{0:n2}" -f ($_.freespace/$_.size*100)}} `
| Where-Object {$_.DriveType -eq 3} `
| ConvertTo-HTML -fragment



$HTMLmessage = @"
<font color=""black"" face=""Arial, Verdana"" size=""3"">
<u><b>Disk Space Storage Report</b></u>
<br>This report was generated because the drive(s) listed below have less than $thresholdspace % free space. Drives above this threshold will not be listed.
<br>
<style type=""text/css"">body{font: .8em ""Lucida Grande"", Tahoma, Arial, Helvetica, sans-serif;}
ol{margin:0;padding: 0 1.5em;}
table{color:
thead{}
thead th{padding:1em 1em .5em;border-bottom:1px dotted 
thead tr{}
td{padding:.5em 1em;}
tfoot{}
tfoot td{padding-bottom:1.5em;}
tfoot tr{}

</style>
<body BGCOLOR=""white"">
$tableFragment
</body>
"@
 


$regexsubject = $HTMLmessage
$regex = [regex] '(?im)<td>'
 


	send-mailmessage -from $fromemail -to $users -subject "Disk Space Monitoring Report" -BodyAsHTML -body $HTMLmessage -priority High -smtpServer $server

 
