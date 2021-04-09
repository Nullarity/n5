// Create Purchase Order
// Create Vendor Invoice based on Purchase Order
// Create Vendor Return based on Vendor Invoice
// Check Records

Call ( "Common.Init" );
CloseAll ();

id = Call ( "Common.ScenarioID", "2BE590F1" );
env = getEnv ( id );
createEnv ( env );

vendor = env.Vendor;
warehouse = env.Warehouse;
department = env.Department;
items = env.Items;

// *************************
// Create Purchase Order
// *************************

Commando("e1cib/command/Document.PurchaseOrder.Create");
form = With ( "Purchase Order (cr*" );
Put ( "#Vendor", vendor );
Put ( "#Warehouse", warehouse );
Put ( "#Department", department );
Put ( "#Memo", id );
table = Activate ( "#ItemsTable" );
for each row in items do
	Click ( "#ItemsTableAdd" );
	Put ( "#ItemsItem", row.Item, table );
	Put ( "#ItemsQuantity", row.Quantity, table );
	Put ( "#ItemsPrice", row.Price, table );
enddo;
table = Activate ( "#Payments" );
Click ( "#PaymentsAdd" );
Put ( "#PaymentsPaymentOption", "no discounts" );
Click ( "#FormPost", form );
Click ( "#FormDocumentVendorInvoiceCreateBasedOn", form );
Close ( form );

// *************************
// Create Vendor Invoice
// *************************

form = With ( "Vendor Invoice (cr*" );
Put ( "#Memo", id );
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
	p.Insert ( "Department", "Department " + ID );
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