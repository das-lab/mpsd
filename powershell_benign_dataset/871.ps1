function Start-PigJob {
    
    $ErrorActionPreference = "Stop"
    
    
    $context = Get-AzContext
    if ($context -eq $null) 
    {
        Connect-AzAccount
    }
    $context

    
    $clusterName = Read-Host -Prompt "Enter the HDInsight cluster name"
    $creds=Get-Credential -Message "Enter the login for the cluster"

    
    $QueryString =  "LOGS = LOAD '/example/data/sample.log';" +
    "LEVELS = foreach LOGS generate REGEX_EXTRACT(`$0, '(TRACE|DEBUG|INFO|WARN|ERROR|FATAL)', 1)  as LOGLEVEL;" +
    "FILTEREDLEVELS = FILTER LEVELS by LOGLEVEL is not null;" +
    "GROUPEDLEVELS = GROUP FILTEREDLEVELS by LOGLEVEL;" +
    "FREQUENCIES = foreach GROUPEDLEVELS generate group as LOGLEVEL, COUNT(FILTEREDLEVELS.LOGLEVEL) as COUNT;" +
    "RESULT = order FREQUENCIES by COUNT desc;" +
    "DUMP RESULT;"


    
    $pigJobDefinition = New-AzHDInsightPigJobDefinition `
        -Query $QueryString `
        -Arguments "-w"

    
    Write-Host "Start the Pig job ..." -ForegroundColor Green
    $pigJob = Start-AzHDInsightJob `
        -ClusterName $clusterName `
        -JobDefinition $pigJobDefinition `
        -HttpCredential $creds

    
    Write-Host "Wait for the Pig job to complete ..." -ForegroundColor Green
    Wait-AzHDInsightJob `
        -ClusterName $clusterName `
        -JobId $pigJob.JobId `
        -HttpCredential $creds

    
    Write-Host "Display the standard output ..." -ForegroundColor Green
    Get-AzHDInsightJobOutput `
        -ClusterName $clusterName `
        -JobId $pigJob.JobId `
        -HttpCredential $creds
}