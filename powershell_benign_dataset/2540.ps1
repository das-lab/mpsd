

[String]   $folder     = "E:\Dexma\SQLIOTesting\";
[int]      $runTimeSec = 60;
[int]      $fileSizeMb = 1000;
[String[]] $stripFct   = @("random", "sequential");
[int[]]    $threads    = @(1, 4, 16);
[Char[]]   $ioTypes    = @("R", "W");
[int[]]    $ioSizesKb  = @(8, 64, 256, 512);
[bool]     $createHtml = $true;


Add-Type @"
public struct IoResult {
   public string stripeFactor;
   public int threads;
   public string ioType;
   public int ioSizeKb;
   public double ioPerSec;
   public double mbPerSec;
   public int minLatMs;
   public int maxLatMs;
   public int avgLatMs;
   public int h00;
   public int h01;
   public int h02;
   public int h03;
   public int h04;
   public int h05;
   public int h06;
   public int h07;
   public int h08;
   public int h09;
   public int h10;
   public int h11;
   public int h12;
   public int h13;
   public int h14;
   public int h15;
   public int h16;
   public int h17;
   public int h18;
   public int h19;
   public int h20;
   public int h21;
   public int h22;
   public int h23;
   public int h24;
}
"@;



function getIoResult
{
    param([String[]] $resultFile)

    [IoResult] $ioResult = New-Object IoResult;
    [String[]] $log = Get-Content $resultFile;

    
    $culture = [Globalization.CultureInfo]::CreateSpecificCulture("en-US");
    foreach($line in $log)
    {
        [int] $start = $line.IndexOf("IOs/sec:");
        if ($start -ne -1)
        {   $ioResult.ioPerSec = [Double]::Parse($line.SubString($start + 8), $culture);   }
        [int] $start = $line.IndexOf("MBs/sec:");
        if ($start -ne -1)
        {   $ioResult.mbPerSec = [Double]::Parse($line.SubString($start + 8), $culture);   }
        [int] $start = $line.IndexOf("Min_Latency(ms):");
        if ($start -ne -1)
        {   $ioResult.minLatMs = [int]::Parse($line.SubString($start + 16), $culture);   }
        [int] $start = $line.IndexOf("Max_Latency(ms):");
        if ($start -ne -1)
        {   $ioResult.maxLatMs = [int]::Parse($line.SubString($start + 16), $culture);   }
        [int] $start = $line.IndexOf("Avg_Latency(ms):");
        if ($start -ne -1)
        {   $ioResult.avgLatMs = [int]::Parse($line.SubString($start + 16), $culture);   }
        [int] $start = $line.IndexOf("%:");
        if ($start -ne -1)
        {
            $ioResult.h00 = [int]::Parse($line.SubString( 2, 3), $culture);
            $ioResult.h01 = [int]::Parse($line.SubString( 5, 3), $culture);
            $ioResult.h02 = [int]::Parse($line.SubString( 8, 3), $culture);
            $ioResult.h03 = [int]::Parse($line.SubString(11, 3), $culture);
            $ioResult.h04 = [int]::Parse($line.SubString(14, 3), $culture);
            $ioResult.h05 = [int]::Parse($line.SubString(17, 3), $culture);
            $ioResult.h06 = [int]::Parse($line.SubString(20, 3), $culture);
            $ioResult.h07 = [int]::Parse($line.SubString(23, 3), $culture);
            $ioResult.h08 = [int]::Parse($line.SubString(26, 3), $culture);
            $ioResult.h09 = [int]::Parse($line.SubString(29, 3), $culture);
            $ioResult.h10 = [int]::Parse($line.SubString(32, 3), $culture);
            $ioResult.h11 = [int]::Parse($line.SubString(35, 3), $culture);
            $ioResult.h12 = [int]::Parse($line.SubString(38, 3), $culture);
            $ioResult.h13 = [int]::Parse($line.SubString(41, 3), $culture);
            $ioResult.h14 = [int]::Parse($line.SubString(44, 3), $culture);
            $ioResult.h15 = [int]::Parse($line.SubString(47, 3), $culture);
            $ioResult.h16 = [int]::Parse($line.SubString(50, 3), $culture);
            $ioResult.h17 = [int]::Parse($line.SubString(53, 3), $culture);
            $ioResult.h18 = [int]::Parse($line.SubString(56, 3), $culture);
            $ioResult.h19 = [int]::Parse($line.SubString(59, 3), $culture);
            $ioResult.h20 = [int]::Parse($line.SubString(62, 3), $culture);
            $ioResult.h21 = [int]::Parse($line.SubString(65, 3), $culture);
            $ioResult.h22 = [int]::Parse($line.SubString(68, 3), $culture);
            $ioResult.h23 = [int]::Parse($line.SubString(71, 3), $culture);
            $ioResult.h24 = [int]::Parse($line.SubString(74), $culture);
        }
    }

    return $ioResult;
}

