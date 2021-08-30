function Send-GraphiteEvent
{

    [CmdletBinding()]
    param
    (
        [CmdletBinding()]
        
        [Parameter(Mandatory = $true)]
        [ValidateNotNull()]
        [ValidateNotNullOrEmpty()]
        [ValidateScript({ $_ -match '^(http|https)\:\/\/.*' })]
        [string]$GraphiteURL,

        
        [Parameter(Mandatory = $true)]
        [ValidateNotNull()]
        [ValidateNotNullOrEmpty()]
        [Alias("Topic", "Title", "Subject")]
        [string]$What,

        
        [Parameter(Mandatory = $false)]
        [ValidateNotNull()]
        [ValidateNotNullOrEmpty()]
        [string]$Tags,

        
        [Parameter(Mandatory = $false)]
        [ValidateNotNull()]
        [ValidateNotNullOrEmpty()]
        [Alias("Body")]
        [string]$Data
    )

    
    if (!($GraphiteURL.Substring($GraphiteURL.Length - 1) -eq '/'))
    {
        $GraphiteURL = $GraphiteURL + '/'
    }

    
    $GraphiteURL = $GraphiteURL + '/events/'

    
    $EventObject = New-Object PSObject -Property @{
        what = $What
    }

    
    if ($Tags)
    {
        Add-Member -NotePropertyName tags -NotePropertyValue $Tags -InputObject $EventObject
    }

    
    if ($Data)
    {
        Add-Member -NotePropertyName data -NotePropertyValue $Data -InputObject $EventObject
    }

    $EventObject = $EventObject | ConvertTo-Json

    Write-Verbose "Json Object:"
    Write-Verbose $EventObject

    try
    {
        $result = Invoke-WebRequest -Uri $GraphiteURL -Body $EventObject -method Post -ContentType "application/json"
        Write-Verbose "Returned StatusCode: $($result.StatusCode)"
        Write-Verbose "Returned StatusDescription: $($result.StatusDescription)"
    }

    catch
    {
        $exceptionText = GetPrettyProblem $_
        throw "An error occurred trying to post data to Graphite. $exceptionText"
    }

}