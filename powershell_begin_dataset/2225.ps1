
[CmdletBinding(SupportsShouldProcess=$true)]
param(
    [parameter(Mandatory=$true,HelpMessage="Site Server where SQL Server Reporting Services are installed")]
    [ValidateScript({Test-Connection -ComputerName $_ -Count 1})]
    [string]$ReportServer,
    [parameter(Mandatory=$true,HelpMessage="SiteCode of the Reporting Service point")]
    [string]$SiteCode,
    [parameter(Mandatory=$false,HelpMessage="Should only be specified if the default 'ConfigMgr_<sitecode>' folder is not used and a custom folder was created")]
    [string]$RootFolderName = "ConfigMgr",
    [parameter(Mandatory=$false,HelpMessage="If specified, search is restricted to within this folder if it exists")]
    [string]$FolderName,
    [parameter(Mandatory=$true,HelpMessage="Path to where .rdl files eligible for import are located")]
    [ValidateScript({Test-Path -Path $_ -PathType Container})]
    [string]$SourcePath,
    [Parameter(Mandatory=$false,HelpMessage="PSCredential object created with Get-Credential or specify an username")]
    [ValidateNotNull()]
    [System.Management.Automation.PSCredential]
    [System.Management.Automation.Credential()]
    $Credential = [System.Management.Automation.PSCredential]::Empty,
    [parameter(Mandatory=$false,HelpMessage="Will create a folder specified in the FolderName parameter if an existing folder is not present. Will be created in the root")]
    [switch]$Force,
    [parameter(Mandatory=$false,HelpMessage="Show a progressbar displaying the current operation")]
    [switch]$ShowProgress
)
Begin {
    
    $SSRSUri = "http://$($ReportServer)/ReportServer/ReportService2010.asmx"
    
    if ($RootFolderName -like "ConfigMgr") {
        $SSRSRootFolderName = -join ("/","$($RootFolderName)","_",$($SiteCode))
    }
    else {
        $SSRSRootFolderName = -join ("/","$($RootFolderName)")
    }
    
    if ($PSBoundParameters["FolderName"]) {
        $SSRSRootPath = -join ($SSRSRootFolderName,"/",$FolderName)
    }
    else {
        $SSRSRootPath = $SSRSRootFolderName
    }
    
    $ProxyArgs = [ordered]@{
        "Uri" = $SSRSUri
        "UseDefaultCredential" = $true
    }
    if ($Credential -ne [System.Management.Automation.PSCredential]::Empty) {
        $ProxyArgs.Remove("UseDefaultCredential")
        $ProxyArgs.Add("Credential", $Credential)
    }
    else {
        Write-Verbose -Message "Credentials was not provided, using default"
    }
    
    if ($PSBoundParameters["ShowProgress"]) {
        $ProgressCount = 0
    }
}
Process {
    try {
        
        function Create-Report {
            param(
            [parameter(Mandatory=$true)]
            [string]$FilePath,
            [parameter(Mandatory=$true)]
            [string]$ServerPath,
            [parameter(Mandatory=$true)]
            [bool]$ShowProgress
            )
            $RDLFiles = Get-ChildItem -Path $FilePath -Filter "*.rdl"
            $RDLFilesCount = ($RDLFiles | Measure-Object).Count
            if (($RDLFiles | Measure-Object).Count -ge 1) {
                foreach ($RDLFile in $RDLFiles) {
                    
                    if ($PSBoundParameters["ShowProgress"]) {
                        $ProgressCount++
                        Write-Progress -Activity "Importing Reports" -Id 1 -Status "$($ProgressCount) / $($RDLFilesCount)" -CurrentOperation "$($RDLFile.Name)" -PercentComplete (($ProgressCount / $RDLFilesCount) * 100)
                    }
                    if ($PSCmdlet.ShouldProcess("Report: $($RDLFile.BaseName)","Validate")) {
                        $ValidateReportName = $WebServiceProxy.ListChildren($SSRSRootPath, $true) | Where-Object { ($_.TypeName -like "Report") -and ($_.Name -like "$($RDLFile.BaseName)") }
                    }
                    if ($ValidateReportName -eq $null) {
                        if ($PSCmdlet.ShouldProcess("Report: $($RDLFile.BaseName)","Create")) {
                            
                            $RDLFileName = [System.IO.Path]::GetFileNameWithoutExtension($RDLFile.Name)
                            
                            $ByteStream = Get-Content -Path $RDLFile.FullName -Encoding Byte
                            
                            $Warnings = @()
                            
                            Write-Verbose -Message "Importing report '$($RDLFileName)'"
                            $WebServiceProxy.CreateCatalogItem("Report",$RDLFileName,$SSRSRootPath,$true,$ByteStream,$null,[ref]$Warnings) | Out-Null
                        }
                        
                        $DefaultCMDataSource = $WebServiceProxy.ListChildren($SSRSRootFolderName, $true) | Where-Object { $_.TypeName -like "DataSource" } | Select-Object -First 1
                        if ($DefaultCMDataSource -ne $null) {
                            if ($PSCmdlet.ShouldProcess("DataSource: $($DefaultCMDataSource.Name)","Set")) {
                                
                                $CurrentReport = $WebServiceProxy.ListChildren($SSRSRootFolderName, $true) | Where-Object { ($_.TypeName -like "Report") -and ($_.Name -like "$($RDLFileName)") -and ($_.CreationDate -ge (Get-Date).AddMinutes(-5)) }
                                
                                $CurrentReportDataSource = $WebServiceProxy.GetItemDataSources($CurrentReport.Path)
                                
                                $DataSourceType = $WebServiceProxy.GetType().Namespace
                                
                                $ArrayItems = 1 
                                $DataSourceArray = New-Object -TypeName (-join ($DataSourceType,".DataSource","[]")) $ArrayItems
                                $DataSourceArray[0] = New-Object -TypeName (-join ($DataSourceType,".DataSource"))
                                $DataSourceArray[0].Name = $CurrentReportDataSource.Name
                                $DataSourceArray[0].Item = New-Object -TypeName (-join ($DataSourceType,".DataSourceReference"))
                                $DataSourceArray[0].Item.Reference = $DefaultCMDataSource.Path
                                
                                Write-Verbose -Message "Changing data source for report '$($RDLFileName)'"
                                $WebServiceProxy.SetItemDataSources($CurrentReport.Path, $DataSourceArray)
                            }
                        }
                        else {
                            Write-Warning -Message "Unable to determine default ConfigMgr data source, will not edit data source for report '$($RDLFileName)'"
                        }
                    }
                    else {
                        Write-Warning -Message "A report with the name '$($RDLFile.BaseName)' already exists, skipping import"
                    }
                }
            }
            else {
                Write-Warning -Message "No .rdl files was found in the specified path"
            }
        }
        
        $WebServiceProxy = New-WebServiceProxy @ProxyArgs -ErrorAction Stop
        if ($PSBoundParameters["FolderName"]) {
            Write-Verbose -Message "FolderName was specified"
            if ($WebServiceProxy.ListChildren($SSRSRootFolderName, $true) | Select-Object ID, Name, Path, TypeName | Where-Object { ($_.TypeName -eq "Folder") -and ($_.Name -like "$($FolderName)") }) {
                Create-Report -FilePath $SourcePath -ServerPath $SSRSRootPath -ShowProgress $ShowProgress
            }
            else {
                if ($PSBoundParameters["Force"]) {
                    if ($PSCmdlet.ShouldProcess("Folder: $($FolderName)","Create")) {
                        Write-Verbose -Message "Creating folder '$($FolderName)'"
                        
                        $TypeName = $WebServiceProxy.GetType().Namespace
                        
                        $Property = New-Object -TypeName (-join ($TypeName,".Property"))
                        $Property.Name = "$($FolderName)"
                        $Property.Value = "$($FolderName)"
                        
                        $Properties = New-Object -TypeName (-join ($TypeName,".Property","[]")) 1
                        $Properties[0] = $Property
                        
                        $WebServiceProxy.CreateFolder($FolderName,"$($SSRSRootFolderName)",$Properties) | Out-Null
                    }
                    Create-Report -FilePath $SourcePath -ServerPath $SSRSRootPath -ShowProgress $ShowProgress
                }
                else {
                    Write-Warning -Message "Unable to find a folder matching '$($FolderName)'"
                }
            }
        }
        else {
            Create-Report -FilePath $SourcePath -ServerPath $SSRSRootPath -ShowProgress $ShowProgress
        }
    }
    catch [Exception] {
        Throw $_.Exception.Message
    }
}
End {
    if ($PSBoundParameters["ShowProgress"]) {
        Write-Progress -Activity "Importing Reports" -Completed -ErrorAction SilentlyContinue
    }
}