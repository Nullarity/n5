// Description:
// Creates new Expense
//
// Returns:
// Structure ( "Code, Description" )

MainWindow.ExecuteCommand ( "e1cib/data/Catalog.Expenses" );
form = With ( "Expenses (create)" );
name = ? ( _ = undefined, "_Expnese: " + CurrentDate (), _ );
Set ( "Description", name );

Click ( "Save" );

code = Fetch ( "Code" );

Close ();

return new Structure ( "Code, Description", code, name );
