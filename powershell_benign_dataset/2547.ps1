


$erroractionpreference = "SilentlyContinue"
$a = New-Object -comobject Excel.Application
$a.visible = $True
 
$b = $a.Workbooks.Add()
$c = $b.Worksheets.Item(1)
 

$ColHeaders = ("DBName", "addl_loan_data", "appraisal", "borrower", "br_address",
				"br_expense", "br_income", "br_liability", "br_REO", 
				"channels", "codes", "customer_elements", "funding", 
				"inst_channel_assoc", "institution", "institution_association", 
				"loan_appl", "loan_fees", "loan_price_history", "loan_prod", 
				"loan_regulatory", "loan_status", "product", "product_channel_assoc", 
				"property", "servicing", "shipping", "underwriting")
$idx=0

foreach ($title in $ColHeaders) {
    $idx+=1
    $c.Cells.Item(1,$idx) = $title
	
    }
 
$d = $c.UsedRange
$d.Interior.ColorIndex = 19
$d.Font.ColorIndex = 11
$d.Font.Bold = $True
 
$intRow = 2
 

 


























$d.Orientation = 90
$d.EntireColumn.AutoFit() |out-null