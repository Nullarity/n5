// Description:
// Creates a new CashFlow
//
// Returns:
// Structure ( "Code, Description" )

MainWindow.ExecuteCommand ( "e1cib/data/Catalog.States" );
form = With ( "States (create)" );
name = ? ( _ = undefined, "_State: " + Format ( CurrentDate (), "DLF = 'D'" ), _.Description );
Set ( "#Description", name );
Put ( "#Owner", _.Country );
Put ( "#TaxGroup", "California" );

Click ( "#FormWrite" );
code = Fetch ( "Code" );

Close ();

return new Structure ( "Code, Description", code, name );

