

$remove_users_found = $false




$today_object = Get-Date


$today_string = get-date -Format 'MM-dd-yyyy hh:mm tt'



$unused_conditions_met = {
    
    !$_.isCriticalSystemObject -and
    
    (!$_.Enabled -or
    
    $_.PasswordExpired -or
    
    !$_.LastLogonDate -or
    
    ($_.LastLogonDate.AddDays(60) -lt $today_object))
}


$unused_accounts = Get-ADUser -Filter * -Properties passwordexpired,lastlogondate,isCriticalSystemobject | Where-Object $unused_conditions_met |
    Select-Object @{Name='Username';Expression={$_.samAccountName}},
        @{Name='FirstName';Expression={$_.givenName}},
        @{Name='LastName';Expression={$_.surName}},
        @{Name='Enabled';Expression={$_.Enabled}},
        @{Name='PasswordExpired';Expression={$_.PasswordExpired}},
        @{Name='LastLoggedOnDaysAgo';Expression={if (!$_.LastLogonDate) { 'Never' } else { ($today_object - $_.LastLogonDate).Days}}},
        @{Name='Operation';Expression={'Found'}},
        @{Name='On';Expression={$today_string}}


$unused_accounts | Export-Csv -Path unused_user_accounts.csv -NoTypeInformation


if ($remove_users_found) {
    foreach ($account in $unused_accounts) {
        Remove-ADUser $account.Username -Confirm:$false
        Add-Content -Value "$($account.UserName),,,,,,Removed,$today_string" -Path unused_user_accounts.csv
    }
}