function getHtmlPageHeader
{
    return `
    "<!DOCTYPE HTML PUBLIC ""-//W3C//DTD HTML 4.0 Transitional//EN""><html><head>
    <title>Storage I/O Performance Test</title>
    <link rel=""stylesheet"" type=""text/css"" href=""StorageIoPerformanceTester.css""></link></head><body>
    <table class=""docTable"">
    <tr><td class=""docHeader"">Storage I/O Performance Test<br><br></td>
    </tr><tr><td>Document Created: " + (Get-Date -Format yyyy-MM-dd) + "</td></tr></table><br>"
}

function getHtmlParagraph1
{
    param([string] $text)
    return "<br><br><p class=""styleHeader1"">$text</p>";
}

function getHtmlParagraph2
{
    param([string] $text)
    return "<br><br><p class=""styleHeader2"">$text</p>";
}

function getHtmlTableStart
{
    param([string[]] $cols)
    [string] $tbl = "<table class=""styleTable""><colgroup>";
    [string] $tr  = "<tr>";
    
    foreach ($col in $cols)
    {
        $tbl += "<col></col>";
        $tr  += "<th class=""styleColHeader""><span>$col</span></th>";
    }
    
    return $tbl + "</colgroup>" + $tr + "</tr>";
}

function getHtmlTableAddRow
{
    param([object[]] $cols)
    [string] $tr  = "<tr>";
    
    foreach ($col in $cols)
    { 
        if (@("int16", "int32", "double") -contains $col.GetType().Name)
        {   $tr  += "<th class=""styleColNum""><span>$col</span></th>";   }
        else
        {   $tr  += "<th class=""styleCol""><span>$col</span></th>"   };    
    }
    
    return $tr + "</tr>";
}

function getHtmlTableEnd
{   return "</table>";   }



Clear-Host;

$check = Get-ChildItem -Path $folder"SqlIo.exe" -ErrorAction SilentlyContinue;
if (!$check)
{
    Write-Host "The SqlIo.exe tool must exist in the test folder!" -BackgroundColor Red;
    break;
}

[string] $batchFile = ($folder + "sqlio.bat");
[IoResult[]] $results = @();

Write-Host ((Get-Date -format HH:mm:ss) + ": Starting ...");


Set-Content -Value $folder"testfile.dat 2 0x0 "$fileSizeMb"" -Path $folder"param.txt";

foreach ($stripeFactor in $stripFct)
{
    foreach ($thread in $threads)
    {
    	foreach ($ioType in $ioTypes)
    	{
    		foreach ($ioSizeKb in $ioSizesKb)
    		{
    			Write-Host ((Get-Date -format HH:mm:ss) + ": Parameter = $stripeFactor $thread $ioType $ioSizeKb");
                
                
    			$batch = "call sqlio.exe " + `
                         "-k$ioType -s$runTimeSec -f$stripeFactor -b$ioSizeKb -t$thread " + `
    			         "-o8 -LS -BN " + `
    			         "-Fparam.txt > result.txt";
    		    Set-Content -Value $batch -Path $batchFile;
    			Start-Process -Wait -FilePath $batchFile -workingdirectory $folder -WindowStyle Hidden;
    			
                
    			[IoResult] $result = getIoResult -resultFile $folder"result.txt";
                $result.stripeFactor = $stripeFactor;
                $result.threads = $thread;
                $result.ioType = $ioType;
                $result.ioSizeKb = $ioSizeKb;
                $results += $result;
    			Remove-Item  $folder"result.txt" -ErrorAction SilentlyContinue;
                Remove-Item  $folder"sqlio.bat"  -ErrorAction SilentlyContinue;
    		}
    	}
    }
}


