// Description:
// Set filters in Write Offs list form and create a new Write Off.
// Checks the automatic header filling process
//
// Conditions:
// Command interface shoud be visible.

Call ( "Common.Init" );
CloseAll ();
form = Call ( "Common.OpenList", Meta.Documents.WriteOff );

Choose ( "#WarehouseFilter" );
p = Call ( "Common.Select.Params" );
p.Object = Meta.Catalogs.Warehouses;
p.Search = "Main";
Call ( "Common.Select", p );

With ( form );
warehouse = Fetch ( "#WarehouseFilter" );
Click ( "#FormCreate" );

With ( "Write Off (create)" );
Check ( "#Warehouse", warehouse );
