Call ( "Common.Init" );
CloseAll ();

date = CurrentDate ();
id = Call ( "Common.GetID" );

warehouse = "_Just Warehouse#" + id;
department = "_Just Department#" + id;
user = Call ( "Common.User" );
userSettings = Call ( "Catalogs.UserSettings.Get" );
company = userSettings.Company;
vendorName = "Test Vendor Invoice Filling " + date;

goods = new Array ();
keys = "Name, Service, CountPackages, Price, DiscountRate, Quantity";
goods.Add ( new Structure ( keys, "_Item Test VI filling#", false, false, "100", "5", "10" ) );
goods.Add ( new Structure ( keys, "_Item Test VI filling, cpkg#", false, true, "150", "6", "20" ) );
goods.Add ( new Structure ( keys, "_Service Test VI filling", true, false, "750", "7", "1" ) );

// ***********************************
// Create Department
// ***********************************

params = Call ( "Catalogs.Departments.Create.Params" );
params.Description = department;
params.Company = company;

p = Call ( "Common.CreateIfNew.Params" );
p.Object = Meta.Catalogs.Departments;
p.Description = params.Description;
p.CreationParams = params;
Call ( "Common.CreateIfNew", p );

// ***********************************
// Create Warehouse
// ***********************************

p = Call ( "Common.CreateIfNew.Params" );
p.Object = Meta.Catalogs.Warehouses;
p.Description = warehouse;
p.CreationParams = warehouse;
Call ( "Common.CreateIfNew", p );

// ***********************************
// Create Items
// ***********************************

for each item in goods do
	name = item.Name;
	p = Call ( "Catalogs.Items.Create.Params" );
	p.Description = name;
	p.CountPackages = item.CountPackages;
	p.Service = item.Service;
	
	params = Call ( "Common.CreateIfNew.Params" );
	params.Object = Meta.Catalogs.Items;
	params.Description = name;
	params.CreationParams = p;
	Call ( "Common.CreateIfNew", params );
enddo;

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
// Create Purchase Order
// ***********************************

Call ( "Common.OpenList", Meta.Documents.PurchaseOrder );
Click ( "#FormCreate" );

With ( "Purchase Order (cre*" );

Set ( "Date", date - 5 );
Set ( "#Vendor", vendorName );
Set ( "#Warehouse", warehouse );
Set ( "#Department", department );

// ***********************************
// Fill Purchase Order
// ***********************************

itemsRow = 1;
servicesRow = 1;
for each item in goods do
	if ( item.Service ) then
		table = Activate ( "#Services" );
		Click ( "#ServicesAdd" );
		table.EndEditRow ();
		Set ( "#ServicesItem", item.Name, table );
		Set ( "#ServicesQuantity", item.Quantity, table );
		Set ( "#ServicesPrice", item.Price, table );
		Set ( "#ServicesDiscountRate", item.DiscountRate, table );
		servicesRow = servicesRow + 1;
	else
		table = Activate ( "#ItemsTable" );
		Click ( "#ItemsTableAdd" );
		table.EndEditRow ();
		Set ( "#ItemsItem", item.Name, table );
		Set ( "#ItemsQuantity", item.Quantity, table );
		Set ( "#ItemsPrice", item.Price, table );
		Set ( "#ItemsDiscountRate", item.DiscountRate, table );
		itemsRow = itemsRow + 1;
	endif;
enddo;

poAmount = Fetch ( "#Amount" );

Click ( "#FormPost" );

// ***********************************************
// Create Vendor Invoice
// ***********************************************

Call ( "Common.OpenList", Meta.Documents.VendorInvoice );
With ( "Vendor Invoices" );
Put ( "#WarehouseFilter", warehouse );

Click ( "#FormCreate" );
form = With ( "Vendor Invoice (cre*" );

Set ( "#Vendor", vendorName ); // After this action document should be prepopulated
form.GotoNextItem ();

amount = Fetch ( "#Amount" );
if ( poAmount <> amount ) then
	Stop ( "PO amount(" + poAmount + ") should be equal Vendor Invoice amount(" + amount + ")" );
endif;
