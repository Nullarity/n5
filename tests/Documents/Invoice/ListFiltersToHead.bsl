// Description:
// Set filters in Invoices list form and create a new Invoice.
// Checks the automatic header filling process
//
// Conditions:
// Command interface shoud be visible.

Call ( "Common.Init" );
CloseAll ();
form = Call ( "Common.OpenList", Meta.Documents.Invoice );

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

With ( "Invoice (create)" );
Check ( "#Customer", customer );
Check ( "#Warehouse", warehouse );
