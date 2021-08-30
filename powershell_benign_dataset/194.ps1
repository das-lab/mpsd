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