Clear-Host;
Write-Output "Measures:";
Write-Output $results | `
    Format-Table -Property stripeFactor, threads, ioType, ioSizeKb, ioPerSec, mbPerSec, `
                           minlatMs, maxLatMs, avgLatMs -AutoSize;

Write-Output "Latency History:";
Write-Output $results | `
    Format-Table -Property stripeFactor, threads, ioType, ioSizeKb, `
                           h00, h01, h02, h03, h04, h05, `
                           h06, h07, h08, h09, h10, h11, `
                           h12, h13, h14, h15, h16, h17, `
                           h18, h19, h20, h21, h23, h24 -AutoSize;


if ($createHtml)
{
    [String] $header = [String]::Empty;
    [String] $overview = [String]::Empty;
    [string] $history = [String]::Empty;
    [String] $html = [String]::Empty;
    
    $header += getHtmlPageHeader;
    $header += getHtmlParagraph1  -text "Test Parameter Settings:";
    $header += getHtmlTableStart  -cols @("Property", "Value");
    $header += getHtmlTableAddRow -cols @("Computer", $Env:COMPUTERNAME);
    $header += getHtmlTableAddRow -cols @("Test folder", $folder);
    $header += getHtmlTableAddRow -cols @("Size of test file (MB)", $fileSizeMb);
    $header += getHtmlTableAddRow -cols @("Duration per test case (sec)", $runTimeSec);
    $header += getHtmlTableAddRow -cols @("Stripe factors", ($stripFct));
    $header += getHtmlTableAddRow -cols @("Threads", ($threads));
    $header += getHtmlTableAddRow -cols @("I/O types", ($ioTypes));
    $header += getHtmlTableAddRow -cols @("I/O size (KB)", ($ioSizesKb));
    $header += getHtmlTableEnd;
    
    $overview += getHtmlParagraph1 -text "Measures Overview:";
    $overview += getHtmlTableStart -cols @("Stripe Factor", "Threads", "IO Type", "IO Size", `
                                           "IO per Sec", "MB per Sec", `
                                           "Min Lat (ms)", "Max Lat (ms)", "Avg Lat (ms)");
    $history += getHtmlParagraph1 -text "Latency History (ms):";
    $history += getHtmlTableStart -cols @("Stripe Factor", "Threads", "IO Type", "IO Size", `
                                           "0",  "1",  "2",  "3",  "4",  "5",  "6",  "7", `
                                           "8",  "9", "10", "11", "12", "13", "14", "15", `
                                          "16", "17", "18", "19", "20", "21", "22", "23", "24+");
    foreach ($res in $results)
    {
        $overview += getHtmlTableAddRow -cols @($res.stripeFactor, $res.threads, $res.ioType, $res.ioSizeKb, `
                                                $res.ioPerSec, $res.mbPerSec, `
                                                $res.minLatMs, $res.maxLatMs, $res.avgLatMs);
        $history += getHtmlTableAddRow -cols @($res.stripeFactor, $res.threads, $res.ioType, $res.ioSizeKb, `
                                               $res.h00, $res.h01, $res.h02, $res.h03, $res.h04, $res.h05, `
                                               $res.h06, $res.h07, $res.h08, $res.h09, $res.h10, $res.h11, `
                                               $res.h12, $res.h13, $res.h14, $res.h15, $res.h16, $res.h17, `
                                               $res.h18, $res.h19, $res.h20, $res.h21, $res.h22, $res.h23, `
                                               $res.h24);
        $overview += "`r`n";
        $history += "`r`n";
    }
    
    $overview += getHtmlTableEnd;
    $history += getHtmlTableEnd;
    $html = $header + $overview + $history + "</body></html>";
    Set-Content -Path $folder"StorageIoPerformanceTester.html" -Value $html;
    Invoke-Item $folder"StorageIoPerformanceTester.html";
}


Remove-Item  $folder"testfile.dat" -ErrorAction SilentlyContinue;
Remove-Item  $folder"param.txt" -ErrorAction SilentlyContinue;
Write-Host ((Get-Date -format HH:mm:ss) + ": Finished");