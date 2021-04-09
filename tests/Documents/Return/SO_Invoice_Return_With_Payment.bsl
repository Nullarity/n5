// Create Sales Order with Reservation "Next Receipts"
// Create Vendor Invoice based on Sales Order
// Create Invoice based on Sales Order
// Create Payment based on Sales Order
// Create Return based on Invoice
// Check Records

Call ( "Common.Init" );
CloseAll ();

id = Call ( "Common.ScenarioID", "2BE61F06" );
env = getEnv ( id );
createEnv ( env );

// *************************
// Create Sales Order
// *************************

p = Call ( "Documents.SalesOrder.CreateApproveOneUser.Params" );
p.Customer = env.Customer;
p.Warehouse = env.Warehouse;
p.Department = env.Department;
p.Memo = id;
p.Shipments = false;
items = p.Items;
for each row in env.Items do
	newRow = Call ( "Documents.SalesOrder.CreateApproveOneUser.ItemsRow" );
	FillPropertyValues ( newRow, row );
	newRow.Quantity = row.Quantity / 5;
	newRow.Price = row.RetailPrice;
	newRow.Reservation = "Next Receipts";
	items.Add ( newRow );
enddo;
number = Call ( "Documents.SalesOrder.CreateApproveOneUser", p );

// *************************
// Create Vendor Invoice
// *************************

ordersForm = Commando ( "e1cib/list/Document.SalesOrder" );
table = Activate ( "#List" );
GoToRow ( table, "Number", number );
Click ( "#FormDocumentVendorInvoiceCreateBasedOn", ordersForm );
form = With ( "Vendor Invoice (cr*" );
Put ( "#Vendor", env.Vendor );
table = Activate ( "#ItemsTable" );
items = env.Items;
ubound = items.UBound ();
for each row in items do
	Set ( "#ItemsPrice", row.Price, table );
	if ( items.Find ( row ) < ubound ) then
		table.GotoNextRow ();
	endif;
enddo;
Click ( "#FormPost", form );

// *************************
// Create Invoice
// *************************

Click ( "#FormDocumentInvoiceCreateBasedOn", ordersForm );
invoiceForm = With ( "Invoice (cr*" );
Click ( "#FormPost", invoiceForm );

// *************************
// Create Payment
// *************************

Click ( "#FormDocumentPaymentCreateBasedOn", ordersForm );
form = With ( "Customer Payment (cr*" );
Set ( "#Amount", "200.00" );
Set ( "#Account", "2422" );
Click ( "#FormPost", form );

// *************************
// Create Return
// *************************

With ( invoiceForm );
Click ( "#FormDocumentReturnCreateBasedOn" );
form = With ( "Return from Customer (cr*" );
Click ( "#FormPost", form );
Click ( "#FormReportRecordsShow", form );
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
	list.Add ( getItem ( "Item1 " + ID, "10.00", "20.00", "10" ) );
	list.Add ( getItem ( "Item2 " + ID, "15.00", "30.00", "20" ) );
	list.Add ( getItem ( "Item3 " + ID, "20.00", "40.00", "30" ) );
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
	Set ( "#Department", Env.Department );
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
	p.Terms = "Due on receipt";
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