


$ErrorActionPreference = "silentlycontinue"
$Excel = New-Object -ComObject Excel.Application
$Excel.visible = $False
$Excel.DisplayAlerts = $false
$ExcelWorkbooks = $Excel.Workbooks.Add()
$Sheet = $ExcelWorkbooks.Worksheets.Item(1)



$date = ( get-date ).ToString('yyyy/MM/dd')
$save = "E:\Dexma\Logs\DatabaseBackup_Report.xls"


$intRow = 1





foreach ($instance in get-content "\\xmonitor11\Dexma\Data\ServerLists\SMC_IMP.txt")
{

    $Sheet.Cells.Item($intRow,1) = "INSTANCE NAME:"
        $Sheet.Cells.Item($intRow,2) = $instance
        $Sheet.Cells.Item($intRow,1).Font.Bold = $True
        $Sheet.Cells.Item($intRow,2).Font.Bold = $True

        $intRow++

        $Sheet.Cells.Item($intRow,1) = "DATABASE NAME"
        $Sheet.Cells.Item($intRow,2) = "LAST FULL BACKUP"
        $Sheet.Cells.Item($intRow,3) = "LAST LOG BACKUP"
        $Sheet.Cells.Item($intRow,4) = "FULL BACKUP AGE(DAYS)"
        $Sheet.Cells.Item($intRow,5) = "LOG BACKUP AGE(HOURS)"

    
        for ($col = 1; $col -le 5; $col++)
    {
        $Sheet.Cells.Item($intRow,$col).Font.Bold = $True
            $Sheet.Cells.Item($intRow,$col).Interior.ColorIndex = 50
            $Sheet.Cells.Item($intRow,$col).Font.ColorIndex = 36
    }

    $intRow++
    
    
        [System.Reflection.Assembly]::LoadWithPartialName('Microsoft.SqlServer.SMO') | out-null

    
    $s = New-Object ('Microsoft.SqlServer.Management.Smo.Server') $instance

    $dbs = $s.Databases
    
    ForEach ($db in $dbs)
    {
        if ($db.Name -ne "tempdb") 
        {
			
            $NumDaysSinceLastFullBackup = ((Get-Date) - $db.LastBackupDate).Days
    		
            $NumDaysSinceLastLogBackup = ((Get-Date) - $db.LastLogBackupDate).TotalHours
            if($db.LastBackupDate -eq "1/1/2005 12:00 AM")
			
			
            {
                $fullBackupDate="Never been backed up"
                $fgColor3="red"
            }
            else
            {
                $fullBackupDate="{0:g}" -f $db.LastBackupDate
            }

            $Sheet.Cells.Item($intRow, 1) = $db.Name
            $Sheet.Cells.Item($intRow, 2) = $fullBackupDate
            $fgColor3="green"

    
                if ($db.RecoveryModel.Tostring() -eq "SIMPLE")
            {
                $logBackupDate="N/A"
                $NumDaysSinceLastLogBackup="N/A"
            }
            else
            {
                if($db.LastLogBackupDate -eq "1/1/2011 12:00 AM")
                {
                    $logBackupDate="Never been backed up"
                }
                else
                {
                    $logBackupDate= "{0:g2}" -f $db.LastLogBackupDate
                }
            }
            $Sheet.Cells.Item($intRow, 3) = $logBackupDate

    
                if ($NumDaysSinceLastFullBackup -gt 0)
            {
                $fgColor = 3
            }
            else
            {
                $fgColor = 50
            }

            $Sheet.Cells.Item($intRow, 4) = $NumDaysSinceLastFullBackup
            $Sheet.Cells.item($intRow, 4).Interior.ColorIndex = $fgColor
            $Sheet.Cells.Item($intRow, 5) = $NumDaysSinceLastLogBackup
            $intRow ++
        }
    }
    $intRow ++
}


$Sheet.UsedRange.EntireColumn.AutoFit()
$ExcelWorkbooks.SaveAs($save)
$Excel.quit()
CLS


$mail = New-Object System.Net.Mail.MailMessage
$att = new-object Net.Mail.Attachment($save)
$mail.From = "mmessano@dexma.com"
$mail.To.Add("mmessano@dexma.com")
$mail.Subject = "Database Backup Report for all SQL servers on $date "
$mail.Body = "This mail gives us detailed information for all the database backups which are scheduled to run every day. Please review the attached Excel report every day and fix the failed backups which are marked in Red and make sure the Full Backup Age(DAYS) is Zero."
$mail.Attachments.Add($att)
$smtp = New-Object System.Net.Mail.SmtpClient("outbound.smtp.dexma.com")
$smtp.Send($mail)
