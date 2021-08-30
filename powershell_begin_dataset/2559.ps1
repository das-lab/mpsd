param( 

	[String[]] $DatabaseList

	)
	







"The number of parameters passed in DatabaseList is $($DatabaseList.Count)"

$i = 0
foreach ($arg in $DatabaseList) { echo "The $i parameter in DatabaseList is $arg"; $i++ }

