
if(-not([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator"))
{
	$Arguments = "& '" + $MyInvocation.MyCommand.Definition + "'"
	Start-Process PowerShell.exe -Verb RunAs -ArgumentList $Arguments
	Break
}