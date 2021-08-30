






param([string]$path=$(throw 'You must provide a path to a file to export the commands to.'))

gcm -type Alias, Function, Filter, Cmdlet, ExternalScript | Sort CommandType, Name | Export-Clixml $path