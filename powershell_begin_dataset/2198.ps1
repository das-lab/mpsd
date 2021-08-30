
[CmdletBinding(SupportsShouldProcess=$true)]
param(
    [parameter(Mandatory=$true, HelpMessage="Site server where the SMS Provider is installed")]
    [ValidateNotNullOrEmpty()]
    [ValidateScript({Test-Connection -ComputerName $_ -Count 1 -Quiet})]
    [string]$SiteServer,
    [parameter(Mandatory=$true, HelpMessage="Specify the full path to a text file containing the device models")]
    [ValidateNotNullOrEmpty()]
    [ValidatePattern("^[A-Za-z]{1}:\\\w+\\\w+")]
    [ValidateScript({
        
        if ((Split-Path -Path $_ -Leaf).IndexOfAny([IO.Path]::GetInvalidFileNameChars()) -ge 0) {
            throw "$(Split-Path -Path $_ -Leaf) contains invalid characters"
        }
        else {
            
            if ([System.IO.Path]::GetExtension((Split-Path -Path $_ -Leaf)) -like ".txt") {
                
                if (-not(Test-Path -Path (Split-Path -Path $_) -PathType Container -ErrorAction SilentlyContinue)) {
                    if ($PSBoundParameters["Force"]) {
                        New-Item -Path (Split-Path -Path $_) -ItemType Directory | Out-Null
                        return $true
                    }
                    else {
                        throw "Unable to locate part of the specified path, use the -Force parameter to create it or specify a valid path"
                    }
                }
                elseif (Test-Path -Path (Split-Path -Path $_) -PathType Container -ErrorAction SilentlyContinue) {
                    return $true
                }
                else {
                    throw "Unhandled error"
                }
            }
            else {
                throw "$(Split-Path -Path $_ -Leaf) contains unsupported file extension. Supported extension is '.xml'"
            }
        }
    })]
    [string]$FilePath,
    [parameter(Mandatory=$false, HelpMessage="Specify a prefix for the collection names")]
    [ValidateNotNullOrEmpty()]
    [string]$Prefix
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
        throw "Unable to determine SiteCode"
    }
    
    $Models = Get-Content -Path $FilePath
    
    $Date = (Get-Date -Hour 00 -Minute 00 -Second 00).AddHours(7)
    $StartTime = [System.Management.ManagementDateTimeconverter]::ToDMTFDateTime($Date)
}
Process {
    $ModelCount = ($Models | Measure-Object).Count
    if ($ModelCount -ge 1) {
        foreach ($Model in $Models) {
            if ($PSBoundParameters["Prefix"]) {
                $FullCollectionName = $Prefix + " " + $Model
            }
            else {
                $FullCollectionName = $Model
            }
            $ValidateCollection = Get-WmiObject -Class "SMS_Collection" -Namespace "root\SMS\site_$($SiteCode)" -Filter "Name like '$($FullCollectionName)'"
            if (-not($ValidateCollection)) {
                try {
                    
                    $ScheduleToken = ([WMIClass]"\\$($SiteServer)\root\SMS\Site_$($SiteCode):SMS_ST_RecurInterval").CreateInstance()
                    $ScheduleToken.DayDuration = 0
                    $ScheduleToken.DaySpan = 1
                    $ScheduleToken.HourDuration = 0
                    $ScheduleToken.HourSpan = 0
                    $ScheduleToken.IsGMT = $false
                    $ScheduleToken.MinuteDuration = 0
                    $ScheduleToken.MinuteSpan = 0
                    $ScheduleToken.StartTime = $StartTime
                    
                    $NewDeviceCollection = ([WmiClass]"\\$($SiteServer)\root\SMS\Site_$($SiteCode):SMS_Collection").CreateInstance()
                    $NewDeviceCollection.Name = "$($FullCollectionName)"
                    $NewDeviceCollection.Comment = "Collection for $($FullCollectionName)"
                    $NewDeviceCollection.OwnedByThisSite = $true
                    $NewDeviceCollection.LimitToCollectionID = "SMS00001"
                    $NewDeviceCollection.RefreshSchedule = $ScheduleToken
                    $NewDeviceCollection.RefreshType = 2
                    $NewDeviceCollection.CollectionType = 2
                    $NewDeviceCollection.Put() | Out-Null
                    Write-Verbose -Message "Successfully created the '$($FullCollectionName)' collection"
                }
                catch [Exception] {
                    Write-Warning -Message "Failed to create collection '$($FullCollectionName)'"
                }
                
                $QueryExpression = "select SMS_R_SYSTEM.ResourceID,SMS_R_SYSTEM.ResourceType,SMS_R_SYSTEM.Name,SMS_R_SYSTEM.SMSUniqueIdentifier,SMS_R_SYSTEM.ResourceDomainORWorkgroup,SMS_R_SYSTEM.Client from SMS_R_System inner join SMS_G_System_COMPUTER_SYSTEM on SMS_G_System_COMPUTER_SYSTEM.ResourceId = SMS_R_System.ResourceId where SMS_G_System_COMPUTER_SYSTEM.Model = '$($Model)'"
                
                $Collection = Get-WmiObject -Namespace "root\SMS\Site_$($SiteCode)" -Class SMS_Collection -Filter "Name like '$($FullCollectionName)' and CollectionType like '2'"
                
                $ValidateQuery = Invoke-WmiMethod -Namespace "root\SMS\site_$($SiteCode)" -Class SMS_CollectionRuleQuery -Name ValidateQuery -ArgumentList $QueryExpression
                if ($ValidateQuery) {
                    
                    $Collection.Get()
                    
                    try {
                        $NewRule = ([WMIClass]"\\$($SiteServer)\root\SMS\Site_$($SiteCode):SMS_CollectionRuleQuery").CreateInstance()
                        $NewRule.QueryExpression = $QueryExpression
                        $NewRule.RuleName = "$($FullCollectionName)"
                        
                        $Collection.CollectionRules += $NewRule.psobject.baseobject
                        $Collection.Put() | Out-Null
                        $Collection.RequestRefresh() | Out-Null
                        Write-Verbose -Message "Successfully added a Query Rule for collection '$($FullCollectionName)'"
                    }
                    catch {
                        Write-Warning -Message "Failed to add a Query Rule for collection '$($FullCollectionName)'"
                    }

                }
            }
            else {
                Write-Warning -Message "Collection '$($FullCollectionName)' already exists"
            }
        }
    }
    else {
        Write-Warning -Message "No items was found in specified text file" ; break
    }
}