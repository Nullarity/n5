// Description:
// Set filters in Inventories list form and create a new Inventory.
// Checks the automatic header filling process
//
// Conditions:
// Command interface shoud be visible.

Call ( "Common.Init" );
CloseAll ();
form = Call ( "Common.OpenList", Meta.Documents.Inventory );

Choose ( "#WarehouseFilter" );
p = Call ( "Common.Select.Params" );
p.Object = Meta.Catalogs.Warehouses;
p.Search = "_Inventory Warehouse";
Call ( "Common.Select", p );

With ( form );
warehouse = Fetch ( "#WarehouseFilter" );
Click ( "#FormCreate" );

With ( "Inventory (create)" );
Check ( "#Warehouse", warehouse );
