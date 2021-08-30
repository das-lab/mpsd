

param
(
	[string]
	$OutputFile = 'MissingBitlockerKeys.csv',
	[string]
	$Path
)

function ProcessTextFile {
	If ((Test-Path -Path $OutputFile) -eq $true) {
		Remove-Item -Path $OutputFile -Force
	}
}


function Get-Laptops {
	
	Set-Variable -Name Item -Scope Local -Force
	Set-Variable -Name QuerySystems -Scope Local -Force
	Set-Variable -Name Systems -Scope Local -Force
	Set-Variable -Name WQL -Scope Local -Force
	
	$QuerySystems = @()
	Set-Location BNA:
	$WQL = 'select SMS_R_SYSTEM.ResourceID,SMS_R_SYSTEM.ResourceType,SMS_R_SYSTEM.Name,SMS_R_SYSTEM.SMSUniqueIdentifier,SMS_R_SYSTEM.ResourceDomainORWorkgroup,SMS_R_SYSTEM.Client from SMS_R_System inner join SMS_G_System_SYSTEM_ENCLOSURE on SMS_G_System_SYSTEM_ENCLOSURE.ResourceId = SMS_R_System.ResourceId where SMS_G_System_SYSTEM_ENCLOSURE.ChassisTypes = "8" or SMS_G_System_SYSTEM_ENCLOSURE.ChassisTypes = "9" or SMS_G_System_SYSTEM_ENCLOSURE.ChassisTypes = "10" or SMS_G_System_SYSTEM_ENCLOSURE.ChassisTypes = "14"'
	$Systems = Get-WmiObject -Namespace Root\SMS\Site_BNA -Query $WQL
	Foreach ($Item in $Systems) {
		$QuerySystems = $QuerySystems + $Item.Name
	}
	Set-Location c:
	$QuerySystems = $QuerySystems | Sort-Object
    Return $QuerySystems
	
	
	Remove-Variable -Name Item -Scope Local -Force
	Remove-Variable -Name QuerySystems -Scope Local -Force
	Remove-Variable -Name Systems -Scope Local -Force
	Remove-Variable -Name WQL -Scope Local -Force
}

Function Get-BitlockeredSystems {
    
    Set-Variable -Name BitLockerObjects -Scope Local -Force
    Set-Variable -Name System -Scope Local -Force
    Set-Variable -Name Systems -Scope Local -Force

    $Usernames = @()
    $Systems = @()
    $BitLockerObjects = Get-ADObject -Filter { objectclass -eq 'msFVE-RecoveryInformation' }
    foreach ($System in $BitLockerObjects) {
        $System = $System.DistinguishedName
        $System = $System.Split(',')
        $System = $System[1]
        $System = $System.Split('=')
        $Systems = $Systems + $System[1]
    }
    Return $Systems

    
    Remove-Variable -Name BitLockerObjects -Scope Local -Force
    Remove-Variable -Name System -Scope Local -Force
    Remove-Variable -Name Systems -Scope Local -Force
}

Function Confirm-Bitlockered {
	param ([String[]]$Laptops, [String[]]$BitlockeredSystems)

    
    Set-Variable -Name Bitlockered -Scope Local -Force
    Set-Variable -Name HeaderRow -Scope Local -Force
    Set-Variable -Name Laptop -Scope Local -Force
    Set-Variable -Name System -Scope Local -Force
	
	foreach ($Laptop in $Laptops) {
        $Bitlockered = $false
        foreach ($System in $BitlockeredSystems) {
            If ($Laptop -eq $System) {
                $Bitlockered = $true
            }
        }
        If ($Bitlockered -eq $false) {
            If ((Test-Path $OutputFile) -eq $false) {
                $HeaderRow = "Computers"+[char]44+"Encrypted"+[char]44+"Recovery Key"
                Out-File -FilePath $OutputFile -InputObject $HeaderRow -Force -Encoding UTF8
            }
            Out-File -FilePath $OutputFile -InputObject $Laptop -Append -Force -Encoding UTF8
            Write-Host $Laptop
        }
	}

    
    Remove-Variable -Name Bitlockered -Scope Local -Force
    Remove-Variable -Name HeaderRow -Scope Local -Force
    Remove-Variable -Name Laptop -Scope Local -Force
    Remove-Variable -Name System -Scope Local -Force
}


Set-Variable -Name BitlockeredSystems -Scope Local -Force
Set-Variable -Name Laptops -Scope Local -Force

cls
Import-Module ActiveDirectory -Scope Global -Force
Import-Module "D:\Program Files\Microsoft Configuration Manager\AdminConsole\bin\ConfigurationManager.psd1" -Force -Scope Global
$OutputFile = $Path + "\" + $OutputFile
ProcessTextFile
$Laptops = Get-Laptops
$BitlockeredSystems = Get-BitlockeredSystems
Confirm-Bitlockered -Laptops $Laptops -BitlockeredSystems $BitlockeredSystems


Remove-Variable -Name BitlockeredSystems -Scope Local -Force
Remove-Variable -Name Laptops -Scope Local -Force
