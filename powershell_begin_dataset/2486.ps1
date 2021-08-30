
Read-Host -AsSecureString | ConvertFrom-SecureString | Out-File encrypted_password.txt


$vpn_profile = 'Profile name'
$username = 'username'


$enc_password = (gc .\encrypted_password.txt | ConvertTo-SecureString)


$credentials = new-object -typename System.Management.Automation.PSCredential -argumentlist $username,$enc_password $password = $credentials.GetNetworkCredential().Password


Set-Location 'C:\Program Files (x86)\Cisco Systems\VPN Client'
.\vpnclient.exe connect $vpn_profile user $username pwd $password






