param($buildVersion = $null)

$releasePath = [System.IO.Path]::GetFullPath("$PSScriptRoot\..\release")
$binariesToSignPath = [System.IO.Path]::GetFullPath("$releasePath\BinariesToSign")
$unpackedPackagesPath = [System.IO.Path]::GetFullPath("$releasePath\UnpackedPackages")


mkdir $releasePath -Force | Out-Null




if ($buildVersion -eq $null) {
    
    $headers = @{ "Content-Type" = "application/json" }
    $project = Invoke-RestMethod -Method Get -Uri "https://ci.appveyor.com/api/projects/PowerShell/PowerShellEditorServices/branch/master" -Headers $headers
    $buildVersion = $project.build.version
    if ($project.build.status -eq "success") {
        Write-Output "Latest build version on master is $buildVersion`r`n"
    }
    else {
        Write-Error "PowerShellEditorServices build $buildVersion was not successful!" -ErrorAction "Stop"
    }
}

function Install-BuildPackage($packageName, $extension) {
	$uri = "https://ci.appveyor.com/nuget/powershelleditorservices/api/v2/package/{0}/{1}" -f $packageName.ToLower(), $buildVersion
	Write-Verbose "Fetching from URI: $uri"

	
	$zipPath = "$releasePath\$packageName.zip"
	$packageContentPath = "$unpackedPackagesPath\$packageName"
	Invoke-WebRequest $uri -OutFile $zipPath -ErrorAction "Stop"
	Expand-Archive $zipPath -DestinationPath $packageContentPath -Force -ErrorAction "Stop"
	Remove-Item $zipPath -ErrorAction "Stop"

	
	mkdir $binariesToSignPath -Force | Out-Null
	cp "$packageContentPath\lib\net45\$packageName.$extension" -Force -Destination $binariesToSignPath

	Write-Output "Extracted package $packageName ($buildVersion)"
}


Install-BuildPackage "Microsoft.PowerShell.EditorServices" "dll"
Install-BuildPackage "Microsoft.PowerShell.EditorServices.Protocol" "dll"
Install-BuildPackage "Microsoft.PowerShell.EditorServices.Host" "dll"


& start $binariesToSignPath
