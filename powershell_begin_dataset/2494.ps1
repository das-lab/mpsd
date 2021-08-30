



 

$ServiceName = "SQL Server (SOX2)"

 



$TranManSec = "Mutual" 





 

 

 

 



$GroupPath = "HKLM:\Cluster\Groups"

$GroupList = dir $GroupPath

 



foreach ($Group in $GroupList)

{

    $GroupChildPath = $Group.PSPath

    if ((Get-ItemProperty -path $GroupChildPath -name Name).Name -eq $ServiceName)

    {

        

        $ReferencedResources = (Get-ItemProperty -path $GroupChildPath -name Contains).Contains

        foreach ($Resource in $ReferencedResources)

        {

            

            $ResourcePath = "HKLM:\Cluster\Resources\$Resource"

            if ((Get-ItemProperty -path $ResourcePath).Type -eq "Distributed Transaction Coordinator")

            {

                

                $SecurityPath = "$ResourcePath\MSDTCPRIVATE\MSDTC\Security"

                Set-ItemProperty -path $SecurityPath -name "NetworkDtcAccess" -value 1

                Set-ItemProperty -path $SecurityPath -name "NetworkDtcAccessClients" -value 0

                Set-ItemProperty -path $SecurityPath -name "NetworkDtcAccessTransactions" -value 0

                Set-ItemProperty -path $SecurityPath -name "NetworkDtcAccessInbound" -value 1

                Set-ItemProperty -path $SecurityPath -name "NetworkDtcAccessOutbound" -value 1

                Set-ItemProperty -path $SecurityPath -name "LuTransactions" -value 1

 

                

                $SecurityPath = "$ResourcePath\MSDTCPRIVATE\MSDTC"

                if ($TranManSec -eq "None")

                {

                    Set-ItemProperty -path $MSDTCPath -name "TurnOffRpcSecurity" -value 1

                    Set-ItemProperty -path $MSDTCPath -name "AllowOnlySecureRpcCalls" -value 0

                    Set-ItemProperty -path $MSDTCPath -name "FallbackToUnsecureRPCIfNecessary" -value 0

                }

 

                elseif ($TranManSec -eq "Incoming")

                {

                    Set-ItemProperty -path $MSDTCPath -name "TurnOffRpcSecurity" -value 0

                    Set-ItemProperty -path $MSDTCPath -name "AllowOnlySecureRpcCalls" -value 0

                    Set-ItemProperty -path $MSDTCPath -name "FallbackToUnsecureRPCIfNecessary" -value 1

                }

 

                else 

                {

                    Set-ItemProperty -path $MSDTCPath -name "TurnOffRpcSecurity" -value 0

                    Set-ItemProperty -path $MSDTCPath -name "AllowOnlySecureRpcCalls" -value 1

                    Set-ItemProperty -path $MSDTCPath -name "FallbackToUnsecureRPCIfNecessary" -value 0

                } 

 

            }

        }

    }

}
