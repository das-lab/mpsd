

$obj = "" | Select-Object $($PSVersionTable.Keys)
foreach($item in $PSVersionTable.Keys) { 
    $obj.$item = $($PSVersionTable[$item] -join ".")
}

$i = 1
Get-ChildItem -Force "$($env:windir)\Microsoft.Net\Framework" -Include mscorlib.dll -Recurse | ForEach-Object { 
    $obj | Add-Member NoteProperty .NET_$i $_.VersionInfo.ProductVersion
    $i++
}

$obj