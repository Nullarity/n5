Call ( "Common.Init" );
CloseAll ();

date = CurrentDate ();
warehouse = "_IO Warehouse#";
department = "_IO_PO_VI#";
user = Call ( "Common.User" );
responsible = user;
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
Put ( "#User", user );
Pick ( "#Role", "Department Head" );
Set ( "#Department", department );
CurrentSource.GotoNextItem ();
Click ( "#Apply" );

// ***********************************
// Roles: SupplyChief
// ***********************************

MainWindow.ExecuteCommand ( "e1cib/list/Document.Roles" );
list = With ( "Roles" );
Click ( "#FormCreate" );
With ( "Roles (create)" );
Put ( "#User", user );
Pick ( "#Role", "Supply Chief" );
Click ( "#Apply" );

// ***********************************
// Create Items
// ***********************************

goods = new Array ();
keys = "Name, Service, CountPackages, Price, Quantity, Performer";
goods.Add ( new Structure ( keys, "_Item Test IO#", false, false, "200", "10" ) );
goods.Add ( new Structure ( keys, "_Item Test IO, cpkg#", false, true, "300", "20" ) );
goods.Add ( new Structure ( keys, "_Service Test IO", true, false, "1500", "1", "Vendor" ) );

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
// Create Internal Order
// ***********************************

p = Call ( "Documents.InternalOrder.CreateApproveOneUser.Params" );
p.Date = date;
p.Warehouse = warehouse;
p.Responsible = responsible;
p.Department = department;
p.TaxGroup = "California";
p.TaxCode = "Taxable Sales";

orderItems = new Array ();
orderServices = new Array ();
for each row in goods do
	if ( row.Service ) then
		newRow = Call ( "Documents.InternalOrder.CreateApproveOneUser.ServicesRow" );
		orderServices.Add ( newRow );
	else
		newRow = Call ( "Documents.InternalOrder.CreateApproveOneUser.ItemsRow" );
		newRow.Reservation = "Next Receipts";
		orderItems.Add ( newRow );
	endif;
	FillPropertyValues ( newRow, row );
	newRow.Item = row.Name;
enddo;

p.Items = orderItems;
p.Services = orderServices;
IONumber = Call ( "Documents.InternalOrder.CreateApproveOneUser", p );

// ***********************************
// Create Purchase Order
// ***********************************

list = Call ( "Common.OpenList", Meta.Documents.InternalOrder );
Clear ( "#StatusFilter" );
Clear ( "#ItemFilter" );
Clear ( "#WarehouseFilter" );
Clear ( "#DepartmentFilter" );

p = Call ( "Common.Find.Params" );
p.Where = "Number";
p.What = IONumber;
Call ( "Common.Find", p );

Click ( "#FormChange" );
With ( "Internal Order #*" );
grossAmount = Fetch ( "#GrossAmount" );

With ( list );
Click ( "#FormDocumentPurchaseOrderCreateBasedOn" );
With ( "Purchase Order (create)" );
Check ( "#GrossAmount", grossAmount );
Close ();

// PO posting and Vendor Invoice are impletemted in Documents.PurchaseOrder tests

// ***********************************
// Create Vendor Invoice
// ***********************************

With ( list );
Click ( "#FormDocumentVendorInvoiceCreateBasedOn" );
With ( "Vendor Invoice (create)" );
Check ( "#GrossAmount", grossAmount );
