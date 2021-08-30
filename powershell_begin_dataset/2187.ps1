
[CmdletBinding(SupportsShouldProcess=$true)]
param(
    [parameter(Mandatory=$true, HelpMessage="Site server where the SMS Provider is installed.")]
    [ValidateNotNullOrEmpty()]
    [ValidateScript({Test-Connection -ComputerName $_ -Count 1 -Quiet})]
    [string]$SiteServer,

    [parameter(Mandatory=$true, HelpMessage="Select the Discovery Method component that the containers will be added to.")]
    [ValidateNotNullOrEmpty()]
    [ValidateSet("SMS_AD_USER_DISCOVERY_AGENT", "SMS_AD_SYSTEM_DISCOVERY_AGENT")]
    [string]$ComponentName,

    [parameter(Mandatory=$true, HelpMessage="Specify a path to the CSV file containing distinguished names of the OU's that will be added.")]
    [ValidatePattern("^(?:[\w]\:|\\)(\\[a-z_\-\s0-9\.]+)+\.(csv)$")]
    [ValidateScript({
	    
	    if ((Split-Path -Path $_ -Leaf).IndexOfAny([IO.Path]::GetInvalidFileNameChars()) -ge 0) {
		    Write-Warning -Message "$(Split-Path -Path $_ -Leaf) contains invalid characters" ; break
	    }
	    else {
		    
		    if (-not(Test-Path -Path (Split-Path -Path $_) -PathType Container -ErrorAction SilentlyContinue)) {
			    Write-Warning -Message "Unable to locate part of or the whole specified path" ; break
		    }
		    elseif (Test-Path -Path (Split-Path -Path $_) -PathType Container -ErrorAction SilentlyContinue) {
			    return $true
		    }
		    else {
			    Write-Warning -Message "Unhandled error" ; break
		    }
	    }
    })]
    [string]$Path,

    [parameter(Mandatory=$false, HelpMessage="Show a progressbar displaying the current operation.")]
    [switch]$ShowProgress
)
Begin {
    
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

    
    try {
        Write-Verbose -Message "Importing data from specified CSV: $($Path)"
        $ContainerData = Import-Csv -Path $Path -Delimiter ";" -ErrorAction Stop
        $ContainerDataCount = ($ContainerData | Measure-Object).Count
        if (-join($ContainerData | Get-Member -MemberType NoteProperty | Select-Object -ExpandProperty Name) -notlike "DistinguishedNameGroupRecursive") {
            Write-Warning -Message "Unsupported headers found in CSV file" ; exit
        }
    }
    catch [System.Exception] {
        Write-Warning -Message "$($_.Exception.Message). Line: $($_.InvocationInfo.ScriptLineNumber)" ; break
    }

    
    $OptionTable = @{
        Yes = 0
        No = 1
        Included = 0
        Excluded = 1
    }
}
Process {
    if ($PSBoundParameters["ShowProgress"]) {
        $ProgressCount = 0
    }

    
    try {
        $DiscoveryContainerList = New-Object -TypeName System.Collections.ArrayList
        $DiscoveryComponent = Get-WmiObject -Namespace "root\SMS\site_$($SiteCode)" -Class SMS_SCI_Component -ComputerName $SiteServer -Filter "ComponentName like '$($ComponentName)'" -ErrorAction Stop
        $DiscoveryPropListADContainer = $DiscoveryComponent.PropLists | Where-Object { $_.PropertyListName -like "AD Containers" }
        if ($DiscoveryPropListADContainer -ne $null) {
            $DiscoveryContainerList.AddRange(@($DiscoveryPropListADContainer.Values)) | Out-Null   
        }
    }
    catch [System.Exception] {
        Write-Verbose -Message "Unable to determine existing discovery method component properties" ; break
    }

    
    foreach ($ContainerItem in $ContainerData) {
        
        if ($ContainerItem.DistinguishedName -notmatch "LDAP://") {
            Write-Verbose -Message "Amending current item to include LDAP protocol prefix: $($ContainerItem.DistinguishedName)"
            $ContainerItem.DistinguishedName = "LDAP://" + $ContainerItem.DistinguishedName
        }

        
        if ($PSBoundParameters["ShowProgress"]) {
            $ProgressCount++
            Write-Progress -Activity "Importing $($ComponentName) containers" -Id 1 -Status "Current container: $($ContainerItem.DistinguishedName)" -PercentComplete (($ProgressCount / $ContainerDataCount) * 100)
        }

        
        if ($ContainerItem.DistinguishedName -notin $DiscoveryContainerList) {
            Write-Verbose -Message "Adding container item: $($ContainerItem.DistinguishedName)"
            $DiscoveryContainerList.AddRange(@($ContainerItem.DistinguishedName, $OptionTable[$ContainerItem.Recursive], $OptionTable[$ContainerItem.Group])) | Out-Null
        }
        else {
            Write-Verbose -Message "Detected duplicate container object: $($ContainerItem.DistinguishedName)"
        }
    }

    
    $ErrorActionPreference = "Stop"
    Write-Verbose -Message "Attempting to save changes made to the $($ComponentName) component PropList"
    try {
        $DiscoveryPropListADContainer.Values = $DiscoveryContainerList
        $DiscoveryComponent.PropLists = $DiscoveryPropListADContainer
        $DiscoveryComponent.Put() | Out-Null
        Write-Verbose -Message "Successfully saved changes to $($ComponentName) component"
    }
    catch [System.Exception] {
        Write-Verbose -Message "Unable to save changes made to $($ComponentName) component" ; break
    }

    
    Write-Verbose -Message "Restarting the SMS_SITE_COMPONENT_MANAGER service"
    try {
        Get-Service -ComputerName $SiteServer -Name "SMS_SITE_COMPONENT_MANAGER" -ErrorAction Stop | Restart-Service -Force -ErrorAction Stop
    }
    catch [System.Exception] {
        Write-Warning -Message "$($_.Exception.Message). Line: $($_.InvocationInfo.ScriptLineNumber)" ; break
    }
}