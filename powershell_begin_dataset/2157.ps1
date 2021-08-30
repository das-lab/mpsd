
[CmdletBinding(SupportsShouldProcess=$true)]
param(
    [parameter(
        Mandatory = $true,
        ParameterSetName = "Download",
        HelpMessage = "Generate a download configuration file for Office."
    )]
    [ValidateNotNullOrEmpty()]
    [switch]$DownloadFile,

    [parameter(
        Mandatory = $true,
        ParameterSetName = "Install",
        HelpMessage = "Generate an install configuration file for Office."
    )]
    [ValidateNotNullOrEmpty()]
    [switch]$InstallFile,

    [parameter(
        Mandatory = $true,
        ParameterSetName = "Remove",
        HelpMessage = "Generate a remove configuration file for Office."
    )]
    [parameter(
        Mandatory = $true,
        ParameterSetName = "RemoveAll"
    )]
    [ValidateNotNullOrEmpty()]
    [switch]$RemoveFile,

    [parameter(
        Mandatory = $true,
        ParameterSetName = "RemoveAll",
        HelpMessage = "Specify this parameter switch to remove all Office products, instead of defining what products should be removed."
    )]
    [ValidateNotNullOrEmpty()]
    [switch]$AllProducts,

    [parameter(
        Mandatory = $true,
        ParameterSetName = "Download",
        HelpMessage = "Specify the fully qualified path of the folder where the configuration file will be created. Should point to an existing folder."
    )]
    [parameter(
        Mandatory = $true,
        ParameterSetName = "Install"
    )]
    [parameter(
        Mandatory = $true,
        ParameterSetName = "Remove"
    )]
    [parameter(
        Mandatory = $true,
        ParameterSetName = "RemoveAll"
    )]
    [ValidateNotNullOrEmpty()]
    [ValidatePattern("^[A-Za-z]{1}:\\\w+")]
    [ValidateScript({
	    
	    if ((Split-Path -Path $_ -Leaf).IndexOfAny([IO.Path]::GetInvalidFileNameChars()) -ge 0) {
		    Throw "$(Split-Path -Path $_ -Leaf) contains invalid characters"
	    }
	    else {
		    
		    if (Test-Path -Path $_ -PathType Container) {
				return $true
		    }
		    else {
			    Throw "Unable to locate part of or the whole specified path, specify a valid path"
		    }
	    }
    })]
    [string]$Path,

    [parameter(
        Mandatory = $false,
        ParameterSetName = "Download",
        HelpMessage = "SourcePath indicates the location to save the Click-to-Run installation source when you run the Office Deployment Tool in download mode. SourcePath indicates the installation source path from which to install Office when you run the Office Deployment Tool in configure mode. If you don’t specify SourcePath in configure mode, Setup will look in the current folder for the Office source files. If the Office source files aren’t found in the current folder, Setup will look on Office 365 for them."
    )]
    [parameter(
        Mandatory = $false,
        ParameterSetName = "Install"
    )]
    [ValidateNotNullOrEmpty()]
    [string]$SourcePath,

    [parameter(
        Mandatory = $true,
        ParameterSetName = "Download",
        HelpMessage = "Specify the Office architecture version."
    )]
    [parameter(
        Mandatory = $true,
        ParameterSetName = "Install"
    )]
    [ValidateSet("32","64")]
    [ValidateNotNullOrEmpty()]
    [string]$OfficeClientEdition,

    [parameter(
        Mandatory = $false,
        ParameterSetName = "Download",
        HelpMessage = "Specify the update branch for the Office product."
    )]
    [parameter(
        Mandatory = $false,
        ParameterSetName = "Install"
    )]
    [ValidateNotNullOrEmpty()]
    [ValidateSet("Current","Business","Validation","FirstReleaseCurrent")]
    [string]$Branch,

    [parameter(
        Mandatory = $true,
        ParameterSetName = "Download",
        HelpMessage = "Choose the product version of Office. Supports multiple input as an string array of the valid Office products."
    )]
    [parameter(
        Mandatory = $true,
        ParameterSetName = "Install"
    )]
    [parameter(
        Mandatory = $false,
        ParameterSetName = "Remove"
    )]
    [ValidateNotNullOrEmpty()]
    [ValidateSet("O365ProPlusRetail","VisioProRetail","ProjectProRetail","SPDRetail")]
    [string[]]$Product,

    [parameter(
        Mandatory = $false,
        ParameterSetName = "Download",
        HelpMessage = "Choose a language for the Office product. Default language is English (United States)."
    )]
    [parameter(
        Mandatory = $false,
        ParameterSetName = "Install"
    )]
    [parameter(
        Mandatory = $false,
        ParameterSetName = "Remove"
    )]
    [ValidateNotNullOrEmpty()]
    [ValidateSet(
        "en-US","ar-SA","bg-BG","zh-CN","zh-TW","hr-HR","cs-CZ","da-DK","nl-NL","et-EE","fi-FI","fr-FR","de-DE","el-GR","he-IL","hi-IN","hu-HU","id-ID","it-IT",
        "ja-JP","kk-KH","ko-KR","lv-LV","lt-LT","ms-MY","nb-NO","pl-PL","pt-BR","pt-PT","ro-RO","ru-RU","sr-latn-RS","sk-SK","sl-SI","es-ES","sv-SE","th-TH",
        "tr-TR","uk-UA"
    )]
    [string[]]$Language = "en-US",

    [parameter(
        Mandatory = $false,
        ParameterSetName = "Install",
        HelpMessage = "If this attribute is set to TRUE, the user does not see a Microsoft Software License Terms dialog box. If this attribute is set to FALSE or is not set, the user may see a Microsoft Software License Terms dialog box. This attribute only applies if you install with the user's account. If you use System Center Configuration Manager or some other software distribution tool which uses the SYSTEM account to install, then the setting for this attribute is not applied."
    )]
    [ValidateNotNullOrEmpty()]
    [ValidateSet("True","False")]
    [string]$AcceptEULA,

    [parameter(
        Mandatory = $false,
        ParameterSetName = "Download",
        HelpMessage = "Selected Office programs will be excluded for installation in the configuration file."
    )]
    [parameter(
        Mandatory = $false,
        ParameterSetName = "Install"
    )]
    [ValidateNotNullOrEmpty()]
    [ValidateSet("Access","Excel","Groove","InfoPath","Lync","OneNote","Outlook","PowerPoint","Project","Publisher","SharePointDesigner","Visio","Word")]
    [string[]]$ExcludeApp,

    [parameter(
        Mandatory = $true,
        ParameterSetName = "Install",
        HelpMessage = "Specify whether the Click-to-Run update system will check for updates during installation of the specified Office product."
    )]
    [ValidateNotNullOrEmpty()]
    [ValidateSet("True","False")]
    [string]$EnableUpdates,

    [parameter(
        Mandatory = $false,
        ParameterSetName = "Install",
        HelpMessage = "Determines the user interface that the user sees when the operation is performed. If DisplayLevel is set to None, the user sees no UI. No progress UI, completion screen, error dialog boxes, or first run automatic start UI are displayed. If DisplayLevel is set to Full, the user sees the normal Click-to-Run user interface: Automatic start, application splash screen, and error dialog boxes."
    )]
    [ValidateNotNullOrEmpty()]
    [ValidateSet("None","Full")]
    [string]$DisplayLevel,

    [parameter(
        Mandatory = $false,
        ParameterSetName = "Install",
        HelpMessage = "When set to True, FORCEAPPSSHUTDOWN property will be added to the Property node, preventing user interaction during installation. Data loss may occur when this property is set to True."
    )]
    [ValidateNotNullOrEmpty()]
    [ValidateSet("True","False")]
    [string]$ForceAppsShutdown,

    [parameter(
        Mandatory = $false,
        ParameterSetName = "Install",
        HelpMessage = "If AutoActivate is set to 1, the specified products will attempt to activate automatically. If AutoActivate is not set, the user may see the Activation Wizard UI."
    )]
    [ValidateNotNullOrEmpty()]
    [ValidateSet(1,0)]
    [int]$AutoActivate,

    [parameter(
        Mandatory = $false,
        ParameterSetName = "Install",
        HelpMessage = "Set SharedComputerLicensing to 1 if you deploy Office 365 ProPlus to shared computers by using Remote Desktop Services."
    )]
    [ValidateNotNullOrEmpty()]
    [ValidateSet(1,0)]
    [int]$SharedComputerLicensing,

    [parameter(
        Mandatory = $false,
        ParameterSetName = "Install",
        HelpMessage = "Specify option for the logging that Click-to-Run Setup performs."
    )]
    [ValidateNotNullOrEmpty()]
    [ValidateSet("Off","Standard")]
    [string]$LoggingLevel,

    [parameter(
        Mandatory = $false,
        ParameterSetName = "Install",
        HelpMessage = "Specify the fully qualified path of the folder that is used for the log file. You can use environment variables."
    )]
    [ValidateNotNullOrEmpty()]
    [string]$LoggingPath
)
Begin {
    
    if ($DownloadFile -or $InstallFile) {
        $ConfigurationFileName = "configuration_" + $PSCmdlet.ParameterSetName.ToLower() + "_" + $OfficeClientEdition + "-bit.xml"
    }
    else {
        $ConfigurationFileName = "configuration_" + $PSCmdlet.ParameterSetName.ToLower() + ".xml"
    }

    
    $ConfigurationFilePath = Join-Path -Path $Path -ChildPath $ConfigurationFileName
}
Process {
    
    $XMLDocument = New-Object -TypeName System.Xml.XmlDocument

    
    [System.Xml.XmlElement]$XMLConfiguration = $XMLDocument.CreateElement("Configuration")
    $XMLDocument.AppendChild($XMLConfiguration) | Out-Null

    if (($RemoveFile)) {
        
        [System.Xml.XmlElement]$XMLRemove = $XMLDocument.CreateElement("Remove")
        $XMLConfiguration.AppendChild($XMLRemove) | Out-Null

        
        if ($AllProducts) {
            $XMLRemove.SetAttribute("All", $true)
        }
    }

    if (($DownloadFile) -or ($InstallFile)) {
        
        [System.Xml.XmlElement]$XMLAdd = $XMLDocument.CreateElement("Add")
        $XMLConfiguration.AppendChild($XMLAdd) | Out-Null

        
        if ($PSBoundParameters["SourcePath"]) {
            $XMLAdd.SetAttribute("SourcePath", $SourcePath)
        }
        $XMLAdd.SetAttribute("OfficeClientEdition", $OfficeClientEdition)
        if ($PSBoundParameters["Branch"]) {
            $XMLAdd.SetAttribute("Branch", $Branch)
        }
    }

    if ($PSCmdlet.ParameterSetName -notlike "RemoveAll") {
        
        $ProductElements = New-Object -TypeName System.Collections.ArrayList
        foreach ($Prod in $Product) {
            if ($Prod -notin $ProductElements) {
                [System.Xml.XmlElement]$XMLProduct = $XMLDocument.CreateElement("Product")
                if ($PSCmdlet.ParameterSetName -in @("Install","Download")) {
                    $XMLAdd.AppendChild($XMLProduct) | Out-Null
                }
                if ($PSCmdlet.ParameterSetName -like "Remove") {
                    $XMLRemove.AppendChild($XMLProduct) | Out-Null
                }

                
                $XMLProduct.SetAttribute("ID", $Prod)

                
                $LanguageElements = New-Object -TypeName System.Collections.ArrayList
                foreach ($Lang in $Language) {
                    if ($Lang -notin $LanguageElements) {
                        [System.Xml.XmlElement]$XMLLanguage = $XMLDocument.CreateElement("Language")
                        $XMLProduct.AppendChild($XMLLanguage) | Out-Null

                        
                        $XMLLanguage.SetAttribute("ID", $Lang)
                    }
                    else {
                        Write-Warning -Message "Language '$($Lang)' for '$($Prod)' has already been added to the configuration file"
                    }

                    
                    $LanguageElements.Add($Lang) | Out-Null
                }
                
                $LanguageElements.Clear()

                
                $ProductElements.Add($Prod) | Out-Null

                
                if (($PSBoundParameters["ExcludeApp"]) -and ($PSCmdlet.ParameterSetName -in @("Download","Install"))) {
                    if ($Prod -like "O365ProPlusRetail") {
                        $ExcludedAppElements = New-Object -TypeName System.Collections.ArrayList
                        foreach ($App in $ExcludeApp) {
                            if ($App -notin $ExcludedAppElements) {
                                [System.Xml.XmlElement]$XMLExcludeApp = $XMLDocument.CreateElement("ExcludeApp")
                                $XMLProduct.AppendChild($XMLExcludeApp) | Out-Null

                                
                                $XMLExcludeApp.SetAttribute("ID", $App)
                            }
                            else {
                                Write-Warning -Message "Excluded application '$($App)' for '$($Prod)' has already been added to the configuration file"
                            }

                            
                            $ExcludedAppElements.Add($App) | Out-Null
                        }
                    }
                }
            }
            else {
                Write-Warning -Message "Product '$($Prod)' has already been added to the configuration file"
            }
        }
    }

    if ($InstallFile) {
        
        if ($PSBoundParameters["EnableUpdates"]) {
            [System.Xml.XmlElement]$XMLUpdates = $XMLDocument.CreateElement("Updates")
            $XMLConfiguration.AppendChild($XMLUpdates) | Out-Null

            
            $XMLUpdates.SetAttribute("Enabled", $EnableUpdates)
            if ($PSBoundParameters["Branch"]) {
                $XMLUpdates.SetAttribute("Branch", $Branch)
            }
        }

        
        if (($PSBoundParameters["ForceAppsShutdown"]) -or ($PSBoundParameters["AutoActivate"])) {
            [System.Xml.XmlElement]$XMLProperty = $XMLDocument.CreateElement("Property")
            $XMLConfiguration.AppendChild($XMLProperty) | Out-Null

            
            if ($PSBoundParameters["ForceAppsShutdown"]) {
                $XMLProperty.SetAttribute("FORCEAPPSHUTDOWN", $ForceAppsShutdown)
            }
            if ($PSBoundParameters["AutoActivate"]) {
                $XMLProperty.SetAttribute("AUTOACTIVATE", $AutoActivate)
            }
            if ($PSBoundParameters["SharedComputerLicensing"]) {
                $XMLProperty.SetAttribute("SharedComputerLicensing", $SharedComputerLicensing)
            }
        }

        
        if (($PSBoundParameters["DisplayLevel"]) -or ($PSBoundParameters["AcceptEULA"])) {
            [System.Xml.XmlElement]$XMLDisplay = $XMLDocument.CreateElement("Display")
            $XMLConfiguration.AppendChild($XMLDisplay) | Out-Null
            
            
            if ($PSBoundParameters["DisplayLevel"]) {
                $XMLDisplay.SetAttribute("Level", $DisplayLevel)
            }
            if ($PSBoundParameters["AcceptEULA"]) {
                $XMLDisplay.SetAttribute("AcceptEULA", $AcceptEULA)
            }
        }

        
        if (($PSBoundParameters["LoggingLevel"]) -or ($PSBoundParameters["LoggingPath"])) {
            [System.Xml.XmlElement]$XMLLogging = $XMLDocument.CreateElement("Logging")
            $XMLConfiguration.AppendChild($XMLLogging) | Out-Null
            
            
            if ($PSBoundParameters["LoggingLevel"]) {
                $XMLLogging.SetAttribute("Level", $LoggingLevel)
            }
            if ($PSBoundParameters["LoggingPath"]) {
                $XMLLogging.SetAttribute("Path", $LoggingPath)
            }
        }
    }
}
End {
    
    $XMLDocument.Save($ConfigurationFilePath)

    
    $PSObject = [PSCustomObject]@{
        FileName = $ConfigurationFileName
        Path = $Path
    }
    Write-Output -InputObject $PSObject
}