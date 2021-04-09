Call ( "Common.Init" );
CloseAll ();


env = Run ( "Create", "2815DF26#" );

form = With ( "Assets Transfer #*" );

table = Activate ( "#ItemsTable" );
Call ( "Table.AddEscape", table );
Click ( "#ItemsTableAdd" );

// CostOffline
Call ( "Catalogs.UserSettings.CostOnline", false );
Choose ( "#ItemsItem", table );
With ( "Fixed assets" );
list = Activate ( "#List" );
Click ( "Command bar / View mode / List" );
search = new Map ();
search.Insert ( "Description", env.Items [ 2 ].Item );
list.GotoRow ( search, RowGotoDirection.Down );
Click ( "Command bar / Select" );
With ( form );

Click ( "#FormPost" );
error = "* is not found in balance";
Call ( "Common.CheckPostingError", error );

// CostOnline
Call ( "Catalogs.UserSettings.CostOnline", true );
Click ( "#FormPost" );
Call ( "Common.CheckPostingError", error );
Call ( "Table.AddEscape", table );
table.DeleteRow ();

Run ( "Logic" );
With ( form );
Run ( "PrintForm" );

