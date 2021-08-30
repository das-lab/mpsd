

$Error.Clear()
$erroractionpreference = "SilentlyContinue"

$a = New-Object -comobject Excel.Application
$a.visible = $True
$b = $a.Workbooks.Add()
$c = $b.Worksheets.Item(1)
$c.Cells.Item(1,1) = "Machine Name"
$c.Cells.Item(1,2) = "SNMP Updated"
$d = $c.UsedRange
$d.Interior.ColorIndex = 19
$d.Font.ColorIndex = 11
$d.Font.Bold = $True
$intRow = 2

foreach ($strComputer in get-content C:\MachineList.Txt) {
		$c.Cells.Item($intRow,1) = $strComputer.ToUpper()
		
		$ping = new-object System.Net.NetworkInformation.Ping
		$Reply = $ping.send($strComputer)
		if($Reply.status -eq "success") {
			
			$reg = [Microsoft.Win32.RegistryKey]::OpenRemoteBaseKey('LocalMachine', $strComputer)
			
			$regKey= $reg.OpenSubKey("SYSTEM\\CurrentControlSet\\Services\\SNMP\\Parameters\\ValidCommunities",$true)
			
			$regKey.SetValue('ipm0nitoR','4','DWORD')
			
			$regKey.DeleteValue('public')
			If($Error.Count -eq 0) {
				$c.Cells.Item($intRow,2).Interior.ColorIndex = 4
				$c.Cells.Item($intRow,2) = "Yes"
				
				}
			Else {
				$c.Cells.Item($intRow,2).Interior.ColorIndex = 3
				$c.Cells.Item($intRow,2) = "No"
				
				$Error.Clear()
			}
		}
		Else {
			$c.Cells.Item($intRow,2).Interior.ColorIndex = 3
			$c.Cells.Item($intRow,2) = "Not Pingable"
			
		}
	$Error.Clear()
	$Reply = ""
	$pwage = ""
	$intRow = $intRow + 1
	}
$d.EntireColumn.AutoFit()
cls