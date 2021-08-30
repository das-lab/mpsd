
[CmdletBinding()]
param (
	[string[]]$OrderNumber,
	[string]$SpSiteUrl = 'https://sharepointsite.domain.local',
	[ValidateScript({
		if (Test-Connection -ComputerName $_ -Quiet -Count 2) {
			throw "The Sharepoint server '$SpServer' appears offline"
		} else {
			$true
		}
	})]
	[string]$SpServer = 'spserver.domain.local',
	[ValidateScript({
		if (Test-Path -Path ($_ | Split-Path -Parent) -PathType Container) {
			throw "The log file folder '$($_ | Split-Path -Parent)' does not exist"
		} else {
			$true
		}
	})]
	[string]$LogFilePath = 'C:\OrderAutomation\ActivityLog.log',
	[ValidateScript({
		if (!(Test-Path -Path $_ -PathType Container)) {
			throw "The PDF order folder path '$($_)' does not exist"
		} else {
			$true
		}
	})]
    [string]$PdfOrderFolderPath = '\\sharepoint.domain.local@SSL\DavWWWRoot\documents\DellDoc',
    [ValidateScript({
		if (!(Test-Path -Path $_ -PathType Leaf)) {
			throw "The orders file '$($_)' does not exist"
		} else {
			$true
		}
	})]
	[string]$DellOrdersFilePath = "\\$SpServer\psfiles\orders.csv",
    [ValidateScript({
		if (!(Test-Path -Path $_ -PathType Container)) {
			throw "The Dell orders archive folder '$($_)' does not exist"
		} else {
			$true
		}
	})]
	[string]$DellOrdersArchiveFolderPath = "\\$SpServer\psfiles\DellOrdersArchive",
	[string]$PdfOrderArchiveFolderPath = "\\sharepoint.domain.local@SSL\DavWWWRoot\documents\DellDoc\$((Get-Date).Year)\orderbevestigingen",
	[ValidateScript({
		if (!(Test-Path -Path $_ -PathType Container)) {
			throw "The PDF invoice folder path '$($_)' does not exist"
		} else {
			$true
		}
	})]
	[string]$PdfInvoiceFolderPath = '\\sharepoint.domain.local@SSL\DavWWWRoot\documents\DellDoc',
	[string]$PdfInvoiceArchiveFolderPath = "\\sharepoint.domain.local@SSL\DavWWWRoot\documents\DellDoc\$((Get-Date).Year)\facturen",
	[ValidateScript({
		if (!(Test-Path -Path $_ -PathType Leaf)) {
			throw "The Sharepoint remoting credential file '$($_)' does not exist"
		} else {
			$true
		}
	})]
	[string]$SpServerRemoteCredFilePath = 'C:\OrderAutomation\sa_automationcred.xml',
	[ValidateScript({
		if (!(Test-Path -Path $_ -PathType Leaf)) {
			throw "The Dell website credential file '$($_)' does not exist"
		} else {
			$true
		}
	})]
	[string]$SDellSiteCredFilePath = 'C:\OrderAutomation\dellwebsite_cred.xml',
    [ValidateScript({
		if (!(Test-Path -Path $_ -PathType Leaf)) {
			throw "The Sharepoint module file '$($_)' does not exist"
		} else {
			$true
		}
	})]
	[string]$PdfDocUrlRootUrl = "$SpSiteUrl/documents/DellDOC",
	[string]$SpModuleFilePath = "C:\OrderAutomation\Sharepoint.psm1",
	[ValidateSet('PDFOrder', 'PDFInvoice', 'DellOrder', 'All')]
	[string[]]$SyncActivities = 'All'
)
begin {
    $ErrorActionPreference = 'Stop'
	function Write-Log {
		
		[CmdletBinding()]
		param (
			[Parameter(Mandatory = $true)]
			[string]$Message,
			[ValidateSet(1, 2, 3)]
			[int]$LogLevel = 1
		)
		
		try {
			[pscustomobject]@{
				'Time' = Get-Date
				'Message' = $Message
				
				'Severity' = $LogLevel
			} | Export-Csv -Path $LogFilePath -Append -NoTypeInformation
		} catch {
			Write-Error $_.Exception.Message
			$false
		}
	}
	function Check-Process {
		
		[CmdletBinding()]
		param (
			[Parameter()]
			[System.Diagnostics.Process]$Process
		)
		process {
			try {
				if (@(0, 3010) -notcontains $Process.ExitCode) {
					Write-Log -Message "Process ID $($Process.Id) failed. Return value was $($Process.ExitCode)" -LogLevel '2'
					$false
				} else {
					Write-Log -Message "Process ID $($Process.Id) exited with successfull exit code '$($Process.ExitCode)'."
					$true
				}
			} catch {
				Write-Log -Message "Error: $($_.Exception.Message) - Line Number: $($_.InvocationInfo.ScriptLineNumber)" -LogLevel '3'
				$false
			}
		}
	}
	function Test-PsRemoting {
		param (
			[Parameter(Mandatory = $true)]
			$Computername
		)
		
		try {
			$errorActionPreference = "Stop"
			$result = Invoke-Command -ComputerName $computername { 1 }
		} catch {
			return $false
		}
		
		
		
		if ($result -ne 1) {
			Write-Verbose "Remoting to $computerName returned an unexpected result."
			return $false
		}
		$true
	}
	function Get-DellOrder {
		
		[CmdletBinding()]
		param ()
        begin {
            
            
            $ExcludedOrders = '104682878','104679730','104669658','104669580','104664833','104720177'
        }
		process {
			try {
                $AllOrders = Import-Csv -Path $DellOrdersFilePath | where {$ExcludedOrders -notcontains $_.Bestelnummer}
                Write-Log "Found $($AllOrders.Count) total Dell orders"
				$Orders = $AllOrders | where {$ExcludedOrders -notcontains $_.Bestelnummer}
                Write-Log "Validating the order file $DellOrdersFilePath..."
                $ValidFields = 'Datum van bestelling','Status','Geschatte leveringsdatum','Bestelnummer','Nummer van inkooporder'
                if (Compare-Object -DifferenceObject ($Orders[0].Psobject.Properties.Name) -ReferenceObject $ValidFields) {
                    throw "Invalid fields found in orders file $DellOrdersFilePath"
                }
                $ValidOrders = @()
                foreach ($Order in $Orders) {
                    if ($Order.'Nummer van inkooporder' -notmatch '^\d+$') {
                        Write-Log "The order number '$($Order.Bestelnummer)' is invalid. Removed from order list to sync" -LogLevel 2
                    } else {
                        $ValidOrders += $Order
                    }
                }
                $ValidOrders
			} catch {
				Write-Log -Message "Error: $($_.Exception.Message) - Line Number: $($_.InvocationInfo.ScriptLineNumber)" -LogLevel '3'
				$false
			}
		}
	}
    function Archive-DellOrder {
		
		[CmdletBinding()]
		param ()
		process {
			try {
                
                $FileNames = Get-ChildItem -Path $DellOrdersArchiveFolderPath | Select-Object -ExpandProperty Basename
                if ($FileNames) {
                    
                    [int]$LastInc = $FileNames | foreach {[int]$_.Split('_')[1]} | Sort-Object -Descending | Select-Object -First 1
                    $NextInc = $LastInc + 1
				    $FileName = "$((Get-Item $DellOrdersFilePath).BaseName)_$NextInc.csv"
                    if (Test-Path "$DellOrdersArchiveFolderPath\$FileName") {
                        throw "Unrecognized order archive file '$FileName' in $DellOrdersArchiveFolderPath. Unable to archive order file."
                    } else {
                        Move-Item -Path $DellOrdersFilePath  -Destination "$DellOrdersArchiveFolderPath\$FileName"
                        Write-Log "Succesfully moved $DellOrdersFilePath to create archive file $FileName"
                    }
                } else {
                    $FileName = "$((Get-Item $DellOrdersFilePath).BaseName)_1.csv"
                    Move-Item -Path $DellOrdersFilePath  -Destination "$DellOrdersArchiveFolderPath\$FileName"
                    Write-Log "Succesfully moved $DellOrdersFilePath to create archive file $FileName"
                }
                
				$true
			} catch {
				Write-Log -Message "Error: $($_.Exception.Message) - Line Number: $($_.InvocationInfo.ScriptLineNumber)" -LogLevel '3'
				$false
			}
		}
	}
	function Get-PdfOrder {
		
		[CmdletBinding()]
		param (
			[string[]]$OrderNumber
		)
		process {
			try {
				
				if ($OrderNumber) {
					foreach ($Order in $OrderNumber) {
						$Filter = "Order_NL_REL_ENTP_$($Order)_\d{4}-\d{2}-\d{2}.pdf"
						$PdfOrders += Get-ChildItem -Path $PdfOrderFolderPath | where { $_.Name -match $Filter }
					}
				} else {
					$Filter = 'Order_NL_REL_ENTP_\d+_\d{4}-\d{2}-\d{2}.pdf'
					$PdfOrders = Get-ChildItem -Path $PdfOrderFolderPath | where { $_.Name -match $Filter }
				}
				if (!$PdfOrders) {
					Write-Log 'No PDF orders found'
				} else {
					foreach ($PdfOrder in $PdfOrders) {
						try {
							
							$TextFileOrder = Convert-PdfToText -PdfFilePath $PdfOrder.FullName -Force
							if (!$TextFileOrder) {
								throw "Unable to convert order PDF file $($PdfOrder.FullName) to a text file"
							} else {
								Write-Log -Message "Successfully converted PDF file $($PdfOrder.FullName) to text"
								Write-Log -Message "Parsing text file for required fields with regex"
								
								
								$Order = @{ }
								$Order.FilePath = $PdfOrder.FullName
								$TextOrder = Get-Content -Path $TextFileOrder.FullName -Raw
								Remove-Item -Path $TextFileOrder.FullName -Force
								$Order.PONumber = [regex]::Match($TextOrder, 'Uw referentie (\d+)').Groups[1].Value
								if (!$Order.PONumber) {
									throw 'Unable to parse PO number from PDF order'
								}
								$Order.Offertenummer = [regex]::Match($TextOrder, 'Offertenummer (.*)\s').Groups[1].Value
								if (!$Order.Offertenummer) {
									Write-Log -Message 'Unable to parse Offertenummer from PDF order' -LogLevel '2'
								}
								$Order.OrderNumber = [regex]::Match($TextOrder, 'Ordernummer: (\d+)').Groups[1].Value
								if (!$Order.OrderNumber) {
									throw 'Unable to parse order number from PDF order'
								}
								$Order.OrderDate = [regex]::Match($TextOrder, 'Orderdatum: (\d{1,2}-\d{1,2}-\d{4})').Groups[1].Value
								if (!$Order.OrderDate) {
									throw 'Unable to parse order date from PDF order'
								}
								$Order.ShippingCost = [regex]::Match($TextOrder, 'Transportkosten (.+)\s\s').Groups[1].Value
								$Order.SubTotal = [regex]::Match($TextOrder, 'Subtotaal (.*)\s\s').Groups[1].Value
								if (!$Order.ShippingCost -or !$Order.Subtotal) {
									throw 'Unable to parse delivery cost from PDF order'
								}
								$Order.TotalCost = [System.Convert]::ToDecimal($Order.Subtotal, $culture.NumberFormat) + [System.Convert]::ToDecimal($Order.ShippingCost, $culture.NumberFormat)
								Write-Log -Message "Successfully parsed all fields from text file $($TextFileOrder.Fullname)"
								[pscustomobject]$Order
							}
						} catch {
							Write-Log -Message "Error: $($_.Exception.Message) - Line Number: $($_.InvocationInfo.ScriptLineNumber)" -LogLevel '3'
						}
					}
				}
			} catch {
				Write-Log -Message "Error: $($_.Exception.Message) - Line Number: $($_.InvocationInfo.ScriptLineNumber)" -LogLevel '3'
				$false
			}
		}
	}
	function Archive-Pdf {
		
		[CmdletBinding()]
		[OutputType('[bool]')]
		param (
			[Parameter(Mandatory)]
			[ValidateScript({
				if (!(Test-Path -Path $_ -PathType Leaf)) {
					throw "The PDF file path '$($_)' does not exist"
				} else {
					$true
				}
			})]
			[string]$FilePath,
			[Parameter(Mandatory)]
			[string]$DestinationPath,
			[switch]$Force
		)
		process {
			try {
				if (!(Test-Path -Path $DestinationPath -PathType Container)) {
					if ($Force) {
						New-Item -Path $DestinationPath -Type Container | Out-Null
					} else {
						throw "The archive folder path $DestinationPath does not exist and -Force was not used to create a new one"	
					}
				}
				Move-Item -Path $FilePath -Destination $DestinationPath
				$true
			} catch {
				Write-Log -Message "Error: $($_.Exception.Message) - Line Number: $($_.InvocationInfo.ScriptLineNumber)" -LogLevel '3'
				$false
			}
		}
	}	
	function Convert-PdfToText {
		
		[CmdletBinding()]
		[OutputType('System.IO.FileSystemInfo')]
		param (
			[Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
			[ValidatePattern('.*\.pdf$')]
			[Alias('FullName')]
			[string]$PdfFilePath,
			[ValidatePattern('.*\.exe$')]
			[ValidateScript({
				if (!(Test-Path -Path $_ -PathType Leaf)) {
					throw "The PDF converter EXE '$($_)' cannot be found"
				} else {
					$true
				}
			})]
			[string]$PdfConverterFilePath = 'C:\OrderAutomation\bin\pdftotext.exe',
			[switch]$Force
		)
		process {
			try {
				$TxtOutputFilePath = "$($PdfFilePath | Split-Path -Parent)\$(($PdfFilePath | Split-Path -Leaf) -replace '\.pdf$','.txt')"
				if (!$Force -and (Test-Path -Path $TxtOutputFilePath)) {
					throw "The text file $TxtOutputFilePath already exists and the -Force param was not used.  Will not overwrite existing file"
				}
				$Result = Start-Process -FilePath $PdfConverterFilePath -ArgumentList "-raw `"$PdfFilePath`"" -NoNewWindow -Wait -PassThru
				if (Check-Process -Process $Result) {
					Get-Item $TxtOutputFilePath
				} else {
					$false
				}
			} catch {
				Write-Log -Message "Error: $($_.Exception.Message) - Line Number: $($_.InvocationInfo.ScriptLineNumber)" -LogLevel '3'
				$false
			}
		}
	}
	function Send-Alert {
		
		[CmdletBinding()]
		[OutputType('[bool]')]
		param (
			[string]$ToEmailAddress = 'helpdesk@domain.local',
			[string]$FromEmailAddress = 'automation@domain.local',
			[string]$FromDisplayName = 'Order Handling Automation',
			[Parameter(Mandatory)]
			[string]$EmailSubject,
			[Parameter(Mandatory)]
			[string]$EmailBody,
			[string]$SmtpServer = 'antispam.domain.local'
		)
		process {
			try {
				$Params = @{
					'From' = "$FromDisplayName <$FromEmailAddress>"
					'To' = $ToEmailAddress
					'Subject' = $EmailSubject
					'SmtpServer' = $SmtpServer
					'Body' = $EmailBody
				}
				Send-MailMessage @Params
				$true
			} catch {
				Write-Log -Message "Error: $($_.Exception.Message) - Line Number: $($_.InvocationInfo.ScriptLineNumber)" -LogLevel '3'
				$false
			}
		}
	}
	function Get-PdfInvoice {
		
		[CmdletBinding(DefaultParameterSetName = 'InvoiceNumber')]
		param (
			[Parameter(ParameterSetName = 'InvoiceNumber')]
			[string[]]$InvoiceNumber,
			[Parameter(ParameterSetName = 'OrderNumber')]
			[string[]]$OrderNumber
		)
		process {
			try {
				
				if ($InvoiceNumber) {
					foreach ($Invoice in $InvoiceNumber) {
						$Filter = "Invoice_NL_REL_ENTP_$($Invoice)_\d{4}-\d{2}-\d{2}.pdf"
						$PdfInvoices += Get-ChildItem -Path $PdfInvoiceFolderPath | where { $_.Name -match $Filter }
					}
				} else {
					$Filter = 'Invoice_NL_REL_ENTP_\d+_\d{4}-\d{2}-\d{2}.pdf'
					$PdfInvoices = Get-ChildItem -Path $PdfInvoiceFolderPath | where { $_.Name -match $Filter }
				}
				if ($PdfInvoices) {
					Write-Log -Message "$($PdfInvoices.Count) PDF invoices found"
					foreach ($PdfInvoice in $PdfInvoices) {
						try {
							
							Write-Log -Message "Converting $($PdfInvoice.FullName) to text"
							$TextFileInvoice = $PdfInvoice | Convert-PdfToText -Force
							if (!$TextFileInvoice) {
								throw "Unable to convert invoice PDF file $($PdfInvoice.FullName) to a text file"
							} else {
								Write-Log -Message "Succesfully converted invoice PDF to text"
								
								$Invoice = @{ }
								$Invoice.FilePath = $PdfInvoice.FullName
								$TextInvoice = Get-Content -Path $TextFileInvoice.FullName -Raw
								Remove-Item -Path $TextFileInvoice.FullName -Force
								$Invoice.InvoiceNumber = [regex]::Match($TextInvoice, 'Factuurnummer: (\d+) ').Groups[1].Value
								if (!$Invoice.InvoiceNumber) {
									throw 'Unable to parse invoice number from PDF invoice'
								}
								$Invoice.OrderNumber = [regex]::Match($TextInvoice, 'Ordernummer: (\d+)').Groups[1].Value
								if (!$Invoice.OrderNumber) {
									throw 'Unable to parse order number from PDF invoice'
								} elseif ($OrderNumber) {
									if ($OrderNumber -contains $Invoice.OrderNumber) {
										[pscustomobject]$Invoice
									}
								} else {
									[pscustomobject]$Invoice
								}
							}
						} catch {
							Write-Log -Message "Error: $($_.Exception.Message) - Line Number: $($_.InvocationInfo.ScriptLineNumber)" -LogLevel '3'
							$false
						}
					}
				}
			} catch {
				Write-Log -Message "Error: $($_.Exception.Message) - Line Number: $($_.InvocationInfo.ScriptLineNumber)" -LogLevel '3'
				$false
			}
		}
	}
	function Get-RemoteSpPurchaseOrder ($PoNumber) {
		Invoke-Command -Session $ServerSession -ScriptBlock { Get-SpPurchaseOrder -PoNumber $using:PoNumber | Tee-Object -Variable PurchaseOrder }
	}	
	function New-RemoteSpOrder($PurchaseOrder,$OrderNumber,$TotalCost,$OrderDate) {
		Invoke-Command -Session $ServerSession -ScriptBlock {
			New-SpOrder -PurchaseOrder $PurchaseOrder -OrderNumber $using:OrderNumber -TotalCost $using:TotalCost -OrderDate $using:OrderDate -PassThru | Tee-Object -Variable Order
		}
	}
	function Set-RemoteSpOrder($InvoiceNumber, $PoNumber, $EstimatedDeliveryDate, $DeliveryStatus, $PdfAttachmentFileUrl) {
		$Params = @{
			'PassThru' = $true
		}
		
		if ($InvoiceNumber) {
			$Params.InvoiceNumber = $InvoiceNumber	
		}
		if ($PoNumber) {
			$Params.PoNumber = $PoNumber
		}
		if ($EstimatedDeliveryDate) {
			$Params.EstimatedDeliveryDate = $EstimatedDeliveryDate
		}
		if ($DeliveryStatus) {
			$Params.DeliveryStatus = $DeliveryStatus
		}
		if ($PdfAttachmentFileUrl) {
			$Params.PdfAttachmentFileUrl = $PdfAttachmentFileUrl
		}
		
		Invoke-Command -Session $ServerSession -ScriptBlock {
			$Params = $using:Params
			Set-SpOrder -Order $Order @Params | Tee-Object -Variable Order
		}
	}	
	function Get-RemoteSpOrder($OrderNumber) {
		Invoke-Command -Session $ServerSession -ScriptBlock {
			Get-SpOrder -OrderNumber $using:OrderNumber | Tee-Object -Variable Order
		}
	}	
	function Convert-LocalPathToUnc ($FilePath,$Computername) {
		$NewPath = $FilePath -replace (":", "$")
		
		if ($NewPath.EndsWith("\")) {
			$NewPath = [Text.RegularExpressions.Regex]::Replace($NewPath, "\\$", "")
		}
		"\\$Computername\$NewPath"
	}
	
	try {
		
		if (!(Test-PsRemoting -Computername $SpServer)) {
			throw "PS remoting on the Sharepoint server '$SpServer' is not enabled"
		} else {
			
			Write-Log "Setting up PS remoting session on $SpServer with $($Cred.username) credentials"
			$Cred = Import-Clixml -Path $SpServerRemoteCredFilePath
			$Credential = New-Object System.Management.Automation.PSCredential($Cred.username, $Cred.password)
			$ServerSession = New-PSSession -ComputerName $SpServer -Authentication CredSSP -Credential $Credential -ConfigurationName PS2
		}
		
		
		
		Write-Log "Copying Sharepoint module $SpModuleFilepath to Sharepoint server..."
		Copy-Item -Path $SpModuleFilePath -Destination "\\$SpServer\c$" -Force
		Write-Log 'Setting up global Sharepoint objects in remote session'
		Invoke-command -Session $ServerSession -ScriptBlock {
			Add-PSSnapin Microsoft.SharePoint.Powershell
			$global:SpSiteUrl = $using:SpSiteUrl
			$global:Site = new-object Microsoft.SharePoint.SPSite($SpSiteUrl)
			$global:SpDocSite = Get-SPWeb "$SpSiteUrl/documents"
			$global:SpPunchSite = Get-SPWeb "$SpSiteUrl/punch"
            $global:AllOrders = $SpPunchSite.Lists["Inkoop Items"].GetItems()
            Import-Module 'C:\Sharepoint.psm1'
		}
	} catch {
		Write-Log -Message "Error: $($_.Exception.Message) - Line Number: $($_.InvocationInfo.ScriptLineNumber)" -LogLevel '3'
		exit
	}
}
process {
	try {
		if (($SyncActivities -contains 'PDFOrder') -or ($SyncActivities -eq 'All')) {
			Write-Log "Retrieving any new PDF Dell orders in $PdfOrderFolderPath..."
			if ($OrderNumber) {
				$PdfOrders = Get-PdfOrder -OrderNumber $OrderNumber
			} else {
				$PdfOrders = Get-PdfOrder
			}
			if (!$PdfOrders) {
				if ($OrderNumber) {
					Write-Log -Message "No PDF orders found matching order number(s) $($OrderNumber -join ',')"
				}
			} else {
				Write-Log "$($PdfOrders.Count) PDF orders found to sync"
				
				foreach ($PdfOrder in $PdfOrders) {
					try {
						Write-Log "Getting Sharepoint purchase order for PO number $($PdfOrder.PoNumber)..."
						$SpPurchaseOrder = Get-RemoteSpPurchaseOrder -PoNumber $PdfOrder.PoNumber
						if (!$SpPurchaseOrder) {
							Send-Alert -EmailSubject 'Failed Sharepoint purchase order match' -EmailBody "Failed to find a matching Sharepoint purchase order for PDF order number $($PdfOrder.PoNumber)"
							Write-Log "Failed to retrieve a Sharepoint purchase order. Emailing notification" -LogLevel '3'
						} else {
							Write-Log "Successfully retrieved Sharepoint purchase order. Attempting to add a new order to it..."
							if (!(New-RemoteSpOrder -OrderNumber $PdfOrder.OrderNumber -TotalCost $PdfOrder.TotalCost -OrderDate $PdfOrder.OrderDate)) {
								throw "Failed to attach new order number $($PdfOrder.OrderNumber) to existing PO number $($PdfOrder.PoNumber)"
							} else {
								Write-Log -Message "Successfully attached new order number $($PdfOrder.OrderNumber) to existing PO number $($SpPurchaseOrder.xml.row.ows_Inkooporder)"
								$PdfUrl = "$PdfDocUrlRootUrl/$($PdfOrder.FilePath | Split-Path -Leaf)"
								if (!($SpOrder | Set-RemoteSpOrder -PdfAttachmentFileUrl $PdfUrl)) {
									throw "Failed to attach order PDF URL $PdfUrl to order number $($PdfOrder.OrderNumber)"
								} else {
									Write-Log -Message "Successfully attached order PDF URL $PdfUrl to order number $($PdfOrder.OrderNumber)"
									if (!(Archive-Pdf -FilePath $PdfOrder.FilePath -DestinationPath $PdfOrderArchiveFolderPath)) {
										throw "Failed to archive PDF file $($PdfOrder.FilePath) to archive folder"
									} else {
										Write-Log -Message "Successfully archived PDF file $($PdfOrder.FilePath) to archive folder"
									}
								}
							}
						}
					} catch {
						Write-Log -Message "Error: $($_.Exception.Message) - Line Number: $($_.InvocationInfo.ScriptLineNumber)" -LogLevel '3'
					}
				}
			}
		}
		if (($SyncActivities -contains 'DellOrder') -or ($SyncActivities -eq 'All')) {
			Write-Log "Getting Dell orders from file..."
			$AllDellOrders = Get-DellOrder
			if ($AllDellOrders -eq $false) {
				Send-Alert -EmailSubject 'Problem with syncing Dell orders' -EmailBody "Either the orders.csv file was not found or there was a problem with the format of the file."
				Write-Log -Message 'Dell order retrieval failed.  Emailed notification' -LogLevel 3
			} else {
				Write-Log "Found $($AllDellOrders.Count) total Dell order(s)"
                $DellOrders = $AllDellOrders  | where {$_.Status -ne 'Verwerking van bestelling'}
                if ($DellOrders) {
                    Write-Log "Found $($AllDellOrders.Count - $DellOrders.Count) orders in a status of 'Verwerking van bestelling'. Excluding from sync process"
                } else {
                    Write-Log "No orders found in a status of 'Verwerking van bestelling'."
                }
				
				foreach ($DellOrder in $DellOrders) {
					try {
						
						$SpOrder = Get-RemoteSpOrder -OrderNumber $DellOrder.Bestelnummer
						if (!$SpOrder) {
							Send-Alert -EmailSubject 'Failed Sharepoint order match' -EmailBody "Failed to find a matching Sharepoint order for Dell order $($DellOrder.Bestelnummer)"
							Write-Log "Could not update Dell order inforration. Failed to find Sharepoint order $($DellOrder.Bestelnummer).  Emailed notification" -LogLevel 2
						} else {
							if (!(Set-RemoteSpOrder -PoNumber $DellOrder.'Nummer van inkooporder' -EstimatedDeliveryDate $DellOrder.'Geschatte leveringsdatum' -DeliveryStatus $DellOrder.Status)) {
								throw "Failed to update order number $($DellOrder.Bestelnummer) with new Dell information"
							} else {
								
							}
						}
					} catch {
						Write-Log -Message "Error: $($_.Exception.Message) - Line Number: $($_.InvocationInfo.ScriptLineNumber)" -LogLevel '3'
					}
				}
                Write-Log "Archiving the Dell order file $DellOrdersFilePath to $DellOrdersArchiveFolderPath"
                Archive-DellOrder
			}
		}
		if (($SyncActivities -contains 'PDFInvoice') -or ($SyncActivities -eq 'All')) {
			Write-Log "Retrieving any new PDF Dell invoices in $PdfInvoiceFolderPath..."
			if ($OrderNumber) {
				$PdfInvoices = Get-PdfInvoice -OrderNumber $OrderNumber
			} else {
				$PdfInvoices = Get-PdfInvoice
			}
			if (!$PdfInvoices) {
				if ($OrderNumber) {
					Write-Log -Message "No PDF invoices found matching order number(s) $($OrderNumber -join ',')"
				} else {
					Write-Log -Message "No PDF invoices found"
				}
			} else {
				Write-Log "$($PdfInvoices.Count) invoices found to sync"
				foreach ($PdfInvoice in $PdfInvoices) {
					try {
						Write-Log "Getting Sharepoint order for order number $($PdfInvoice.OrderNumber)..."
						$SpOrder = Get-RemoteSpOrder -OrderNumber $PdfInvoice.OrderNumber
						if (!$SpOrder) {
							Send-Alert -EmailSubject 'Failed Sharepoint order match' -EmailBody "Failed to find a matching Sharepoint order for PDF invoice number $($PdfInvoice.InvoiceNumber)"
							Write-Log "Failed to find Sharepoint order.  Emailed notification" -LogLevel 2
						} else {
							if (!(Set-RemoteSpOrder -InvoiceNumber $PdfInvoice.InvoiceNumber)) {
								throw "Failed to update order number $($PdfInvoice.OrderNumber) with invoice number $($PdfInvoice.InvoiceNumber)"
							} else {
								Write-Log -Message "Successfully updated order number $($PdfInvoice.OrderNumber) with invoice number $($PdfInvoice.InvoiceNumber)"
							}
							$PdfUrl = "$PdfDocUrlRootUrl/$($PdfInvoice.FilePath | Split-Path -Leaf)"
							if (!($SpOrder | Set-RemoteSpOrder -PdfAttachmentFileUrl $PdfUrl)) {
								throw "Failed to attach invoice PDF URL $PdfUrl to order number $($PdfInvoice.OrderNumber)"
							} else {
								Write-Log -Message "Successfully attached invoice PDF URL $PdfUrl to order number $($PdfInvoice.OrderNumber)"
								if (!(Archive-Pdf -FilePath $PdfInvoice.FilePath -DestinationPath $PdfInvoiceArchiveFolderPath)) {
									throw "Failed to archive PDF file $($PdfInvoice.FilePath) to archive folder"
								} else {
									Write-Log -Message "Successfully archived PDF file $($PdfInvoice.FilePath) to archive folder"
								}
							}
						}
					} catch {
						Write-Log -Message "Error: $($_.Exception.Message) - Line Number: $($_.InvocationInfo.ScriptLineNumber)" -LogLevel '3'
					}
				}
			}
		}
	} catch {
		Write-Log -Message "Error: $($_.Exception.Message) - Line Number: $($_.InvocationInfo.ScriptLineNumber)" -LogLevel '3'
		
		Remove-PSSession -Session $ServerSession
		exit 1
	}
}
end {
	
	Remove-PSSession -Session $ServerSession
}