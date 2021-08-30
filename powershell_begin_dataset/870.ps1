$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path) -replace '\.Tests', ''
. "$here\$sut"

$clusterName = $ENV:ClusterName
$httpUserPassword = $ENV:HttpPassword
$securePassword = ConvertTo-SecureString $httpUserPassword -AsPlainText -Force
$creds = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList "admin", $securePassword


function Get-Credential { return $creds }

Describe "hdinsight-hadoop-use-pig-powershell" {
    It "Runs a Pig query using Start-AzHDInsightJob" {
        Mock Read-Host { $clusterName }
        
        (Start-PigJob $clusterName $creds)[-1].StartsWith("(TRACE,816)") | Should be True
    }
}
