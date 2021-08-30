


param(
	$ServerList = "E:\Dexma\Servers.txt"
	, $ReportFileName = "E:\Dexma\FreeSpace.htm"
	, $EmailTo = "mmessano@primealliancesolutions.com"
	, $EmailFrom = "mmessano@primealliancesolutions.com"
	, $EmailSubject = "Disk Space Report for $Domain"
	, $SMTPServer = "10.0.5.199"
)


clear


$Domain = [System.DirectoryServices.ActiveDirectory.Domain]::GetCurrentDomain();


New-Item -ItemType file $ReportFileName -Force


$warning = 40
$critical = 20


Function writeHtmlHeader
{
param($fileName)
	$date = ( get-date ).ToString('yyyy/MM/dd')
	Add-Content $fileName "<html>"
	Add-Content $fileName "<head>"
	Add-Content $fileName "<meta http-equiv='Content-Type' content='text/html; charset=iso-8859-1'>"
	Add-Content $fileName '<title> DiskSpace Report - $Domain</title>'
	add-content $fileName '<STYLE TYPE="text/css">'
	add-content $fileName  "<!--"
	add-content $fileName  "td {"
	add-content $fileName  "font-family: Tahoma;"
	add-content $fileName  "font-size: 11px;"
	add-content $fileName  "border-top: 1px solid 
	add-content $fileName  "border-right: 1px solid 
	add-content $fileName  "border-bottom: 1px solid 
	add-content $fileName  "border-left: 1px solid 
	add-content $fileName  "padding-top: 0px;"
	add-content $fileName  "padding-right: 0px;"
	add-content $fileName  "padding-bottom: 0px;"
	add-content $fileName  "padding-left: 0px;"
	add-content $fileName  "}"
	add-content $fileName  "body {"
	add-content $fileName  "margin-left: 5px;"
	add-content $fileName  "margin-top: 5px;"
	add-content $fileName  "margin-right: 0px;"
	add-content $fileName  "margin-bottom: 10px;"
	add-content $fileName  ""
	add-content $fileName  "table {"
	add-content $fileName  "border: thin solid 
	add-content $fileName  "}"
	add-content $fileName  "-->"
	add-content $fileName  "</style>"
	Add-Content $fileName "</head>"
	Add-Content $fileName "<body>"

	add-content $fileName  "<table width='100%'>"
	add-content $fileName  "<tr bgcolor='
	add-content $fileName  "<td colspan='7' height='25' align='center'>"
	add-content $fileName  "<font face='tahoma' color='
	add-content $fileName  "</td>"
	add-content $fileName  "</tr>"
	add-content $fileName  "</table>"
}


Function writeTableHeader
{
	param($fileName)
	Add-Content $fileName "<tr bgcolor=
	Add-Content $fileName "<td width='10%' align='center'>Drive</td>"
	Add-Content $fileName "<td width='50%' align='center'>Drive Label</td>"
	Add-Content $fileName "<td width='10%' align='center'>Total Capacity(GB)</td>"
	Add-Content $fileName "<td width='10%' align='center'>Used Capacity(GB)</td>"
	Add-Content $fileName "<td width='10%' align='center'>Free Space(GB)</td>"
	Add-Content $fileName "<td width='10%' align='center'>Freespace %</td>"
	Add-Content $fileName "</tr>"
}

Function writeHtmlFooter
{
	param($fileName)
	Add-Content $fileName "</body>"
	Add-Content $fileName "</html>"
}

