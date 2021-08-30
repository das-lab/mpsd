




[CmdletBinding(DefaultParameterSetName = "Group")]
PARAM (
    [Parameter(ParameterSetName = "Group", Mandatory = $true, HelpMessage = "You must specify at least one Active Directory group")]
    [ValidateNotNull()]
    [Alias('DN', 'DistinguishedName', 'GUID', 'SID', 'Name')]
    [string[]]$Group,

    [Parameter(ParameterSetName = "OU", Mandatory = $true)]
    [Alias('SearchBase')]
    [String[]]$SearchRoot,

    [Parameter(ParameterSetName = "OU")]
    [ValidateSet("Base", "OneLevel", "Subtree")]
    [String]$SearchScope,

    [Parameter(ParameterSetName = "OU")]
    [ValidateSet("Global", "Universal", "DomainLocal")]
    [String]$GroupScope,

    [Parameter(ParameterSetName = "OU")]
    [ValidateSet("Security", "Distribution")]
    [String]$GroupType,

    [Parameter(ParameterSetName = "File", Mandatory = $true)]
    [ValidateScript({ Test-Path -Path $_ })]
    [String[]]$File,

    [Parameter()]
    [Alias('DomainController', 'Service')]
    $Server,

    [Parameter(Mandatory = $true, HelpMessage = "You must specify the Sender Email Address")]
    [ValidatePattern("[a-z0-9!
    [String]$Emailfrom,

    [Parameter(Mandatory = $true, HelpMessage = "You must specify the Destination Email Address")]
    [ValidatePattern("[a-z0-9!
    [String[]]$Emailto,

    [Parameter(Mandatory = $true, HelpMessage = "You must specify the Email Server to use (IPAddress or FQDN)")]
    [String]$EmailServer,

    [Parameter()]
    [ValidateSet("ASCII", "UTF8", "UTF7", "UTF32", "Unicode", "BigEndianUnicode", "Default")]
    [String]$EmailEncoding="ASCII",

    [Parameter()]
    [Switch]$HTMLLog
)
BEGIN
{
    TRY
    {

        
        $ScriptPath = (Split-Path -Path ((Get-Variable -Name MyInvocation).Value).MyCommand.Path)
        $ScriptPathOutput = $ScriptPath + "\Output"
        IF (!(Test-Path -Path $ScriptPathOutput))
        {
            Write-Verbose -Message "[BEGIN] Creating the Output Folder : $ScriptPathOutput"
            New-Item -Path $ScriptPathOutput -ItemType Directory | Out-Null
        }
        $ScriptPathChangeHistory = $ScriptPath + "\ChangeHistory"
        IF (!(Test-Path -Path $ScriptPathChangeHistory))
        {
            Write-Verbose -Message "[BEGIN] Creating the ChangeHistory Folder : $ScriptPathChangeHistory"
            New-Item -Path $ScriptPathChangeHistory -ItemType Directory | Out-Null
        }

        
        $DateFormat = Get-Date -Format "yyyyMMdd_HHmmss"
        $ReportDateFormat = Get-Date -Format "yyyy\MM\dd HH:mm:ss"


        
        IF (Get-Module -Name ActiveDirectory -ListAvailable) 
        {
            Write-Verbose -Message "[BEGIN] Active Directory Module"
            
            IF (-not (Get-Module -Name ActiveDirectory -ErrorAction SilentlyContinue -ErrorVariable ErrorBEGINGetADModule))
            {
                Write-Verbose -Message "[BEGIN] Active Directory Module - Loading"
                Import-Module -Name ActiveDirectory -ErrorAction SilentlyContinue -ErrorVariable ErrorBEGINAddADModule
                Write-Verbose -Message "[BEGIN] Active Directory Module - Loaded"
                $global:ADModule = $true
            }
            ELSE
            {
                Write-Verbose -Message "[BEGIN] Active Directory module seems loaded"
                $global:ADModule = $true
            }
        }
        ELSE 
        {
            Write-Verbose -Message "[BEGIN] Quest AD Snapin"
            
            IF (-not (Get-PSSnapin -Name Quest.ActiveRoles.ADManagement -ErrorAction Stop -ErrorVariable ErrorBEGINGetQuestAD))
            {
                Write-Verbose -Message "[BEGIN] Quest Active Directory - Loading"
                Add-PSSnapin -Name Quest.ActiveRoles.ADManagement -ErrorAction Stop -ErrorVariable ErrorBEGINAddQuestAd
                Write-Verbose -Message "[BEGIN] Quest Active Directory - Loaded"
                $global:QuestADSnappin = $true
            }
            ELSE
            {
                Write-Verbose -Message "[BEGIN] Quest AD Snapin seems loaded"
            }
        }

        Write-Verbose -Message "[BEGIN] Setting HTML Variables"
        
        $Report = "<p style=`"background-color:white;font-family:consolas;font-size:9pt`">" +
        "<strong>Report Time:</strong> $DateFormat <br>" +
        "<strong>Account:</strong> $env:userdomain\$($env:username.toupper()) on $($env:ComputerName.toUpper())" +
        "</p>"

        $Head = "<style>" +
        "BODY{background-color:white;font-family:consolas;font-size:11pt}" +
        "TABLE{border-width: 1px;border-style: solid;border-color: black;border-collapse: collapse}" +
        "TH{border-width: 1px;padding: 3px;border-style: solid;border-color: black;background-color:`"
        "TD{border-width: 1px;padding-right: 2px;padding-left: 2px;padding-top: 0px;padding-bottom: 0px;border-style: solid;border-color: black;background-color:white}" +
        "</style>"
        $Head2 = "<style>" +
        "BODY{background-color:white;font-family:consolas;font-size:9pt;}" +
        "TABLE{border-width: 1px;border-style: solid;border-color: black;border-collapse: collapse;}" +
        "TH{border-width: 1px;padding: 3px;border-style: solid;border-color: black;background-color:`"
        "TD{border-width: 1px;padding-right: 2px;padding-left: 2px;padding-top: 0px;padding-bottom: 0px;border-style: solid;border-color: black;background-color:white}" +
        "</style>"


    }
    CATCH
    {
        Write-Warning -Message "[BEGIN] Something went wrong"

        
        
        Write-Warning -Message $Error[0]

        
        if ($ErrorBEGINGetQuestAD) { Write-Warning -Message "[BEGIN] Can't Find the Quest Active Directory Snappin" }
        if ($ErrorBEGINAddQuestAD) { Write-Warning -Message "[BEGIN] Can't Load the Quest Active Directory Snappin" }

        
        if ($ErrorBEGINGetADmodule) { Write-Warning -Message "[BEGIN] Can't find the Active Directory module" }
        if ($ErrorBEGINAddADmodule) { Write-Warning -Message "[BEGIN] Can't load the Active Directory module" }
    }
}

PROCESS
{
    TRY
    {

        
        
        

        IF ($PSBoundParameters['SearchRoot'])
        {
            Write-Verbose -Message "[PROCESS] SearchRoot specified"
            FOREACH ($item in $SearchRoot)
            {
                
                $ADGroupParams = @{ }


                
                IF ($ADModule)
                {
                    $ADGroupParams.SearchBase = $item

                    
                    IF ($PSBoundParameters['Server']) { $ADGroupParams.Server = $Server}
                }
                IF ($QuestADSnappin)
                {
                    $ADGroupParams.SearchRoot = $item

                    
                    IF ($PSBoundParameters['Server']) { $ADGroupParams.Service = $Server }
                }


                
                
                
                IF ($PSBoundParameters['SearchScope'])
                {
                    Write-Verbose -Message "[PROCESS] SearchScope specified"
                    $ADGroupParams.SearchScope = $SearchScope
                }


                
                
                
                IF ($PSBoundParameters['GroupScope'])
                {
                    Write-Verbose -Message "[PROCESS] GroupScope specified"
                    
                    IF ($ADModule) { $ADGroupParams.Filter = "GroupScope -eq `'$GroupScope`'" }
                    
                    ELSE { $ADGroupParams.GroupScope = $GroupScope }
                }


                
                
                
                IF ($PSBoundParameters['GroupType'])
                {
                    Write-Verbose -Message "[PROCESS] GroupType specified"
                    
                    IF ($ADModule)
                    {
                        
                        IF ($ADGroupParams.Filter)
                        {
                            $ADGroupParams.Filter = "$($ADGroupParams.Filter) -and GroupCategory -eq `'$GroupType`'"
                        }
                        ELSE
                        {
                            $ADGroupParams.Filter = "GroupCategory -eq '$GroupType'"
                        }
                    }
                    
                    ELSE
                    {
                        $ADGroupParams.GroupType = $GroupType
                    }
                }



                IF ($ADModule)
                {
                    IF (-not($ADGroupParams.filter)){$ADGroupParams.Filter = "*"}

                    Write-Verbose -Message "[PROCESS] AD Module - Querying..."

                    
                    $GroupSearch = Get-ADGroup @ADGroupParams

                    if ($GroupSearch){
                        $group += $GroupSearch.Distinguishedname
                        Write-Verbose -Message "[PROCESS] OU: $item"
                    }
                }

                IF ($QuestADSnappin)
                {
                    Write-Verbose -Message "[PROCESS] Quest AD Snapin - Querying..."
                    
                    $GroupSearchQuest = Get-QADGroup @ADGroupParams
                    if ($GroupSearchQuest){
                        $group += $GroupSearchQuest.DN
                        Write-Verbose -Message "[PROCESS] OU: $item"
                    }
                }

            }
        }




        
        
        

        IF ($PSBoundParameters['File'])
        {
            Write-Verbose -Message "[PROCESS] File"
            FOREACH ($item in $File)
            {
                Write-Verbose -Message "[PROCESS] Loading File: $item"

                $FileContent = Get-Content -Path $File

                if ($FileContent)
                {
                    
                    $Group += Get-Content -Path $File
                }



            }
        }



        
        
        

        
        FOREACH ($item in $Group)
        {
            TRY
            {

                Write-Verbose -Message "[PROCESS] GROUP: $item... "

                
                $GroupSplatting = @{ }
                $GroupSplatting.Identity = $item

                
                if ($ADModule)
                {
                    Write-Verbose -Message "[PROCESS] ActiveDirectory module"

                    
                    IF ($PSBoundParameters['Server']) { $GroupSplatting.Server = $Server }

                    
                    $GroupName = Get-ADGroup @GroupSplatting -Properties * -ErrorAction Continue -ErrorVariable ErrorProcessGetADGroup
                    $DomainName = ($GroupName.canonicalname -split '/')[0]
                    $RealGroupName = $GroupName.name
                }
                if ($QuestADSnappin)
                {
                    Write-Verbose -Message "[PROCESS] Quest ActiveDirectory Snapin"

                    
                    IF ($PSBoundParameters['Server']) { $GroupSplatting.Service = $Server }

                    
                    $GroupName = Get-QADgroup @GroupSplatting -ErrorAction Continue -ErrorVariable ErrorProcessGetQADGroup
                    $DomainName = $($GroupName.domain.name)
                    $RealGroupName = $GroupName.name
                }

                
                IF ($GroupName)
                {

                    
                    $GroupMemberSplatting = @{ }
                    $GroupMemberSplatting.Identity = $GroupName


                    
                    if ($ADModule)
                    {
                        Write-Verbose -Message "[PROCESS] GROUP: $item - Querying Membership (AD Module)"

                        
                        IF ($PSBoundParameters['Server']) { $GroupMemberSplatting.Server = $Server }

                        
                        $Members = Get-ADGroupMember @GroupMemberSplatting -Recursive -ErrorAction Stop -ErrorVariable ErrorProcessGetADGroupMember | Select-Object -Property *,@{ Name = 'DN'; Expression = { $_.DistinguishedName } }
                    }
                    if ($QuestADSnappin)
                    {
                        Write-Verbose -Message "[PROCESS] GROUP: $item - Querying Membership (Quest AD Snapin)"

                        
                        IF ($PSBoundParameters['Server']) { $GroupMemberSplatting.Service = $Server }

                        $Members = Get-QADGroupMember @GroupMemberSplatting -Indirect -ErrorAction Stop -ErrorVariable ErrorProcessGetQADGroupMember 
                    }
                    
                    
                    IF (-not ($Members))
                    {
                        Write-Verbose -Message "[PROCESS] GROUP: $item is empty"
                        $Members = New-Object -TypeName PSObject -Property @{
                            Name = "No User or Group"
                            SamAccountName = "No User or Group"
                        }
                    }


                    
                    
                    $StateFile = "$($DomainName)_$($RealGroupName)-membership.csv"
                    IF (!(Test-Path -Path (Join-Path -Path $ScriptPathOutput -ChildPath $StateFile)))
                    {
                        Write-Verbose -Message "[PROCESS] $item - The following file did not exist: $StateFile"
                        Write-Verbose -Message "[PROCESS] $item - Exporting the current membership information into the file: $StateFile"
                        $Members | Export-csv -Path (Join-Path -Path $ScriptPathOutput -ChildPath $StateFile) -NoTypeInformation
                    }
                    ELSE
                    {
                        Write-Verbose -Message "[PROCESS] $item - The following file Exists: $StateFile"
                    }


                    
                    Write-Verbose -Message "[PROCESS] $item - Comparing Current and Before"
                    $ImportCSV = Import-Csv -Path (Join-Path -path $ScriptPathOutput -childpath $StateFile) -ErrorAction Stop -ErrorVariable ErrorProcessImportCSV
                    $Changes = Compare-Object -DifferenceObject $ImportCSV -ReferenceObject $Members -ErrorAction stop -ErrorVariable ErrorProcessCompareObject -Property Name, SamAccountName, DN |
                    Select-Object @{ Name = "DateTime"; Expression = { Get-Date -Format "yyyyMMdd-hh:mm:ss" } }, @{
                        n = 'State'; e = {
                            IF ($_.SideIndicator -eq "=>") { "Removed" }
                            ELSE { "Added" }
                        }
                    }, DisplayName, Name, SamAccountName, DN | Where-Object { $_.name -notlike "*no user or group*" }
                    Write-Verbose -Message "[PROCESS] $item - Compare Block Done !"

                    

                    
                    If ($Changes)
                    {
                        Write-Verbose -Message "[PROCESS] $item - Some changes found"
                        $changes | Select-Object -Property DateTime, State, Name, SamAccountName, DN

                        
                        
                        Write-Verbose -Message "[PROCESS] $item - Get the change history for this group"
                        $ChangesHistoryFiles = Get-ChildItem -Path $ScriptPathChangeHistory\$($DomainName)_$($RealGroupName)-ChangeHistory.csv -ErrorAction 'SilentlyContinue'
                        Write-Verbose -Message "[PROCESS] $item - Change history files: $(($ChangesHistoryFiles|Measure-Object).Count)"

                        
                        IF ($ChangesHistoryFiles)
                        {
                            $infoChangeHistory = @()
                            FOREACH ($file in $ChangesHistoryFiles.FullName)
                            {
                                Write-Verbose -Message "[PROCESS] $item - Change history files - Loading $file"
                                
                                $ImportedFile = Import-Csv -Path $file -ErrorAction Stop -ErrorVariable ErrorProcessImportCSVChangeHistory
                                FOREACH ($obj in $ImportedFile)
                                {
                                    $Output = "" | Select-Object -Property DateTime, State, DisplayName,Name, SamAccountName, DN
                                    
                                    $Output.DateTime = $obj.DateTime
                                    $Output.State = $obj.State
                                    $Output.DisplayName = $obj.DisplayName
                                    $Output.Name = $obj.Name
                                    $Output.SamAccountName = $obj.SamAccountName
                                    $Output.DN = $obj.DN
                                    $infoChangeHistory = $infoChangeHistory + $Output
                                }
                            }
                            Write-Verbose -Message "[PROCESS] $item - Change history process completed"
                        }

                        
                        Write-Verbose -Message "[PROCESS] $item - Save changes to a ChangesHistory file"

                        IF (-not (Test-Path -path (Join-Path -Path $ScriptPathChangeHistory -ChildPath "$($DomainName)_$($RealGroupName)-ChangeHistory.csv")))
                        {
                            $Changes | Export-Csv -Path (Join-Path -Path $ScriptPathChangeHistory -ChildPath "$($DomainName)_$($RealGroupName)-ChangeHistory.csv") -NoTypeInformation
                        }
                        ELSE
                        {
                            
                            $Changes | Export-Csv -Path (Join-Path -Path $ScriptPathChangeHistory -ChildPath "$($DomainName)_$($RealGroupName)-ChangeHistory.csv") -NoTypeInformation -Append
                        }


                        
                        Write-Verbose -Message "[PROCESS] $item - Preparing the notification email..."

                        $EmailSubject = "PS MONITORING - $($GroupName.SamAccountName) Membership Change"

                        
                        $body = "<h2>Group: $($GroupName.SamAccountName)</h2>"
                        $body += "<p style=`"background-color:white;font-family:consolas;font-size:8pt`">"
                        $body += "<u>Group Description:</u> $($GroupName.Description)<br>"
                        $body += "<u>Group DistinguishedName:</u> $($GroupName.DistinguishedName)<br>"
                        $body += "<u>Group CanonicalName:</u> $($GroupName.CanonicalName)<br>"
                        $body += "<u>Group SID:</u> $($GroupName.Sid.value)<br>"
                        $body += "<u>Group Scope/Type:</u> $($GroupName.GroupScope) / $($GroupName.GroupType)<br>"
                        $body += "</p>"

                        $body += "<h3> Membership Change"
                        $body += "</h3>"
                        $body += "<i>The membership of this group changed. See the following Added or Removed members.</i>"

                        
                        $Changes = $changes | Select-Object -Property DateTime, State,Name, SamAccountName, DN

                        $body += $changes | ConvertTo-Html -head $head | Out-String
                        $body += "<br><br><br>"
                        IF ($ChangesHistoryFiles)
                        {
                            
                            $infoChangeHistory = $infoChangeHistory | Select-Object -Property DateTime, State, Name, SamAccountName, DN

                            $body += "<h3>Change History</h3>"
                            $body += "<i>List of the previous changes on this group observed by the script</i>"
                            $body += $infoChangeHistory | Sort-Object -Property DateTime -Descending | ConvertTo-Html -Fragment -PreContent $Head2 | Out-String
                        }
                        $body = $body -replace "Added", "<font color=`"blue`"><b>Added</b></font>"
                        $body = $body -replace "Removed", "<font color=`"red`"><b>Removed</b></font>"
                        $body += $Report

                        
                        $SmtpClient = New-Object -TypeName system.net.mail.smtpClient
                        $SmtpClient.host = $EmailServer
                        $MailMessage = New-Object -TypeName system.net.mail.mailmessage
                        
                        $MailMessage.from = $EmailFrom
                        
                        FOREACH ($To in $Emailto) { $MailMessage.To.add($($To)) }
                        $MailMessage.IsBodyHtml = 1
                        $MailMessage.Subject = $EmailSubject
                        $MailMessage.Body = $Body

                        
                        $MailMessage.BodyEncoding = [System.Text.Encoding]::$EmailEncoding
                        $MailMessage.SubjectEncoding = [System.Text.Encoding]::$EmailEncoding


                        
                        $SmtpClient.Send($MailMessage)
                        Write-Verbose -Message "[PROCESS] $item - Email Sent."


                        
                        Write-Verbose -Message "[PROCESS] $item - Exporting the current membership to $StateFile"
                        $Members | Export-csv -Path (Join-Path -Path $ScriptPathOutput -ChildPath $StateFile) -NoTypeInformation -Encoding Unicode

                        
                        IF ($PSBoundParameters['HTMLLog'])
                        {
                            
                            $ScriptPathHTML = $ScriptPath + "\HTML"
                            IF (!(Test-Path -Path $ScriptPathHTML))
                            {
                                Write-Verbose -Message "[PROCESS] Creating the HTML Folder : $ScriptPathHTML"
                                New-Item -Path $ScriptPathHTML -ItemType Directory | Out-Null
                            }

                            
                            $HTMLFileName = "$($DomainName)_$($RealGroupName)-$(Get-Date -Format 'yyyyMMdd_HHmmss').html"

                            
                            $Body | Out-File -FilePath (Join-Path -Path $ScriptPathHTML -ChildPath $HTMLFileName)
                        }


                    }
                    ELSE { Write-Verbose -Message "[PROCESS] $item - No Change" }

                }
                ELSE
                {
                    Write-Verbose -message "[PROCESS] $item - Group can't be found"
                    
                    
                    
                    

                }
            }
            CATCH
            {
                Write-Warning -Message "[PROCESS] Something went wrong"
                
                Write-Warning -Message $Error[0]

                
                if ($ErrorProcessGetQADGroup) { Write-warning -Message "[PROCESS] QUEST AD - Error When querying the group $item in Active Directory" }
                if ($ErrorProcessGetQADGroupMember) { Write-warning -Message "[PROCESS] QUEST AD - Error When querying the group $item members in Active Directory" }

                
                if ($ErrorProcessGetADGroup) { Write-warning -Message "[PROCESS] AD MODULE - Error When querying the group $item in Active Directory" }
                if ($ErrorProcessGetADGroupMember) { Write-warning -Message "[PROCESS] AD MODULE - Error When querying the group $item members in Active Directory" }

                
                if ($ErrorProcessImportCSV) { Write-warning -Message "[PROCESS] Error Importing $StateFile" }
                if ($ErrorProcessCompareObject) { Write-warning -Message "[PROCESS] Error when comparing" }
                if ($ErrorProcessImportCSVChangeHistory) { Write-warning -Message "[PROCESS] Error Importing $file" }

                Write-Warning -Message $error[0].exception.Message
            }
        }
    }
    CATCH
    {
        Write-Warning -Message "[PROCESS] Something wrong happened"
        
        Write-Warning -Message $error[0]
    }

}
END
{
    Write-Verbose -message "[END] Script Completed"
}
