// Description:
// Set filters in Vendor Invoices list form and create a new Vendor Invoice.
// Checks the automatic header filling process
//
// Conditions:
// Command interface shoud be visible.

Call ( "Common.Init" );
CloseAll ();
form = Call ( "Common.OpenList", Meta.Documents.VendorInvoice );

Choose ( "#VendorFilter" );
p = Call ( "Common.Select.Params" );
p.Object = Meta.Catalogs.Organizations;
p.CreateScenario = "Catalogs.Organizations.CreateVendor";
p.Search = "_Vendor";
Call ( "Common.Select", p );

With ( form );
vendor = Fetch ( "#VendorFilter" );

Choose ( "#WarehouseFilter" );
p.Object = Meta.Catalogs.Warehouses;
p.Search = "Main";
Call ( "Common.Select", p );

With ( form );
warehouse = Fetch ( "#WarehouseFilter" );
Click ( "#FormCreate" );

With ( "Vendor Invoice (create)" );
Check ( "#Vendor", vendor );
Check ( "#Warehouse", warehouse );
