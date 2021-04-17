// Create & fill SalesOrder
// Create ProductionOrder based on SalesOrder
// Post & check records

Call ( "Common.Init" );
CloseAll ();

id = Call ( "Common.ScenarioID", "2A0E221B" );
env = getEnv ( id );
createEnv ( env );

// Find SO
Commando("e1cib/list/Document.SalesOrder");
With();
Set("#CustomerFilter", env.Customer);
Next();
Click("#FormDocumentProductionOrderCreateBasedOn");
With();
Put("#Workshop", env.Workshop);
Click("#FormPost");
Click("#FormReportRecordsShow");
With();
Call("Common.CheckLogic", "#TabDoc");

// *************************
// Procedures
// *************************

Function getEnv ( ID )
	
	p = new Structure ();
	p.Insert ( "ID", ID );
	p.Insert ( "SODate", CurrentDate () - 86400 );
	p.Insert ( "Customer", "Customer " + ID );
	p.Insert ( "Workshop", "Workshop " + ID );
	p.Insert ( "Department", "Department " + ID );
	p.Insert ( "Warehouse", "Warehouse " + ID );
	p.Insert ( "Item", "Item " + ID );
	return p;
	
EndFunction

Procedure createEnv ( Env )
	
	id = Env.ID;
	if ( EnvironmentExists ( id ) ) then
		return;
	endif;
	
	// *************************
	// Create Customer
	// *************************
	
	p = Call ( "Catalogs.Organizations.CreateCustomer.Params" );
	p.Description = Env.Customer;
	Call ( "Catalogs.Organizations.CreateCustomer", p );
	
	// *************************
	// Create Department
	// *************************
	
	p = Call ( "Catalogs.Departments.Create.Params" );
	p.Description = Env.Department;
	p.Production = true;
	Call ( "Catalogs.Departments.Create", p );
	
	// *************************
	// Create Workshop
	// *************************
	
	p = Call ( "Catalogs.Warehouses.Create.Params" );
	p.Description = Env.Workshop;
	p.Production = true;
	p.Department = Env.Department;
	Call ( "Catalogs.Warehouses.Create", p );
	
	// *************************
	// Create Warehouse
	// *************************
	
	p = Call ( "Catalogs.Warehouses.Create.Params" );
	p.Description = Env.Warehouse;
	Call ( "Catalogs.Warehouses.Create", p );
	
	// *************************
	// Create Item
	// *************************
	
	p = Call ( "Catalogs.Items.Create.Params" );
	p.Product = true;
	p.Description = Env.Item;
	Call ( "Catalogs.Items.Create", p );
	
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
	
	// ***********************************
	// Sales Order & Approval
	// ***********************************
	
	p = Call ( "Documents.SalesOrder.CreateApproveOneUser.Params");
	p.Date = env.SODate;
	p.Customer = env.Customer;
	p.Warehouse = env.Warehouse;
	p.Department = env.Department;
	p.Shipments = false;
	list = new Array ();
	item = Call ( "Documents.SalesOrder.CreateApproveOneUser.ItemsRow");
	item.Item = env.Item;
	item.Quantity = 3;
	item.Price = 10;
	item.Reservation = "Next Receipts";
	p.Items.Add ( item );
	Call ( "Documents.SalesOrder.CreateApproveOneUser", p);
	
	RegisterEnvironment ( id );
	
EndProcedure
