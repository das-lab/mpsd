

function Switch-SPOEnableDisableSolution
{
	[CmdletBinding()]
	param
	(
		[Parameter(Mandatory=$true, Position=1)]
	    [string]$solutionName,
		
		[Parameter(Mandatory=$true, Position=2)]
	    [bool]$activate
	)
	
	
	$solutionId = Get-SPOSolutionId -solutionName $solutionName

    
    $operation = ""
	if($activate) 
	{ 
		$operation = "ACT" 
	} 
	else 
	{ 
		$operation = "DEA" 
	}
	
    $solutionPageUrl = Join-SPOParts -Separator '/' -Parts $clientContext.Site.Url, "/_catalogs/solutions/forms/activate.aspx?Op=$operation&ID=$solutionId"
	
	$cookieContainer = New-Object System.Net.CookieContainer
    
	$request = $clientContext.WebRequestExecutorFactory.CreateWebRequestExecutor($clientContext, $solutionPageUrl).WebRequest
	
	if ($clientContext.Credentials -ne $null)
	{
		$authCookieValue = $clientContext.Credentials.GetAuthenticationCookie($clientContext.Url)
	    
	  	$fedAuth = new-object System.Net.Cookie
		$fedAuth.Name = "FedAuth"
	  	$fedAuth.Value = $authCookieValue.TrimStart("SPOIDCRL=")
	  	$fedAuth.Path = "/"
	  	$fedAuth.Secure = $true
	  	$fedAuth.HttpOnly = $true
	  	$fedAuth.Domain = (New-Object System.Uri($clientContext.Url)).Host
	  	
		
		$cookieContainer.Add($fedAuth)
		
		$request.CookieContainer = $cookieContainer
	}
	else
	{
		
		$request.UseDefaultCredentials = $true
	}
	
	$request.ContentLength = 0
	
	$response = $request.GetResponse()
	
		
		$strResponse = $null
		$stream = $response.GetResponseStream()
		if (-not([String]::IsNullOrEmpty($response.Headers["Content-Encoding"])))
		{
        	if ($response.Headers["Content-Encoding"].ToLower().Contains("gzip"))
			{
                $stream = New-Object System.IO.Compression.GZipStream($stream, [System.IO.Compression.CompressionMode]::Decompress)
			}
			elseif ($response.Headers["Content-Encoding"].ToLower().Contains("deflate"))
			{
                $stream = new-Object System.IO.Compression.DeflateStream($stream, [System.IO.Compression.CompressionMode]::Decompress)
			}
		}
		
		
        $sr = New-Object System.IO.StreamReader($stream)

			$strResponse = $sr.ReadToEnd()
            
		$sr.Close()
		$sr.Dispose()
        
        $stream.Close()
		
        $inputMatches = $strResponse | Select-String -AllMatches -Pattern "<input.+?\/??>" | select -Expand Matches
		
		$inputs = @{}
		
		
        foreach ($match in $inputMatches)
        {
			if (-not($match[0] -imatch "name=\""(.+?)\"""))
			{
				continue
			}
			$name = $matches[1]
			
			if(-not($match[0] -imatch "value=\""(.+?)\"""))
			{
				continue
			}
			$value = $matches[1]

            $inputs.Add($name, $value)
        }

        
        $searchString = ""
		if ($activate) 
		{
			$searchString = "ActivateSolutionItem"
		}
		else
		{
			$searchString = "DeactivateSolutionItem"
		}
        
		$match = $strResponse -imatch "__doPostBack\(\&\
		$inputs.Add("__EVENTTARGET", $Matches[1])
	
	$response.Close()
	$response.Dispose()
	
	
    $strPost = ""
    foreach ($inputKey in $inputs.Keys)
	{
        if (-not([String]::IsNullOrEmpty($inputKey)) -and -not($inputKey.EndsWith("iidIOGoBack")))
		{
            $strPost += [System.Uri]::EscapeDataString($inputKey) + "=" + [System.Uri]::EscapeDataString($inputs[$inputKey]) + "&"
		}
	}
	$strPost = $strPost.TrimEnd("&")
	
    $postData = [System.Text.Encoding]::UTF8.GetBytes($strPost);

    
    $activateRequest = $clientContext.WebRequestExecutorFactory.CreateWebRequestExecutor($clientContext, $solutionPageUrl).WebRequest
    $activateRequest.Method = "POST"
    $activateRequest.Accept = "text/html, application/xhtml+xml, */*"
    if ($clientContext.Credentials -ne $null)
	{
		$activateRequest.CookieContainer = $cookieContainer
	}
	else
	{
		
		$activateRequest.UseDefaultCredentials = $true
	}
    $activateRequest.ContentType = "application/x-www-form-urlencoded"
    $activateRequest.ContentLength = $postData.Length
    $activateRequest.UserAgent = "Mozilla/5.0 (compatible; MSIE 9.0; Windows NT 6.1; WOW64; Trident/5.0)";
    $activateRequest.Headers["Cache-Control"] = "no-cache";
    $activateRequest.Headers["Accept-Encoding"] = "gzip, deflate";
    $activateRequest.Headers["Accept-Language"] = "fr-FR,en-US";

    
    $stream = $activateRequest.GetRequestStream()
        $stream.Write($postData, 0, $postData.Length)
        $stream.Close();
	$stream.Dispose()
	
    
    $response = $activateRequest.GetResponse()
	$response.Close()
	$response.Dispose()
	
}
