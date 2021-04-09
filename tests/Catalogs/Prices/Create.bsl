// Description:
// Creates new Prices
//
// Returns:
// Structure ( "Code, Description" )

MainWindow.ExecuteCommand ( "e1cib/data/Catalog.Prices" );
form = With ( "Prices (create)" );
name = ? ( _ = undefined, "_Prices test: " + CurrentDate (), _ );
Set ( "#Description", name );
Set ( "#Owner", Call ( " ) );
Set ( "#Pricing", "Base" );
Set ( "#Currency", Call ( "Select.MainCurrencyName" ) );

Click ( "Save" );

code = Fetch ( "Code" );

Close ();

return new Structure ( "Code, Description", code, name );

