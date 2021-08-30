Function Add-LocalGroupMember
{
    
    [cmdletBinding()]
    Param (
        [Parameter(Mandatory = $True)]
        [string[]]$ComputerName,
        [Parameter(Mandatory = $True)]
        [string]$GroupName,
        [Parameter(Mandatory = $True)]
        [string]$Domain,
        [Parameter(Mandatory = $True)]
        [string]$Account
    )
    BEGIN
    {
        
        $ADCheck = ([adsisearcher]"(samaccountname=$Account)").findone().properties['samaccountname']
        if ($SamAccountName -notmatch '\\')
        {
            $ADResolved = (Resolve-SamAccount -SamAccount $SamAccountName -Exit:$true)
            $SamAccountName = 'WinNT://', "$env:userdomain", '/', $ADResolved -join ''
        }
        else
        {
            $ADResolved = ($SamAccountName -split '\\')[1]
            $DomainResolved = ($SamAccountName -split '\\')[0]
            $SamAccountName = 'WinNT://', $DomainResolved, '/', $ADResolved -join ''
        }

    }
    PROCESS
    {
        $de = [ADSI]"WinNT://$computer/$Group,group"
        $de.psbase.Invoke("Add", ([ADSI]"WinNT://$domain/$user").path)
    }
    END
    {

    }
}