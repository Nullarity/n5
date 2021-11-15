// Description:
// Set filters in Receive Items list form and create a new Receive Items.
// Checks the automatic header filling process
//
// Conditions:
// Command interface shoud be visible.

Call ( "Common.Init" );
CloseAll ();
form = Call ( "Common.OpenList", Meta.Documents.ReceiveItems );

Choose ( "#WarehouseFilter" );
p = Call ( "Common.Select.Params" );
p.Object = Meta.Catalogs.Warehouses;
p.Search = "Main";
Call ( "Common.Select", p );

With ( form );
warehouse = Fetch ( "#WarehouseFilter" );
Click ( "#FormCreate" );

With ( "Receive Items (create)" );
Check ( "#Warehouse", warehouse );
