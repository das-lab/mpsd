Function Update-ServiceNowDateTimeField {
    

    [OutputType([PSCustomObject[]])]
    [CmdletBinding(SupportsShouldProcess)]
    param (
        
        [Parameter(
            Mandatory         = $true,
            ValueFromPipeline = $true
        )]
        [ValidateNotNullOrEmpty()]
        [PSCustomObject[]]$Result
    )

	begin {}
	process	{
		
        $ConvertToDateField = @('closed_at', 'expected_start', 'follow_up', 'opened_at', 'sys_created_on', 'sys_updated_on', 'work_end', 'work_start')

        If ($PSCmdlet.ShouldProcess($SearchBase,$MyInvocation.MyCommand)) {
        ForEach ($SNResult in $Result) {
                ForEach ($Property in $ConvertToDateField) {
                    If (-not [string]::IsNullOrEmpty($SNResult.$Property)) {
                        Try {
                            
                            $CultureDateTimeFormat = (Get-Culture).DateTimeFormat
                            $DateFormat = $CultureDateTimeFormat.ShortDatePattern
                            $TimeFormat = $CultureDateTimeFormat.LongTimePattern
                            $DateTimeFormat = "$DateFormat $TimeFormat"
                            $SNResult.$Property = [DateTime]::ParseExact($($SNResult.$Property), $DateTimeFormat, [System.Globalization.DateTimeFormatInfo]::InvariantInfo, [System.Globalization.DateTimeStyles]::None)
                        }
                        Catch {
                            Try {
                                
                                $DateTimeFormat = 'yyyy-MM-dd HH:mm:ss'
                                $SNResult.$Property = [DateTime]::ParseExact($($SNResult.$Property), $DateTimeFormat, [System.Globalization.DateTimeFormatInfo]::InvariantInfo, [System.Globalization.DateTimeStyles]::None)
                            }
                            Catch {
                                
                                $null = 'Code to make PSSA happy when we just want to suppress errors'
                            }
                        }
                    }
                }
            }
        }

        $Result
    }
	end {}
}
