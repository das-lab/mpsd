
















$groupId = " FILL ME IN "           
$datasetId = " FILL ME IN "         




Login-PowerBI


$uri = "groups/$groupId/datasets/$datasetId/Default.TakeOver"


try { 
    Invoke-PowerBIRestMethod -Url $uri -Method Post

    
    if (-Not $?)
    {
        $errmsg = Resolve-PowerBIError -Last
        $errmsg.Message
    }
} catch {

    $errmsg = Resolve-PowerBIError -Last
    $errmsg.Message
}