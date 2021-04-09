Call ( "Common.Init" );
CloseAll ();

id = Call ( "Common.GetID" );

date = CurrentDate ();
warehouse = "_Just Warehouse# " + id;
department = "_Just Department# " + id;
user = Call ( "Common.User" );
userSettings = Call ( "Catalogs.UserSettings.Get" );
company = userSettings.Company;
paymentOptions = "nodiscount#";
terms = "100% prepay, 0-1-5#";
vendorName = "Test PO Printing# " + id;

goods = new Array ();
keys = "Name, Service, CountPackages, Price, Quantity";
goods.Add ( new Structure ( keys, "_Item Test PO printing# " + id, false, false, "100", "10" ) );
goods.Add ( new Structure ( keys, "_Item Test PO printing, cpkg# " + id, false, true, "150", "20" ) );
goods.Add ( new Structure ( keys, "_Service Test PO printing " + id, true, false, "750", "1" ) );

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
// Create PaymentOption
// ***********************************

params = Call ( "Catalogs.PaymentOptions.Create.Params" );
params.Description = paymentOptions;

p = Call ( "Common.CreateIfNew.Params" );
p.Object = Meta.Catalogs.PaymentOptions;
p.Description = params.Description;
p.CreationParams = params;
Call ( "Common.CreateIfNew", p );

// ***********************************
// Create Terms
// ***********************************

params = Call ( "Catalogs.Terms.Create.Params" );
params.Description = terms;
payments = params.Payments;
row = Call ( "Catalogs.Terms.Create.Row" );
row.Option = paymentOptions;
row.Variant = "On delivery";
row.Percent = "100";
payments.Add ( row );

p = Call ( "Common.CreateIfNew.Params" );
p.Object = Meta.Catalogs.Terms;
p.Description = params.Description;
p.CreationParams = params;
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
		Set ( "#ServicesItem", item.Name, table );
		Set ( "#ServicesQuantity", item.Quantity, table );
		Set ( "#ServicesPrice", item.Price, table );
		servicesRow = servicesRow + 1;
	else
		table = Activate ( "#ItemsTable" );
		Click ( "#ItemsTableAdd" );
		Set ( "#ItemsItem", item.Name, table );
		Set ( "#ItemsQuantity", item.Quantity, table );
		Set ( "#ItemsPrice", item.Price, table );
		itemsRow = itemsRow + 1;
	endif;
enddo;

// ***********************************************
// Print Purchase Order
// ***********************************************

Click ( "#FormWrite" );
Click ( "#FormDocumentPurchaseOrderPurchaseOrder" );

With ( "Purchase Order: Print" );
CheckTemplate ( "#TabDoc" );