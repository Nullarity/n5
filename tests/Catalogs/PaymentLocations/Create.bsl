// Description:
// Creates a new Payment Location
//
// Conditions:
// User should have default Company
//
// Returns:
// Structure ( "Code, Description" )

MainWindow.ExecuteCommand ( "e1cib/data/Catalog.PaymentLocations" );

form = With ( "Payment Locations (create)" );
name = ? ( _ = undefined, "_Location: " + CurrentDate (), _ );
Set ( "Description", name );
Click ( "#FormWrite" );
code = Fetch ( "Code" );
Close ( form );

return new Structure ( "Code, Description", code, name );
