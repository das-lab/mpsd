
[CmdletBinding(SupportsShouldProcess=$true)]
param(
    [parameter(
        Mandatory = $true, 
        HelpMessage = "Define user principal name for the service account. As a best practice, always use your tenant suffix and not a verified domain."
    )]
    [ValidateNotNullOrEmpty()]
    [string]$UserPrincipalName,

    [parameter(
        Mandatory = $true, 
        HelpMessage = "Define display name for the service account."
    )]
    [ValidateNotNullOrEmpty()]
    [string]$DisplayName,

    [parameter(
        Mandatory = $true, 
        HelpMessage = "Define a password for the service account."
    )]
    [ValidateNotNullOrEmpty()]
    [ValidateLength(8,16)]
    [string]$Password
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

    
    foreach ($CurrentUserPrincipalName in $UserPrincipalName) {
        try {
            $ValidateMsolUser = Get-MsolUser -UserPrincipalName $CurrentUserPrincipalName -ErrorAction SilentlyContinue
            if ($ValidateMsolUser -eq $null) {
                
                $ServiceAccountArguments = @{
                    UserPrincipalName = $UserPrincipalName
                    DisplayName = $DisplayName
                    FirstName = $DisplayName.Split(" ")[0]
                    LastName = $DisplayName.Split(" ")[1]
                    Password = $Password
                    ForceChangePassword = $false
                    PasswordNeverExpires = $true
                    Verbose = $false
                    ErrorAction = "Stop"
                }
                New-MsolUser @ServiceAccountArguments | Out-Null
                Write-Verbose -Message "Successfully created service account '$($UserPrincipalName)'"

                
                $RoleMemberArguments = @{
                    RoleName = "Company Administrator"
                    RoleMemberEmailAddress = $UserPrincipalName
                    Verbose = $false
                    ErrorAction = "Stop"
                }
                Add-MsolRoleMember @RoleMemberArguments | Out-Null
                Write-Verbose -Message "Successfully added service account '$($UserPrincipalName)' as a member of 'Global Administrator'"
            }
            else {
                Write-Warning -Message "Specified UserPrincipalName already exists."
            }
        }
        catch [System.Exception] {
            Write-Warning -Message $_.Exception.Message ; break
        }
    }
}