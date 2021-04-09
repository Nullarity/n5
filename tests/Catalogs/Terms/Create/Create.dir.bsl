// Description:
// Creates a new Item
//
// Returns:
// Structure ( "Code, Description" )

MainWindow.ExecuteCommand ( "e1cib/data/Catalog.Terms" );
form = With ( "Terms (create)" );
if ( _ = undefined ) then
	name = "_Item: " + CurrentDate ();
	payments = new Array ();
else
	name = _.Description;
	payments = _.Payments;
endif;

Set ( "Description", name );

table = Activate ( "#Payments" );
for each row in payments do
	Click ( "#PaymentsAdd" );
	Set ( "#PaymentsOption", row.Option, table );
	Set ( "#PaymentsVariant", row.Variant, table );
	Set ( "#PaymentsPercent", row.Percent, table );
enddo;

Click ( "#FormWrite" );
code = Fetch ( "Code" );
Close ();

return new Structure ( "Code, Description", code, name );
