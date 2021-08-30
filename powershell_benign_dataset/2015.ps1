

. "$psscriptroot/TestRunner.ps1"

$assemblyName = "Microsoft.WSMan.Management"



$excludeList = @()

if ( $IsWindows ) {
    import-module Microsoft.WSMan.Management
}


Test-ResourceStrings -AssemblyName $AssemblyName -ExcludeList $excludeList
