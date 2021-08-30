$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path) -replace '\.Tests', ''
. "$here\$sut"

$clusterName = $ENV:ClusterName
$httpUserPassword = $ENV:HttpPassword
$securePassword = ConvertTo-SecureString $httpUserPassword -AsPlainText -Force
$creds = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList "admin", $securePassword



function Get-Credential { return $creds }

Describe "hdinsight-hadoop-dotnet-csharp-mapreduce" {
    
    in $TestDrive {
        It "Runs a C
            Mock Read-host { $clusterName }
            
            (Start-MapReduce)[0].State | Should be "SUCCEEDED"
        }
        It "Downloaded the output file" {
            Test-Path .\output.txt | Should be True
        }
    }
}
