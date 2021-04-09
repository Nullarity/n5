Call ( "Common.Init" );
CloseAll ();

id = Call ( "Common.GetID" );
date = CurrentDate ();
customer = "_SO Customer fill VI# " + id;
warehouse = "_SO Warehouse# " + id;
department = "_Sales no Shipmets# " + id;
user = Call ( "Common.User" );
userSettings = Call ( "Catalogs.UserSettings.Get" );
company = userSettings.Company;

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

goods = new Array ();
keys = "Name, Service, CountPackages, Price, Quantity";
goods.Add ( new Structure ( keys, "_Item Test SO# " + id, false, false, "200", "10" ) );
goods.Add ( new Structure ( keys, "_Item Test SO, cpkg# " + id, false, true, "300", "20" ) );
goods.Add ( new Structure ( keys, "_Service Test SO " + id, true, false, "1500", "1" ) );

for each item in goods do
	creationParams = Call ( "Catalogs.Items.Create.Params" );
	creationParams.Description = item.Name;
	creationParams.CountPackages = item.CountPackages;
	creationParams.Service = item.Service;
	
	p = Call ( "Common.CreateIfNew.Params" );
	p.Object = Meta.Catalogs.Items;
	p.Description = item.Name;
	p.CreationParams = creationParams;
	Call ( "Common.CreateIfNew", p );
enddo;

// ***********************************
// Create Sales Order
// ***********************************

p = Call ( "Documents.SalesOrder.CreateApproveOneUser.Params" );
p.Date = date;
p.Warehouse = warehouse;
p.Customer = customer;
p.Department = department;
p.Shipments = false;

orderItems = new Array ();
orderServices = new Array ();
for each row in goods do
	if ( row.Service ) then
		newRow = Call ( "Documents.SalesOrder.CreateApproveOneUser.ServicesRow" );
		orderServices.Add ( newRow );
	else
		newRow = Call ( "Documents.SalesOrder.CreateApproveOneUser.ItemsRow" );
		orderItems.Add ( newRow );
	endif;
	FillPropertyValues ( newRow, row );
	newRow.Item = row.Name;
enddo;

p.Items = orderItems;
for each row in orderServices do
	row.Item = row.Item + " (Service)";
enddo;
p.Services = orderServices;
SONumber = Call ( "Documents.SalesOrder.CreateApproveOneUser", p );

// ***********************************
// Get Quantity
// ***********************************

list = Call ( "Common.OpenList", Meta.Documents.SalesOrder );
Clear ( "#CustomerFilter" );
Clear ( "#StatusFilter" );
Clear ( "#ItemFilter" );
Clear ( "#WarehouseFilter" );
Clear ( "#DepartmentFilter" );

p = Call ( "Common.Find.Params" );
p.Where = "Number";
p.What = SONumber;
Call ( "Common.Find", p );

Click ( "#FormChange" );
With ( "Sales Order #*" );
quantity = Fetch ( "#ItemsTotalQuantityPkg" );
Close ();

// ***********************************
// Test Vendor Invoice
// ***********************************

With ( list );
Click ( "#FormDocumentVendorInvoiceCreateBasedOn" );
form = With ( "Vendor Invoice (create)" );
Check ( "#ItemsTotalQuantityPkg", quantity );

// ***********************************
// Click Fill and check again
// ***********************************

Click ( "#ItemsTableApplySalesOrders" );

p = Call ( "Common.Fill.Params" );
filters = new Array ();

item = Call ( "Common.Report.Filter" );
item.Name = "Sales Order";
item.Value = SONumber;
filters.Add ( item );

p.Filters = filters;
Call ( "Common.Fill", p );

Check ( "#ItemsTotalQuantityPkg", quantity );
