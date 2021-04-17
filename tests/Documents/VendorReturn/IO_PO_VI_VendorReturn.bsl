// Check creation Return to Vendor based on Vendor Invoice with
// restore Internal Orders and Purchase Orders needs. 
// - Create InternalOrder
// - Create PurchaseOrder based on InternalOrder
// - Create VendorInvoice based on PurchaseOrder
// - Create VendorReturn based on VendorInvoice
// - Post & CheckTemplate

Call ( "Common.Init" );
CloseAll ();

id = Call ( "Common.ScenarioID", "2BE58679" );
env = getEnv ( id );
createEnv ( env );

vendor = env.Vendor;
warehouse = env.Warehouse;
department = env.Department;
responsible = env.Responsible;
items = env.Items;

// *********************************
// Internal Order: Send For Approval
// *********************************

Commando("e1cib/command/Document.InternalOrder.Create");
form = With ( "Internal Order (cr*" );
Set ( "#Responsible", responsible );
Set ( "#Department", department );
Set ( "#Warehouse", warehouse );
Set ( "#Memo", id );
table = Activate ( "#ItemsTable" );
for each row in items do
	Click ( "#ItemsTableAdd" );
	Set ( "#ItemsItem", row.Item, table );
	Put ( "#ItemsQuantity", row.Quantity, table );
	Put ( "#ItemsPrice", row.Price, table );
enddo;
Click ( "#FormSendForApproval");
With ();
Click ( "Yes" );

// *********************************
// Internal Order: Complete Approval
// *********************************
Commando("e1cib/list/Document.InternalOrder");
form = With ( "Internal Orders" );
Put ( "#StatusFilter", "All" );
Clear ( "#WarehouseFilter" );
Clear ( "#DepartmentFilter" );
list = Activate ( "#List", form );
GoToRow ( list, "Memo", id );
Click ( "#FormChange" );
With ( "Internal Order #*" );
Click ( "#FormCompleteApproval" );
With ();
Click ( "Yes" );
With ( form );
Click ( "#FormDocumentPurchaseOrderCreateBasedOn" );
Close ( form );

// *************************
// Create PurchaseOrder
// *************************

form = With ( "Purchase Order (cr*" );
Set ( "#Vendor", vendor );
Set ( "#Warehouse", warehouse );
Set ( "#Department", department );
Set ( "#Memo", id );
table = Activate ( "#Payments" );
Click ( "#PaymentsAdd" );
Set ( "#PaymentsPaymentOption", "no discounts" );
Click ( "#FormPost", form );
Click ( "#FormDocumentVendorInvoiceCreateBasedOn", form );
Close ( form );

// *************************
// Create VendorInvoice
// *************************

form = With ( "Vendor Invoice (cr*" );
Click ( "#FormPost", form );
Click ( "#FormDocumentVendorReturnCreateBasedOn", form );
Close ( form );

// *************************
// Create VendorReturn
// *************************

form = With ( "Return to Vendor (cr*" );
Set ( "#Memo", id );
Click ( "#FormPost", form );

// *************************
// Post & CheckTemplate
// *************************

Click ( "#FormReportRecordsShow" );
With ( "Records: Return *" );
CheckTemplate ( "#TabDoc" );

// *************************
// Procedures
// *************************

Function getEnv ( ID )

	p = new Structure ();
	p.Insert ( "ID", ID );
	p.Insert ( "User", Call ( "Common.User" ) );
	p.Insert ( "Department", "Department " + ID );
	p.Insert ( "Responsible", "Responsible " + ID );
	p.Insert ( "Warehouse", "Warehouse " + ID );
	p.Insert ( "Vendor", "Vendor " + ID );
	p.Insert ( "Contract", "General" );
	p.Insert ( "Items", getItems ( ID ) );
	return p;

EndFunction

Function getItems ( ID )

	list = new Array ();
	list.Add ( getItem ( "Item1 " + ID, "10.00", "5" ) );
	list.Add ( getItem ( "Item2 " + ID, "15.00", "10" ) );
	list.Add ( getItem ( "Item3 " + ID, "35.00", "20" ) );
	return list;

EndFunction

Function getItem ( Description, Price, Quantity )

	p = new Structure ();
	p.Insert ( "Item", Description );
	p.Insert ( "Price", Price );
	p.Insert ( "Quantity", Quantity );
	return p;	

EndFunction

Procedure createEnv ( Env )

	id = Env.ID;
	if ( EnvironmentExists ( id ) ) then
		return;
	endif;
	
	// *************************
	// Create Warehouse
	// *************************
	
	p = Call ( "Catalogs.Warehouses.Create.Params" );
	p.Description = Env.Warehouse;
	Call ( "Catalogs.Warehouses.Create", p );
	
	// *************************
	// Create Department
	// *************************
	
	p = Call ( "Catalogs.Departments.Create.Params" );
	p.Description = Env.Department;
	Call ( "Catalogs.Departments.Create", p );
	
	// ***********************************
	// Create Depatment Head
	// ***********************************

	Commando ( "e1cib/command/Document.Roles.Create" );
	form = With ( "Roles (create)" );
	Set ( "#User", Env.User );
	Pick ( "#Role", "Department Head" );
	Set ( "#Department", Env.Department );
	Set ( "#Memo", id );
	Click ( "#Apply" );
	
	// *************************
	// Create Responsible
	// *************************
	
	p = Call ( "Catalogs.Employees.Create.Params" );
	p.Description = Env.Responsible;
	Call ( "Catalogs.Employees.Create", p );
	
	// *************************
	// Create Vendor
	// *************************
	
	p = Call ( "Catalogs.Organizations.CreateVendor.Params" );
	p.Description = Env.Vendor;
	p.ClearTerms = true;
	Call ( "Catalogs.Organizations.CreateVendor", p );
	
	// *************************
	// Create Items
	// *************************
	
	p = Call ( "Catalogs.Items.Create.Params" );
	for each row in env.Items do
		p.Description = row.Item;
		Call ( "Catalogs.Items.Create", p );
	enddo;
		
	RegisterEnvironment ( id );
	
EndProcedure