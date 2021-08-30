$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path) -replace '\.Tests', ''
. "$here\$sut"

$clusterName = $ENV:ClusterName
$httpUserPassword = $ENV:HttpPassword
$securePassword = ConvertTo-SecureString $httpUserPassword -AsPlainText -Force
$creds = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList "admin", $securePassword



function Get-Credential { return $creds }

Describe "hdinsight-mahout" {
    
    in $TestDrive {
        It "Runs a MapReduce job using Start-AzHDInsightJob" {
            Mock Read-host { $clusterName }
            
            (Start-MahoutJob)[0].State | Should be "SUCCEEDED"
        }
        It "Downloaded the output file" {
            Test-Path .\output.txt | Should be True
        }
        It "Downloaded the moviedb file" {
            Test-Path .\moviedb.txt | Should be True
        }
        It "Downloaded the ratings file" {
            Test-Path .\user-ratings.txt | Should be True
        }

        
        
        
        It "Displays user-readable output" {
            { Format-MahoutOutput -userId 4 -userDataFile .\user-ratings.txt -movieFile .\moviedb.txt -recommendationFile .\output.txt } | Should not throw
        }
    }
}
