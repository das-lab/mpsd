









function ConvertTo-Encoding ([string]$From, [string]$To){  
        Begin{  
            $encFrom = [System.Text.Encoding]::GetEncoding($from)  
            $encTo = [System.Text.Encoding]::GetEncoding($to)  
        }  
        Process{  
            $bytes = $encTo.GetBytes($_)  
            $bytes = [System.Text.Encoding]::Convert($encFrom, $encTo, $bytes)  
            $encTo.GetString($bytes)  
        }  
    }  

if (Get-Command Get-DnsClientCache -ErrorAction SilentlyContinue) {
    Get-DnsClientCache | Select-Object TimeToLIve, Caption, Description, 
        ElementName, InstanceId, Data, DataLength, Entry, Name, Section, 
        Status, Type
} else {
	$current_lang = Get-Culture
	if ($current_lang.TwoLetterISOLanguageName -eq "en") {
		$o = "" | Select-Object TimeToLive, Caption, Description, ElementName,
			InstanceID, Data, DataLength, Entry, Name, Section, Status, Type
		
		$(& ipconfig /displaydns | Select-Object -Skip 3 | % { $_.Trim() }) | % { 
			switch -Regex ($_) {
				"-----------" {
				}
				"Record Name[\s|\.]+:\s(?<RecordName>.*$)" {
					$Name = ($matches['RecordName'])
				} 
				"Record Type[\s|\.]+:\s(?<RecordType>.*$)" {
					$RecordType = ($matches['RecordType'])
				}
				"Time To Live[\s|\.]+:\s(?<TTL>.*$)" {
					$TTL = ($matches['TTL'])
				}
				"Data Length[\s|\.]+:\s(?<DataLength>.*$)" {
					$DataLength = ($matches['DataLength'])
				}
				"Section[\s|\.]+:\s(?<Section>.*$)" {
					$Section = ($matches['Section'])
				}
				"(?<Type>[A-Za-z()\s]+)\s.*Record[\s|\.]+:\s(?<Data>.*$)" {
					$Type,$Data = ($matches['Type'],$matches['Data'])
					$o.TimeToLive  = $TTL
					$o.Caption     = ""
					$o.Description = ""
					$o.ElementName = ""
					$o.InstanceId  = ""
					$o.Data        = $Data
					$o.DataLength  = $DataLength
					$o.Entry       = $Entry
					$o.Name        = $Name
					$o.Section     = $Section
					$o.Status      = ""
					$o.Type        = $Type
					$o
				}
				"^$" {
					$o = "" | Select-Object TimeToLive, Caption, Description, ElementName,
					InstanceID, Data, DataLength, Entry, Name, Section, Status, Type
				}
				default {
					$Entry = $_
				}
			}
        }
    }
	if ($current_lang.TwoLetterISOLanguageName -eq "ru") {
		$o = "" | Select-Object TimeToLive, Caption, Description, ElementName,
			InstanceID, Data, DataLength, Entry, Name, Section, Status, Type
		
		$(& ipconfig /displaydns | ConvertTo-Encoding cp866 windows-1251 | Select-Object -Skip 3 | % { $_.Trim() }) | % { 
			switch -Regex ($_) {
				"-----------" {
				}
				"Имя записи[\s|\.]+:\s(?<RecordName>.*$)" {
					$Name = ($matches['RecordName'])
				} 
				"Тип записи[\s|\.]+:\s(?<RecordType>.*$)" {
					$RecordType = ($matches['RecordType'])
				}
				"Срок жизни[\s|\.]+:\s(?<TTL>.*$)" {
					$TTL = ($matches['TTL'])
				}
				"Длина данных[\s|\.]+:\s(?<DataLength>.*$)" {
					$DataLength = ($matches['DataLength'])
				}
				"Раздел[\s|\.]+:\s(?<Section>.*$)" {
					$Section = ($matches['Section'])
				}
				"(?<Type>[^\s]+\s+\([^\)]+\))[\s\.]+:\s(?<Data>.*$)" {
					$Type,$Data = ($matches['Type'],$matches['Data'])
					$o.TimeToLive  = $TTL
					$o.Caption     = ""
					$o.Description = ""
					$o.ElementName = ""
					$o.InstanceId  = ""
					$o.Data        = $Data
					$o.DataLength  = $DataLength
					$o.Entry       = $Entry
					$o.Name        = $Name
					$o.Section     = $Section
					$o.Status      = ""
					$o.Type        = $Type
					$o
				}
				"^$" {
					$o = "" | Select-Object TimeToLive, Caption, Description, ElementName,
					InstanceID, Data, DataLength, Entry, Name, Section, Status, Type
				}
				default {
					$Entry = $_
				}
			}
        }			
	}
}


