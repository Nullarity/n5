Call ( "Common.Init" );
CloseAll ();

id = Call ( "Common.GetID" );

date = CurrentDate ();
customer = "_SO Customer# " + id;
warehouse = "_SO Warehouse# " + id;
department = "_Sales test PO# " + id;
user = Call ( "Common.User" );
userSettings = Call ( "Catalogs.UserSettings.Get" );
company = userSettings.Company;
paymentOptions = "nodiscount#";
terms = "100% prepay, 0-1-5#";
vendorName = "Test PO Generating#";

goods = new Array ();
keys = "Name, Service, CountPackages, Price, Cost, Quantity";
goods.Add ( new Structure ( keys, "_Item Test PO filling# " + id, false, false, "200", "100", "10" ) );
goods.Add ( new Structure ( keys, "_Item Test PO filling, cpkg " + id, false, true, "300", "150", "20" ) );
goods.Add ( new Structure ( keys, "_Service Test PO filling " + id, true, false, "1500", "750", "1" ) );

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
// Roles: Division head
// ***********************************

MainWindow.ExecuteCommand ( "e1cib/list/Document.Roles" );
list = With ( "Roles" );
Click ( "#FormCreate" );
With ( "Roles (create)" );
Set ( "#User", user );
Pick ( "#Role", "Department Head" );
Set ( "#Department", department );
CurrentSource.GotoNextItem ();
Click ( "#Apply" );

//With ( DialogsTitle );
//Click ( "Yes" );

// ***********************************
// Roles: Warehouse manager
// ***********************************

MainWindow.ExecuteCommand ( "e1cib/list/Document.Roles" );
list = With ( "Roles" );
Click ( "#FormCreate" );
With ( "Roles (create)" );
Set ( "#User", user );
Pick ( "#Role", "Warehouse Manager" );
Click ( "#Apply" );

//With ( DialogsTitle );
//Click ( "Yes" );

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
// Create Sales Order
// ***********************************

p = Call ( "Documents.SalesOrder.CreateApproveOneUser.Params" );
p.Date = date;
p.Warehouse = warehouse;
p.Customer = customer;
p.Terms = terms;
p.Department = department;
p.Shipments = false;

orderItems = new Array ();
orderServices = new Array ();
for each item in goods do
	if ( item.Service ) then
		row = Call ( "Documents.SalesOrder.CreateApproveOneUser.ServicesRow" );
		row.Item = item.Name + " (Service)";
		row.Quantity = item.Quantity;
		row.Price = item.Price;
		row.Performer = "Vendor";
		orderServices.Add ( row );
	else
		row = Call ( "Documents.SalesOrder.CreateApproveOneUser.ItemsRow" );
		row.Item = item.Name;
		row.Quantity = item.Quantity;
		row.CountPackages = item.CountPackages;
		row.Price = item.Price;
		row.Reservation = "Next Receipts";
		orderItems.Add ( row );
	endif;
enddo;
p.Items = orderItems;
p.Services = orderServices;
SONumber = Call ( "Documents.SalesOrder.CreateApproveOneUser", p );

Run ( "FillingBySO.CheckAllocation", SONumber );

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
// Generate Purchase Order
// ***********************************

salesOrders = Call ( "Common.OpenList", Meta.Documents.SalesOrder );

Clear ( "#CustomerFilter" );
Clear ( "#StatusFilter" );
Clear ( "#ItemFilter" );
Clear ( "#WarehouseFilter" );
Clear ( "#DepartmentFilter" );

p = Call ( "Common.Find.Params" );
p.Where = "Number";
p.What = SONumber;
Call ( "Common.Find", p );

Click ( "#FormDocumentPurchaseOrderCreateBasedOn" );

// ***********************************
// Fill Purchase Order
// ***********************************

With ( "Purchase Order (cre*" );

Set ( "#Vendor", vendorName );
Set ( "#Warehouse", warehouse );

// ***********************************
// Set purchasing prices
// ***********************************

itemsRow = 1;
servicesRow = 1;
for each item in goods do
	if ( item.Service ) then
		table = Activate ( "#Services" );
		Set ( "#ServicesPrice [" + servicesRow + "]", item.Cost, table );
		servicesRow = servicesRow + 1;
	else
		table = Activate ( "#ItemsTable" );
		Set ( "#ItemsPrice [" + itemsRow + "]", item.Cost, table );
		itemsRow = itemsRow + 1;
	endif;
enddo;

// ***********************************************
// Post Purchase Order and check Allocation Report
// ***********************************************

Click ( "#FormPost" );
Run ( "FillingBySO.CheckAllocationAfterPostingPO", SONumber );
