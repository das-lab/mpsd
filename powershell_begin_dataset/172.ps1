function View-Cats
{
	
    Param(
        [int]$refreshtime=5
    )
    $IE = new-object -ComObject internetexplorer.application
    $IE.visible = $true
    $IE.FullScreen = $true
    $shell = New-Object -ComObject wscript.shell
    $shell.AppActivate("Internet Explorer")

    while($true){
        $request = Invoke-WebRequest -Uri "http://thecatapi.com/api/images/get" -Method get
        $IE.Navigate($request.BaseResponse.ResponseUri.AbsoluteUri)
        Start-Sleep -Seconds $refreshtime
    }
}
