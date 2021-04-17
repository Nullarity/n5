// Create an Internal Order on Warehouse1 with future reservations
// Create Vendor Invoice and receive items on Warehouse2
// Check Items report: Warehouse2 should have reserve
// Transfer items from Warehouse2 to Warehouse1
// Check Items report: Warehouse1 should have reserve
// Write Off items from Warehouse1
// Check Items report: report should be empty

Call ( "Common.Init" );
CloseAll ();

id = Call ( "Common.ScenarioID", "27DC49D6" );
env = getEnv ( id );
createEnv ( env );

// Check Items report: Warehouse2 should have reserve
Run ( "CheckReserveWarehouse2", env );

// Transfer items from Warehouse2 to Warehouse1
Commando("e1cib/command/Document.Transfer.Create");
With();
Set ( "#Sender", env.Warehouse2 );
Set ( "#Receiver", env.Warehouse1 );
Click ( "#ItemsSelectItems" );
With();
if ( "Yes" <> Fetch ( "#AskDetails" ) ) then
	Click ( "#AskDetails" );
endif;
table = Get("#ItemsList");
GotoRow(table, "Item", env.Item);
table.Choose ();
With();
Click("#ChangeReservationChangeReserveQuantity");
With();
Click("#FormOK");
With();
Click("#FormOK");
With();
Click("#FormPost");

// Check Items report: Warehouse1 should have reserve
Run ( "CheckReserveWarehouse1", env );

// Write Off items from Warehouse1
Commando("e1cib/command/Document.WriteOff.Create");
With();
Set ( "#Warehouse", env.Warehouse1 );
Set ( "#ExpenseAccount", "8111" );
Click ( "#ItemsSelectItems" );
With();
table = Get("#ItemsList");
GotoRow(table, "Item", env.Item);
table.Choose ();
With();
Click("#ChangeReservationChangeReserveQuantity");
With();
Click("#FormOK");
With();
Click("#FormOK");
With();
Click("#FormPost");

// Check Items report: report should be empty
Run ( "CheckIfWarehouse1Empty", env );

// *************************
// Procedures
// *************************

Function getEnv ( ID )
	
	p = new Structure ();
	p.Insert ( "ID", ID );
	p.Insert ( "IODate", CurrentDate () );
	p.Insert ( "Item", "Item " + ID );
	p.Insert ( "Department", "Department " + ID );
	p.Insert ( "Warehouse1", "Warehouse1 " + ID );
	p.Insert ( "Warehouse2", "Warehouse2 " + ID );
	p.Insert ( "Vendor", "Vendor " + ID );
	return p;
	
EndFunction

Procedure createEnv ( Env )
	
	id = Env.ID;
	if ( EnvironmentExists ( id ) ) then
		return;
	endif;
	
	// *************************
	// Create Department
	// *************************
	
	p = Call ( "Catalogs.Departments.Create.Params" );
	p.Description = Env.Department;
	Call ( "Catalogs.Departments.Create", p );
	
	// *************************
	// Create Item
	// *************************
	
	p = Call ( "Catalogs.Items.Create.Params" );
	p.Description = Env.Item;
	Call ( "Catalogs.Items.Create", p );
	
	// *************************
	// Create Warehouses
	// *************************
	
	p = Call ( "Catalogs.Warehouses.Create.Params" );
	p.Description = Env.Warehouse1;
	Call ( "Catalogs.Warehouses.Create", p );
	p.Description = Env.Warehouse2;
	Call ( "Catalogs.Warehouses.Create", p );
	
	// ***********************************
	// Roles: Division head
	// ***********************************
	
	Commando ( "e1cib/list/Document.Roles" );
	list = With ();
	Click ( "#FormCreate" );
	With ();
	Set ( "#User", "admin" );
	Pick ( "#Role", "Department Head" );
	Put ( "#Department", Env.Department );
	Click ( "#Apply" );
	
	// *************************
	// Create Vendor
	// *************************
	
	p = Call ( "Catalogs.Organizations.CreateVendor.Params" );
	p.Description = Env.Vendor;
	Call ( "Catalogs.Organizations.CreateVendor", p );
	
	// ***********************************
	// Internal Order & Approval
	// ***********************************
	
	p = Call ( "Documents.InternalOrder.CreateApproveOneUser.Params");
	p.Date = Env.IODate;
	p.Responsible = "admin";
	p.Warehouse = Env.Warehouse1;
	p.Department = Env.Department;
	list = new Array ();
	item = Call ( "Documents.InternalOrder.CreateApproveOneUser.ItemsRow");
	item.Item = Env.Item;
	item.Quantity = 5;
	item.Price = 10;
	item.Reservation = "Next Receipts";
	p.Items.Add ( item );
	Call ( "Documents.InternalOrder.CreateApproveOneUser", p);
	
	// ***********************************
	// Create Vendor Invoice, Warehouse 2
	// ***********************************
	
	Commando("e1cib/list/Document.InternalOrder");
	With();
	Click("#FormDocumentVendorInvoiceCreateBasedOn");
	With();
	Set ( "#Vendor", Env.Vendor );
	Set ( "#Warehouse", Env.Warehouse2 );
	Click ( "#FormPostAndClose" );
	
	RegisterEnvironment ( id );
	
EndProcedure
