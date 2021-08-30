
[CmdletBinding(SupportsShouldProcess=$true)]
param(
    [parameter(Mandatory=$true, HelpMessage="Specify the user principal name to amend the password expire policy on")]
    [ValidateNotNullOrEmpty()]
    [ValidatePattern("^[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}$")]
    [string]$UserPrincipalName,
    [parameter(Mandatory=$true, HelpMessage="Specify whether the password expire policy should be true or false")]
    [ValidateNotNullOrEmpty()]
    [bool]$PasswordNeverExpires
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
    
    $User = Get-MsolUser -UserPrincipalName $UserPrincipalName -ErrorAction Stop
    if ($User -ne $null) {
        
        try {
            Set-MsolUser -UserPrincipalName $UserPrincipalName -PasswordNeverExpires $PasswordNeverExpires -ErrorAction Stop
        }
        catch [System.Exception] {
            Write-Warning -Message "Unable to change the password expires policy for user '$($UserPrincipalName)'" ; break
        }
        $UserPasswordNeverExpires = Get-MsolUser -UserPrincipalName $UserPrincipalName -ErrorAction Stop | Select-Object -Property PasswordNeverExpires
        $PSObject = [PSCustomObject]@{
            UserPrincipalName = $UserPrincipalName
            DisplayName = $User.DisplayName
            PasswordNeverExpires = $UserPasswordNeverExpires.PasswordNeverExpires
        }
        Write-Output -InputObject $PSObject
    }
    else {
        Write-Warning -Message "Specified user principal name was not found" ; break
    }
}