// Description:
// Set filters in Assemblings list form and create a new Assembling.
// Checks the automatic header filling process
//
// Conditions:
// Command interface should be visible.

Call ( "Common.Init" );
CloseAll ();
form = Call ( "Common.OpenList", Meta.Documents.Assembling );

Choose ( "#WarehouseFilter" );
p = Call ( "Common.Select.Params" );
p.Object = Meta.Catalogs.Warehouses;
p.Search = "Main";
Call ( "Common.Select", p );

With ( form );
warehouse = Fetch ( "#WarehouseFilter" );
Click ( "#FormCreate" );

With ( "Assembling (create)" );
Check ( "#Warehouse", warehouse );
