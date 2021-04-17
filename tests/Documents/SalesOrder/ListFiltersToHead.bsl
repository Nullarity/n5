// Description:
// Set filters in Sales Order list form and create a new Sales Order.
// Checks the automatic header filling process
//
// Conditions:
// Command interface shoud be visible.

Call ( "Common.Init" );
CloseAll ();
form = Call ( "Common.OpenList", Meta.Documents.SalesOrder );

Choose ( "#CustomerFilter" );
p = Call ( "Common.Select.Params" );
p.Object = Meta.Catalogs.Organizations;
p.CreateScenario = "Catalogs.Organizations.CreateCustomer";
p.Search = "_Customer";
Call ( "Common.Select", p );

With ( form );
customer = Fetch ( "#CustomerFilter" );

Choose ( "#WarehouseFilter" );
p.Object = Meta.Catalogs.Warehouses;
p.Search = "Main";
Call ( "Common.Select", p );

With ( form );
warehouse = Fetch ( "#WarehouseFilter" );
Click ( "#FormCreate" );

With ( "Sales Order (create)" );
Check ( "#Customer", customer );
Check ( "#Warehouse", warehouse );
