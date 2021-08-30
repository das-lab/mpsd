







Import-Module Docker


Pull-ContainerImage hello-world 



Run-ContainerImage hello-world 



cls


Get-Container | Where-Object State -eq "exited"


Get-Container | Where-Object State -eq "exited" | Remove-Container


Remove-ContainerImage hello-world


Get-ContainerImage
