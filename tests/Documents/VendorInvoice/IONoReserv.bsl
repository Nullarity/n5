// Create IO without reserves
// Create VI based on IO
// Check if IO has been closed

Call("Common.Init");
CloseAll();

id = Call("Common.ScenarioID", "2B8A8A89");
env = getEnv(id);
createEnv(env);

// Create VI based on IO
Commando("e1cib/list/Document.InternalOrder");
Set("#WarehouseFilter", env.Warehouse);
Next ();
Click("#FormDocumentVendorInvoiceCreateBasedOn");

// Check if IO has been closed
With();
Set("#Vendor", env.Vendor);
Next ();
Click("#FormPost");
Click("#FormReportRecordsShow");
With();
CheckTemplate("#TabDoc");

// *************************
// Procedures
// *************************

Function getEnv(ID)
	
	p = new Structure();
	p.Insert("ID", ID);
	p.Insert("Warehouse", "Warehouse " + ID );
	p.Insert("Department", "Department " + ID );
	p.Insert("Responsible", "Admin" );
	p.Insert("Vendor", "Vendor " + ID );
	p.Insert("Item", "Item " + ID );
	return p;
	
EndFunction

Procedure createEnv(Env)
	
	id = Env.ID;
	if (EnvironmentExists(id)) then
		return;
	endif;
	
	// *************************
	// Create Warehouse
	// *************************
	
	p = Call ( "Catalogs.Warehouses.Create.Params");
	p.Description = Env.Warehouse;
	Call ( "Catalogs.Warehouses.Create", p);
	
	// *************************
	// Create Department
	// *************************
	
	p = Call ( "Catalogs.Departments.Create.Params");
	p.Description = Env.Department;
	Call ( "Catalogs.Departments.Create", p);
	
	// ***********************************
	// Create Roles
	// **********************************
	
	MainWindow.ExecuteCommand ( "e1cib/list/Document.Roles" );
	list = With ( "Roles" );
	Click ( "#FormCreate" );
	With ( "Roles (create)" );
	Set ( "#User", "Admin" );
	Pick ( "#Role", "Department Head" );
	Set ( "#Department", Env.Department );
	CurrentSource.GotoNextItem ();
	Click ( "#Apply" );
	Close ( list );
	
	// *************************
	// Create Vendor
	// *************************
	
	p = Call ( "Catalogs.Organizations.CreateVendor.Params");
	p.Description = Env.Vendor;
	Call ( "Catalogs.Organizations.CreateVendor", p);
	
	// *************************
	// Create Item
	// *************************
	
	p = Call ( "Catalogs.Items.Create.Params");
	p.Description = Env.Item;
	Call ( "Catalogs.Items.Create", p);
	
	// *************************
	// Create IO
	// *************************
	
	items = new Array();
	row = Call ( "Documents.InternalOrder.CreateApproveOneUser.ItemsRow");
	row.Item = Env.Item;
	row.Quantity = 1;
	row.Price = 1;
	items.Add(row);
	p = Call ( "Documents.InternalOrder.CreateApproveOneUser.Params");
	p.Date = CurrentDate() - 86400;
	p.Warehouse = Env.Warehouse;
	p.Department = Env.Department;
	p.Responsible = Env.Responsible;
	p.Items = items;
	Call ( "Documents.InternalOrder.CreateApproveOneUser", p);
	
	RegisterEnvironment(id);
	
EndProcedure

