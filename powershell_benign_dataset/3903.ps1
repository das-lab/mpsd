














function Start-TestSleep($milliseconds)
{
    if ([Microsoft.Azure.Test.HttpRecorder.HttpMockServer]::Mode -ne [Microsoft.Azure.Test.HttpRecorder.HttpRecorderMode]::Playback)
    {
        Start-Sleep -Milliseconds $milliseconds
    }
}

function Compute-TestTimeout($seconds)
{
    if ([Microsoft.Azure.Test.HttpRecorder.HttpMockServer]::Mode -eq [Microsoft.Azure.Test.HttpRecorder.HttpRecorderMode]::Playback)
    {
        
        return 60 * 24 * 3
    }
    else
    {
        return $seconds
    }
}


function Get-BatchAccountName
{
    return getAssetName
}


function Get-ResourceGroupName
{
    return getAssetName
}


function Get-BatchAccountProviderLocation($index)
{
    if ([Microsoft.Azure.Test.HttpRecorder.HttpMockServer]::Mode -ne [Microsoft.Azure.Test.HttpRecorder.HttpRecorderMode]::Playback)
    {
        $namespace = "Microsoft.Batch"
        $type = "batchAccounts"
        $r = Get-AzResourceProvider -ProviderNamespace $namespace | where {$_.ResourceTypes[0].ResourceTypeName -eq $type}
        $location = $r.Locations
  
        if ($location -eq $null)
        {  
            return "westus"
        } 
        else 
        {  
            if ($index -eq $null)
            {
                return "westus"
            }
            else
            {
                return $location[$index]
            }
        }  
    }

    return "westus"
}