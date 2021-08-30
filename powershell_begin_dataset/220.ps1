



[CmdletBinding()]
PARAM (
    [Parameter(Mandatory = $true, HelpMessage = "You must specify the Sender Email Address")]
    [ValidatePattern("[a-z0-9!
    [String]$EmailFrom,

    [Parameter(Mandatory = $true, HelpMessage = "You must specify the Destination Email Address")]
    [ValidatePattern("[a-z0-9!
    [String[]]$EmailTo,

    [Parameter(Mandatory = $true, HelpMessage = "You must specify the Email Server to use (IPAddress or FQDN)")]
    [String]$EmailServer,

    [ValidateRange(0,65535)]
    [int]$EmailServerPort = 25,

    [String]$EmailSubject = "Report - Active Directory - SITE - Missing Subnets",

    [Int]$LogsLines = "-200",

    [Switch]$KeepLogs,

    [ValidateScript({ Test-Path -Path $_})]
    [String]$HTMLReportPath

)

BEGIN
{
    TRY
    {
        
        $ScriptPath = (Split-Path -Path ((Get-Variable -Name MyInvocation).Value).MyCommand.Path)
        $ScriptPathOutput = $ScriptPath + "\Output"
        IF (-not (Test-Path -Path $ScriptPathOutput))
        {
            Write-Verbose -Message "[BEGIN] Creating the Output Folder : $ScriptPathOutput"
            New-Item -Path $ScriptPathOutput -ItemType Directory -ErrorAction 'Stop' | Out-Null
        }

        
        $DateFormat = Get-Date -Format "yyyyMMdd_HHmmss"
        $ReportDateFormat = Get-Date -Format "yyyy\MM\dd HH:mm:ss"

        
        $ReportTitle = "<H2>" +
        "Report - Active Directory - SITE - Missing Subnets" +
        "</H2>"
        
        $Report = "<p style=`"background-color:white;font-family:consolas;font-size:9pt`">" +
        "<strong>Report Time:</strong> $DateFormat <br>" +
        "<strong>Account:</strong> $env:userdomain\$($env:username.toupper()) on $($env:ComputerName.toUpper())" +
        "</p>"

        $Head = "<style>" +
        "BODY{background-color:white;font-family:consolas;font-size:11pt}" +
        "TABLE{border-width: 1px;border-style: solid;border-color: black;border-collapse: collapse}" +
        "TH{border-width: 1px;padding: 3px;border-style: solid;border-color: black;background-color:`"
        "TD{border-width: 1px;padding-right: 2px;padding-left: 2px;padding-top: 0px;padding-bottom: 0px;border-style: solid;border-color: black;background-color:white}" +
        "</style>"+

        '<style type="text/css">
        table.gridtable {
            font-family: verdana,arial,sans-serif;
            font-size:11px;
            color:
            border-width: 1px;
            border-color: 
            border-collapse: collapse;
        }
        table.gridtable th {
            border-width: 1px;
            padding: 8px;
            border-style: solid;
            border-color: 
            background-color: 
        }
        table.gridtable td {
            border-width: 1px;
            padding: 8px;
            border-style: solid;
            border-color: 
            background-color: 
        }
        </style>'

        $Head2 = "<style>" +
        "BODY{background-color:white;font-family:consolas;font-size:9pt;}" +
        "TABLE{border-width: 1px;border-style: solid;border-color: black;border-collapse: collapse;}" +
        "TH{border-width: 1px;padding: 3px;border-style: solid;border-color: black;background-color:`"
        "TD{border-width: 1px;padding-right: 2px;padding-left: 2px;padding-top: 0px;padding-bottom: 0px;border-style: solid;border-color: black;background-color:white}" +
        "</style>"

        $TableCSS = @"
<style type="text/css">
table.gridtable {
    font-family: verdana,arial,sans-serif;
    font-size:11px;
    color:
    border-width: 1px;
    border-color: 
    border-collapse: collapse;
}
table.gridtable th {
    border-width: 1px;
    padding: 8px;
    border-style: solid;
    border-color: 
    background-color: 
}
table.gridtable td {
    border-width: 1px;
    padding: 8px;
    border-style: solid;
    border-color: 
    background-color: 
}
</style>
"@

        $PostContent = "<font size=`"1`" color=`"black`"><br><br><i><u>Generated from:</u> $($env:COMPUTERNAME.ToUpper()) <u>on</u> $(Get-Date -Format "yyyy/MM/dd HH:mm:ss")</i></font>"

        
        $Forest = [System.DirectoryServices.ActiveDirectory.Forest]::GetCurrentForest()
        $ForestName = $Forest.Name.ToUpper()
        Write-Verbose -Message "[BEGIN] Forest: $ForestName"


    }
    CATCH
    {
        Write-Warning -Message "BEGIN BLOCK - Something went wrong"
        Write-Warning -Message $Error[0].Exception.Message
    }
}

PROCESS
{
    TRY
    {
        FOREACH ($Domain in $Forest.Domains)
        {
            $DomainName = $Domain.Name.ToUpper()

            
            Write-Verbose -Message "[PROCESS] FOREST: $ForestName DOMAIN: $domainName - Getting all Domain Controllers from ..."
            $DomainControllers = $domain | ForEach-Object -Process { $_.DomainControllers } | Select-Object -Property Name

            
            Write-Verbose "[PROCESS] FOREST: $ForestName DOMAIN: $domainName - Gathering Logs from Domain controllers"
            FOREACH ($dc in $DomainControllers)
            {
                $DCName = $($dc.Name).toUpper()
                TRY
                {

                    
                    
                    

                    
                    Write-Verbose -Message "[PROCESS] FOREST: $ForestName DOMAIN: $domainName - $DCName - Gathering Logs"

                    
                    $path = "\\$DCName\admin`$\debug\netlogon.log"

                    
                    IF ((Test-Path -Path $path) -and ((Get-Item -Path $path).Length -ne $null))
                    {
                        IF ((Get-Content -Path $path | Measure-Object -Line).lines -gt 0)
                        {
                            
                            Write-Verbose -Message "[PROCESS] FOREST: $ForestName DOMAIN: $domainName - $DCName - NETLOGON.LOG - Copying..."
                            Copy-Item -Path $path -Destination $ScriptPathOutput\$DomainName-$DCName-$DateFormat-netlogon.log

                            
                            ((Get-Content -Path $ScriptPathOutput\$DomainName-$DCName-$DateFormat-netlogon.log -ErrorAction Continue)[$LogsLines .. -1]) |
                            Out-File -FilePath "$ScriptPathOutput\$DomainName-$DCName.txt" -ErrorAction 'Continue' -ErrorVariable ErrorOutFileNetLogon
                            Write-Verbose -Message "[PROCESS] FOREST: $ForestName DOMAIN: $domainName - $DCName - NETLOGON.LOG - Copied"
                        }
                        ELSE { Write-Verbose -Message "[PROCESS] FOREST: $ForestName DOMAIN: $domainName - $DCName - NETLOGON File Empty !!" }
                    }
                    ELSE { Write-Warning -Message "[PROCESS] FOREST: $ForestName DOMAIN: $domainName - $DCName - NETLOGON.log is not reachable" }



                    
                    
                    
                    
                    $FilesToCombine = Get-Content -Path $ScriptPathOutput\*.txt -ErrorAction SilentlyContinue
                    IF ($FilesToCombine)
                    {

                        
                        
                        IF ($FilesToCombine[0] -match "\[\d{1,5}\]")
                        {
                            Write-Verbose -Message "[PROCESS] FOREST: $ForestName DOMAIN: $domainName - Importing exported data to a CSV format..."
                            Write-Verbose -Message "[PROCESS] FOREST: $ForestName DOMAIN: $domainName - NETLOGON format: 2012"
                            $ImportString = $FilesToCombine | ConvertFrom-Csv -Delimiter ' ' -Header Date, Time, Code, Domain, Error, Name, IPAddress
                        }

                        
                        IF($FilesToCombine[0] -notmatch "\[\d{1,5}\]")
                        {
                            Write-Verbose -Message "[PROCESS] FOREST: $ForestName DOMAIN: $domainName - Importing exported data to a CSV format..."
                            Write-Verbose -Message "[PROCESS] FOREST: $ForestName DOMAIN: $domainName - NETLOGON format: 2008 and Previous versions"
                            $ImportString = $FilesToCombine | ConvertFrom-Csv -Delimiter ' ' -Header Date, Time, Domain, Error, Name, IPAddress,Code
                        }

                        
                        Write-Verbose -Message "[PROCESS] FOREST: $ForestName DOMAIN: $domainName - Importing exported data to a CSV format..."
                        $ImportString = $FilesToCombine | ConvertFrom-Csv -Delimiter ' ' -Header Date, Time, Code, Domain, Error, Name, IPAddress

                        
                        $importString | Where-Object { $_.Error -like "*NO_CLIENT_SITE*" } | Export-Csv -LiteralPath $scriptpathOutput\$ForestName-$dateformat-NOCLIENTSITE.csv -Append
                        
                        $importString | Where-Object { $_.Error -notlike "*NO_CLIENT_SITE*" } | Export-Csv -LiteralPath $scriptpathOutput\$ForestName-$dateformat-OTHERERRORS.csv -Append

                    }
                    ELSE { Write-Verbose -Message "[PROCESS] Nothing to process" }

                }
                CATCH
                {
                    Write-Warning -Message "$ForestName - $domainName - $DCName - Something wrong happened"
                    if ($ErrorOutFileNetLogon) { Write-Warning -Message "$ForestName - $domainName - $DCName - Error with Out-File" }
                }
            }
        }


        
        
        
        $MissingSubnets = Import-Csv -LiteralPath $scriptpathOutput\$ForestName-$dateformat-NOCLIENTSITE.csv
        $OtherErrors = Import-Csv -LiteralPath $scriptpathOutput\$ForestName-$dateformat-OTHERERRORS.csv



        
        
        
        Write-Verbose -Message "[PROCESS] $ForestName - Building the HTML Report"

        
        $EmailBody += "<h1><u>Forest:</u> $($ForestName.ToUpper())</h1>"
        $EmailBody += "<h2><u>Domain</u>: $($DomainName.ToUpper())</h2>"
        $EmailBody += "<h3>Missing Subnet(s) for $($DomainName.ToUpper())</h3>"
        IF ($MissingSubnets)
        {
            $EmailBody += "<i>List of Active Directory client that can not find their site.<br> You need to add those subnets into the console Active Directory Sites And Services</i>"
            $EmailBody += $MissingSubnets | Sort-Object IPAddress -Unique | ConvertTo-Html -property IPAddress,Name,Date,Domain,Code, Error -Fragment 
        }
        ELSE { $EmailBody += "<i>No Missing Subnet(s) detected</i>" }

        
        $EmailBody += "<h2>Other Error(s)</h2>"
        IF ($OtherErrors)
        {
            $EmailBody += "<br><font size=`"1`" color=`"red`">"
            
            Get-ChildItem $scriptpathoutput\$DomainName-*.txt -Exclude "*All_Export*" |
            ForEach-Object{
                
                $CurrentFile = Get-Content $_ | Where-Object { $_ -notlike "*NO_CLIENT_SITE*" }
                IF ($CurrentFile)
                {
                    
                    $EmailBody += "<font size=`"2`"><b>$($_.basename)</b><br></font>"
                    $EmailBody += "<br><font size=`"1`" color=`"red`">"
                    FOREACH ($Line in $CurrentFile)
                    {
                        $EmailBody += "$line<br>"
                    }
                    
                    $EmailBody += "</font>"
                }
            }
        }
        ELSE { $EmailBody += "<i>No Other Error detected</i>" }

    }
    CATCH
    {
        Write-Warning -Message "[PROCESS] Something wrong happened"
        Write-Warning -Message $Error[0].Exception.Message
    }
    FINALLY
    {


        
        
        

        
        $EmailBody += $PostContent

        $EmailBody = $EmailBody -replace "<table>", '<table class="gridtable">'
        $FinalEmailBody = ConvertTo-Html -Head $Head -PostContent $EmailBody

        
        Write-Verbose -Message "[PROCESS] Preparing the final Email"
        $SmtpClient = New-Object -TypeName system.net.mail.smtpClient
        $SmtpClient.host = $EmailServer
        $SmtpClient.Port = $EmailServerPort
        $MailMessage = New-Object -TypeName system.net.mail.mailmessage
        $MailMessage.from = $EmailFrom
        
        FOREACH ($To in $Emailto) { $MailMessage.To.add($($To)) }
        $MailMessage.IsBodyHtml = $true
        $MailMessage.Subject = $EmailSubject
        $MailMessage.Body = $FinalEmailBody
        $SmtpClient.Send($MailMessage)
        Write-Verbose -Message "[PROCESS] Email Sent!"


        
        
        

        if ($PSBoundParameters['HTMLReportPath'])
        {
            $FinalEmailBody | Out-File -LiteralPath (Join-Path -Path $HTMLReportPath -ChildPath "$ForestName-$dateformat-Report.html")
        }
    }

}
END
{
    IF (-not $KeepLogs)
    {
        Write-Verbose "Cleanup txt and log files..."
        Remove-item -Path $ScriptpathOutput\*.txt -force
        Remove-Item -Path $ScriptPathOutput\*.log -force
        Write-Verbose -Message "Script Completed"
    }
}