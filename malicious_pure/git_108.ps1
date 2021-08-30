function Invoke-RunAs {

    [CmdletBinding()]Param (
    [Parameter(
        ValueFromPipeline=$True)]
        [String]$username,
    [Parameter(
        ValueFromPipeline=$True)]
        [String]$password,
    [Parameter(
        ValueFromPipeline=$True)]
        [String]$domain,
    [Parameter(
        ValueFromPipeline=$True)]
        [String]$cmd,
    [Parameter()]
        [String]$Arguments,
    [Parameter()]
        [Switch]$ShowWindow
    )
    PROCESS {
        try{
            $startinfo = new-object System.Diagnostics.ProcessStartInfo

            $startinfo.FileName = $cmd
            $startinfo.UseShellExecute = $false

            if(-not ($ShowWindow)) {
                $startinfo.CreateNoWindow = $True
                $startinfo.WindowStyle = "Hidden"
            }

            if($Arguments) {
                $startinfo.Arguments = $Arguments
            }

            if($UserName) {
                
                $startinfo.UserName = $username
                $sec_password = convertto-securestring $password -asplaintext -force
                $startinfo.Password = $sec_password
                $startinfo.Domain = $domain
            }
            
            [System.Diagnostics.Process]::Start($startinfo) | out-string
        }
        catch {
            "[!] Error in runas: $_"
        }

    }
}
