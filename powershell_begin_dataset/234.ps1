function Remove-PSObjectEmptyOrNullProperty
{

    PARAM (
        $PSObject)
    PROCESS
    {
        $PsObject.psobject.Properties |
        Where-Object { -not $_.value } |
        ForEach-Object {
            $PsObject.psobject.Properties.Remove($_.name)
        }
    }
}