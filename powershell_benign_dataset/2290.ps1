
[CmdletBinding(SupportsShouldProcess=$true)]
param(
    [parameter(Mandatory=$false, ParameterSetName="List", HelpMessage="List user accounts eligible for removal instead of being removed")]
    [ValidateNotNullOrEmpty()]
    [switch]$List,
    [parameter(Mandatory=$false, ParameterSetName="Purge", HelpMessage="Removed user accounts will be removed from the Recycle Bin")]
    [ValidateNotNullOrEmpty()]
    [switch]$Purge,
    [parameter(Mandatory=$false, ParameterSetName="List", HelpMessage="Show a progressbar displaying the current operation")]
	[parameter(Mandatory=$false, ParameterSetName="Purge")]
    [ValidateNotNullOrEmpty()]
    [switch]$ShowProgress
)
Begin {
    
    try {
        Import-Module -Name MSOnline -ErrorAction Stop -Verbose:$false
    }
    catch [System.Exception] {
        Write-Warning -Message $_.Exception.Message ; break
    }

    
    if (($Credentials = Get-Credential -Message "Enter the username and password for a Microsoft Online Service") -eq $null) {
        Write-Warning -Message "Please specify a Global Administrator account and password" ; break
    }

    
    try {
        Connect-MsolService -Credential $Credentials -ErrorAction Stop -Verbose:$false
    }
    catch [System.Exception] {
        Write-Warning -Message $_.Exception.Message ; break
    }
}
Process {
    if ($PSBoundParameters["ShowProgress"]) {
        $UserCount = 0
    }
    
    try {
        
        $SynchronizedUsers = Get-MsolUser -Synchronized -All -ErrorAction Stop
        
        $SyncedUserCount = ($SynchronizedUsers | Measure-Object).Count
        
        foreach ($User in $SynchronizedUsers) {
            if ($PSBoundParameters["ShowProgress"]) {
                $UserCount++
                Write-Progress -Activity "Removing synchronized users from Azure Active Directory" -Status "$($UserCount) / $($SyncedUserCount)" -CurrentOperation "User: $($User.UserPrincipalName)" -PercentComplete (($UserCount / $SyncedUserCount) * 100)
            }
            
            if ($PSBoundParameters["List"] -eq $true) {
                $PSObject = [PSCustomObject]@{
                    UserPrincipalName = $User.UserPrincipalName
                    DisplayName = $User.DisplayName
                }
                Write-Output -InputObject $PSObject
            }
            else {
                try {
                    Write-Verbose -Message "Attempting to remove user account '$($User.UserPrincipalName)'"
                    Remove-MsolUser -UserPrincipalName $User.UserPrincipalName -Force -ErrorAction Stop
                    Write-Verbose -Message "Successfully removed user account '$($User.UserPrincipalName)'"
                }
                catch [System.Exception] {
                    Write-Warning -Message "Unable to remove synchronized user account '$($User.UserPrincipalName)'"
                }
                try {
                    
                    if ($PSBoundParameters["Purge"]) {
                        Write-Verbose -Message "Attempting to remove deleted user account '$($User.UserPrincipalName)'"
                        Get-MsolUser -ReturnDeletedUsers | Where-Object { $_.UserPrincipalName -like $User.UserPrincipalName } | Remove-MsolUser -RemoveFromRecycleBin -Force -ErrorAction Stop
                        Write-Verbose -Message "Successfully removed deleted user account '$($User.UserPrincipalName)'"
                    }
                }
                catch [System.Exception] {
                    Write-Warning -Message "There was a problem when attempting to remove deleted user account '$($User.UserPrincipalName)' from the recycle bin"
                }
            }
            Start-Sleep -Seconds 3
        }
    }
    catch [System.Exception] {
        Write-Warning -Message $_.Exception.Message ; break
    }
}