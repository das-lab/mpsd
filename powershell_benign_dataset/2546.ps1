




































Function New-SecurityDescriptor (
$ACEs = (throw "Missing one or more Trustees"), 
[string] $ComputerName = ".")
{
	
	$SecDesc = ([WMIClass] "\\$ComputerName\root\cimv2:Win32_SecurityDescriptor").CreateInstance()
	
	if ($ACEs -is [System.Array])
	{
		
		foreach ($ACE in $ACEs )
		{
			$SecDesc.DACL += $ACE.psobject.baseobject
		}
	}
	else
	{
		
		$SecDesc.DACL =  $ACEs
	}
	
	return $SecDesc
}

Function New-ACE (
	[string] $Name = (throw "Please provide user/group name for trustee"),
	[string] $Domain = (throw "Please provide Domain name for trustee"), 
	[string] $Permission = "Read",
	[string] $ComputerName = ".",
	[switch] $Group = $false)
{
	
	$Trustee = ([WMIClass] "\\$ComputerName\root\cimv2:Win32_Trustee").CreateInstance()
	
	if (!$group)
	{ $account = [WMI] "\\$ComputerName\root\cimv2:Win32_Account.Name='$Name',Domain='$Domain'" }
	else
	{ $account = [WMI] "\\$ComputerName\root\cimv2:Win32_Group.Name='$Name',Domain='$Domain'" }
	
	$accountSID = [WMI] "\\$ComputerName\root\cimv2:Win32_SID.SID='$($account.sid)'"
	
	$Trustee.Domain = $Domain
	$Trustee.Name = $Name
	$Trustee.SID = $accountSID.BinaryRepresentation
	
	$ACE = ([WMIClass] "\\$ComputerName\root\cimv2:Win32_ACE").CreateInstance()
	
	switch ($Permission)
	{
		"Read" 		 { $ACE.AccessMask = 1179817 }
		"Change"  {	$ACE.AccessMask = 1245631 }
		"Full"		   { $ACE.AccessMask = 2032127 }
		default { throw "$Permission is not a supported permission value. Possible values are 'Read','Change','Full'" }
	}
	
	$ACE.AceFlags = 3
	$ACE.AceType = 0
	$ACE.Trustee = $Trustee
	
	return $ACE
}

Function New-Share (
	[string] $FolderPath = (throw "Please provide the share folder path (FolderPath)"),
	[string] $ShareName = (throw "Please provide the Share Name"), 
	$ACEs, 
	[string] $Description = "",
	[string] $ComputerName=".")
{
	
	$text = "$ShareName ($FolderPath): "
	
	$SecDesc = New-SecurityDescriptor $ACEs
	
	$Share = [WMICLASS] "\\$ComputerName\Root\Cimv2:Win32_Share"
	$result = $Share.Create($FolderPath, $ShareName, 0, $false , $Description, $false  , $SecDesc)
	switch ($result.ReturnValue)
	{
		0 {$text += "has been success fully created" }
		2 {$text += "Error 2: Access Denied" }
		8 {$text += "Error 8: Unknown Failure" }
		9 {$text += "Error 9: Invalid Name"}
		10 {$text += "Error 10: Invalid Level" }
		21 {$text += "Error 21: Invalid Parameter" }
		22 {$text += "Error 22 : Duplicate Share"}
		23 {$text += "Error 23: Redirected Path" }
		24 {$text += "Error 24: Unknown Device or Directory" }
		25 {$text += "Error 25: Net Name Not Found" }
	}
	
	$return = New-Object System.Object
	$return | Add-Member -type NoteProperty -name ReturnCode -value $result.ReturnValue
	$return | Add-Member -type NoteProperty -name Message -value $text	
	
	$return
}







$ACE = New-ACE -Name "Domain Users" -Domain "CORETECH" -Permission "Read" -Group

$ACE2 = New-ACE -Name "CCO" -Domain "CORETECH" -Permission "Full"


$result = New-Share -FolderPath "C:\Temp" -ShareName "Temp4"  -ACEs $ACE,$ACE2 -Description "Test Description" -Computer "localhost" 


Write-Output $result.Message


If ($result.ReturnCode -eq 0)
{
	
}