Function writeDiskInfo
{
	param(
			$fileName
			,$devId
			,$volName
			,$frSpace
			,$totSpace
		)
	$totSpace 		= [math]::Round(($totSpace/1073741824),2)
	$frSpace 		= [Math]::Round(($frSpace/1073741824),2)
	$usedSpace 		= $totSpace - $frspace
	$usedSpace 		= [Math]::Round($usedSpace,2)
	$freePercent 	= ($frspace/$totSpace)*100
	$freePercent 	= [Math]::Round($freePercent,0)
	if ($freePercent -gt $warning)
	{
		Add-Content $fileName "<tr>"
		Add-Content $fileName "<td>$devid</td>"
		Add-Content $fileName "<td>$volName</td>"
		Add-Content $fileName "<td>$totSpace</td>"
		Add-Content $fileName "<td>$usedSpace</td>"
		Add-Content $fileName "<td>$frSpace</td>"
		Add-Content $fileName "<td bgcolor='
		Add-Content $fileName "</tr>"
	}
	elseif ($freePercent -le $critical)
	{
		Add-Content $fileName "<tr>"
		Add-Content $fileName "<td>$devid</td>"
		Add-Content $fileName "<td>$volName</td>"
		Add-Content $fileName "<td>$totSpace</td>"
		Add-Content $fileName "<td>$usedSpace</td>"
		Add-Content $fileName "<td>$frSpace</td>"
		Add-Content $fileName "<td bgcolor='
		Add-Content $fileName "</tr>"
	}
	else
	{
		Add-Content $fileName "<tr>"
		Add-Content $fileName "<td>$devid</td>"
		Add-Content $fileName "<td>$volName</td>"
		Add-Content $fileName "<td>$totSpace</td>"
		Add-Content $fileName "<td>$usedSpace</td>"
		Add-Content $fileName "<td>$frSpace</td>"
		Add-Content $fileName "<td bgcolor='
		Add-Content $fileName "</tr>"
	}
}

writeHtmlHeader $ReportFileName

foreach ($server in Get-Content $serverlist)
{
	try {
		$ServerName = [System.Net.Dns]::gethostentry($server).hostname
		}
	catch [System.DivideByZeroException] {
		Write-Host "DivideByZeroException: "
		$_.Exception
		Write-Host
		if ($_.Exception.InnerException) {
			Write-Host "Inner Exception: "
			$_.Exception.InnerException.Message 
			}
		"Continuing..."
		continue
		}
	catch [System.UnauthorizedAccessException] {
		Write-Host "System.UnauthorizedAccessException"
		$_.Exception
		Write-Host
		if ($_.Exception.InnerException) {
			Write-Host "Inner Exception: "
			$_.Exception.InnerException.Message 
			}
		"Continuing..."
		continue
		}
	catch [System.Management.Automation.RuntimeException] {
		Write-Host "RuntimeException"
		$_.Exception
		Write-Host
		if ($_.Exception.InnerException) {
			Write-Host "Inner Exception: "
			$_.Exception.InnerException.Message 
			}
		"Continuing..."
		continue
		}	
	catch [System.Exception] {
		Write-Host "Exception connecting to $Server" 
		$_.Exception
		Write-Host
		if ($_.Exception.InnerException) {
			Write-Host "Inner Exception: "
			$_.Exception.InnerException.Message 
			}
		"Continuing..."
		continue
		}	
	
	
	if ($ServerName -eq $null) {
			$ServerName = $Server
			}
			
	Add-Content $ReportFileName "<table width='100%'><tbody>"
	Add-Content $ReportFileName "<tr bgcolor='
	Add-Content $ReportFileName "<td width='100%' align='center' colSpan=6><font face='tahoma' color='
	Add-Content $ReportFileName "</tr>"

	writeTableHeader $ReportFileName

	$dp = Get-WmiObject win32_logicaldisk -ComputerName $server |  Where-Object {$_.drivetype -eq 3}

	foreach ($item in $dp)
	{
		Write-Host  $ServerName $item.DeviceID  $item.VolumeName $item.FreeSpace $item.Size
		writeDiskInfo $ReportFileName $item.DeviceID $item.VolumeName $item.FreeSpace $item.Size
	}
	$ServerName = $NULL
}

writeHtmlFooter $ReportFileName
$date = ( get-date ).ToString('yyyy/MM/dd')
$EmailSubject = $EmailSubject + " for " + $Domain + " on " + $date

Send-MailMessage -To 			$EmailTo `
				-Subject 		$EmailSubject `
				-From 			$EmailFrom `
				-SmtpServer 	$SMTPServer `
				-Attachments 	$ReportFileName



