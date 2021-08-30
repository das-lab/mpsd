

. "$psscriptroot/TestRunner.ps1"

$assemblyName = "Microsoft.Management.Infrastructure.CimCmdlets"



$excludeList = @()

if ( $IsWindows )
{
    import-module CimCmdlets
}


Test-ResourceStrings -AssemblyName $AssemblyName -ExcludeList $excludeList
