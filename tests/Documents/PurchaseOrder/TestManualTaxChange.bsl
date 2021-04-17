Call ( "Common.Init" );
CloseAll ();

itemName = "Just Item#";
vendorName = "Vendor, manualtax#";

Call ( "Catalogs.Items.CreateIfNew", itemName );

// ***********************************
// Create Vendor if new
// ***********************************

p = Call ( "Common.CreateIfNew.Params" );
p.Object = Meta.Catalogs.Organizations;
p.Description = vendorName;
p.CreationParams = vendorName;
p.CreateScenario = "Catalogs.Organizations.CreateVendor";
Call ( "Common.CreateIfNew", p );

// ***********************************
// Open document
// ***********************************

Call ( "Common.OpenList", Meta.Documents.PurchaseOrder );
Click ( "#FormCreate" );
With ( "Purchase Order (cr*" );

Set ( "#Vendor", vendorName );
table = Get ( "#ItemsTable" );
Click ( "#ItemsTableAdd" );
table.EndEditRow ();
Set ( "#ItemsItem", itemName, table );
Set ( "#ItemsQuantityPkg", "1", table );
Set ( "#ItemsPrice", "100", table );
Set ( "#ItemsTaxCode", "Taxable Sales", table );

Check ( "#Amount", "107" );
table = Activate ( "#Taxes" );
Set ( "#TaxesAmount", 6, table );
Check ( "#Amount", "108" );

Click ( "#FormWrite" );
Check ( "#Amount", "108" );
