$samaccount_to_copy = 'abertram'
$new_samaccountname = 'aaaa'
$new_displayname = 'displayname'
$new_firstname = 'firstname'
$new_lastname = 'lastname'
$new_name = 'namehere'
$new_user_logon_name = 'logonname'
$new_password = 'password'
$new_description = 'description'
$new_ou_DN = ''
$enable_user_after_creation = $true
$password_never_expires = $false
$cannot_change_password = $false


$ad_account_to_copy = Get-Aduser $samaccount_to_copy -Properties memberOf

$params = @{'SamAccountName' = $new_samaccountname;
            'Instance' = $ad_account_to_copy;
            'DisplayName' = $new_displayname;
            'GivenName' = $new_firstname;
            'SurName' = $new_lastname;
            'PasswordNeverExpires' = $password_never_expires;
            'CannotChangePassword' = $cannot_change_password;
            'Description' = $new_description;
            'Enabled' = $enable_user_after_creation;
            'UserPrincipalName' = $new_user_logon_name;
            'AccountPassword' = (ConvertTo-SecureString -AsPlainText $new_password -Force);
            }


New-ADUser -Name $new_name @params


$ad_account_to_copy.Memberof | % {Add-ADGroupMember $_ $new_samaccountname }


Get-ADUser $new_samaccountname| Move-ADObject -TargetPath $new_ou_DN