
$ThisModule = "$($MyInvocation.MyCommand.Path -replace "\.Tests\.ps1$", '').psm1"
$ThisModuleName = (($ThisModule | Split-Path -Leaf) -replace ".psm1")
Get-Module -Name $ThisModuleName -All | Remove-Module -Force

Import-Module -Name $ThisModule -Force -ErrorAction Stop



@(Get-Module -Name $ThisModuleName).where({ $_.version -ne "0.0" }) | Remove-Module -Force


InModuleScope $ThisModuleName {
	describe 'Restore-Acl' {
		
	}
 	describe 'Save-Acl' {
		
	}

}
