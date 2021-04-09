// Description:
// Creates a new CashFlow
//
// Returns:
// Structure ( "Code, Description" )

MainWindow.ExecuteCommand ( "e1cib/data/Catalog.CashFlows" );
form = With ( "Cash Flows (create)" );
name = ? ( _ = undefined, "_CashFlow: " + Format ( CurrentDate (), "DLF = 'D'" ), _ );
Set ( "#Description", name );
Set ( "#FlowType", "Type_010" );

Click ( "#FormWrite" );
code = Fetch ( "Code" );

Close ();

return new Structure ( "Code, Description", code, name );

