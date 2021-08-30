function Get-O365CalendarEvent
{


    [CmdletBinding()]
    param
    (
        [System.String]$EmailAddress,

        [System.datetime]$StartDateTime = (Get-Date),

        [System.datetime]$EndDateTime = ((Get-Date).adddays(7)),

        [System.Management.Automation.Credential()]
        [pscredential]
        $Credential = [System.Management.Automation.PSCredential]::Empty,

        [ValidateNotNullOrEmpty()]
        [ValidateRange(1, 50)]
        $PageResult = '10',

        [ValidateSet(
            'Afghanistan Standard Time',
            'Alaskan Standard Time',
            'Arab Standard Time',
            'Arabian Standard Time',
            'Arabic Standard Time',
            'Atlantic Standard Time',
            'AUS Central Standard Time',
            'AUS Eastern Standard Time',
            'Azerbaijan Standard Time',
            'Azores Standard Time',
            'Canada Central Standard Time',
            'Cape Verde Standard Time',
            'Caucasus Standard Time',
            'Cen. Australia Standard Time',
            'Central America Standard Time',
            'Central Asia Standard Time',
            'Central Brazilian Standard Time',
            'Central Europe Standard Time',
            'Central European Standard Time',
            'Central Pacific Standard Time',
            'Central Standard Time',
            'Central Standard Time (Mexico)',
            'China Standard Time',
            'Dateline Standard Time',
            'E. Africa Standard Time',
            'E. Australia Standard Time',
            'E. Europe Standard Time',
            'E. South America Standard Time',
            'Eastern Standard Time',
            'Egypt Standard Time',
            'Ekaterinburg Standard Time',
            'Fiji Standard Time', 'FLE Standard Time',
            'Georgian Standard Time',
            'GMT Standard Time',
            'Greenland Standard Time',
            'Greenwich Standard Time',
            'GTB Standard Time',
            'Hawaiian Standard Time',
            'India Standard Time',
            'Iran Standard Time',
            'Israel Standard Time',
            'Korea Standard Time',
            'Mid-Atlantic Standard Time',
            'Mountain Standard Time',
            'Mountain Standard Time (Mexico)',
            'Myanmar Standard Time',
            'N. Central Asia Standard Time',
            'Namibia Standard Time',
            'Nepal Standard Time',
            'New Zealand Standard Time',
            'Newfoundland Standard Time',
            'North Asia East Standard Time',
            'North Asia Standard Time',
            'Pacific SA Standard Time',
            'Pacific Standard Time',
            'Romance Standard Time',
            'Russian Standard Time',
            'SA Eastern Standard Time',
            'SA Pacific Standard Time',
            'SA Western Standard Time',
            'Samoa Standard Time',
            'SE Asia Standard Time',
            'Singapore Standard Time',
            'South Africa Standard Time',
            'Sri Lanka Standard Time',
            'Taipei Standard Time',
            'Tasmania Standard Time',
            'Tokyo Standard Time',
            'Tonga Standard Time',
            'US Eastern Standard Time',
            'US Mountain Standard Time',
            'Vladivostok Standard Time',
            'W. Australia Standard Time',
            'W. Central Africa Standard Time',
            'W. Europe Standard Time',
            'West Asia Standard Time',
            'West Pacific Standard Time',
            'Yakutsk Standard Time'
        )]
        [System.String]$Timezone
    )

    PROCESS
    {
        TRY
        {
            $FunctionName = (Get-Variable -Name MyInvocation -Scope 0 -ValueOnly).MyCommand

            Write-Verbose -Message "[$FunctionName] Create splatting"
            $Splatting = @{
                Credential = $Credential
                Uri = "https://outlook.office365.com/api/v1.0/users/$EmailAddress/calendarview?startDateTime=$StartDateTime&endDateTime=$($EndDateTime)&`$top=$PageResult"
            }


            if ($TimeZone)
            {
                Write-Verbose -Message "[$FunctionName] Add TimeZone"
                $headers = New-Object -TypeName 'System.Collections.Generic.Dictionary[[String],[String]]'
                $headers.Add('Prefer', "outlook.timezone=`"$TimeZone`"")
                $Splatting.Add('Headers', $headers)
            }
            if (-not $PSBoundParameters['EmailAddress'])
            {
                Write-Verbose -Message "[$FunctionName] EmailAddress not specified, updating URI"
                
                $Splatting.Uri = "https://outlook.office365.com/api/v1.0/me/calendarview?startDateTime=$StartDateTime&endDateTime=$($EndDateTime)&`$top=$PageResult"
            }
            Write-Verbose -Message "[$FunctionName] URI: $($Splatting.Uri)"
            Invoke-RestMethod @Splatting -ErrorAction Stop | Select-Object -ExpandProperty Value
        }
        CATCH
        {
            $PSCmdlet.ThrowTerminatingError($_)
        }
    }
}