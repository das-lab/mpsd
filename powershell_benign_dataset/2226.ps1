
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
    [parameter(Mandatory=$true,HelpMessage="Path to where the reports will be exported")]
    [string]$ExportPath,
    [Parameter(Mandatory=$false,HelpMessage="PSCredential object created with Get-Credential or specify an username")]
    [ValidateNotNull()]
    [System.Management.Automation.PSCredential]
    [System.Management.Automation.Credential()]
    $Credential = [System.Management.Automation.PSCredential]::Empty,
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
    
    $ProxyArgs = [ordered]@{
        "Uri" = $SSRSUri
        "Namespace" = "SSRS.ReportingServices2010"
        "UseDefaultCredential" = $true
    }
    if ($Credential -ne [System.Management.Automation.PSCredential]::Empty) {
        $ProxyArgs.Remove("UseDefaultCredential")
        $ProxyArgs.Add("Credential", $Credential)
    }
    else {
        Write-Verbose -Message "Credentials was not provided, using default"
    }
    
    if ($ExportPath.EndsWith("\")) {
        Write-Verbose -Message "Trimmed export path"
        $ExportPath = $ExportPath.TrimEnd("\")
    }
    
    if ($PSBoundParameters["ShowProgress"]) {
        $ProgressCount = 0
    }
}
Process {
    try {
        
        $WebServiceProxy = New-WebServiceProxy @ProxyArgs -ErrorAction Stop
        if ($PSBoundParameters["FolderName"]) {
            Write-Verbose -Message "FolderName parameter was specified, matching results"
            $WebItems = $WebServiceProxy.ListChildren($SSRSRootFolderName, $true) | Select-Object ID, Name, Path, TypeName | Where-Object { $_.Path -match "$($FolderName)" } | Where-Object { $_.TypeName -eq "Report" }
        }
        else {
            Write-Verbose -Message "Gathering objects from Report Server"
            $WebItems = $WebServiceProxy.ListChildren($SSRSRootFolderName, $true) | Select-Object ID, Name, Path, TypeName | Where-Object { $_.TypeName -eq "Report" }
        }
        $WebItemsCount = ($WebItems | Measure-Object).Count
        
        foreach ($Item in $WebItems) {
            
            $SubPath = (Split-Path -Path $Item.Path).TrimStart("\")
            $ReportName = Split-Path -Path $Item.Path -Leaf
            $File = New-Object -TypeName System.Xml.XmlDocument
            
            if ($PSBoundParameters["ShowProgress"]) {
                $ProgressCount++
                Write-Progress -Activity "Exporting Reports" -Id 1 -Status "$($ProgressCount) / $($WebItemsCount)" -CurrentOperation "$($ReportName)" -PercentComplete (($ProgressCount / $WebItemsCount) * 100)
            }
            
            [byte[]]$ReportDefinition = $null
            
            $ReportDefinition = $WebServiceProxy.GetItemDefinition($Item.Path)
            [System.IO.MemoryStream]$MemoryStream = New-Object -TypeName System.IO.MemoryStream(@(,$ReportDefinition))
            $File.Load($MemoryStream)
            
            $ReportFileName = -join ($ExportPath,"\",$SubPath,"\",$ReportName,".rdl")
            
            if (-not(Test-Path -Path (-join ($ExportPath,"\",$SubPath)))) {
                New-Item -Path (-join ($ExportPath,"\",$SubPath)) -ItemType Directory -Force -Verbose:$false | Out-Null
            }
            
            if ($PSCmdlet.ShouldProcess("Report: $($ReportName)","Save")) {
                if (-not(Test-Path -Path $ReportFileName -PathType Leaf)) {
                    $File.Save($ReportFileName)
                }
                else {
                    Write-Warning -Message "Existing file found with name '$($ReportName).rdl', skipping download"
                }
            }
        }
    }
    catch [Exception] {
        Throw $_.Exception.Message
    }
}
End {
    if ($PSBoundParameters["ShowProgress"]) {
        Write-Progress -Activity "Exporting Reports" -Completed -ErrorAction SilentlyContinue
    }
}