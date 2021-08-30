
[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [parameter(Mandatory = $true, ParameterSetName = "DefaultSet", HelpMessage = "Specify the type of object to query for")]
    [parameter(Mandatory = $true, ParameterSetName = "CriteriaSet")]
    [ValidateNotNullOrEmpty()]
    [ValidateSet("User")]
    [string]$ObjectClass,
    [parameter(Mandatory = $true, ParameterSetName = "DefaultSet", HelpMessage = "Specify the criteria to validate object against")]
    [parameter(Mandatory = $true, ParameterSetName = "CriteriaSet")]
    [ValidateNotNullOrEmpty()]
    [ValidateSet("NullOrEmpty", "NotMatch", "Duplicate")]
    [string]$Criteria,
    [parameter(Mandatory = $true, ParameterSetName = "CriteriaSet", HelpMessage = "Pattern to validate for when using NotMatched criteria")]
    [ValidateNotNullOrEmpty()]
    [string]$Pattern,
    [parameter(Mandatory = $true, ParameterSetName = "DefaultSet", HelpMessage = "Specify the userPrincipleName attribute used to match for Azure Active Directory to check for sync eligibility")]
    [parameter(Mandatory = $true, ParameterSetName = "CriteriaSet")]
    [ValidateNotNullOrEmpty()]
    [ValidateSet("UserPrincipleName","Mail")]
    [string]$Attribute,
    [parameter(Mandatory = $false, ParameterSetName = "DefaultSet", HelpMessage = "Use a specific search base when querying for objects")]
    [parameter(Mandatory = $false, ParameterSetName = "CriteriaSet")]
    [ValidateNotNullOrEmpty()]
    [string]$SearchBase,
    [parameter(Mandatory = $false, ParameterSetName = "DefaultSet", HelpMessage = "Show a progressbar displaying the current operation")]
    [parameter(Mandatory = $false, ParameterSetName = "CriteriaSet")]
    [switch]$ShowProgress
)
Begin {
    
    $CurrentLocation = Split-Path -Parent -Path $MyInvocation.MyCommand.Definition
    
    if (-not(Get-Module -Name ActiveDirectory)) {
        try {
            Import-Module ActiveDirectory -ErrorAction Stop -Verbose:$false
        }
        catch [Exception] {
            Write-Warning -Message "Unable to load the Active Directory PowerShell module" ; break
        }
    }
    
    Set-Location -Path AD: -Verbose:$false
}
Process {
    
    function Write-CustomOutput {
        param(
            [parameter(Mandatory = $true)]
            $InputObject,
            [parameter(Mandatory = $true)]
            [ValidateSet("Normal", "Duplicate")]
            $Type
        )
        if ($Type -eq "Normal") {
            $PSObject = [PSCustomObject]@{
                Name = $InputObject.Name
                DistinguishedName = $InputObject.DistinguishedName
            }
            Write-Output $PSObject
        }
        if ($Type -eq "Duplicate") {
            $PSObject = [PSCustomObject]@{
                samAccountName = $InputObject.Name
                AttributeValue = $InputObject.Value
            }
            Write-Output $PSObject
        }
    }
    
    if ($PSBoundParameters["ShowProgress"]) {
        $ProgressCount = 0
    }
    $ADObjectsArgumentList = @{
        LDAPFilter = "(&(objectclass=$($ObjectClass))(objectcategory=$($ObjectClass))(!useraccountcontrol:1.2.840.113556.1.4.803:=2))"
        Properties = $Attribute, "samAccountName", "DistinguishedName"
        ErrorAction = "Stop"
    }
    if ($PSBoundParameters["SearchBase"]) {
        $ADObjectsArgumentList.Add("SearchBase", $SearchBase)
    }
    try {
        
        $DuplicateHashTable = New-Object -TypeName System.Collections.Hashtable
        Write-Verbose -Message "Querying for all '$($ObjectClass)' objects"
        $Objects = Get-ADObject @ADObjectsArgumentList
        $ObjectCount = ($Objects | Measure-Object).Count
        foreach ($Object in $Objects) {
            if ($PSBoundParameters["ShowProgress"]) {
                $ProgressCount++
                Write-Progress -Activity "Enumerating Active Directory $($ObjectClass) objects" -Id 1 -Status "$($ProgressCount) / $($ObjectCount)" -CurrentOperation "Current object: $($Object.samAccountName)" -PercentComplete (($ProgressCount / $ObjectCount) * 100)
            }
            if ($Criteria -eq "NullOrEmpty") {
                if ($Object.$Attribute -eq $null) {
                    Write-CustomOutput -InputObject $Object -Type Normal
                }
            }
            if ($Criteria -eq "NotMatch") {
                if ($Object.$Attribute -notmatch $Pattern) {
                    Write-CustomOutput -InputObject $Object -Type Normal
                }
            }
            if ($Criteria -eq "Duplicate") {
                Write-Verbose -Message "Preparing duplicate list"
                $DuplicateHashTable.Add($Object.samAccountName, $Object.$Attribute)
            }
        }
        if ($Criteria -eq "Duplicate") {
            $DuplicateObjects = $DuplicateHashTable.GetEnumerator() | Group-Object -Property Value | Where-Object { $_.Count -gt 1 }
            if (($DuplicateObjects | Measure-Object).Count -ge 1) {
                foreach ($DuplicateObject in $DuplicateObjects.Group) {
                    Write-CustomOutput -InputObject $DuplicateObject -Type Duplicate
                }
            }
        }
    }
    catch [System.UnauthorizedAccessException] {
        Write-Warning -Message "Access denied" ; break
    }
    catch [System.Exception] {
        Write-Warning -Message $_.Exception.Message ; break
    }
}
End {
    
    if ($PSBoundParameters["ShowProgress"]) {
        Write-Progress -Activity "Enumerating Active Directory $($ObjectClass) objects" -Id 1 -Completed
    }
    
    Set-Location -Path $CurrentLocation
}