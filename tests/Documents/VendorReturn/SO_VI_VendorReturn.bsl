// Create Sales Order
// Create Vendor Invoice based on Sales Order
// Create Vendor Return based on Vendor Invoice
// Check Records

Call ( "Common.Init" );
CloseAll ();

id = Call ( "Common.ScenarioID", "2B6EB069" );
env = getEnv ( id );
createEnv ( env );

vendor = env.Vendor;
customer = env.Customer;
warehouse = env.Warehouse;
department = env.Department;
items = env.Items;

// *********************************
// Sales Order: Send For Approval
// *********************************

Commando("e1cib/command/Document.SalesOrder.Create");
form = With ( "Sales Order (cr*" );
Put ( "#Customer", customer );
Put ( "#Department", department );
Put ( "#Warehouse", warehouse );
Put ( "#Memo", id );
table = Activate ( "#ItemsTable" );
for each row in items do
	Click ( "#ItemsTableAdd" );
	Put ( "#ItemsItem", row.Item, table );
	Put ( "#ItemsQuantity", row.Quantity, table );
	Put ( "#ItemsPrice", row.RetailPrice, table );
	table.EndEditRow ();
	table.ChangeRow ();
	Pick ( "#ItemsReservation", "Next Receipts", table );
enddo;
table = Activate ( "#Payments" );
Click ( "#PaymentsAdd" );
Put ( "#PaymentsPaymentOption", "no discounts" );
Click ( "#FormSendForApproval", form );
With ();
Click ( "Yes" );

// *********************************
// Sales Order: Complete Approval
// *********************************

Commando("e1cib/list/Document.SalesOrder");
form = With ( "Sales Orders" );
list = Activate ( "#List", form );
GoToRow ( list, "Memo", id );
Click ( "#FormChange" );
With ( "Sales Order #*" );
Click ( "#FormCompleteApproval" );
With ();
Click ( "Yes" );
With ( form );
Click ( "#FormDocumentVendorInvoiceCreateBasedOn" );
Close ( form );

// *************************
// Create Vendor Invoice
// *************************

form = With ( "Vendor Invoice (cr*" );
Put ( "#Vendor", vendor );
Put ( "#Warehouse", warehouse );
Put ( "#Memo", id );
table = Activate ( "#ItemsTable" );
for i = 0 to items.UBound () do
	GoToRow ( table, "#", i + 1 );
	Put ( "#ItemsPrice", items [ i ].Price, table );
enddo;
Click ( "#FormPost", form );
Click ( "#FormDocumentVendorReturnCreateBasedOn", form );
Close ( form );

// *************************
// Create Vendor Return
// *************************

form = With ( "Return to Vendor (cr*" );
Put ( "#Memo", id );
Click ( "#FormPost", form );

// *************************
// Check Records
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
	p.Insert ( "Warehouse", "Warehouse " + ID );
	p.Insert ( "Vendor", "Vendor " + ID );
	p.Insert ( "Customer", "Customer " + ID );
	p.Insert ( "Items", getItems ( ID ) );
	return p;

EndFunction

Function getItems ( ID )

	list = new Array ();
	list.Add ( getItem ( "Item1 " + ID, "10.00", "15.00", "5" ) );
	list.Add ( getItem ( "Item2 " + ID, "15.00", "22.00", "10" ) );
	list.Add ( getItem ( "Item3 " + ID, "35.00", "50.00", "20" ) );
	return list;

EndFunction

Function getItem ( Description, Price, RetailPrice, Quantity )

	p = new Structure ();
	p.Insert ( "Item", Description );
	p.Insert ( "Price", Price );
	p.Insert ( "RetailPrice", RetailPrice );
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
	Put ( "#User", Env.User );
	Put ( "#Role", "Department Head" );
	Put ( "#Department", Env.Department );
	Put ( "#Memo", id );
	Click ( "#Apply" );
	
	// *************************
	// Create Vendor
	// *************************
	
	p = Call ( "Catalogs.Organizations.CreateVendor.Params" );
	p.Description = Env.Vendor;
	p.ClearTerms = true;
	Call ( "Catalogs.Organizations.CreateVendor", p );
	
	// *************************
	// Create Customer
	// *************************
	
	p = Call ( "Catalogs.Organizations.CreateCustomer.Params" );
	p.Description = Env.Customer;
	p.ClearTerms = true;
	Call ( "Catalogs.Organizations.CreateCustomer", p );
	
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