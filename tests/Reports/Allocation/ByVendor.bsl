Call ( "Common.Init" );
CloseAll ();

vendorName = "_Test Allocation by Vendor#";
itemName = "_Vendor Item#";

// ***********************************
// Create Vendor
// ***********************************

p = Call ( "Common.CreateIfNew.Params" );
p.Object = Meta.Catalogs.Organizations;
p.Description = vendorName;
p.CreationParams = vendorName;
p.CreateScenario = "Catalogs.Organizations.CreateVendor";
Call ( "Common.CreateIfNew", p );

// ***********************************
// Create Item
// ***********************************

creation = Call ( "Catalogs.Items.Create.Params" );
creation.Description = itemName;

p = Call ( "Common.CreateIfNew.Params" );
p.Object = Meta.Catalogs.Items;
p.Description = creation.Description;
p.CreationParams = creation;
Call ( "Common.CreateIfNew", p );

// ***********************************
// Open Vendor and assign Item
// ***********************************

OpenMenu ( "Purchases / Vendors" );
With ( "Vendors" );
p = Call ( "Common.Find.Params" );
p.Where = "Name";
p.What = vendorName;
Call ( "Common.Find", p );
Click ( "#FormChange" );
With ( vendorName + "*" );
Click ( "#VendorPage" );
table = Activate ( "#VendorItems" );
try
	GotoRow ( table, "Item", itemName );
	found = true;
except
	found = false;
endtry;
if ( found ) then
	Click ( "#VendorItemsDelete" );
	Click ( "Yes", Forms.Get1C () );
endif;
Click ( "#VendorItemsCreate" );
With ( "Vendor Items (create)" );
Set ( "#Item", itemName );
Set ( "#Price", "5" );
Click ( "#FormWriteAndClose" );

// ***********************************
// Open Report
// ***********************************

p = Call ( "Common.Report.Params" );
p.Path = "Purchases / Allocation";
p.Title = "Allocation";
filters = new Array ();

item = Call ( "Common.Report.Filter" );
item.Name = "Vendor";
item.Value = vendorName;
filters.Add ( item );

p.Filters = filters;
With ( Call ( "Common.Report", p ) );
