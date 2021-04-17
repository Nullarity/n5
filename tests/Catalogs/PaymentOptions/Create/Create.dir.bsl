// Description:
// Creates a new PaymentOption
//
// Returns:
// Structure ( "Code, Description" )

MainWindow.ExecuteCommand ( "e1cib/data/Catalog.PaymentOptions" );

form = With ( "Payment Options (create)" );
if ( _ = undefined ) then
	name = "_Payment Option: " + CurrentDate ();
	discounts = new Array ();
else
	name = _.Description;
	discounts = _.discounts;
endif;

Set ( "Description", name );

table = Activate ( "#Discounts" );
for each row in discounts do
	Click ( "#DiscountsAdd" );
	Set ( "#DiscountsEdge", row.During, table );
	Set ( "#DiscountsDiscount", row.Discount, table );
enddo;

Click ( "#FormWrite" );
code = Fetch ( "Code" );
Close ();

return new Structure ( "Code, Description", code, name );
