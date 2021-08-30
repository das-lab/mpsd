
















function Invoke-SafeWebRequest{
    Param(
    [Parameter(Mandatory=$True)]
    [string]$Query
    )
    try
    {
        Write-Debug "Sending query to the server..."
        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
        $jsonResult = Invoke-WebRequest $Query -ErrorAction Stop -UseBasicParsing
    }
    catch
    {
        Write-Debug "Something went wrong."
        Write-Debug "Response: $($_.Exception.Response)"
        $code = $_.Exception.Response.StatusCode.Value__
        $message = ""

        if ($code -ge 400 -and $code -le 499){
            $message =  "Request to GitHub Api failed with error code $code. List of commits could not be returned. "+
                        "One or multiple parameters are incorrect."
        } else {
            $message = "The server returned an error. List of commits could not bet returned. "
        }

        $exception = New-Object -TypeName System.Exception -ArgumentList $message, $_.Exception
        Write-Debug $exception.ToString
        throw $exception
    }

    return $jsonResult
}

function Get-PullRequestFileChanges{
    [CmdletBinding()]
    Param(
    [Parameter(Mandatory=$True)]
    [string]$RepositoryOwner,
    [Parameter(Mandatory=$True)]
    [string]$RepositoryName,
    [Parameter(Mandatory=$True)]
    [int]$PullRequestNumber
    )
PROCESS {
    $filesChanged = New-Object 'System.Collections.Generic.HashSet[string]'
    Write-Debug "Number of files detected so far: $($filesChanged.Count)"
    
    $currentPage = 0

    do
    {
        Write-Debug "Starting pagination..."
        $currentPage += 1
        Write-Debug "Current page is: $currentPage"
        $query = "https://api.github.com/repos/$RepositoryOwner/$RepositoryName/pulls/$PullRequestNumber/files?page=$currentPage&per_page=100"
        Write-Debug "Query to be send is: $query"
        $jsonResult = Invoke-SafeWebRequest $query
        Write-Debug "Response from server received successfully."
        Write-Debug "Response from server: $jsonResult"
        Write-Debug "Extracting content from response..."
        [object[]]$files = ConvertFrom-Json -InputObject $jsonResult.Content
        Write-Debug "Number of files on page '$currentPage' is: $($files.Count)"

        foreach ($file in $files)
        {
                $filesChanged.Add($file.filename) | Out-Null
        }

        Write-Debug "Number of files detected so far: $($filesChanged.Count)"
        
        $link = $jsonResult.Headers.Link
        Write-Debug "Getting next page information..."
        $isThereNextPage = $link -match 'rel="next"'
        Write-Debug "Pages left?: $isThereNextPage"
    } while ($isThereNextPage)

    Write-Debug "List of files changed: "
    foreach ($fileName in $filesChanged) {
        Write-Debug " $fileName"
    }

    Write-Debug "Total: $($filesChanged.Count)"

    return $filesChanged
    }
}
