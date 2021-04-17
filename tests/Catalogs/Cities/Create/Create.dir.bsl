// Description:
// Creates a new CashFlow
//
// Returns:
// Structure ( "Code, Description" )

MainWindow.ExecuteCommand ( "e1cib/data/Catalog.Cities" );
form = With ( "Cities (create)" );
name = ? ( _ = undefined, "_State: " + Format ( CurrentDate (), "DLF = 'D'" ), _.Description );
Set ( "#Description", name );
Put ( "#Owner", _.State );

Click ( "#FormWrite" );
code = Fetch ( "Code" );

Close ();

return new Structure ( "Code, Description", code, name );

