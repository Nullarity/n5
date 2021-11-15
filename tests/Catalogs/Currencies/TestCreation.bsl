Call ( "Common.Init" );
CloseAll ();

currency = "BOB";

// *****************************************
// Create currency from classifier
// *****************************************

form = Call ( "Common.OpenList", Meta.Catalogs.Currencies );
Click ( "#FormCreate" );

With ( "Classifier" );

table = Get ( "#List" );
search = new Map ();
search.Insert ( "Code", currency );
table.GotoFirstRow ();
table.GotoRow ( search, RowGotoDirection.Down );

Click ( "#FormSelect" );

With ( form );

Check ( "#Description", currency, Get ( "#List" ) );

// *****************************************
// Create currency from text input.
// Testing classifier-row activation process
// *****************************************

MainWindow.ExecuteCommand ( "e1cib/data/Catalog.Prices" );
With ( "Prices (create)" );

f = Set ( "#Currency", currency );
f.Create ();

With ( "Classifier" );
Check ( "#ListCode", currency, Get ( "#List" ) );
